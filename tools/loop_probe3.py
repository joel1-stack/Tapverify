"""
Fast bounded probe (round 3): 1.0/2.0 only, 8s timeout, focused slugs.
Skips Spring 'Not Found' (true route miss) silently; prints anything else.
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


def main():
    env = load_env()
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
        sys.exit("token failed")
    headers = {"Authorization": f"Bearer {token}",
               "Content-Type": "application/json", "Accept": "application/json"}
    ref = str(uuid.uuid4()).lower()
    payload = {"serviceCode": "MRCHNT_SENDMONEY", "txnReference": ref,
               "requestParameters": {"merchantTill": env.get("LOOP_TILL", "133239"),
                                     "timestamp": "2026-08-14T00:00:00Z",
                                     "nonce": ref, "signature": "x",
                                     "channel": "MPESA"}}

    slugs = ["prompt", "loop", "loop-prompt", "loop-collection",
             "receive-money-loop", "loop-receive", "request-money",
             "pay-to-loop", "pay-to-loop-till", "loop-till", "loop-account",
             "transaction-status", "transaction-history", "txn-status",
             "get-transaction-status", "get-transaction-history",
             "reverse", "refund", "balance", "statement",
             "pay-to-mpesa-paybill", "collection", "disbursement",
             "checkout", "check-status"]
    session = requests.Session()
    hits = 0
    total = 0
    for slug in slugs:
        for ver in ("1.0", "2.0"):
            url = f"{base}/gateway/{slug}/{ver}/services/process-request"
            try:
                resp = session.post(url, json=payload, headers=headers, timeout=8)
            except requests.RequestException:
                continue
            total += 1
            body = resp.text[:110].replace("\n", " ")
            spring = resp.status_code == 404 and "requested resource" in resp.text.lower()
            if spring:
                continue
            hits += 1
            print(f"  ✓ {slug}/{ver:<4} HTTP {resp.status_code}  {body}")
    print(f"\n  probed {total} combos, {hits} non-404 route candidates")


if __name__ == "__main__":
    main()