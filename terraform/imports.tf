# 콘솔로 이미 만든 리소스를 코드와 연결한다 (10/7 AWS 조회 결과 기준)
# plan에서 "import"로 나오고 변경 사항이 없으면 코드가 콘솔 구성과 같다는 뜻이다
# plan은 아무것도 바꾸지 않는다. apply 하기 전에는 state에도 반영되지 않는다

# --- 네트워크 (준용님) ---

import {
  to = aws_vpc.main
  id = "vpc-0dd4d4302df5ac369"
}

import {
  to = aws_internet_gateway.main
  id = "igw-06a56f1fa2699cec8"
}

import {
  to = aws_subnet.public["a"]
  id = "subnet-0d71e57aaab03a078"
}

import {
  to = aws_subnet.public["c"]
  id = "subnet-02725617dd5a06732"
}

import {
  to = aws_subnet.app["a"]
  id = "subnet-0f9e9f3f19896a5f8"
}

import {
  to = aws_subnet.app["c"]
  id = "subnet-0e106e00a8cf33f20"
}

import {
  to = aws_route_table.public
  id = "rtb-0b46ce0870e28a893"
}

import {
  to = aws_route_table.app
  id = "rtb-06b3627064ef36902"
}

# 라우팅 테이블 연결의 ID 형식은 "서브넷ID/라우팅테이블ID"
import {
  to = aws_route_table_association.public["a"]
  id = "subnet-0d71e57aaab03a078/rtb-0b46ce0870e28a893"
}

import {
  to = aws_route_table_association.public["c"]
  id = "subnet-02725617dd5a06732/rtb-0b46ce0870e28a893"
}

import {
  to = aws_route_table_association.app["a"]
  id = "subnet-0f9e9f3f19896a5f8/rtb-06b3627064ef36902"
}

import {
  to = aws_route_table_association.app["c"]
  id = "subnet-0e106e00a8cf33f20/rtb-06b3627064ef36902"
}

import {
  to = aws_vpc_endpoint.s3
  id = "vpce-014add8bb5c9555f6"
}

# --- 보안그룹 (형서님) ---

import {
  to = aws_security_group.alb
  id = "sg-022c5f9549f0ddb2d"
}

import {
  to = aws_security_group.app
  id = "sg-03d2e4c9675704e9f"
}

import {
  to = aws_security_group.nat
  id = "sg-0537dec35081ec06a"
}

import {
  to = aws_security_group.wg
  id = "sg-0e0b86d423e0f97ba"
}

# --- 보안그룹 규칙 ---

import {
  to = aws_vpc_security_group_ingress_rule.alb_http
  id = "sgr-0c518bc5a7dd0e46c"
}

import {
  to = aws_vpc_security_group_ingress_rule.app_http_from_alb
  id = "sgr-01dc0f346174205ee"
}

import {
  to = aws_vpc_security_group_ingress_rule.nat_from_app["a"]
  id = "sgr-08d0bb5cd56c05927"
}

import {
  to = aws_vpc_security_group_ingress_rule.nat_from_app["c"]
  id = "sgr-090d33cdb0416d544"
}

import {
  to = aws_vpc_security_group_ingress_rule.wg_tunnel
  id = "sgr-04f4d467a8a8c0143"
}

import {
  to = aws_vpc_security_group_ingress_rule.wg_from_app["a"]
  id = "sgr-05b474bcb69e0b6a9"
}

import {
  to = aws_vpc_security_group_ingress_rule.wg_from_app["c"]
  id = "sgr-084d6cbf743c2021b"
}

import {
  to = aws_vpc_security_group_egress_rule.all["alb"]
  id = "sgr-04a973c0616f2e4dd"
}

import {
  to = aws_vpc_security_group_egress_rule.all["app"]
  id = "sgr-0d6ac8b3390e55b2f"
}

import {
  to = aws_vpc_security_group_egress_rule.all["nat"]
  id = "sgr-00b0db855268f55e1"
}

import {
  to = aws_vpc_security_group_egress_rule.all["wg"]
  id = "sgr-06f1090350ef347ff"
}
