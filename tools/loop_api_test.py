"""
TapVerify — LOOP sandbox API tester (terminal).

Loads LOOP_* credentials from django-backend/.env (never prints them),
obtains an OAuth2 bearer token, signs the payload with the till secret
(HMAC-SHA256 of "merchantTill|timestamp|nonce"), and calls the requested
product gateway endpoint.

Usage:
    python tools/loop_api_test.py [product] [phone] [amount]

Products:
    prompt        Mpesa Prompt (mpesa-prompt/2.0)  — API 1 / API 7 (LOOP Prompt)
    till          Pay to M-Pesa Till (pay-to-paybill/1.0) — API 2
    paybill       Pay to Paybill (pay-to-paybill/1.0)      — API 3
    send          Send Money - M-Pesa (send-money-mpesa/1.0) — API 6
    loop          Send Money - Loop (send-money-loop/1.0)  — API 8 (may be stubbed)

Examples:
    python tools/loop_api_test.py prompt 254712345678 10
    python tools/loop_api_test.py send 254798765432 5
"""
import argparse
import base64
import hashlib
import hmac
import json
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent
ENV = ROOT / "django-backend" / ".env"
TOKEN_PATH = "/oauth2/token"


def load_env():
    env = {}
    if not ENV.exists():
        sys.exit(f"Missing {ENV} — copy django-backend/.env.example to .env and fill LOOP_* keys.")
    for line in ENV.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip()
    return env


def mask(v):
    v = str(v)
    return f"{v[:4]}...{v[-4:]}" if len(v) > 8 else "(set)"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("product", nargs="?", default="prompt",
                    help="prompt | till | paybill | send | loop")
    ap.add_argument("phone", nargs="?", default="254712345678")
    ap.add_argument("amount", nargs="?", default="10")
    args = ap.parse_args()

    env = load_env()
    base = (env.get("LOOP_BASE_URL") or "https://sandbox.loop.co.ke").rstrip("/")
    key = env.get("LOOP_CONSUMER_KEY", "")
    secret = env.get("LOOP_CONSUMER_SECRET", "")
    till = env.get("LOOP_TILL", "133239")
    till_secret = env.get("LOOP_TILL_SECRET", "")
    token_url = env.get("LOOP_TOKEN_URL", "") or f"{base}{TOKEN_PATH}"

    if not key or not secret or not till_secret:
        sys.exit("LOOP consumer key/secret or till secret missing in .env")

    print("── TapVerify LOOP sandbox tester ─────────────────────────────")
    print(f"  base        : {base}")
    print(f"  consumer    : {mask(key)}")
    print(f"  till        : {till}")

    # 1. OAuth2 token
    basic = base64.b64encode(f"{key}:{secret}".encode()).decode()
    r = requests.post(
        token_url,
        data={"grant_type": "client_credentials"},
        headers={"Authorization": f"Basic {basic}",
                 "Content-Type": "application/x-www-form-urlencoded"},
        timeout=30,
    )
    data = r.json() if r.text else {}
    token = data.get("access_token") or data.get("token") or (data.get("data") or {}).get("token")
    if not token:
        print(f"  token       : FAILED HTTP {r.status_code}")
        print(json.dumps(data, indent=2)[:1200])
        sys.exit(1)
    print(f"  token       : OK ({mask(token)})")
    headers = {"Authorization": f"Bearer {token}",
               "Content-Type": "application/json", "Accept": "application/json"}

    # 2. Sign
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    nonce = str(uuid.uuid4()).lower()
    message = f"{till}|{timestamp}|{nonce}"
    signature = hmac.new(till_secret.encode(), message.encode(), hashlib.sha256).hexdigest()

    params = {
        "merchantTill": till,
        "timestamp": timestamp,
        "nonce": nonce,
        "signature": signature,
        "channel": "MPESA",
        "recipientMobileNo": args.phone,
        "amount": f"{float(args.amount):.2f}",
        "purposeOfPayment": "TapVerify sandbox test",
    }

    spec = {
        "prompt": ("mpesa-prompt", "2.0"),
        "till": ("pay-to-paybill", "1.0"),
        "paybill": ("pay-to-paybill", "1.0"),
        "send": ("send-money-mpesa", "1.0"),
        "loop": ("send-money-loop", "1.0"),
    }
    if args.product not in spec:
        sys.exit(f"Unknown product '{args.product}'. Choose: {', '.join(spec)}")
    product, version = spec[args.product]
    url = f"{base}/gateway/{product}/{version}/services/process-request"
    payload = {
        "serviceCode": "MRCHNT_SENDMONEY",
        "txnReference": str(uuid.uuid4()).lower(),
        "requestParameters": params,
    }

    print(f"  request     : POST {product}/{version} → {args.phone} Ksh {float(args.amount):.2f}")
    print("───────────────────────────────────────────────────────────────")
    resp = requests.post(url, json=payload, headers=headers, timeout=45)
    print(f"HTTP {resp.status_code}")
    try:
        body = resp.json()
    except ValueError:
        print(resp.text[:1200])
        return
    print(json.dumps(body, indent=2))
    code = body.get("statusCode")
    if code == 200:
        inner = body.get("data") or {}
        st = inner.get("serviceTransactionStatus") or ((inner.get("response") or {}).get("responseDetails") or {}).get("transferStatus")
        print("── RESULT: SUCCESS" if st in ("S", "COMPLETED") else f"── RESULT: pending/handled (statusCode 200, serviceStatus={st})")
    else:
        print(f"── RESULT: FAILED (statusCode={code})")


if __name__ == "__main__":
    main()
