> **공개용 편집본:** 운영 식별자를 예시 값으로 치환했다. 원본 설정·실험 로그는 비공개 로컬 보관이며 이 폴더에는 포함되지 않는다. 아래의 원본/바이트 보존 표현은 수집 당시 이력을 뜻하며 공개 파일의 원본 일치를 주장하지 않는다. 실서버 적용용이 아니다.

# 모니터링 운영 점검·트러블슈팅·개선사항

> 이 문서는 기존 팀 저장소에 **새 폴더로만 추가할 참고·검증 기록**이며, 운영 중인 VM/CloudWatch/ALB/Terraform 설정을 변경하지 않습니다.

## 9. 재점검 명령어 모음 (안전한 조회 예시)

> 아래는 **후속 재현용 점검 예시**. 이 모든 명령을 과거 실험에서 실제 실행한 것으로 기록하지 않는다. 다른 팀원의 환경 설정 변경이나 포트 개방이 필요한 경우 먼저 협의한다.

### Ubuntu Monitoring VM

```bash
# WireGuard 피어/경로/인터페이스
sudo wg show
ip -br addr show wg0
ip route

# Rocky exporter 접근 확인
curl --connect-timeout 3 -fsS http://192.0.2.2:9100/metrics | head
curl --connect-timeout 3 -fsS http://192.0.2.2:9113/metrics | head
curl --connect-timeout 3 -fsS http://192.0.2.2:32180/metrics | head

# Prometheus/Grafana/Blackbox 포트 리슨
ss -lntp | grep -E ':(9090|3000|9115)\b'

# Blackbox 자체 수집 준비 확인 (실제 module 이름/설정은 현 구성 확인)
curl --connect-timeout 3 -I http://127.0.0.1:9115/

# 직접 온프렘 Pretix 접속 (정상 운영 중이며 테스트 허용된 경우)
curl --connect-timeout 3 -I http://192.0.2.2:30637/
```

### AWS CloudShell (읽기 전용)

```bash
aws sts get-caller-identity
aws autoscaling describe-auto-scaling-groups \
  --region ap-northeast-2 \
  --query 'AutoScalingGroups[].{ASG:AutoScalingGroupName,Desired:DesiredCapacity,InService:Instances[?LifecycleState==`InService`].InstanceId}'
aws elbv2 describe-target-groups --region ap-northeast-2 \
  --query 'TargetGroups[].[TargetGroupName,TargetGroupArn]' --output table
```

### 문제 발생 시 우선 확인 순서

| 증상 | 가장 먼저 볼 것 | 추가 확인 |
|---|---|---|
| Grafana `No data` | 데이터소스 자체 연결/시간 범위 | 레이블·CloudWatch dimensions/period/쿼리 옵션 |
| ALB `probe_success=0`, Rocky `up=1` | ALB/서비스 HTTP 접근 경로 | AWS TG Healthy, 리스너 가중치, 응답 코드 |
| Rocky Node/Nginx/k3s `up=0` | WG handshake, 수집 경로, Rocky 전원 | 포트 접근, Prometheus Target 오류, FORWARD/방화벽 |
| Nginx RPS 낮음, hey 오류 상승 | 클라이언트 측 오류·지연과 Nginx 지표 | 서버 CPU/메모리, 라우팅, 동시성·테스트 조건 |
| ASG `Desired=2`, `InService=1` | 스케일아웃 진행 중인지 | AWS TG Healthy 증가 여부 |
| Pod 재시작 숫자 증가 | 실험 전후 재시작 **증가분** | 이유/시간대, Pod 이벤트, Ready 상태 |

---

## 10. 작업 중 얻은 기술적 교훈 및 남은 과제

### 확실히 검증한 내용

- AWS/온프렘 인프라 지표를 Prometheus/Grafana와 CloudWatch로 **구분·교차 관측**할 수 있게 했다.
- 네트워크 장애와 메트릭 스크레이프 장애, HTTP 검사 실패는 **동일한 장애 판정이 아니다**.
- AWS Auto Scaling은 3A에서 **1→2대 확장 및 신규 타깃 Healthy 등록**을 확인했다.
- 3B는 **최대 처리량 검증보다 정상 기준선 확보가 선행**돼야 함을 확인했다.
- WG 허브 장애는 단일 `UP` 패널이 아니라 **Exporter, VPN 트래픽, Target Group, HTTP 검사**를 함께 봐야 한다.
- CloudWatch 데이터소스의 인증 성공과 패널 `No data` 문제는 별개이며, **Metric 쿼리 옵션·Dimension·Period**도 검증해야 한다.

### 향후 검증·개선할 항목 (미완료/추가 필요)

- [ ] Rocky VM이 충분히 유휴인 상태에서 3B 단계별 c5/c10/c20/c40 반복 실험(팀 승인 및 사전 자원 점검 필요).
- [ ] 시나리오 3B의 라우팅/부하 시작 조건·테스트 기간을 통일하고 원본 `hey` 결과와 Grafana 시간대를 같이 보존.
- [ ] 3A 과거 시간대의 EC2 인스턴스 교체 이력과 CloudWatch 지표의 ID 매핑 재확인.
- [ ] Grafana Alert Rule의 실제 적용/수신 테스트 및 유지보수 시 음소거 정책.
- [ ] 대시보드 Export JSON에서 자격증명·내부 식별자 점검 후 버전 관리.
- [ ] WG 허브 FORWARD 30637 임시 허용 규칙의 원복/영구화 여부 팀 정책에 맞춰 정리.
- [ ] `No data`와 `0`/`UP`을 혼동하지 않도록 상태 패널과 문서 표현 점검.
- [x] 2026-10-28 컨테이너의 `prometheus.yml`과 Grafana API `dashboard` JSON 확보 및 YAML/JSON 검증.
- [x] 2026-10-28 `docker-compose.yml` 및 `blackbox.yml` 실제 VM 파일 확보·문법 검증.
- [x] 시나리오 2 원본 HTTP 로그와 시나리오 3B `public-results-summary.md` 확보 및 수치 검증.
- [ ] Prometheus `/api/v1/targets` 실제 모든 job UP/DOWN 상태 조회 (설정 존재만 확인했으며 최신 target 상태 미검증).
- [ ] 시나리오 5 2026-10-26 실험의 독립 HTTP 원본 로그 추가 확보 여부 확인. 현재 Ubuntu 파일명 검색에서는 해당 날짜 로그 미발견.

---
