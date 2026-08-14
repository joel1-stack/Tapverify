"""
Full product matrix vs. a real phone. Uses live OAuth token + till secret.
Send Money - Loop gets a full account payload (hypothesis: it needs the
creditPartyAccount field, not just a phone). Pesalink checked for entitlement.
"""
import base64
import hashlib
import hmac
import json
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent
ENV = ROOT / "django-backend" / ".env"


def load_env():
    env = {}
    for line in ENV.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip()
    return env


def call(env, product, version, params, service_code="MRCHNT_SENDMONEY"):
    base = (env.get("LOOP_BASE_URL") or "https://sandbox.loop.co.ke").rstrip("/")
    key, secret = env["LOOP_CONSUMER_KEY"], env["LOOP_CONSUMER_SECRET"]
    till = env.get("LOOP_TILL", "133239")
    till_secret = env.get("LOOP_TILL_SECRET", "")
    token_url = env.get("LOOP_TOKEN_URL", "") or f"{base}/oauth2/token"
    basic = base64.b64encode(f"{key}:{secret}".encode()).decode()
    r = requests.post(token_url,
                      data={"grant_type": "client_credentials"},
                      headers={"Authorization": f"Basic {basic}",
                               "Content-Type": "application/x-www-form-urlencoded"},
                      timeout=30)
    data = r.json() if r.text else {}
    token = data.get("access_token") or data.get("token") or (data.get("data") or {}).get("token")
    if not token:
        return None, f"token failed {r.status_code}"
    headers = {"Authorization": f"Bearer {token}",
               "Content-Type": "application/json", "Accept": "application/json"}
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    nonce = str(uuid.uuid4()).lower()
    signature = hmac.new(till_secret.encode(),
                         f"{till}|{timestamp}|{nonce}".encode(),
                         hashlib.sha256).hexdigest()
    params = {**params, "merchantTill": till, "timestamp": timestamp,
              "nonce": nonce, "signature": signature}
    payload = {"serviceCode": service_code, "txnReference": str(uuid.uuid4()).lower(),
               "requestParameters": params}
    url = f"{base}/gateway/{product}/{version}/services/process-request"
    resp = requests.post(url, json=payload, headers=headers, timeout=45)
    try:
        body = resp.json()
    except ValueError:
        return resp.status_code, resp.text[:300]
    return resp.status_code, body


def show(label, result):
    code, body = result
    print(f"\n── {label} ────────────────────────────────────────────")
    if isinstance(body, str):
        print(f"  HTTP {code}  {body}")
        return
    print(f"  HTTP {code}  statusCode={body.get('statusCode')}")
    inner = body.get("data") or {}
    print(f"  message={body.get('message')}  serviceStatus={inner.get('serviceTransactionStatus')}")
    rd = (inner.get("response") or {}).get("responseDetails") or {}
    if rd:
        print(f"  transferOrderId={rd.get('transferOrderId')}  requestId={rd.get('requestId')}  "
              f"status={rd.get('transferStatus')}")
    print(f"  raw={json.dumps(body)[:400]}")


def main():
    env = load_env()
    phone = "254715641339"
    common = {"channel": "MPESA", "recipientMobileNo": phone,
              "amount": "5.00", "purposeOfPayment": "TapVerify matrix demo"}
    show("1. LOOP M-Pesa Prompt (mpesa-prompt/2.0)", call(env, "mpesa-prompt", "2.0", dict(common)))
    show("2. Pay to M-Pesa Till (pay-to-mpesa-till/1.0)", call(env, "pay-to-mpesa-till", "1.0", dict(common)))
    show("3. Pay to M-Pesa Paybill (pay-to-paybill/1.0)", call(env, "pay-to-paybill", "1.0", dict(common)))
    show("4. Send Money M-Pesa (send-money-mpesa/1.0)", call(env, "send-money-mpesa", "1.0", dict(common)))
    show("5. Send Money Loop — phone only (send-money-loop/1.0)", call(env, "send-money-loop", "1.0", dict(common)))
    loop_acc = dict(common)
    loop_acc["creditPartyAccount"] = phone
    loop_acc["debitPartyAccount"] = env.get("LOOP_TILL", "133239")
    show("6. Send Money Loop — account fields (send-money-loop/1.0)", call(env, "send-money-loop", "1.0", loop_acc))
    show("7. Send Money Pesalink entitlement (send-money-pesalink/1.0)", call(env, "send-money-pesalink", "1.0", dict(common)))
    show("8. Probe: LOOP Prompt (loop-prompt/2.0)", call(env, "loop-prompt", "2.0", dict(common)))


if __name__ == "__main__":
    main()