> **공개용 편집본:** 운영 식별자를 예시 값으로 치환했다. 원본 설정·실험 로그는 비공개 로컬 보관이며 이 폴더에는 포함되지 않는다. 아래의 원본/바이트 보존 표현은 수집 당시 이력을 뜻하며 공개 파일의 원본 일치를 주장하지 않는다. 실서버 적용용이 아니다.

# 인프라·모니터링 구성과 수집 지표

> 이 문서는 기존 팀 저장소에 **새 폴더로만 추가할 참고·검증 기록**이며, 운영 중인 VM/CloudWatch/ALB/Terraform 설정을 변경하지 않습니다.

## 1. 프로젝트 목표와 본인 담당 범위

### 1.1 프로젝트 배경

- **프로젝트:** Ferrot / KT Cloud 인프라 과정 팀 하이브리드 프로젝트.
- **서비스:** Pretix 예매 서비스. 평시 AWS 애플리케이션으로 요청을 처리하고, 장애 시 온프레미스 k3s의 Nginx/Pretix로 ALB 가중치를 전환하는 구조.
- **데이터:** AWS 앱과 온프렘 앱이 온프렘 PostgreSQL을 사용. AWS와 온프렘 간 통신에 WireGuard 경유.
- **운영 검증:** AWS 앱 고가용성 및 Auto Scaling, AWS→온프렘 전환, 온프렘 부하, WireGuard 허브 장애·복구.

### 1.2 본인 직접 수행/담당한 작업

- Ubuntu Monitoring VM 관리와 WireGuard를 통한 Rocky Exporter 수집 경로 점검.
- Prometheus / Grafana / Blackbox Exporter 활용, 서비스·서버·네트워크 지표 통합 대시보드 구성.
- Grafana 패널을 시나리오별 접이식 행(row)으로 묶어 필요한 관측 지표를 동시에 비교.
- 시나리오 3A에서 **AWS CloudShell `hey` c20/c100 직접 실행**, Ubuntu 별도 `curl` 로그인 프로브 로그 기록, Grafana 관측, 결과 분석.
- 시나리오 3B에서 온프렘 지표 모니터링 및 **2026-10-26 WireGuard 직접 연결 c2 예비 테스트** 수행, 고부하 재검증 보류 판단.
- **2026-10-25** Grafana CloudWatch 읽기 전용 IAM 사용자 및 데이터소스 구성, `No data` 쿼리 설정 문제 해결.
- 팀원들이 수행한 장애 주입, ALB 가중치 전환, AWS ASG·Lambda 구성 결과를 지표로 비교·검증. 팀원 담당 인프라 작업을 본인이 구축했다고 기재하지 않음.

### 1.3 팀 협업 구분

| 영역 | 담당 | 본 노트에서 다루는 범위 |
|---|---|---|
| AWS VPC, ALB, 대상 그룹, 앱/허브 ASG, 가중치 | AWS 인프라 담당 팀원 | 기존 구성 사용, 상태/지표 교차 검증 |
| CloudWatch 경보 → SNS → Lambda 자동 전환 | IaC/AWS 모니터링 담당 팀원 | 경보·전환 결과와 Grafana 관측 시간 구분 |
| Rocky Linux, k3s Nginx/Pretix/Redis, PostgreSQL | 온프렘 담당 팀원 | Exporter/Pod/서버 상태 수집과 부하 영향 관측 |
| Ubuntu Monitoring VM, Prometheus·Grafana, AWS 지표 통합 | 본인 | 이 문서의 중심 구현·운영 작업 |

---

## 2. 시스템 구성 및 주요 통신 경로

### 2.1 확인된 주요 대상

| 대상 | 주소 / 경로 | 역할 | 포트·프로토콜 |
|---|---|---|---|
| 사용자 → AWS ALB | 공개 ALB 주소 | HTTP 진입점 / 가중치 분기 | TCP 80 |
| AWS WireGuard 허브 | `wg0 192.0.2.1` | AWS↔온프렘 VPN 중계 | 외부 UDP 51820 |
| Rocky 온프렘 | `wg0 192.0.2.2` | k3s Nginx/Pretix/Redis, PostgreSQL | 내부 TCP 80, 5432 등 |
| Ubuntu Monitoring VM | `wg0 192.0.2.3` | Prometheus / Grafana / Blackbox | TCP 9090 / 3000 / 9115 |
| Ubuntu Monitoring VM | LAN `192.0.2.6` | 관리자 접근용 LAN 주소 | 내부망 전용 |
| Rocky Node Exporter | `192.0.2.2:9100` | CPU / 메모리 / 디스크 / 네트워크 | TCP 9100 |
| Rocky Nginx Exporter | `192.0.2.2:9113` | Nginx 요청량 / 연결 수 | TCP 9113 |
| Rocky k3s 상태 메트릭 | `192.0.2.2:32180` | Pod/Deployment 운영 상태 | TCP 32180 |
| Rocky 앱 직접 테스트 경로 | `192.0.2.2:30637` | k3s Nginx NodePort → Pretix | TCP 30637 |
| AWS CloudWatch | `ap-northeast-2` | AWS EC2 / ASG / ALB 대상 그룹 메트릭 | AWS API |

**주의:** `192.0.2.1~3`은 VPN **내부 주소**다. UDP 51820은 허브의 외부 VPN 접속 포트이며, 9100/9113/32180/9090/3000이 인터넷에 모두 공개돼 있다는 뜻이 아니다. AWS 보안 담당 영역에서는 외부 진입을 ALB(TCP 80)와 WG(UDP 51820)로 제한했다고 설명했다. 모니터링 접근 제어는 실제 배포 규칙과 별도로 점검한다.

### 2.2 수집·서비스 경로

```text
[사용자 / hey / curl]
       │ HTTP
       ▼
     AWS ALB ── 가중치 ──┬── AWS Pretix EC2 ASG
                          └── WG 허브 ── Rocky k3s Nginx → Pretix
                                              └── PostgreSQL (온프렘)

[Ubuntu Monitoring VM / wg0 192.0.2.3]
  ├─ Prometheus :9090 ── scrape over WG ── Rocky :9100 / :9113 / :32180
  │                      └─ Blackbox :9115 ── ALB /healthcheck/ HTTP 검사
  └─ Grafana :3000
       ├─ Prometheus 데이터소스 → ALB 프로브 / Rocky / Nginx / k3s / wg0
       └─ CloudWatch 데이터소스 → AWS EC2 / ASG / Target Group / ALB
```

- Prometheus는 **Exporter가 노출하는 메트릭을 pull(scrape)** 한다. Grafana는 Prometheus 또는 CloudWatch API를 조회해 시각화한다.
- WireGuard가 끊겨 Exporter 수집이 실패해도, Rocky 프로세스가 실제 종료됐다고 단정할 수 없다.
- ALB 가중치 평시 `AWS 100 : 온프렘 0`, 장애 전환 후 `AWS 0 : 온프렘 100`. **AWS 복귀는 팀원 확인 후 수동 원복**하도록 설계한 회차 기록이 있다.
- CloudWatch 경보→SNS→Lambda의 **자동 가중치 전환**과 본인의 **Grafana 관측**은 담당과 측정 기준이 다르다.

---

### 2.3 2026-10-28 실제 컨테이너 실행 구성의 추가 확인

실제 `docker-compose.yml`에 `prometheus`, `grafana`, `blackbox` 3개 서비스가 있다. Prometheus와 Grafana는 호스트 전체 인터페이스에 각각 TCP 9090/3000을 바인딩하고, Blackbox TCP 9115는 호스트 루프백에만 바인딩한다. 기본 Compose 네트워크를 통해 컨테이너 내부에서 `blackbox:9115`에 접근할 수 있다. 실제 외부 노출은 방화벽과 호스트 네트워크 조건을 따로 확인해야 한다. 자세한 사항은 [실제 Compose/Blackbox 스냅샷](runtime-compose-blackbox-2026-10-28.md) 참고.

## 3. Prometheus·Grafana 통합 모니터링 구성

### 3.1 수집 목표

1. **서비스 접근 가능 여부:** Blackbox의 ALB HTTP 검사 `probe_success`와 검사 시간.
2. **메트릭 수집 경로:** Prometheus `up`으로 Rocky Node, Nginx, k3s Exporter 수집 성공/실패.
3. **서버 자원:** CPU, 메모리, 디스크, WireGuard `wg0` 네트워크 RX/TX.
4. **애플리케이션 앞단:** Nginx RPS(초당 요청), 활성 연결 수.
5. **k3s:** Pod Running/Pending 및 재시작 증가분.
6. **AWS:** CloudWatch API의 ASG Desired/InService, EC2 CPU, Target Group Healthy, ALB TargetResponseTime.

### 3.2 Prometheus Job / 관제 항목

| Job / 지표 | 의미 | 해석 시 주의 |
|---|---|---|
| `team-rocky-node` / `up` | Rocky Node Exporter 수집 성공(1)/실패(0) | OS 자체 생존 판정 아님 |
| `team-rocky-nginx` / `up` | Nginx Exporter 수집 여부 | HTTP 서비스 정상 판정과 별도 |
| `team-k3s-state` / `up` | k3s 상태 메트릭 수집 여부 | 개별 Pod readiness와 별도 |
| Blackbox / `probe_success` | ALB의 설정 URL 검사 성공(1)/실패(0) | 모든 URL/로그인/주문 성공을 보장하지 않음 |
| `nginx_http_requests_total` | Nginx 누적 HTTP 요청 카운터 | `rate(...[1m])`은 대략 초당 처리량 |
| `nginx_connections_active` | 현재 활성 연결 | hey 동시성(`-c`)과 같은 숫자가 아님 |
| `node_network_receive_bytes_total` / `transmit_bytes_total` | 네트워크 누적 바이트 | `wg0` 인터페이스로 필터링하여 변화 비교 |
| `kube_pod_container_status_restarts_total` | 컨테이너 누적 재시작 | 누적값이 아니라 **실험 전후 증가분** 확인 |

### 3.3 조회·분석용 PromQL 예시

아래는 **재현용 점검 예시**이다. 실제 Grafana 패널에는 Job/레이블/시간 윈도가 다를 수 있으므로 현재 대시보드 쿼리를 우선한다.

```promql
# Exporter 수집 성공 여부
up{job="team-rocky-node"}
up{job="team-rocky-nginx"}
up{job="team-k3s-state"}

# Blackbox HTTP 검사 성공 여부
probe_success

# Rocky 전체 CPU 사용률(%)
100 * (1 - avg(rate(node_cpu_seconds_total{job="team-rocky-node", mode="idle"}[5m])))

# Rocky 메모리 사용률(%)
100 * (1 - node_memory_MemAvailable_bytes{job="team-rocky-node"}
              / node_memory_MemTotal_bytes{job="team-rocky-node"})

# Nginx 초당 요청량(RPS)
sum(rate(nginx_http_requests_total{job="team-rocky-nginx"}[1m]))

# WireGuard TX/RX (bytes/s)
rate(node_network_transmit_bytes_total{job="team-rocky-node", device="wg0"}[1m])
rate(node_network_receive_bytes_total{job="team-rocky-node", device="wg0"}[1m])
```

**PromQL 메모:** `rate`는 계속 증가하는 Counter에, `nginx_connections_active` 등 Gauge는 시점 값으로 본다. `No data`는 0이 아니며 `up=0`도 곧바로 애플리케이션 전체 장애를 의미하지 않는다. 실험 시각의 **KST와 AWS/Ubuntu의 UTC**를 맞춰 비교한다.

### 3.4 Grafana 관제판 설계

- **한 화면 상단:** ALB HTTP, Rocky/Nginx/k3s 수집 UP/DOWN, 서버 CPU·메모리·디스크.
- **중단:** Nginx RPS·활성 연결, WireGuard RX/TX, Pod 상태.
- **접이식 시나리오별 행(row):** 02 AWS→온프렘 전환 / 03A AWS Auto Scaling / 03B 온프렘 부하 / 05 WG 허브 장애.
- **2026-10-25:** CloudWatch 쿼리 문제를 고친 통합 관제판 2.3에서 EC2 CPU, ASG, TG, ALB p95 표시 확인. 이후 정리된 통합 관제판 2.4에서도 시나리오별 관측을 사용.
- **Alert 설정 여부:** 대시보드 Import/Alert List 패널 생성만으로 실제 Alert Rule과 알림 수신처가 설정되는 것은 아니다. 당시 실제 Grafana Alert Rule 적용은 미확인/미완료로 기록.

---
