"""
Round 2 gateway discovery: hunt for the LOOP Prompt / Transaction Status /
Transaction History / Pay-to-LOOP-till product paths using informed slug
guesses + version variants, and try an unauthenticated WSO2 store catalogue.
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

    # candidate slugs ordered by likelihood
    slugs = ["prompt", "loop", "loop-prompt", "loop-prompt-v1", "loop-prompt-v2",
             "loop-collection", "receive-money-loop", "loop-receive", "request-money",
             "request-money-loop", "loop-request-to-pay", "request-to-pay",
             "pay-to-loop", "pay-to-loop-till", "pay-to-loop-account",
             "transaction", "transaction-status", "transaction-history",
             "transaction-status-query", "transaction-history-query",
             "get-transaction-status", "get-transaction-history", "txn-status",
             "query-status", "check-status", "payment-status", "status",
             "history", "reverse", "refund", "balance", "statement",
             "pay-to-mpesa-paybill", "paybill", "pay-to-till", "till",
             "send-money-loop-account", "loop-account", "loop-till",
             "transaction-status-v1", "transaction-history-v1",
             "collection", "disbursement", "mnapi", "mpesa", "pesalink",
             "prompt-v1", "prompt-v2"]
    versions = ["1.0", "2.0", "v1", "v2", "1", "2"]

    print(f"── gateway {base} ────────────────────────────────────────")
    hits = []
    checked = 0
    for slug in slugs:
        for ver in versions:
            url = f"{base}/gateway/{slug}/{ver}/services/process-request"
            try:
                resp = requests.post(url, json=payload, headers=headers, timeout=20)
            except requests.RequestException as e:
                print(f"  {slug}/{ver:<4} NETERR {e}")
                continue
            checked += 1
            body = resp.text[:100].replace("\n", " ")
            spring = "The requested resource" in body or '"status report"' in body.lower()
            if resp.status_code == 404 and spring:
                continue  # true route miss — skip
            print(f"  ✓ {slug}/{ver:<4} HTTP {resp.status_code}  {body}")
            hits.append((slug, ver, resp.status_code, resp.text[:400]))
    print(f"\n  checked {checked} combos; route candidates above ({len(hits)})")

    print("\n── unauthenticated store catalogue ────────────────────────")
    for url in [f"{base}/devportal/apis?limit=100",
                f"{base}/api/am/store/v4/apis?limit=100",
                f"{base}/api/am/publisher/v4/apis?limit=100&expand=true"]:
        try:
            rr = requests.get(url, timeout=30)
        except requests.RequestException as e:
            print(f"  NETERR {e}")
            continue
        print(f"  {url.replace(base, '')}  HTTP {rr.status_code}  {rr.text[:200]}")


if __name__ == "__main__":
    main()