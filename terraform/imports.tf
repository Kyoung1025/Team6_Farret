# 콘솔로 이미 만든 리소스를 코드와 연결한다 (10/7 값 표 기준)
# plan에서 "import"로 나오고 변경 사항이 없으면 코드가 콘솔 구성과 같다는 뜻이다
# plan은 아무것도 바꾸지 않는다. apply 하기 전에는 실제 state에도 반영되지 않는다

# --- 네트워크 (준용님) ---

import {
  to = aws_vpc.main
  id = "vpc-0dd4d4302df5ac369"
}

# TODO: 서브넷 4개, IGW, 라우팅 테이블 2개, 라우팅 테이블 연결, S3 엔드포인트
# 값 표의 서브넷 ID가 어느 서브넷(public-a/c, app-a/c)인지 표시가 없어서 AWS에서 조회 후 추가
#   subnet-0d71e57aaab03a078
#   subnet-0f9e9f3f19896a5f8
#   subnet-02725617dd5a06732
#   subnet-0e106e00a8cf33f20

# --- 보안그룹 (값 표 기준, 형서님) ---

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

# TODO: 보안그룹 규칙(sgr-...) ID는 AWS에서 조회 후 추가
