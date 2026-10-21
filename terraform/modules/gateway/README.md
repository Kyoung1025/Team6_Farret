# gateway

NAT 인스턴스와 WireGuard 허브를 만든다. (AWS 구축 가이드 4·5번)

NAT 게이트웨이(시간당 요금) 대신 t3.micro 인스턴스로 NAT를 한다.

## WireGuard 허브

ASG 1대(`<name_prefix>-wg-asg`)로 띄운다. 인스턴스가 죽으면 ASG가 새로 띄우고, 부팅 스크립트가 아래를 한다.

1. 소스/대상 확인 끄기
2. SSM에서 개인키(`/pretix/wg/server-private-key`)와 `wg0.conf` 본문(`/pretix/wg/wg0-body`)을 읽어 wg0 시작
3. 탄력적 IP를 자기에게 연결
4. App, Public 라우팅 테이블의 터널 대역 경로를 자기로 바꾸기

그래서 EIP 연결과 터널 경로는 Terraform이 아니라 인스턴스가 관리한다. SSM 파라미터 두 개는 비밀값이라 코드에 없고 사람이 넣는다. peer를 추가할 때는 `/pretix/wg/wg0-body`를 고치고 인스턴스를 교체(또는 `wg syncconf`)한다.

## 입력

| 이름 | 설명 |
|---|---|
| `name_prefix` | 리소스 이름 접두사 |
| `region` | 리전 |
| `subnet_id` | NAT를 둘 Public 서브넷 |
| `public_subnet_ids` | WireGuard 허브 ASG 서브넷 |
| `nat_ami_id` | NAT 인스턴스 AMI (Amazon Linux 2023) |
| `wg_ami_id` | WireGuard 허브 AMI |
| `nat_security_group_id` | NAT 보안그룹 |
| `wg_security_group_id` | WireGuard 보안그룹 |
| `instance_profile_name` | NAT 인스턴스 프로파일 |
| `app_route_table_id` | App 라우팅 테이블 |
| `public_route_table_id` | Public 라우팅 테이블 |
| `onprem_tunnel_cidr` | WireGuard 터널 대역 |

## 출력

| 이름 | 설명 |
|---|---|
| `wg_public_ip` | WireGuard 탄력적 IP (온프렘 `wg0.conf`의 Endpoint) |
| `wg_asg_name` | WireGuard 허브 ASG |
| `nat_instance_id` | NAT 인스턴스 ID |
