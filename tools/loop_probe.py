"""
Discover which LOOP gateway product routes actually exist, using the real
OAuth token from django-backend/.env. A route that exists returns 4xx/200 on a
payload POST; a route that doesn't exist returns the Spring "404 Runtime Error"
body. Mini payload keeps it cheap and safe.
"""
import base64
import json
import sys
import uuid
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


def get_token(env):
    base = (env.get("LOOP_BASE_URL") or "https://sandbox.loop.co.ke").rstrip("/")
    key = env.get("LOOP_CONSUMER_KEY", "")
    secret = env.get("LOOP_CONSUMER_SECRET", "")
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
        sys.exit(f"token failed HTTP {r.status_code}: {data}")
    return base, token


def main():
    env = load_env()
    base, token = get_token(env)
    headers = {"Authorization": f"Bearer {token}",
               "Content-Type": "application/json", "Accept": "application/json"}
    payload = {"serviceCode": "PING", "txnReference": str(uuid.uuid4()).lower(),
               "requestParameters": {}}
    slugs = ["mpesa-prompt", "loop-prompt", "loop-mpesa-prompt", "request-to-pay",
             "pay-to-till", "pay-to-mpesa-till", "pay-to-loop-till", "till",
             "pay-to-paybill", "pay-to-mpesa-paybill", "paybill",
             "send-money", "send-money-mpesa", "send-money-loop", "send-money-pesalink",
             "transaction-status", "transaction-history", "transaction-inquiry",
             "status", "history", "stk-push", "stkpush", "pesalink"]
    versions = ["1.0", "2.0"]
    print(f"── gateway: {base} ─────────────────────────────")
    for slug in slugs:
        for ver in versions:
            url = f"{base}/gateway/{slug}/{ver}/services/process-request"
            try:
                r = requests.post(url, json=payload, headers=headers, timeout=20)
            except requests.RequestException as e:
                print(f"  {slug}/{ver:<4} NETERR {e}")
                continue
            body = r.text[:90].replace("\n", " ")
            marker = "FAIL(404)" if r.status_code == 404 else f"EXISTS {r.status_code}"
            print(f"  {slug}/{ver:<4} {marker:>10}  {body}")
    # also try unversioned form
    for slug in ["mpesa-prompt", "pay-to-till", "send-money-mpesa", "transaction-status"]:
        url = f"{base}/gateway/{slug}/services/process-request"
        try:
            r = requests.post(url, json=payload, headers=headers, timeout=20)
        except requests.RequestException as e:
            print(f"  {slug}      NETERR {e}")
            continue
        print(f"  {slug}      {'FAIL(404)' if r.status_code == 404 else f'EXISTS {r.status_code}'}  {r.text[:90]}")


if __name__ == "__main__":
    main()