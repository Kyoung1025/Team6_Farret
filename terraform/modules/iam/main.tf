# 다른 모듈이 같이 쓰는 역할 3개 (앱 서버, NAT, 디스코드 Lambda)
# 허브 역할과 자동 전환 Lambda 역할은 그걸 쓰는 모듈(gateway, monitoring) 안에 있다

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  ec2_trust = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# --- 앱 서버 ---
# 부팅할 때 ECR에서 이미지를 받고, Secrets Manager에서 DB·SMTP 비밀번호를 읽는다

resource "aws_iam_role" "app" {
  name               = "${var.name_prefix}-app-role"
  description        = "Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = local.ec2_trust
}

# SSMFullAccess는 콘솔에서 붙여 둔 그대로. Session Manager 접속만 쓰면 ManagedInstanceCore로 충분해서 정리 대상
resource "aws_iam_role_policy_attachment" "app" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.app.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "app_db_secret" {
  name = "${var.name_prefix}-read-db-secret"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:pretix/db-password-*"
    }]
  })
}

resource "aws_iam_role_policy" "app_smtp_secret" {
  name = "pretix-smtp-secret-read"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:pretix/smtp-password-*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = aws_iam_role.app.name
  role = aws_iam_role.app.name
}

# --- NAT 인스턴스 ---
# Session Manager 접속만

resource "aws_iam_role" "infra" {
  name               = "${var.name_prefix}-infra-role"
  description        = "Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = local.ec2_trust
}

resource "aws_iam_role_policy_attachment" "infra_ssm" {
  role       = aws_iam_role.infra.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "infra" {
  name = aws_iam_role.infra.name
  role = aws_iam_role.infra.name
}

# --- 디스코드 알림 Lambda ---
# 로그만 쓴다

resource "aws_iam_role" "lambda_alert" {
  name        = "${var.name_prefix}-lambda-alert-role"
  description = "Allows Lambda functions to call AWS services on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_alert_logs" {
  role       = aws_iam_role.lambda_alert.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
