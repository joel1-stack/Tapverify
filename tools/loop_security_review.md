# LOOP Public-Surface Security Review

Date: 2026-08-14
Scope: passive, non-intrusive (GET/HEAD + TLS handshake only). No exploitation performed.

## Summary
Overall posture is **strong**: valid DigiCert certificates, TLS 1.2/1.3 with strong ciphers,
HSTS preload on the API gateway, strict CSP, and an effective auth wall (401) across the
gateway. The API gateway and sandbox did **not** expose `.env`, source, actuator, or docs.
One genuine finding (`/debug`), plus several hardening nits worth raising.

## Findings

### 1. MEDIUM — Public unauthenticated `/debug` endpoint discloses internals
- `https://sandbox.loop.co.ke/debug`  → HTTP 200
- `https://api.loop.co.ke/debug`      → HTTP 200

Returns plaintext:
```
Host: sandbox.loop.co.ke
Client IP: 172.31.208.4
Forwarded For: 105.161.169.123:1638
```
and
```
Host: api.loop.co.ke
Served from gateway API route
Client IP: 10.200.61.18
Forwarded For: 105.161.169.123
```
Risks:
- Discloses **internal IPs** (`172.31.208.4` VPC, `10.200.61.18` backend).
- **Echoes the `X-Forwarded-For` header** — attacker-controlled input reflected back
  verbatim; potential for cache-poisoning / CDN-spoofing / log-injection tricks.
- Enumerates which route served the request ("Served from gateway API route").

Remediation: remove the route from the public gateway (or auth-gate it), and stop echoing
the `X-Forwarded-For` value in responses.

### 2. LOW — Conflicting `X-Frame-Options` values
`sandbox.loop.co.ke` returns `x-frame-options: DENY, SAMEORIGIN` (two values).
Browsers honor the first (`DENY`), so clickjacking is still blocked, but the duplicate
indicates conflicting layers and is unreliable across proxies.
Remediation: emit a single value (keep `DENY`), or move to `frame-ancestors` in the CSP.

### 3. LOW — HSTS missing `includeSubDomains` on the marketing site
- `loop.co.ke`       → `strict-transport-security: max-age=31536000` (no `includeSubDomains`)
- `sandbox.loop.co.ke` → `max-age=31536000; includeSubDomains; preload` (correct)

Remediation: add `includeSubDomains` (and `preload` once verified) on `loop.co.ke`.

### 4. INFO — Backend stack disclosure (cookie/headers)
- `api.loop.co.ke` sets `f5_cspm` (F5 ASPM) and `ApplicationGatewayAffinityCORS` (Azure
  App Gateway affinity) cookies → reveals load-balancer/ADC vendor.
- `server: nginx` (sandbox), `Apache` (loop.co.ke), `cloudflare` (api.loop.co.ke) — no
  version numbers disclosed (good).
- WSO2 API Manager confirmed via `JSESSIONID` under `/devportal`, `apim-dual-ring`,
  and the `f5_cspm`/affinity cookie set.

Remediation (optional): prefix/hide ADC cookies; remove `f5_cspm=1234` placeholder.

### 5. INFO — `/swagger-ui*` returns 400 on the gateway
`https://api.loop.co.ke/swagger-ui.html` → HTTP 400 (gateway catch-all intercepts).
Not a leak — indicates a gateway rule exists for those paths. Fine to leave, but verify
no unauthenticated swagger is reachable via alternate hosts.

## What was checked and found secure
- TLS certificates valid (DigiCert), no weak cipher suites observed, SANs correct.
- `/.env`, `/.git/*`, `/actuator/*`, `/v3|v2/api-docs`, `/swagger-*`, `/backup.zip`,
  `/dump.sql`, `/server-status`, `/graphql`, `/console`, `/admin` → **401/403/404**, not exposed.
- `trinity.cbaloom.com` (IAM, JWT issuer `trinity.cbaloop.com/mlinzi/realms/api-service`)
  fully 403 behind Cloudflare.
- `robots.txt` on `loop.co.ke` redirects to the homepage (WordPress catch-all) — benign.
- CSP, `nosniff`, `referrer-policy` present on the gateway.

## Note on the M-Pesa STK prompt (not a security issue)
The sandbox (`sandbox.loop.co.ke`) returns `COMPLETED` for `mpesa-prompt/2.0` within ~0ms —
it **simulates** the M-Pesa rails and never sends a real popup to a phone. This is by design
for all M-Pesa sandboxes (Safaricom Daraja included), not an exposure or a bug. A real STK
requires production credentials.

## Tooling
- `tools/recon.py` — TLS cert, security headers, path probe (reproduces everything above).
