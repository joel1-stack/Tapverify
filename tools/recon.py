"""
Passive recon for the LOOP review: TLS certificate inspection, security
headers, and probing for publicly exposed paths/docs on the public surface.
Non-intrusive — GET/HEAD only, no exploitation.
"""
import socket
import ssl
from datetime import datetime

import requests

TARGETS = [
    "https://sandbox.loop.co.ke",
    "https://loop.co.ke",
    "https://api.loop.co.ke",
    "https://devportal.loop.co.ke",
    "https://trinity.cbaloop.com",
]

PATHS = [
    "/.env", "/.git/config", "/.git/HEAD", "/wp-config.php", "/config.php",
    "/backup.zip", "/dump.sql", "/server-status", "/.well-known/security.txt",
    "/actuator", "/actuator/health", "/actuator/env", "/actuator/beans",
    "/v3/api-docs", "/v2/api-docs", "/swagger-ui.html", "/swagger-ui/index.html",
    "/swagger-resources", "/api-docs", "/openapi.json", "/robots.txt",
    "/devportal/admin", "/admin", "/console", "/graphql", "/debug",
]


def tls_info(host, port=443):
    ctx = ssl.create_default_context()
    try:
        with socket.create_connection((host, port), timeout=10) as sock:
            with ctx.wrap_socket(sock, server_hostname=host) as tls:
                cert = tls.getpeercert()
                return {
                    "host": host,
                    "protocol": tls.version(),
                    "cipher": tls.cipher(),
                    "issuer": cert.get("issuer"),
                    "subject": cert.get("subject"),
                    "notAfter": cert.get("notAfter"),
                    "notBefore": cert.get("notBefore"),
                    "san": [v for v in cert.get("subjectAltName", [])],
                }
    except Exception as e:
        return {"host": host, "error": str(e)}


def header_check(base):
    print(f"\n== {base} ==")
    try:
        r = requests.get(base, timeout=15, allow_redirects=True)
        print(f"  final URL: {r.url}  HTTP {r.status_code}  server: {r.headers.get('Server', '-')}")
        for h in ["x-powered-by", "x-frame-options", "content-security-policy", "strict-transport-security",
                  "x-content-type-options", "referrer-policy", "permissions-policy", "set-cookie",
                  "access-control-allow-origin"]:
            v = r.headers.get(h)
            if v:
                print(f"  {h}: {v}")
    except requests.RequestException as e:
        print(f"  ERROR {e}")


def path_probe(base):
    print(f"\n== path probe {base} ==")
    for p in PATHS:
        url = base + p
        try:
            r = requests.get(url, timeout=12, allow_redirects=False)
        except requests.RequestException:
            continue
        if r.status_code in (200, 301, 302, 307, 401):
            ct = (r.headers.get("Content-Type") or "")[:40]
            print(f"  {p:<28} HTTP {r.status_code}  {ct}")
        else:
            print(f"  {p:<28} HTTP {r.status_code}")


def main():
    print("── TLS / certificate inspection ──────────────────────────────")
    for t in TARGETS:
        host = t.split("://")[1].split("/")[0]
        info = tls_info(host)
        if "error" in info:
            print(f"  {host:<26} {info['error']}")
            continue
        def flat(rdn):
            out = {}
            for lst in rdn or []:
                for kv in lst:
                    if len(kv) >= 2:
                        out[kv[0]] = kv[1]
            return out
        issuer = flat(info["issuer"])
        subj = flat(info["subject"])
        print(f"  {host:<26} {info['protocol']} | {info['cipher'][0]} | {info['cipher'][1]}")
        print(f"    issuer   : {issuer.get('organizationName', '?')} / {issuer.get('commonName', '?')}")
        print(f"    subject  : {subj.get('commonName', '?')}")
        print(f"    valid    : {info['notBefore']} → {info['notAfter']}")
        print(f"    SAN      : {[s for _, s in info['san']][:8]}")
        days = (datetime.strptime(info["notAfter"], "%b %d %H:%M:%S %Y %Z") - datetime.utcnow()).days
        print(f"    expires in: {days} days")

    for t in TARGETS:
        header_check(t)
        path_probe(t)


if __name__ == "__main__":
    main()