# network

VPC, 서브넷, 라우팅, S3 엔드포인트, 보안그룹을 만든다. (AWS 구축 가이드 3번)

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `region` | S3 엔드포인트 서비스 이름에 쓰는 리전 |
| `vpc_cidr` | VPC 대역 |
| `public_subnets` | Public 서브넷 `{ 키 = { az, cidr } }` |
| `app_subnets` | App 서브넷 `{ 키 = { az, cidr } }` |
| `onprem_public_cidr` | 온프렘 공인 IP (/32). wg-sg의 UDP 51820 소스 |

## 출력

| 이름 | 설명 |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public 서브넷 ID 목록 |
| `app_subnet_ids` | App 서브넷 ID 목록 |
| `app_route_table_id` | App 라우팅 테이블 ID |
| `security_group_ids` | 보안그룹 ID 맵 (`alb`, `app`, `nat`, `wg`) |
