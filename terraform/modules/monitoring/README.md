# monitoring

알림, 자동 전환, 대시보드를 만든다. 설계는 `monitoring/design.md`, Lambda 코드는 `monitoring/discord-notifier/`, `monitoring/failover/`에 있다.

```
CloudWatch 알람 → SNS <name_prefix>-alerts ─┬─ 이메일
                                            ├─ Lambda discord  → 디스코드
                                            └─ Lambda failover → ALB 가중치 0:100 + 디스코드
```

## 알람 (노션 모니터링 문서 6번)

| 알람 | 조건 | 비고 |
|---|---|---|
| `aws-unhealthy` | AWS 대상 그룹 정상 서버 1분 × 3번 연속 < 1 | 데이터 없음도 장애로 봄. failover Lambda가 이 이름만 처리 |
| `alb-5xx` | ALB 5XX 5분 합 10 이상 | |
| `target-5xx` | 대상 5XX 5분 합 20 이상 | |

OK 알림은 보내지 않는다. ASG 확장 정책이 만드는 `TargetTracking-*` 알람 2개는 `app` 모듈 몫이라 여기 없다.

서버가 0대가 되면 ALB가 `HealthyHostCount`를 아예 안 보내서 `aws-unhealthy`가 늦게(10/20 시나리오 2에서 약 10분) 울린다. `FILL(지표, 0)` 수식으로 바꾸는 걸 검토 중.

## 자동 전환 (failover)

- `aws-unhealthy`가 ALARM이고 온프렘 대상 그룹이 healthy면 리스너 가중치를 AWS 0 : 온프렘 100으로 바꾼다.
- 온프렘이 unhealthy면 바꾸지 않고 디스코드에 알리기만 한다.
- 역할 `<name_prefix>-failover-role`: 이 리스너의 `ModifyListener`, `DescribeTargetHealth`
- 복귀(100 : 0)는 사람이 한다.

## 대시보드

| 이름 | 용도 | 배치 |
|---|---|---|
| `<name_prefix>` | 평소 감시, 시나리오 2(장애 전환), 4B(온프렘 부하) | 노션 6번 순서. 1~6번 3칸 × 2줄, 7~10번 2칸 × 2줄. 9번(WireGuard 핸드셰이크)은 지표가 없어 텍스트로 자리만 |
| `<name_prefix>-test3` | 시나리오 3(부하테스트, ASG 확장) | AWS 대상 그룹 기준 1분 단위: CPU(60% 기준선), InService/Desired, 요청 수, p95(2초 기준선), healthy, 5XX(ELB/Target) |

test3의 CPU는 인스턴스 세부 모니터링이 켜져 있어야 1분마다 들어온다. 기본 모니터링이면 5분마다라 점으로 보인다.

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `region` | 대시보드 위젯의 리전 |
| `asg_name` | 대시보드 7, 8번 패널의 Auto Scaling 그룹 |
| `alb_arn_suffix` | ALB 지표의 LoadBalancer 차원 값 |
| `target_group_arn_suffix` | AWS 대상 그룹 차원 값 |
| `onprem_target_group_arn_suffix` | 온프렘 대상 그룹 차원 값 |
| `listener_arn` | failover가 가중치를 바꿀 리스너 |
| `target_group_arn`, `onprem_target_group_arn` | failover 환경 변수 |
| `waf_name` | 대시보드 10번 패널 |
| `alert_email` | 알림을 받을 이메일 |
| `discord_webhook_url` | 디스코드 웹훅 URL (sensitive) |
| `lambda_role_arn` | 디스코드 Lambda 실행 역할 |
| `lambda_source_file`, `failover_source_file` | Lambda 코드 파일 경로 |
| `log_retention_days` | Lambda 로그 보관 기간 (기본 14일) |

## 출력

| 이름 | 설명 |
|---|---|
| `sns_topic_arn` | 알림 SNS 토픽 |
| `failover_function_name` | 자동 전환 Lambda |
