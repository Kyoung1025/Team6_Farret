> **공개용 편집본:** 운영 식별자를 예시 값으로 치환했다. 원본 설정·실험 로그는 비공개 로컬 보관이며 이 폴더에는 포함되지 않는다. 아래의 원본/바이트 보존 표현은 수집 당시 이력을 뜻하며 공개 파일의 원본 일치를 주장하지 않는다. 실서버 적용용이 아니다.

# Ferrot — Prometheus · Grafana 통합 모니터링 기술 기록

> 저장소: `Kyoung1025/Team6_Farret`
> 추가 경로: `monitoring/prometheus-grafana/`
> 현재 실제 환경 추출 기준일: **2026-10-28 (KST)**
> **운영 변경이 아닌 문서/설정 백업**: 서버 재배포·대시보드 import·AWS 수정 작업을 포함하지 않음.

## 목적 및 분담

Ubuntu Monitoring VM의 Prometheus/Blackbox로 온프렘 Rocky/k3s·AWS ALB HTTP 경로를 관측하고, Grafana에서 AWS CloudWatch와 함께 지표를 교차 확인한다. AWS의 CloudWatch 경보→SNS→Lambda 자동 전환 로직은 다른 팀원이 구성한 것으로 여기서는 수정하지 않는다.

## 원본 설정 파일 (실제 추출 완료)

| 파일 | 출처와 확인 결과 |
|---|---|
| [`prometheus/prometheus.yml`](prometheus/prometheus.yml) | **2026-10-28 Ubuntu Monitoring VM에서 `docker cp prometheus:/etc/prometheus/prometheus.yml` 명령으로 직접 추출한 실제 컨테이너 내 설정.** YAML 유효, scrape job 10개. 서버에 재적용하지 않음 |
| [`grafana/ferrot-dashboard-live-v36-2026-10-28.json`](grafana/ferrot-dashboard-live-v36-2026-10-28.json) | Grafana GET `/api/dashboards/uid/example-dashboard` 결과의 `dashboard` 객체 그대로 보존. **버전 36, 패널 68개(접이식 내부 포함), 마지막 업데이트 2026-10-28 16:39 KST**. API `meta`는 코드 저장소의 JSON에서 제외 |
| [`SOURCE-PROVENANCE.md`](SOURCE-PROVENANCE.md) | 원본 추출 방법·설정 검증 한계·공개 저장소 유의사항 |

### 추가 확보한 실제 Docker 구성·실험 로그

| 파일 | 출처 및 의미 |
|---|---|
| [`docker-compose.yml`](docker-compose.yml) | 2026-10-28 Ubuntu `~/monitoring/docker-compose.yml` **실제 원본**. Prometheus/Grafana/Blackbox 3서비스, read-only config mounts, named volumes |
| [`blackbox/blackbox.yml`](blackbox/blackbox.yml) | Ubuntu `~/monitoring/blackbox/blackbox.yml` **실제 원본**. HTTP `GET`, IPv4 우선, 5초 timeout |
| [`experiments/evidence/public-results-summary.md`](experiments/evidence/public-results-summary.md) | 2026-10-26 시나리오 2 HTTP 프로브 **실제 원본**. HTTP 200 899건, 503 323건, 미완성 끝줄 1개 |
| [`experiments/evidence/public-results-summary.md`](experiments/evidence/public-results-summary.md) | 2026-10-26 시나리오 3B `hey` c2 20초 예비 테스트 **실제 원본**. HTTP 200 80건 |

확인: `diff -u`에서 VM 호스트와 컨테이너의 Prometheus 설정이 일치했으며, 실제 사용자 업로드 `prometheus.yml`도 이전 컨테이너 추출본과 **SHA-256까지 동일**했다. Docker/Blackbox 파일은 사용자 제공 VM 원본이다. 민감정보 검토는 아래 보안 항목을 따른다.

**실험 원본의 시간 해석:** 시나리오 2의 **15:12:17 첫 HTTP 503 ~ 15:17:56 첫 HTTP 200**은 339초(5분 39초)의 **검사 관측 간격**이다. 정확한 서비스 전체 다운타임 또는 Lambda 실행시간으로 기재하지 않는다.

## 주요 수집 job (설정에 존재하는 대상, UP 보장은 아님)

| 유형 | job | 대상 및 목적 |
|---|---|---|
| 이전 APP/DATA 개인 실습 설정 | `app-node`, `app-cadvisor`, `data-node`, `data-cadvisor` | LAN `192.0.2.4/153`의 Node Exporter/cAdvisor. **2026-10-28 설정에 그대로 남아 있으나 최종 팀 핵심 대상과 구분** |
| 팀 Rocky | `team-rocky-node` | `192.0.2.2:9100`, OS CPU·메모리·wg0 |
| 팀 Rocky | `team-rocky-cadvisor` | `192.0.2.2:8081`, 컨테이너 지표 (실제 수집 상태 별도 확인) |
| 팀 Rocky | `team-rocky-nginx` | `192.0.2.2:9113`, HTTP 요청률·연결 |
| 팀 k3s | `team-k3s-state` | `192.0.2.2:32180`, 15초 간격 Kubernetes 상태 |
| ALB HTTP probe | `blackbox-pretix` | AWS ALB `/healthcheck/`를 Blackbox `http_2xx`로 검사 |
| Prometheus readiness probe | `blackbox-http` | `http://prometheus:9090/-/ready` 검사 (ALB 검사가 아님) |

기본 scrape 간격 5초, 별도 설정된 `team-k3s-state`/`blackbox-http`는 15초. **실행 시점에 Prometheus가 모든 target을 UP으로 수집 중인지**는 별도 API Target 확인이 필요하다.

## 기술 문서 및 실험 결과

- [`docs/architecture-and-observability.md`](docs/architecture-and-observability.md) — 관측 구조, 경로, 포트, PromQL 개념
- [`docs/runtime-compose-blackbox-2026-10-28.md`](docs/runtime-compose-blackbox-2026-10-28.md) — **실제** Compose 서비스·마운트·포트 및 보안·재현 한계
- [`docs/cloudwatch-integration-2026-10-25.md`](docs/cloudwatch-integration-2026-10-25.md) — 읽기 전용 IAM, Grafana CloudWatch 연결, `No data` 원인/수정
- [`docs/operations-and-lessons.md`](docs/operations-and-lessons.md) — 점검/트러블슈팅/개선 사항
- [`experiments/`](experiments/) — 2026-10-21 및 2026-10-26 시나리오 2·3A·3B·5 결과와 해석 주의

**중요:** `probe_success=1`은 검사한 HTTP 경로의 성공이고, `up=1`은 exporter scrape 성공이다. 둘 다 실제 모든 사용자 기능의 정상 동작을 보장하는 값은 아니다. `No data`는 0이나 정상 상태가 아니다.

## 다른 팀원 작업물 보호

이 폴더는 오직 **새 파일을 PR로 추가하는 용도**다. 기존 `monitoring/design.md`, `monitoring/failover/`, `monitoring/discord-notifier/`, AWS Terraform, Ansible, GitHub 설정과 `main` 브랜치를 건드리지 않는다. `monitoring/prometheus-grafana/`가 이미 존재하면 덮어쓰지 말고 중단한다. 팀원 리뷰 1명 이상 받은 후에만 merge한다.

## 공개 범위와 안전

- `prometheus.yml`에는 실습 내부 IP와 AWS ALB DNS가 포함되며, Grafana JSON에는 리소스 식별자·데이터소스 UID가 들어 있다. **팀의 공개 저장소 공개 범위 승인 필요**.
- Compose YAML에는 `latest` 이미지 태그가 포함돼 있어 이미지 버전이 고정되지 않는다. 포트 9090·3000은 호스트 전체에 바인딩되므로 별도 접근 통제 점검 필요. 운영 서버에 파일을 재적용하지 않는다.
- 추출된 Grafana API 메타데이터에 `publicDashboardEnabled: true`가 있었다. 이 표시는 외부 공유가 활성화된 상태일 수 있으므로, 공개 의도가 없다면 Grafana에서 **Share externally → Revoke access**를 확인한다.
- 설정 스냅샷은 **새 환경에 바로 배포 가능한 IaC 전체가 아니다**. Prometheus 네트워크·Blackbox/Exporter 별도 구성, Grafana 데이터소스 자격 증명, UID 매핑이 필요하다. 실서버에는 import/deploy 금지.
