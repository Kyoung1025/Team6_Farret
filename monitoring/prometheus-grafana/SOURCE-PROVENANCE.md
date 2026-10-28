> **공개용 편집본:** 운영 식별자를 예시 값으로 치환했다. 원본 설정·실험 로그는 비공개 로컬 보관이며 이 폴더에는 포함되지 않는다. 아래의 원본/바이트 보존 표현은 수집 당시 이력을 뜻하며 공개 파일의 원본 일치를 주장하지 않는다. 실서버 적용용이 아니다.

# SOURCE PROVENANCE — 실제 운영 설정 원본 추적

| 항목 | 출처 | 처리 |
|---|---|---|
| Prometheus | 2026-10-28 `user@monitoring-example`의 `docker cp prometheus:/etc/prometheus/prometheus.yml ~/ferrot-export/prometheus.yml` 출력에서 실파일 수집 | **파일 바이트 그대로 보관**; 10 job, YAML 검사만 완료. 등록된 Target의 UP 상태는 미조회 |
| Grafana | 2026-10-28 Grafana GET `http://192.0.2.6:3000/api/dashboards/uid/example-dashboard` 응답 | API JSON의 `dashboard` 객체 전체를 원형 보존, `meta` 제외. Grafana dashboard 버전 36, UID `example-dashboard`, 68 패널(재귀 집계) |
| Grafana 저장 시각 | API `meta.updated`: `2026-10-28T07:39:32Z` | KST **2026-10-28 16:39:32**. 조회 시점의 설정 스냅샷이므로 이후 수정은 반영 안 됨 |
| Grafana 이전 v2.4 초안 | 구형 JSON의 version 1·구성 일부 상이 | **최신 실제 API 추출본으로 교체**. 구형 v1 JSON은 이 신규 PR 패키지에 포함하지 않음 |
| CloudWatch 10/25 | 기존 당일 실습노트 | 별도 읽기 전용 IAM과 `No data` 수정 기록. Grafana 설정과 별도의 실제 과거 작업 |
| 시나리오 2·3A·3B·5 | 별도 이전 기록·실험 로그 요약 | 날짜·실험 경로와 측정값을 구분해서 기재. 최신 Grafana의 텍스트 패널 일부는 **과거 실험 기록**이므로 현재 실시간 지표로 보지 않음 |

## 2026-10-28 추가 제공받은 실제 파일과 로그

- `docker-compose.yml`: Ubuntu VM `~/monitoring/docker-compose.yml` → `~/ferrot-export/docker-compose.yml` → Windows SCP → 이 채팅 파일 업로드. **바이트 보존**.
- `blackbox/blackbox.yml`: Ubuntu VM `~/monitoring/blackbox/blackbox.yml` → `~/ferrot-export/blackbox.yml` → Windows SCP → 이 채팅 파일 업로드. **바이트 보존**.
- `prometheus/prometheus.yml`: Ubuntu에서 `docker cp` 후 `diff -u`로 호스트 설정과 동일 확인. 사용자 업로드 파일을 패키지에 **바이트 보존**, 이전 추출 파일과 SHA-256 일치.
- `experiments/evidence/public-results-summary.md`: 사용자 제공 10/26 HTTP 프로브 원본 1,223줄. 유효 1,222줄의 HTTP 200=899/503=323, 불완전 마지막 줄 1개. 15:12:17 첫 503~15:17:56 첫 200 관측 간격 339초.
- `experiments/evidence/public-results-summary.md`: 사용자 제공 `hey` c2 원본 파일, HTTP 200 80개/80개, p95 1.2460초.
- 시나리오5 **10/26** 실험의 독립 원본 로그는 현재 VM에서 확인되지 않았으므로 추정해 생성하지 않고 기존 문서의 관측 근거만 유지한다.

## 원본 그대로/변환 구분

- `prometheus/prometheus.yml`: 추출한 실제 파일 원본. (본문을 임의 보정하지 않음)
- `grafana/ferrot-dashboard-live-v36-2026-10-28.json`: API 응답의 `dashboard` 객체를 들여쓰기 JSON으로 직렬화한 **그대로의 설정 객체**. API `meta` 래퍼는 이 저장소용 파일에 의도적으로 포함하지 않음.
- API 전체 원본 JSON은 사용자 로컬 자료로 별도 보관하며 **GitHub에는 넣지 않음**. `meta`에는 `updatedBy`, 권한/외부 공유 상태 등 운영 메타데이터가 들어 있다.
- 문서 내 명령어는 재점검용 **예시**일 수 있으므로 모든 예시가 실행되었다고 주장하지 않는다.

## 주의

1. 이 저장소에 기존 파일과 같은 이름의 `prometheus.yml`이 다른 폴더에 있더라도 **기존 파일은 수정하지 않는다**.
2. YAML/JSON 문법 검증은 실제 수집 성공 또는 실환경 재배포 가능성까지 증명하지 않는다.
3. 코드·대시보드 내용에서 AWS secret/access key, 비밀번호, API token, Cookie 등이 없는지 최종 Codex 검사 및 사람 검토를 모두 실시한다.
4. 공개 GitHub에는 내부 IP·ALB 호스트명·리소스 ID 등 운영 식별자가 포함될 수 있으므로 팀원 승인 전 공개 PR을 만들지 여부를 검토한다.
5. 사용자 Grafana 외부 공유 여부는 별도로 확인할 것(`publicDashboardEnabled: true` 관측). GitHub용 JSON 저장과 외부 공유는 독립된 문제다.
