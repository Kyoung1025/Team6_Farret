import json
import os
import urllib.request
from datetime import datetime, timedelta, timezone

WEBHOOK_URL = os.environ["WEBHOOK_URL"]
KST = timezone(timedelta(hours=9))


def _to_kst(utc_text):
    try:
        t = datetime.strptime(utc_text, "%Y-%m-%dT%H:%M:%S.%f%z")
        return t.astimezone(KST).strftime("%Y-%m-%d %H:%M:%S")
    except (ValueError, TypeError):
        return utc_text  # 형식이 다르면 받은 값을 그대로 보여줌


def _format(subject, message):
    try:
        alarm = json.loads(message)
    except (ValueError, TypeError):
        alarm = None

    if not isinstance(alarm, dict) or "AlarmName" not in alarm:
        return f"📢 **{subject or 'pretix-demo 알림'}**\n{message}"

    state = alarm.get("NewStateValue", "")
    icon = {"ALARM": "🔴", "OK": "🟢", "INSUFFICIENT_DATA": "⚪"}.get(state, "📢")
    label = {"ALARM": "경고", "OK": "정상", "INSUFFICIENT_DATA": "데이터 부족"}.get(state, state)
    lines = [
        f"{icon} **[{label}] {alarm['AlarmName']}**",
        alarm.get("AlarmDescription") or "",
        f"사유: {alarm.get('NewStateReason', '')}",
        f"시각: {_to_kst(alarm.get('StateChangeTime', ''))} (KST)",
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
