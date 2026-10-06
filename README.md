# pretix-demo

대입 원서접수 마감 트래픽 폭주 대응 하이브리드 인프라 (온프레미스 + AWS 버스팅)

## 폴더 구조

| 폴더 | 내용 |
|---|---|
| `onprem/` | docker-compose.yml, nginx.conf, pretix.cfg.example, .env.example |
| `terraform/` | main.tf, variables.tf, network.tf ... |
| `docs/` | 구축 가이드, 브랜치·PR 규칙, 측정 기록 |
| `monitoring/` | 알람·대시보드 설계 |

## 규칙

- 비밀값(DB 비밀번호, WireGuard 개인키, AWS 액세스 키)은 레포에 올리지 않는다
- main에 직접 push하지 않는다. 작업 브랜치 → PR → 리뷰 → merge
- AWS 리소스 이름은 `pretix-demo-` 접두사, 태그 `Project=pretix-demo`, 리전 `ap-northeast-2`
