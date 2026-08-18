# TapVerify — Full Product & Tech Stack (as built)

> Generated: 2026-08-14  
> Scope: everything that exists in the repo and has been tested/built with you.

---

## 1. Product Overview

TapVerify is a **proof-of-payment layer** on top of LOOP (NCBA) and M-PESA rails.
Every inbound payment becomes a verified, uneditable record the whole group can see.

### 1.1 Core Value Proposition
- **Trust layer for group payments** — replaces WhatsApp screenshot receipts with
  cryptographically verified LOOP/MPesa records.
- **Two-user system** — Board App (staff: Treasurer, Chairman, Secretary, Assistant)
  and Member App (anyone added to an org) share one backend.
- **KYC-gated organization creation** — orgs cannot collect until verified.
- **Offline-first** — payments save locally via Hive; sync when signal returns.

### 1.2 Supported Organization Types
- Chama / Burial
- SACCO
- School
- Church

All types share one engine; rules engine changes what each sees/does.

### 1.3 Member Lifecycle
invited → active → (suspended / left) → reinstated / banned

### 1.4 Payment Rails
- **LOOP (primary)** — OAuth2 + HMAC-signed gateway
- **PayHero (legacy)** — STK Push integration

### 1.5 Verified LOOP Gateway Contract
- **Base**: `https://sandbox.loop.co.ke`
- **Auth**: OAuth2 `client_credentials` at `/oauth2/token` (consumer key/secret)
- **Signing**: HMAC-SHA256 of `"merchantTill|timestamp|nonce"` with the till secret
- **Call**: `POST /gateway/{product}/{version}/services/process-request`
- **Envelope**: `{ "serviceCode": "MRCHNT_SENDMONEY", "txnReference", "requestParameters" }`

### 1.6 Confirmed Live Products (sandbox)
| # | API | Gateway path | Status | Transfer ID example |
|---|---|---|---|---|
| 1 | LOOP M-Pesa Prompt | `mpesa-prompt/2.0` | COMPLETED | `TAM202608141181682087` |
| 2 | Pay to M-Pesa Till | `pay-to-mpesa-till/1.0` | COMPLETED | `TAM202608144850275747` |
| 3 | Pay to M-Pesa Paybill | `pay-to-paybill/1.0` | COMPLETED | `TAM202608146269208749` |
| 4 | Send Money – M-Pesa | `send-money-mpesa/1.0` | COMPLETED | `TAM202608148129060470` |
| 5 | Send Money – Loop | `send-money-loop/1.0` | 404 (sandbox stub) | — |
| 6 | Send Money – Pesalink | `send-money-pesalink/1.0` | 403 (not subscribed) | — |
| 7 | LOOP Prompt | route not found | — | — |
| 8 | Transaction Status / History | route not found | — | — |

> Sandbox **simulates** M-Pesa rails (instant COMPLETED, no real STK).

---

## 2. Full Tech Stack

### 2.1 Frontend (Flutter)
- **Language**: Dart 3.x
- **Framework**: Flutter 3.x (Material 3)
- **State**: Riverpod / Provider (none used) — direct service calls
- **Offline**: Hive (NoSQL local storage) for pending events, members, settings
- **Theme**: LOOP orange (`#FF6B00`) as primary brand color; deep orange
  (`#9A3412`), primary orange (`#EA580C`), primaryLight (`#FFB27A`), accent
  (`#FF6B00`).
- **Fonts**: Google Fonts (Inter)
- **Platforms**: Web, Android, iOS (codebase ready)

#### 2.1.1 Screens (lib/screens/)
| Screen | Purpose |
|---|---|
| `splash_screen.dart` | LOOP-orange gradient splash, animated logo |
| `login_screen.dart` | Phone + PIN login (staff) / OTP (member) |
| `home_shell.dart` | Bottom-nav shell (Dashboard, More) |
| `dashboard_screen.dart` | Stats, recent activity, quick actions |
| `member_list_screen.dart` | Searchable member list, filter by status |
| `confirm_screen.dart` | Amount + payment type confirmation |
| `success_screen.dart` | Approval + receipt PIN display |
| `disburse_screen.dart` | Loan disbursement, refunds, payouts |
| `board_demo_screen.dart` | Treasurer & KYC demo journey |
| `member_payment_demo_screen.dart` | Member payment demo journey |
| `more_screen.dart` | Profile, offline sync, payment rails, LOOP integration (8 APIs), technical snapshots, demos, about, logout |
| `org_select_screen.dart` | Organization selector (multi-org) |
| `create_organization_screen.dart` | Create org with KYC docs upload |
| `import_members_screen.dart` | CSV member import |
| `add_member_screen.dart` | Add single member |
| `payments_ledger_screen.dart` | Every payment with ref + PIN proof, export PDF, share/print |
| `loan_eligibility_screen.dart` | 12-month transaction inquiry, eligibility report |
| `activity_screen.dart` | Full activity feed with filtering |
| `qr_scan_screen.dart` | QR code scanning (future) |
| `campaign_detail_screen.dart` | Campaign details (future) |

#### 2.1.2 Widgets (lib/widgets/)
| Widget | Purpose |
|---|---|
| `loop_value_strip.dart` | 8-API value panel used by demos |

#### 2.1.3 Services (lib/services/)
| Service | Purpose |
|---|---|
| `api_service.dart` | HTTP client with offline fallback, LOOP gateway calls |
| `hive_service.dart` | Local cache + pending queue (Hive) |
| `demo_service.dart` | Demo data seeding, member demo launcher |
| `payment_report_service.dart` | PDF receipt generation (PDF lib) |
| `pdf_share.dart` / `pdf_share_web.dart` / `pdf_share_io.dart` | Platform-specific PDF sharing |
| `contribution_service.dart` | Contribution management |

#### 2.1.4 Models (lib/models/)
| Model | Purpose |
|---|---|
| `member.dart` | Hive model for member |
| `pending_event.dart` | Offline queue model |

#### 2.1.5 Constants & Assets
- `constants.dart`: AppColors palette, AppAssets paths
- `main.dart`: Theme, auth wrapper, splash web shell

### 2.2 Backend (Django)
- **Framework**: Django 4.2
- **REST**: Django REST Framework
- **Database**: PostgreSQL
- **Auth**: JWT (djangorestframework-simplejwt)
- **Async**: Celery (for SMS, reminders)
- **SMS**: Africa's Talking API
- **Payments**: LOOP API (primary), PayHero (legacy)

#### 2.2.1 Project Structure
```
django-backend/
├── manage.py
├── requirements.txt
├── .env.example
└── tapverify/
    ├── config/
    │   ├── settings.py
    │   ├── urls.py
    │   └── wsgi.py
    └── apps/core/
        ├── models.py
        ├── views.py
        ├── urls.py
        ├── admin.py
        ├── serializers.py
        ├── services/
        │   ├── loop/
        │   │   └── client.py   # Verified LOOP gateway contract
        │   ├── sms.py
        │   └── payment_rail.py
        └── templates/core/
            ├── receipt_pin.html
            ├── receipt.html
            ├── payment_link.html
            ├── payment_success.html
            └── payment_expired.html
```

#### 2.2.2 Models (core/models.py)
- Workspace
- Staff
- Member
- VerificationEvent
- MpesaTransaction
- PaymentReminder
- PaymentLink

#### 2.2.3 Views (core/views.py)
- Auth: login
- Members: list, create, update
- Verify: payment verification + SMS
- Stats: dashboard statistics
- Reminders: bulk SMS reminders
- Payment Link: create, serve
- Rail: info
- Webhooks: LOOP IPN, M-Pesa callback
- Demo: setup

#### 2.2.4 API Endpoints
| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/auth/login/` | POST | Staff login (phone + PIN) |
| `/api/v1/members/` | GET | List workspace members |
| `/api/v1/verify/` | POST | Verify payment + send SMS |
| `/api/v1/stats/` | GET | Dashboard statistics |
| `/api/v1/reminders/send/` | POST | Bulk payment reminders |
| `/api/v1/payment-link/create/` | POST | Create member payment link |
| `/api/v1/rail/info/` | GET | Active payment rail info |
| `/api/v1/webhooks/loop/` | POST | LOOP IPN webhook |
| `/api/v1/webhooks/mpesa/` | POST | M-Pesa callback (PayHero) |
| `/api/v1/demo/setup/` | POST | Create demo workspace |
| `/r/<token>/` | GET/POST | PIN-protected receipt portal |
| `/p/<token>/` | GET | Member payment link page |

### 2.3 Infrastructure & Tooling

#### 2.3.1 CI/CD (GitHub Actions)
| Workflow | Trigger | Output |
|---|---|---|
| `flutter-web.yml` | push to main | Build Flutter web (`--base-href=/Tapverify/`) → deploy to GitHub Pages |
| `android-release.yml` | push tag `v*` | Build release APK → publish to GitHub Release |

#### 2.3.2 Terminal Testers (tools/)
| Tool | Purpose |
|---|---|
| `loop_api_test.py` | OAuth2 + HMAC sandbox tester for LOOP gateway products |
| `loop_matrix.py` | Full 8-product matrix vs live sandbox with your phone |
| `loop_probe.py` / `loop_probe2.py` / `loop_probe3.py` | Gateway route discovery (slug/version probing) |
| `loop_discover.py` | JWT scope + WSO2 store API probing |
| `loop_security_review.md` | Public-surface security findings (TLS, headers, exposed paths) |
| `recon.py` | TLS cert inspection, security headers, path probing |

#### 2.3.3 Security Review Findings
- **MEDIUM**: Public unauthenticated `/debug` endpoint on sandbox & api gateways — discloses internal IPs (`172.31.208.4`, `10.200.61.18`) and reflects `X-Forwarded-For` header.
- **LOW**: Conflicting `X-Frame-Options: DENY, SAMEORIGIN` on sandbox gateway.
- **LOW**: HSTS missing `includeSubDomains` on `loop.co.ke`.
- **INFO**: Backend stack disclosure (F5 ASPM, Azure App Gateway, WSO2 APIM, nginx/Apache).
- **INFO**: `/swagger-ui*` returns 400 on gateway (catch-all rule).

### 2.4 Deployment

#### 2.4.1 Web
- **Build**: `flutter build web --release --base-href=/Tapverify/`
- **Deploy**: GitHub Pages (auto via `flutter-web.yml`)
- **URL**: `https://joel1-stack.github.io/Tapverify/` (once Pages enabled in repo settings)
- **Local dev**: `flutter run -d chrome` or detached server on port 8090

#### 2.4.2 Android
- **Build**: `flutter build apk --release` (debug-signed)
- **Artifact**: `build/app/outputs/flutter-apk/app-release.apk` (69.6MB)
- **Deploy**: GitHub Release (auto via `android-release.yml` on tag push)
- **Download**: `https://github.com/joel1-stack/Tapverify/releases/download/v1.0.0/app-release.apk`

---

## 3. What Exists — Full Inventory

### 3.1 Flutter App (lib/)
- ✅ **Theme**: LOOP orange everywhere (constants, main.dart, all screens)
- ✅ **Screens**: 19 screens (see 2.1.1)
- ✅ **Widgets**: loop_value_strip (8-API value panel)
- ✅ **Services**: api_service, hive_service, demo_service, payment_report_service, pdf_share_*
- ✅ **Models**: member, pending_event (Hive)
- ✅ **Constants**: AppColors, AppAssets
- ✅ **More screen**: Technical Snapshots section with live LOOP gateway responses

### 3.2 Django Backend (django-backend/)
- ✅ **Models**: Workspace, Staff, Member, VerificationEvent, MpesaTransaction, PaymentReminder, PaymentLink
- ✅ **Views**: Auth, members, verify, stats, reminders, payment-link, rail, webhooks, demo
- ✅ **Services**: LOOP client (OAuth2 + HMAC), SMS (Africa's Talking), payment rail abstraction
- ✅ **Templates**: receipt_pin, receipt, payment_link, payment_success, payment_expired
- ✅ **Webhooks**: LOOP IPN, M-Pesa callback

### 3.3 CI/CD
- ✅ **flutter-web.yml**: auto-build + deploy to GitHub Pages on push to main
- ✅ **android-release.yml**: auto-build APK + publish to GitHub Release on tag push

### 3.4 Terminal Tooling
- ✅ **loop_api_test.py**: live sandbox tester (OAuth2 + HMAC)
- ✅ **loop_matrix.py**: full 8-product matrix vs your phone
- ✅ **loop_probe*.py**: gateway route discovery
- ✅ **loop_discover.py**: JWT scope + WSO2 store probing
- ✅ **recon.py**: TLS/headers/path recon
- ✅ **loop_security_review.md**: documented findings

### 3.5 Documentation
- ✅ **README.md**: Full platform architecture (V2), problem statement, solution, target market, setup, endpoints, tech stack, hackathon submission
- ✅ **loop_security_review.md**: Public-surface security review

---

## 4. What Might Be Missing

### 4.1 Product / Features
- [ ] **iOS build** — codebase is ready, but iOS not built/tested.
- [ ] **Production LOOP keys** — sandbox only; need go-live for real STK.
- [ ] **LOOP Prompt / Transaction Status / Transaction History** — gateway routes not discovered; need exact product slugs from portal.
- [ ] **Test-number whitelist** — sandbox may support; need docs from portal.
- [ ] **Member app OTP flow** — backend SMS via Africa's Talking; frontend OTP entry screen exists but not fully wired?
- [ ] **KYC document upload & review UI** — backend supports; frontend upload flow exists.
- [ ] **Loan module** — eligibility screen exists; full loan lifecycle (apply, approve, disburse, repay) may need more screens.
- [ ] **PDF receipt signing** — PDF export exists; signing/certification may need enhancement.
- [ ] **Multi-currency** — currently KES only.
- [ ] **Audit logs** — backend may need explicit audit trail for compliance.

### 4.2 Backend
- [ ] **Rate limiting** — API endpoints may need throttling.
- [ ] **Input validation hardening** — ensure all endpoints sanitize inputs.
- [ ] **CORS configuration** — verify CORS headers for web.
- [ ] **Production database** — PostgreSQL setup documented but not provisioned.
- [ ] **Monitoring / logging** — no explicit monitoring setup.
- [ ] **Backup strategy** — database backup not configured.

### 4.3 Frontend
- [ ] **Responsive web** — desktop web shell exists (capped 960px); full responsive may need polish.
- [ ] **Accessibility** — color contrast, screen reader support not audited.
- [ ] **Localization** — currently English only.
- [ ] **Dark mode** — not implemented.
- [ ] **Error handling UX** — some error states may need better messaging.
- [ ] **Loading states** — some screens may need skeleton loaders.

### 4.4 DevOps / CI
- [ ] **iOS CI** — no iOS build workflow.
- [ ] **Test suite** — no automated tests (unit, widget, integration).
- [ ] **Code signing** — Android release uses debug key; production signing not configured.
- [ ] **Secrets management** — `.env` ignored; consider GitHub Secrets for CI.
- [ ] **Dependency scanning** — no SCA (Software Composition Analysis) in CI.

### 4.5 Security
- [ ] **Penetration testing** — only passive recon done; active testing pending.
- [ ] **Secrets rotation** — LOOP sandbox keys in `.env`; need rotation policy.
- [ ] **Rate limit on `/debug`** — endpoint should be auth-gated or removed.
- [ ] **CSP hardening** — current CSP allows `unsafe-inline`/`unsafe-eval`; could be tightened.
- [ ] **HSTS preload submission** — `sandbox.loop.co.ke` has preload; `loop.co.ke` needs submission.

### 4.6 LOOP Integration
- [ ] **Production keys** — sandbox only; need go-live credentials.
- [ ] **Transaction Status / History** — exact gateway slugs unknown.
- [ ] **LOOP Prompt** — exact gateway slug unknown.
- [ ] **Pay to LOOP Till** — exact gateway slug unknown.
- [ ] **Test-number whitelist** — sandbox may support; need portal docs.

---

## 5. Quick Start (What Works Now)

### 5.1 Run the App
```bash
# Web (local)
flutter run -d chrome

# Android (local)
flutter run -d <device_id>

# Web (detached server)
flutter run -d web-server --web-port 8090 --web-hostname 0.0.0.0 --release
```

### 5.2 Backend
```bash
cd django-backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env
# Fill LOOP_* + Africa's Talking keys in .env
createdb tapverify
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### 5.3 Test LOOP APIs
```bash
python tools/loop_api_test.py prompt 254715641339 10
python tools/loop_matrix.py
```

---

## 6. Next Steps (If You Want to Go Deeper)

1. **Verify LOOP production go-live** — apply for production keys to get real STK.
2. **Discover remaining gateway slugs** — check portal for LOOP Prompt, Transaction Status/History, Pay to LOOP Till.
3. **Add automated tests** — unit, widget, integration for Flutter + Django.
4. **Hardening** — rate limiting, input validation, monitoring, backups.
5. **iOS build** — test and deploy to TestFlight/App Store.
6. **Security audit** — active penetration testing, secrets rotation, CSP tightening.

---

*This document is a snapshot of what exists as of 2026-08-14. No new features or code were added — only inventory and analysis.*