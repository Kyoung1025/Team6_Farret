# 공개용 보안 검토 보고서

기준: 2026-10-28. 원본 17개 중 로그 2개는 공개 제외, 나머지 15개는 공개용으로 보존. 결과 요약과 본 보고서 2개 추가로 공개 파일은 17개.

## 분류 및 처리

| 항목 | 분류 | 처리 |
|---|---|---|
| 내부 IP·ALB DNS | 운영 경로 식별자 | RFC 5737 예시 주소·example.invalid로 일관 치환 |
| AWS 리소스 이름·EC2 ID·ALB/TG dimension | 운영 리소스 식별자 | example-* 값으로 치환 |
| Grafana UID·루트 DB id | 설치별 식별자 | 예시 UID·DS_CLOUDWATCH 변수·id null |
| 인증정보 | 공개 금지 | 패턴·설정 키 검토, 실제 비밀값 발견 없음(완전성 보장 아님) |
| 원본 로그 2개 | 상세 운영 증거 | 공개 제외, 수치·실험 시각 요약만 제공 |

## 기술 내용 보존

- Prometheus scrape job·포트·주기·relabel 구조 유지. ALB/IP 주소만 예시화.
- Grafana 패널·PromQL·CloudWatch 통계/기간/연산 구조 유지. dimension 값과 UID만 예시화하고 루트 id를 제거. JSON 구조 비교 통과.
- 실험 날짜·RPS·응답시간·HTTP 집계·검증 한계 유지. 원본 로그 개별 요청은 제외.
- localhost·Docker 서비스 DNS·메트릭 이름·리전은 기술 이해에 필요한 일반 설정으로 유지.
- latest 태그·포트 바인딩 등 운영 설정은 변경하지 않음. 재배포·import 실행 없음.

## 변경 전후 파일 목록

| 원본 상대 경로 | 공개용 처리 |
|---|---|
| `docker-compose.yml` | 동일 |
| `README.md` | 공개용 문서/식별자 치환 |
| `SOURCE-PROVENANCE.md` | 공개용 문서/식별자 치환 |
| `blackbox/blackbox.yml` | 동일 |
| `docs/architecture-and-observability.md` | 공개용 문서/식별자 치환 |
| `docs/cloudwatch-integration-2026-10-25.md` | 공개용 문서/식별자 치환 |
| `docs/operations-and-lessons.md` | 공개용 문서/식별자 치환 |
| `docs/runtime-compose-blackbox-2026-10-28.md` | 공개용 문서/식별자 치환 |
| `experiments/scenario-02-aws-to-onprem-2026-10-26.md` | 공개용 문서/식별자 치환 |
| `experiments/scenario-03a-aws-asg-2026-10-21.md` | 공개용 문서/식별자 치환 |
| `experiments/scenario-03b-onprem-load-2026-10-21-and-26.md` | 공개용 문서/식별자 치환 |
| `experiments/scenario-05-wireguard-hub-2026-10-26.md` | 공개용 문서/식별자 치환 |
| `grafana/ferrot-dashboard-live-v36-2026-10-28.json` | 공개용 문서/식별자 치환 |
| `prometheus/prometheus.yml` | 공개용 문서/식별자 치환 |
| `experiments/evidence/README.md` | 공개용 문서/식별자 치환 |
| `experiments/evidence/scenario2_20261026_060822.log` | 공개 제외 → evidence/public-results-summary.md |
| `experiments/evidence/smoke_c2.txt` | 공개 제외 → evidence/public-results-summary.md |
| 없음 | `experiments/evidence/public-results-summary.md` 신규 |
| 없음 | `PUBLIC-SECURITY-REVIEW.md` 신규 |

## 검증 범위

- 실제 식별자 목록 재검색 및 비밀키 패턴 검사 수행. 상세 원본→치환 대응표는 로컬에만 보관.
- 운영 설정 스냅샷은 바로 배포 가능한 구성으로 보장하지 않음. 데이터소스 연결은 새 환경에서 별도 설정 필요.
- 원본 커밋을 부모로 사용하지 않고 팀 main 기준 커밋에서 새 브랜치를 생성. 기존 팀 파일 변경 없음.
- 공개 승인 전 push/PR 생성 금지.

### 검사 한계

YAML 전용 파서는 현재 실행 환경에 없어 파서 기반 검증은 수행하지 않았다. YAML은 원본과 줄별 비교해 주소 치환 외 구조 변경이 없음을 확인한다. JSON은 파싱 및 구조 비교, Markdown 상대 링크와 Git 변경 범위는 검증했다. 실제 배포·수집·대시보드 import는 실행하지 않았다.
