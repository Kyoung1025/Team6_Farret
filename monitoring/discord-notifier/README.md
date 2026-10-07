# 디스코드 알람 (pretix-demo-alerts → #aws-알람)

```
CloudWatch 알람 → SNS pretix-demo-alerts ─┬→ 이메일 (백업)
                                          └→ Lambda pretix-demo-discord-notifier → 디스코드 웹훅
```

## 준비물

| 항목 | 값 | 담당 |
|---|---|---|
| 디스코드 채널 | `#aws-알람` | 디스코드 서버 관리자 |
| 웹훅 URL | Parameter Store `/pretix-demo/discord-webhook-url` (SecureString) | 웹훅을 만든 사람이 직접 저장 |
| Lambda 실행 Role | `pretix-demo-discord-notifier-role` | 형서님 (IAM 권한 필요) |

웹훅 URL은 아는 사람이 누구나 채널에 글을 쓸 수 있는 비밀값이다. 채팅이나 레포에 올리지 않는다.

## 1. 웹훅 URL 저장 (웹훅 만든 사람)

```powershell
aws ssm put-parameter --name /pretix-demo/discord-webhook-url --type SecureString --value "웹훅URL" --tags Key=Project,Value=pretix-demo --profile ferret --region ap-northeast-2
```

## 2. Lambda 실행 Role (형서님)

- 신뢰할 엔터티: AWS 서비스 / Lambda
- 정책
  - `AWSLambdaBasicExecutionRole` (실행 로그)
  - 인라인: `ssm:GetParameter`, 리소스 `arn:aws:ssm:ap-northeast-2:994114886472:parameter/pretix-demo/discord-webhook-url`
- 함수를 만드는 사람에게 이 Role에 대한 `iam:PassRole` 권한

## 3. Lambda와 SNS 구독

- 함수 이름 `pretix-demo-discord-notifier`, 런타임 Python, 코드는 `lambda_function.py`
- 환경 변수 `WEBHOOK_PARAM=/pretix-demo/discord-webhook-url`
- SNS 주제 `pretix-demo-alerts`에 프로토콜 **AWS Lambda**로 구독 추가

## 비용

Lambda(월 100만 건 무료), SNS → Lambda 전달(무료), Parameter Store 표준(무료). 사실상 0원.
