import json
import os
import urllib.request
from datetime import datetime, timedelta, timezone

import boto3

elb = boto3.client("elbv2")
KST = timezone(timedelta(hours=9))


def _discord(text):
    # pretix-demo-discord와 같은 웹훅. 실패해도 전환은 이미 끝난 뒤라 로그만 남김
    url = os.environ.get("WEBHOOK_URL")
    if not url:
        return
    body = json.dumps({"username": "pretix-demo-failover", "content": text[:2000]}).encode()
    req = urllib.request.Request(
        url, data=body, method="POST",
        headers={"Content-Type": "application/json", "User-Agent": "pretix-demo-failover"},
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            print(f"discord status={resp.status}")
    except Exception as e:
        print(f"discord 실패: {e}")


def _set_weights(aws, onprem):
    elb.modify_listener(
        ListenerArn=os.environ["LISTENER_ARN"],
        DefaultActions=[{
            "Type": "forward",
            "ForwardConfig": {"TargetGroups": [
                {"TargetGroupArn": os.environ["AWS_TG_ARN"], "Weight": aws},
                {"TargetGroupArn": os.environ["ONPREM_TG_ARN"], "Weight": onprem},
            ],
                # AWS TG에 고정 세션이 켜져 있어서 이게 빠지면 ModifyListener가 거부됨
                "TargetGroupStickinessConfig": {"Enabled": True, "DurationSeconds": 3600}},
        }],
    )


def lambda_handler(event, context):
    for r in event["Records"]:
        msg = json.loads(r["Sns"]["Message"])
        name, state = msg.get("AlarmName"), msg.get("NewStateValue")
        print(f"경보 {name} {state}")

        # 같은 SNS에 5xx 경보도 오므로 AWS 다운 경보만 처리
        if name != "pretix-demo-aws-unhealthy" or state != "ALARM":
            continue

        now = datetime.now(KST).strftime("%Y-%m-%d %H:%M:%S")

        # 온프렘도 죽어 있으면 넘겨도 502라서 안 넘김
        targets = elb.describe_target_health(
            TargetGroupArn=os.environ["ONPREM_TG_ARN"])["TargetHealthDescriptions"]
        if not any(t["TargetHealth"]["State"] == "healthy" for t in targets):
            print("온프렘 unhealthy, 전환 안 함")
            _discord(f"⚠️ **자동 전환 안 함** (온프렘 unhealthy)\n{now}")
            continue

        _set_weights(0, 100)
        print("가중치 AWS 0 : 온프렘 100 으로 변경")
        _discord(f"🔀 **자동 전환 완료** (AWS 0 : 온프렘 100)\n{now}")
