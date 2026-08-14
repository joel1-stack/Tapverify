"""
Check the LOOP OAuth token's JWT (scopes/aud) and probe WSO2 APIM store /
publisher REST APIs to enumerate the real product/endpoint definitions for the
Tap Verify app. If the scopes allow, dump each API's OpenAPI spec so we can
nail the exact gateway paths for all 8 products.
"""
import base64
import json
import sys
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


def b64d(s):
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4)).decode("utf-8", "replace")


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
        sys.exit(f"token failed HTTP {r.status_code}: {data}")

    print("── token JWT ────────────────────────────────────────────────")
    try:
        payload = json.loads(b64d(token.split(".")[1]))
    except Exception as e:
        print(f"  could not decode JWT payload: {e}")
        payload = {}
    for k in ("scope", "scopes", "aud", "iss", "exp", "sub", "client_id", "application", "tier"):
        if k in payload:
            v = payload[k]
            if isinstance(v, str) and len(v) > 400:
                v = v[:400] + "…"
            print(f"  {k}: {v}")
    scopes = (payload.get("scope") or "").split() or (payload.get("scopes") or [])

    headers = {"Authorization": f"Bearer {token}",
               "Content-Type": "application/json", "Accept": "application/json"}

    print("\n── WSO2 API discovery ──────────────────────────────────────")
    candidates = [
        ("store v3",           f"{base}/devportal/apis"),
        ("store v4",           f"{base}/api/am/store/v4/apis"),
        ("store v4 all",       f"{base}/api/am/store/v4/apis?limit=100"),
        ("publisher v4",       f"{base}/api/am/publisher/v4/apis?limit=100"),
        ("publisher apps",     f"{base}/api/am/publisher/v4/applications?limit=100"),
        ("user app list",      f"{base}/devportal/applications"),
        ("store subscriptions", f"{base}/api/am/store/v4/subscriptions"),
    ]
    found = False
    for label, url in candidates:
        try:
            rr = requests.get(url, headers=headers, timeout=30)
        except requests.RequestException as e:
            print(f"  {label:<22} NETERR {e}")
            continue
        snippet = rr.text[:180].replace("\n", " ")
        print(f"  {label:<22} HTTP {rr.status_code}  {snippet}")
        if rr.status_code == 200 and rr.text.strip().startswith(("{", "[")):
            found = True
            try:
                j = rr.json()
                print(f"    → JSON keys: {list(j.keys()) if isinstance(j, dict) else 'list'}")
            except Exception:
                pass
    if not found and not any("apim:" in s for s in scopes):
        print("\n  No API listed and token has no apim: scope — the gateway is "
              "the only thing reachable. Sticking to gateway probing.")


if __name__ == "__main__":
    main()