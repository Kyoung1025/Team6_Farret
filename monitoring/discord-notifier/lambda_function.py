"""SNS(pretix-demo-alerts)로 들어온 CloudWatch 알람을 디스코드 채널로 보낸다.

구조: CloudWatch 알람 → SNS → 이 Lambda → 디스코드 웹훅
웹훅 URL은 비밀값이라 코드에 두지 않고 Lambda 환경 변수 WEBHOOK_URL에 넣는다.
외부 라이브러리 없이 표준 라이브러리만 쓴다 (콘솔 코드 편집기에 이 파일 내용만 붙여넣으면 된다).
"""

import json
import os
import urllib.request

WEBHOOK_URL = os.environ["WEBHOOK_URL"]


def _format(subject, message):
    """CloudWatch 알람 형식이면 읽기 좋게 바꾸고, 아니면 받은 글을 그대로 보낸다."""
    try:
        alarm = json.loads(message)
    except (ValueError, TypeError):
        alarm = None

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
    for record in event.get("Records", []):
        sns = record.get("Sns", {})
        content = _format(sns.get("Subject"), sns.get("Message", ""))

        body = json.dumps({"username": "pretix-demo-alerts", "content": content[:2000]}).encode()  # 디스코드 메시지 최대 2000자
        req = urllib.request.Request(
            WEBHOOK_URL,
            data=body,
            headers={"Content-Type": "application/json", "User-Agent": "pretix-demo-alerts"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            print(f"discord status={resp.status}")

    return {"ok": True}
