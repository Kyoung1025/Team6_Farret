# 디스코드 알림 (pretix-demo-alerts → 디스코드 알림 채널)

```
CloudWatch 알람 → SNS pretix-demo-alerts ─┬→ 이메일 (백업)
                                          └→ Lambda pretix-demo-discord → 디스코드 웹훅
```

| 항목 | 값 |
|---|---|
| Lambda 함수 | `pretix-demo-discord` (Python 3.14, x86_64, VPC 연결 안 함) |
| 실행 Role | `pretix-demo-lambda-alert-role` (형서님, `AWSLambdaBasicExecutionRole`) |
| 웹훅 URL | Lambda 환경 변수 `WEBHOOK_URL` |
| 트리거 | SNS `pretix-demo-alerts` |

웹훅 URL은 아는 사람이 누구나 채널에 글을 쓸 수 있는 비밀값이다. 채팅이나 레포에 올리지 않는다.
VPC에 연결하지 않는 이유: 연결하면 디스코드로 나가는 길이 NAT 인스턴스를 거쳐야 하는데, NAT는 쉬는 날 꺼둔다.

## 만드는 순서 (콘솔)

1. Lambda → 함수 생성 → 새로 작성
   - 이름 `pretix-demo-discord`, 런타임 Python 3.14
   - 추가 설정 → 실행 역할 → **기존 역할 사용** → `pretix-demo-lambda-alert-role`
   - 태그 `Project` = `pretix-demo`
2. 코드 탭: `lambda_function.py` 내용을 붙여넣고 **Deploy**
3. 구성 → 환경 변수 → `WEBHOOK_URL` = 디스코드 웹훅 URL
4. 트리거 추가 → SNS → `pretix-demo-alerts`
