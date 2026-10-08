# 모니터링 설계 (초안)

AWS 쪽 알람·대시보드 설계와, 온프렘 측정값과의 대응 관계를 정리한다.
임계값은 시작값이고 부하 테스트 결과를 보고 조정한다.

## 1. 합격·먹통 기준 (성민님과 동일하게 해야함)

| 판정 | 조건 |
|---|---|
| 합격 | p95 ≤ 2초 **그리고** 에러율 < 1% |
| 먹통 | p95 > 5초 **또는** 에러율 > 5% |

## 2. 지표 대응표

| 지표 | 온프렘 (성민님) | AWS (CloudWatch) | 비고 |
|---|---|---|---|
| 응답 시간 p95 | hey 결과의 95% 지점 | ALB `TargetResponseTime` p95 | ⚠️ 아래 주의 참고 |
| 에러율 | hey 상태 코드 중 200이 아닌 비율 | (`HTTPCode_Target_5XX_Count` + `HTTPCode_ELB_5XX_Count`) ÷ `RequestCount` | ELB 5xx는 정상 서버가 없을 때 ALB가 직접 내는 502/503 |
| 처리량 | hey `Requests/sec` | ALB `RequestCount` (1분 합계 ÷ 60) | |
| CPU | `docker stats` (5초 간격) | ASG 평균 `CPUUtilization` | |
| 서버 대수 | VM 1대 고정 | ASG `GroupInServiceInstances` | |

### ⚠️ 응답 시간은 직접 비교하지 않는다

- **hey p95** = 클라이언트가 체감하는 전체 시간 (네트워크 + 온프렘 Nginx + ALB + 서버 처리)
- **ALB `TargetResponseTime`** = ALB가 EC2에 요청을 보내고 응답을 받기까지의 서버 처리 시간만

두 값을 나란히 놓으면 AWS가 실제보다 빨라 보인다.
**Before/After 비교는 hey 값 하나로만 하고**, 같은 측정 PC에서 같은 경로(공인 IP)로 잰다.
CloudWatch 값은 "왜 그렇게 나왔는지" 설명하는 보조 자료로 쓴다.

## 3. CloudWatch 알람

모든 알람은 SNS 주제 `pretix-demo-alerts`로 보낸다.

| 알람 이름 | 지표 | 조건 (시작값) | 의미 |
|---|---|---|---|
| `pretix-demo-app-cpu-high` | ASG 평균 `CPUUtilization` | 80% 초과, 5분 | 확장이 부하를 못 따라감 |
| `pretix-demo-latency-high` | ALB `TargetResponseTime` p95 | 2초 초과, 3분 | 합격 기준 위반 |
| `pretix-demo-5xx-high` | ALB `HTTPCode_Target_5XX_Count` 합계 | 분당 10건 초과 | 에러율 상승 |
| `pretix-demo-unhealthy-host` | ALB `UnHealthyHostCount` 최대 | 1 이상 | 인스턴스 장애 |

### 추가 제안 (팀 논의 필요)

| 알람 이름 | 지표 | 이유 |
|---|---|---|
| `pretix-demo-wg-down` | WireGuard 인스턴스 `StatusCheckFailed` | 터널이 끊기면 AWS의 앱 서버 전체가 DB에 접속하지 못한다 (단일 장애점) |
| `pretix-demo-nat-down` | NAT 인스턴스 `StatusCheckFailed` | NAT가 죽으면 새 EC2가 이미지를 받지 못해 확장이 멈춘다 |
| `pretix-demo-elb-5xx` | ALB `HTTPCode_ELB_5XX_Count` | 정상 서버가 0대일 때는 Target 5xx가 아니라 ELB 5xx로 집계된다 |

## 4. 시연 대시보드 `pretix-demo`

한 화면에 아래 위젯을 둔다. 시간 범위는 시연 구간(예: 30분), 1분 간격.

| 위치 | 위젯 | 지표 |
|---|---|---|
| 1행 왼쪽 | 서버 대수 | ASG `GroupInServiceInstances`, `GroupDesiredCapacity` |
| 1행 오른쪽 | 요청 수 | ALB `RequestCount` |
| 2행 왼쪽 | 응답 시간 | ALB `TargetResponseTime` p50, p95 |
| 2행 오른쪽 | 에러 | ALB `HTTPCode_Target_5XX_Count`, `HTTPCode_ELB_5XX_Count` |
| 3행 왼쪽 | CPU | ASG 평균 `CPUUtilization` |
| 3행 오른쪽 | 터널 트래픽 | WireGuard 인스턴스 `NetworkIn`, `NetworkOut` |

온프렘 VM의 CPU·메모리는 CloudWatch에 들어오지 않는다. 측정 때 `docker stats` 기록을 따로 남긴다.

## 5. SNS

- 주제 이름: `pretix-demo-alerts`
- 구독: 팀원 이메일 6개. 확인 메일의 링크를 각자 눌러야 구독이 확정된다
- 오늘은 콘솔로 만들고, 나중에 `terraform/alarms.tf`로 옮긴다

## 6. 성민님과 맞출 것

- [ ] 측정 경로: Before(온프렘 단독)도 공인 IP 경로로 한 번 더 잴지
- [ ] 측정 URL: 모든 단계에서 같은 이벤트 페이지
- [ ] 에러율 계산: hey의 "200이 아닌 비율"에 302(리다이렉트)를 에러로 셀지
- [ ] 기록 시각: 측정 시작·종료 시각을 적어 두면 CloudWatch 그래프와 맞춰 볼 수 있다
- [x] 온프렘 지표 수집 방식 (7번 참고): 이번 주는 수기 기록

## 7. 모니터링 아키텍처

### 이번 주 결정 (10/7)

**A안으로 간다.** 도구는 hey, docker stats, CloudWatch.
k6, Grafana, Prometheus는 설치와 학습에 시간이 들어 이번 주 범위에서 빼고, 아래 B·C와 함께 다음 주 후보로 둔다.

### 구조 (A안)

```
[AWS]
 ALB ─┐
 ASG ─┼─→ CloudWatch (자동 수집) ─→ 알람 ─→ SNS ─→ 팀원 이메일
 EC2 ─┘           │
                  └─→ 대시보드 (시연 화면)

[온프렘]
 측정 PC: hey ─────→ 결과를 손으로 표에 기록
 VM: docker stats ─→ stats.log 파일 ─→ 손으로 표에 기록
```

AWS 쪽은 설치 없이 CloudWatch에 자동으로 쌓인다. 온프렘 쪽은 수집 시스템이 없고 수기로 옮긴다.

### 약점

1. **한 화면에서 볼 수 없다.** 시연의 핵심인 "온프렘 먹통 → AWS 전환 → 안정화"를 한 그래프로 보여줄 수 없다
2. **병목 지점이 안 보인다.** DB가 온프렘 VM에 있어서 온프렘이 과부하면 AWS 쪽도 같이 느려질 수 있는데, PostgreSQL 연결 수, DB CPU, 터널 트래픽을 보는 계획이 없다
3. **수작업이라 실수가 생긴다.** 5단계 × 여러 회 측정을 손으로 옮긴다

### 다음 주 후보

| 방법 | 내용 | 장점 | 단점 |
|---|---|---|---|
| A. 현재대로 | AWS는 CloudWatch, 온프렘은 수기 | 추가 작업 없음 | 위 약점 그대로 |
| B. 온프렘에 CloudWatch Agent | 온프렘 VM에 에이전트를 설치해 CPU·메모리를 CloudWatch로 전송 | AWS 대시보드 하나에 온프렘까지 표시 | 사용자 지정 지표 요금(소액, 금액 확인 필요), 온프렘에 AWS 자격 증명 필요 |
| C. Prometheus + Grafana | 온프렘에 수집기와 그래프 도구를 띄워 양쪽 지표 수집 | 업계 표준, DB·Redis 지표와 pretix `/metrics` 연결 가능 | 구축 작업이 가장 많음, 온프렘 VM(2 vCPU) 자원을 나눠 씀 |

다음 주에 위 약점이 측정에 실제로 문제가 되면 B를 먼저 검토한다.
B는 작업량 대비 효과가 크고, 대시보드 하나에 "온프렘 CPU 100% → AWS 서버 대수 증가"를 담을 수 있다.
C는 더 나은 구조지만 구축 시간이 가장 많이 든다.
