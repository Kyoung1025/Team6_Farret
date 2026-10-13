# gateway

NAT 인스턴스, WireGuard 서버, WireGuard 탄력적 IP, App 라우팅 테이블 경로 2개를 만든다. (AWS 구축 가이드 4·5번)

NAT 게이트웨이(시간당 요금) 대신 t3.micro 인스턴스로 NAT를 한다.
WireGuard 설정과 키는 서버 안에 있고 코드에는 넣지 않는다.

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `subnet_id` | NAT·WireGuard를 둘 Public 서브넷 |
| `nat_ami_id` | NAT 인스턴스 AMI (Amazon Linux 2023) |
| `wg_ami_id` | WireGuard 서버 AMI (Ubuntu 24.04) |
| `nat_security_group_id` | NAT 보안그룹 |
| `wg_security_group_id` | WireGuard 보안그룹 |
| `instance_profile_name` | IAM 인스턴스 프로파일 |
| `app_route_table_id` | 경로를 추가할 App 라우팅 테이블 |
| `onprem_tunnel_cidr` | WireGuard 터널 대역 |

## 출력

| 이름 | 설명 |
|---|---|
| `wg_public_ip` | WireGuard 탄력적 IP (온프렘 `wg0.conf`의 Endpoint) |
| `wg_private_ip` | WireGuard 서버 사설 IP |
| `nat_instance_id` | NAT 인스턴스 ID |
