> **공개용 편집본:** 운영 식별자를 예시 값으로 치환했다. 원본 설정·실험 로그는 비공개 로컬 보관이며 이 폴더에는 포함되지 않는다. 아래의 원본/바이트 보존 표현은 수집 당시 이력을 뜻하며 공개 파일의 원본 일치를 주장하지 않는다. 실서버 적용용이 아니다.

# Grafana ↔ CloudWatch 연동: 2026-10-25

> 이 문서는 기존 팀 저장소에 **새 폴더로만 추가할 참고·검증 기록**이며, 운영 중인 VM/CloudWatch/ALB/Terraform 설정을 변경하지 않습니다.

## 4. 2026-10-25 Grafana ↔ AWS CloudWatch 실제 연동

### 4.1 수행 과정 및 결과 (확인)

1. AWS에서 Grafana 조회 전용 IAM 사용자 `example-cloudwatch-reader` 생성.
2. AWS 관리형 정책 `CloudWatchReadOnlyAccess` 부여. 기존 강한 권한의 개인 IAM 키를 그대로 사용하지 않음.
3. IAM 사용자용 액세스 키를 별도로 발급해 **Grafana 설정 화면에만 입력**(키 값은 기술 노트/저장소에 미기재).
4. Grafana → **Connections → Data sources → Add new data source → CloudWatch**.
5. 데이터소스 이름 `cloudwatch`, 인증 `Access & secret key`, 기본 리전 `ap-northeast-2`.
6. **Save & test** 성공:

```text
Successfully queried the CloudWatch metrics API.
Successfully queried the CloudWatch logs API.
```

7. Grafana **Explore**에서 EC2 `AWS/EC2` → `CPUUtilization` → `Average` 메트릭 조회.
8. 기존 관제판 AWS 패널이 `No data`였으나 CloudWatch 쿼리 옵션 보완 후 실제 그래프 표시 성공.

### 4.2 CloudWatch 패널 `No data` 트러블슈팅

- **증상:** 데이터소스 Metrics/Logs 연결 테스트는 성공하지만 대시보드의 AWS 메트릭 패널에는 `No data`.
- **확인한 원인 중 하나:** 기존 JSON 대상 쿼리에서 `metricQueryType`, `metricEditorMode` 항목이 누락된 형식 문제.
- **조치:** CloudWatch target에 두 옵션을 보완하고, EC2 CPU 기본 수집 간격에 맞춰 period를 60초 대신 **300초**로 조정, 대시보드 재 Import.
- **결과:** AWS EC2 CPU, ASG `GroupDesiredCapacity` / `GroupInServiceInstances`, ALB 앱 TG `HealthyHostCount`, `TargetResponseTime p95` 실제 표시 확인.

```json
{
  "metricQueryType": 0,
  "metricEditorMode": 0,
  "namespace": "AWS/EC2",
  "metricName": "CPUUtilization",
  "statistics": ["Average"],
  "dimensions": {"InstanceId": "<현재_대상_EC2_ID>"},
  "period": "300"
}
```

- **추가 확인 포인트:** Region, Dimension(특히 ALB+Target Group 모두), metric period, UTC/KST 시간 범위, IAM 권한, 실제 해당 시간대 수집 유무.
- **`RequestCountPerTarget`:** 대상당 요청 수 메트릭이며 그룹 전체 요청 수와 혼동하지 않는다. 당일 쿼리는 `Sum`으로 수정.
- **중요:** 10월 21일 3A 부하 테스트 **후** 10월 25일 CloudWatch 데이터소스를 연동했다. 과거 테스트 당시부터 Grafana에서 CloudWatch를 직접 봤다고 기록하면 안 됨.
- **참고:** 10월 25일 휴일 Rocky 전원 OFF로 Prometheus Rocky/Nginx/k3s Targets `DOWN` 및 `No data`가 발생한 것은 AWS CloudWatch 데이터소스 장애가 아니었다.

### 4.3 AWS 리소스·메트릭 조회 명령 (실제 기록에서 확인)

```bash
# 사용자/권한 확인
aws sts get-caller-identity

# AWS에서 실제 그룹 이름과 인스턴스 매핑 조회
aws autoscaling describe-auto-scaling-groups \
  --region ap-northeast-2 \
  --query 'AutoScalingGroups[].{ASG:AutoScalingGroupName,Desired:DesiredCapacity,Instances:Instances[].InstanceId}' \
  --output json

# AWS ALB/TG ARN 확인: 화면·리전 변경시 먼저 재조회
aws elbv2 describe-load-balancers \
  --region ap-northeast-2 \
  --query 'LoadBalancers[].[LoadBalancerName,LoadBalancerArn]' \
  --output table
aws elbv2 describe-target-groups \
  --region ap-northeast-2 \
  --query 'TargetGroups[].[TargetGroupName,TargetGroupArn]' \
  --output table

# 앱 ASG 그룹 메트릭 활성화 확인
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names example-aws_name-3 \
  --region ap-northeast-2 \
  --query 'AutoScalingGroups[0].EnabledMetrics[].Metric' \
  --output table
```

리소스명 확인(2026-10-25): 앱 ASG `example-aws_name-3`, WG 허브 ASG `example-aws_name-5`, 앱 TG `example-aws_name-4`, 온프렘 TG `example-aws_name-6`. **ASG가 교체한 EC2의 InstanceId는 바뀔 수 있다.** 허브 ASG 그룹 메트릭 수집 활성화 상태는 별도 확인 필요.

---
