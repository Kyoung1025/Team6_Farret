> **공개용 편집본:** 운영 식별자를 예시 값으로 치환했다. 원본 설정·실험 로그는 비공개 로컬 보관이며 이 폴더에는 포함되지 않는다. 아래의 원본/바이트 보존 표현은 수집 당시 이력을 뜻하며 공개 파일의 원본 일치를 주장하지 않는다. 실서버 적용용이 아니다.

# 2026-10-28 Ubuntu Monitoring VM — 실제 Compose/Blackbox 수집 스냅샷

> 이 폴더는 **기록/백업용**이다. Docker Compose 파일을 `up`/`down`하여 서비스를 재배포하거나 실환경의 Grafana JSON을 import하지 않는다.

## 확보한 설정과 추출 경로

| 새 파일 | 실제 VM 원본 | 검증 |
|---|---|---|
| [`../docker-compose.yml`](../docker-compose.yml) | `~/monitoring/docker-compose.yml`에서 `cp`로 `~/ferrot-export/docker-compose.yml`을 만든 뒤 Windows SCP로 받은 원본 | YAML 구문 파싱, 3개 서비스 확인 |
| [`../prometheus/prometheus.yml`](../prometheus/prometheus.yml) | 실행 중 `prometheus:/etc/prometheus/prometheus.yml`을 `docker cp`하여 직접 추출한 원본 | `diff -u ~/monitoring/prometheus/prometheus.yml ~/ferrot-export/prometheus.yml` 출력 없음, 10개 job |
| [`../blackbox/blackbox.yml`](../blackbox/blackbox.yml) | `~/monitoring/blackbox/blackbox.yml` 복사본 | YAML 파싱, `http_2xx` 모듈 확인 |
| [`../grafana/ferrot-dashboard-live-v36-2026-10-28.json`](../grafana/ferrot-dashboard-live-v36-2026-10-28.json) | Grafana GET `/api/dashboards/uid/example-dashboard` 응답의 dashboard 객체 | JSON 파싱, 버전 36, 접이식 하위 포함 68개 패널 |

## 실행 환경 (2026-10-28 당시 사용자 제공 `docker ps`)

| 컨테이너 | 이미지 태그 | 관측 상태 | 호스트 포트 |
|---|---|---|---|
| prometheus | `prom/prometheus:latest` | Up 2 hours | `0.0.0.0:9090` 및 IPv6 9090 |
| grafana | `grafana/grafana:latest` | Up 2 hours | `0.0.0.0:3000` 및 IPv6 3000 |
| blackbox | `prom/blackbox-exporter:latest` | Up 2 hours | `127.0.0.1:9115` |

이 표는 조회 당시의 **컨테이너 상태**만 의미하며 현재 시점의 가동 보증이 아니다.

## Compose 설정 해설

- Prometheus는 `./prometheus/prometheus.yml`을 컨테이너 `/etc/prometheus/prometheus.yml`에 `:ro` 마운트하고, 시계열 데이터는 `prometheus-data` named volume에 저장한다.
- Grafana 저장 데이터는 `grafana-data` named volume에 저장한다. 이 볼륨의 **데이터나 실제 CloudWatch 자격증명은 본 패키지에 포함되지 않는다**.
- Blackbox는 `./blackbox/blackbox.yml`을 `:ro` 마운트하며, `http_2xx`의 HTTP `GET`, `timeout: 5s`, `preferred_ip_protocol: ip4`를 적용한다.
- Docker Compose는 명시적 네트워크 없이 기본 네트워크를 형성하므로, 같은 Compose 네트워크의 Prometheus에서는 컨테이너 이름 `blackbox:9115`로 접근하는 구성이 가능하다. **호스트 공개 바인딩 `127.0.0.1`과 컨테이너 내부 접근은 구별**해야 한다.
- Prometheus와 Grafana의 공개 바인딩(`9090:9090`, `3000:3000`)은 호스트의 모든 인터페이스를 대상으로 한다. 실제 외부 접근 가능성은 VM 방화벽/라우터/VPN 등에 달려 있으며 별도 보안 점검이 필요하다.
- 세 서비스가 모두 `latest` 태그이므로, 미래에 새로 pull하여 재현하면 버전이 달라질 수 있다. **해당일 실행 이미지 digest/버전은 확보하지 않았음**.
- 이 Compose 파일에는 Grafana CloudWatch 데이터소스 설정·인증정보, Grafana Alert Rule provisioning 또는 시스템 방화벽 설정을 선언하지 않았다. 따라서 설정 파일 4개만으로 운영 환경을 완전히 재현할 수 있다고 주장하지 않는다.
- YAML 구문 및 상대경로 일치 검증만 했고, **실제 `docker compose up`을 실행하지 않았다**. 실행 중인 VM은 변경하지 않았다.

## 확인된 수집 대상 설명

`blackbox-pretix`는 AWS ALB `/healthcheck/`에 대한 HTTP 검사이다. 별개의 `blackbox-http`는 `http://prometheus:9090/-/ready`에 대한 Prometheus 준비 상태 검사이다. 둘의 `probe_success`를 혼동하지 않는다. Prometheus `up`은 메트릭 수집 성공이므로 앱 HTTP 정상 여부의 직접 증명이 아니다.
