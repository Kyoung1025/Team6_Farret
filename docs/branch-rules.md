# 브랜치·PR 규칙 (초안, 나영님과 확정 예정)

## 브랜치

- `main`: 항상 동작하는 상태. **직접 push 금지**
- 작업은 `main`에서 브랜치를 따서 한다. 이름은 `종류/내용`

| 종류 | 용도 | 예 |
|---|---|---|
| `feat/` | 새 기능, 새 리소스 | `feat/terraform-network` |
| `fix/` | 버그·설정 수정 | `fix/wg-allowed-ips` |
| `docs/` | 문서 | `docs/onprem-guide` |
| `chore/` | 설정, 정리 | `chore/gitignore` |

## PR

1. 작업 브랜치를 push하고 PR을 연다
2. 본문에 **무엇을, 왜** 바꿨는지 적는다. Terraform 변경이면 `terraform plan` 결과 요약을 붙인다
3. **리뷰 1명 이상 승인** 후 merge. 리뷰어는 해당 영역의 부담당을 우선 지정

| 영역 | 리뷰어 |
|---|---|
| Terraform | 승호 |
| 온프렘 | 성민 |
| AWS 콘솔 작업 문서 | 형서 |
| 보안 설정 | 준용 |
| 모니터링·부하테스트 | 경현 |

4. merge 방식: **Squash merge** (PR 하나가 커밋 하나로 남는다)
5. merge 후 작업 브랜치는 삭제

## 커밋 전 확인

- 비밀값(DB 비밀번호, WireGuard 개인키, AWS 키, `.env`)이 들어가지 않았는지 `git diff --staged`로 확인
- Terraform 파일은 `terraform fmt`, `terraform validate` 통과
- 셸 스크립트는 LF 줄바꿈 (`.gitattributes`가 처리)

## Terraform 작업 규칙

- `apply` 전에 반드시 `plan`을 확인한다. **삭제(destroy)가 포함되면 팀에 먼저 알린다**
- 요금이 나가는 리소스를 만들거나 지우기 전에 채널에 공유한다
- state 파일은 S3 백엔드에만 둔다. 로컬 `*.tfstate`는 커밋하지 않는다
