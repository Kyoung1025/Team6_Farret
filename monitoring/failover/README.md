# failover

`pretix-demo-aws-unhealthy` 경보가 울리면 ALB 가중치를 AWS 0 : 온프렘 100으로 바꾸는 Lambda.

```
경보 ALARM → SNS pretix-demo-alerts → 이 Lambda → ModifyListener → 디스코드
```

- 다른 경보(5xx)와 OK는 무시한다.
- 온프렘 대상 그룹이 unhealthy면 바꾸지 않고 디스코드에 "자동 전환 안 함"만 보낸다.
- 리스너에 고정 세션(1시간)이 켜져 있어서 가중치를 바꿀 때 같이 넣어야 한다. 빠지면 ModifyListener가 거부된다.
- 복귀(100:0)는 사람이 한다. AWS 대상 그룹이 healthy 2개인 걸 보고 돌린다.

| 환경 변수 | 값 |
|---|---|
| `LISTENER_ARN` | ALB 80 리스너 |
| `AWS_TG_ARN` | pretix-demo-tg |
| `ONPREM_TG_ARN` | pretix-onprem-tg |
| `WEBHOOK_URL` | 디스코드 웹훅 (discord-notifier와 같은 값) |

로그: `/aws/lambda/pretix-demo-failover`
