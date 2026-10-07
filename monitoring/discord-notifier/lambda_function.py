"""SNS(pretix-demo-alerts)로 들어온 CloudWatch 알람을 디스코드 채널로 보낸다.

구조: CloudWatch 알람 → SNS → 이 Lambda → 디스코드 웹훅
웹훅 URL은 비밀값이라 코드에 두지 않고 SSM Parameter Store(SecureString)에서 읽는다.
외부 라이브러리 없이 표준 라이브러리만 쓴다 (배포할 때 zip에 이 파일 하나만 넣으면 된다).
"""

import json
import os
import urllib.request

import boto3

PARAM_NAME = os.environ.get("WEBHOOK_PARAM", "/pretix-demo/discord-webhook-url")

_ssm = boto3.client("ssm")
_webhook_url = None  # 같은 실행 환경에서 재사용될 때 Parameter Store를 다시 읽지 않도록 저장


def _get_webhook_url():
    global _webhook_url
    if _webhook_url is None:
        resp = _ssm.get_parameter(Name=PARAM_NAME, WithDecryption=True)
        _webhook_url = resp["Parameter"]["Value"]
    return _webhook_url


def _format(subject, message):
    """CloudWatch 알람 형식이면 읽기 좋게 바꾸고, 아니면 받은 글을 그대로 보낸다."""
    try:
        alarm = json.loads(message)
    except (ValueError, TypeError):
        return f"📢 **{subject or 'pretix-demo 알림'}**\n{message}"

    if not isinstance(alarm, dict) or "AlarmName" not in alarm:
        return f"📢 **{subject or 'pretix-demo 알림'}**\n{message}"

    state = alarm.get("NewStateValue", "")
    icon = {"ALARM": "🔴", "OK": "🟢", "INSUFFICIENT_DATA": "⚪"}.get(state, "📢")
    lines = [
        f"{icon} **[{state}] {alarm['AlarmName']}**",
        alarm.get("AlarmDescription") or "",
        f"사유: {alarm.get('NewStateReason', '')}",
        f"시각(UTC): {alarm.get('StateChangeTime', '')}",
    ]
    return "\n".join(line for line in lines if line)


def lambda_handler(event, context):
    url = _get_webhook_url()

    for record in event.get("Records", []):
        sns = record.get("Sns", {})
        content = _format(sns.get("Subject"), sns.get("Message", ""))

        body = json.dumps({"content": content[:2000]}).encode()  # 디스코드 메시지 최대 2000자
        req = urllib.request.Request(
            url,
            data=body,
            headers={"Content-Type": "application/json", "User-Agent": "pretix-demo-alerts"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            print(f"discord status={resp.status}")

    return {"ok": True}
