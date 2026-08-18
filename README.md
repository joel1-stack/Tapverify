# TapVerify Workforce

**Team:** TapVerify
**Product:** Obligation · Payment · Proof — the coordination layer for factory
collections, running on LOOP, SasaPay, Africa's Talking and (optionally) Avalanche.
**Built for:** the Africa's Talking Hackathon (Aug 27, 2026) and the Avalanche
Team1 Kenya Mini Hack (Aug 28–30, 2026).

> A foreman raises an obligation. Every worker is notified and pays from their
> phone. The foreman watches proof land in real time — with streaks, badges and
> rewards on top.

The **mobile app is the real product** (foreman + worker). The **web build is the
demo** — an auto-playing story of what the mobile app serves.

---

## 1. Product: Obligation → Payment → Proof

TapVerify Workforce turns a factory's welfare / medical / emergency / trip
collections into trackable obligations with unforgeable proof.

### 1.1 The two-user system

| | Foreman (Board) | Worker |
|---|---|---|
| **Who** | Juma Kamau, factory foreman | Any of the 47 workers (e.g. Ochieng Odhiambo) |
| **Login** | Phone + PIN | Phone + PIN (same demo PIN `1234`) |
| **Sees** | Dashboard, collections, who-paid grid, workers roster, evidence console | Due obligations, paid history, streak, badges |
| **Acts** | Raise collection, remind, simulate/verify a payment, archive | Pay now → proof receipt |

### 1.2 The 9-state transaction lifecycle

Every payment task moves through the full lifecycle and every state transition
is evidence the foreman can audit:

```
CREATED → NOTIFIED → PENDING → COMPLETED → VERIFIED → STREAK → BADGE → REWARD → ARCHIVED
```

- **CREATED** the obligation exists
- **NOTIFIED** the worker got the SMS / STK prompt / checkout link
- **PENDING** awaiting payment
- **COMPLETED** the rail confirmed the money moved (transferOrderId / txn ref)
- **VERIFIED** proof checked (signed webhook; Avalanche attestation optional)
- **STREAK → BADGE → REWARD** on-time behaviour is rewarded (3/6/12-month streaks)
- **ARCHIVED** the collection closes and stays as an auditable record

### 1.3 Multi-rail payment architecture

`payments/router.py` (`PaymentRouter.charge(task, method='auto')`) is the moat —
"everything else is UI". Rails are pluggable and tested:

| Rail | Status | What it does |
|---|---|---|
| **LOOP (NCBA)** | **LIVE — proven on sandbox** | M-Pesa Prompt, Pay to Till, Pay to Paybill, Send Money — all 4 products returned `200 COMPLETED` with real `TAM…` transferOrderIds |
| **SasaPay** | READY — keys pending | OAuth token + Checkout link + webhook signed `X-SasaPay-Signature` (HMAC-SHA512) |
| **Africa's Talking** | READY — keys pending | SMS delivery of prompts/links, USSD for feature phones, airtime rewards |
| **Avalanche** | PLANNED | Optional attestation of badges/streaks (proof layer, **not** payment) |

SasaPay contract (implemented in `services/sasapay.py`):

```
GET https://sandbox.sasapay.app/oauth/v1/generate?grant_type=client_credentials
Authorization: Basic base64(CLIENT_ID:SECRET)
→ create checkout → { CheckoutRequestID, CheckoutUrl }
callback signed: X-SasaPay-Signature = HMAC-SHA512(
    transaction_code-merchant_code-account_number-payment_reference-amount)
```

Credentials live only in the backend (`.env`), never in the Flutter app.

### 1.4 Registration, KYC and onboarding

The foreman registers a factory in four steps:

1. **Factory details** — name, type, phone, monthly contribution
2. **KYC documents** — upload ID / business registration / utility bill
   (collections stay locked until admin review approves — uploads staged locally
   in the demo, review queue wired before launch)
3. **Members** — CSV import (`name, phone, department`) via `file_picker`; every
   row becomes a worker with a code and a QR card. No CSV → 47 seeded demo workers
4. **Payment QR** — the factory's QR card, generated with `qr_flutter`; workers
   scan to pay once live

### 1.5 Demo story (web)

Kamau Metalworks, 47 workers. The foreman raises the August welfare levy
(Ksh 200). Every worker is notified, Ochieng pays from his phone, the foreman
watches the who-paid grid fill in real time, and streaks/badges start building.

---

## 2. Brand

Trust Teal system + partner tints, so the four rails read without a rainbow:

| Token | Hex | Use |
|---|---|---|
| `primary` (Trust Teal) | `#0D9488` | Main buttons, progress, paid/verified emphasis |
| `deep` / `primaryLight` | `#0F766E` / `#14B8A6` | Gradients, headers |
| `accent` (Avalanche Red) | `#E84142` | Raise collection, simulate payment, badges, streaks |
| `secondary` (SasaPay Blue) | `#1E40AF` | Payment rails, checkout links |
| `success` / `warning` / `danger` | `#16A34A` / `#D97706` / `#DC2626` | Lifecycle semantics |
| neutrals | `#F8FAFC` / `#E2E8F0` / `#0F172A` / `#64748B` | Background, borders, text |

Most important action → Avalanche Red. Navigation & progress → Trust Teal.
Payment rails → SasaPay Blue. Everything else → neutrals.

---

## 3. Project Structure

```
tapverify/
├── django-backend/              # Django REST API
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env.example             # LOOP_*, SASAPAY_*, AT_* keys
│   └── tapverify/
│       ├── config/              # settings, urls, wsgi
│       └── apps/core/
│           ├── models.py        # Workspace, Staff, Member, Collection, PaymentTask
│           │                      (9-state lifecycle), VerificationEvent, PaymentLink…
│           ├── views.py / urls.py / serializers.py / admin.py
│           └── services/
│               ├── loop/client.py    # Verified LOOP gateway contract
│               ├── sasapay.py        # SasaPay OAuth + checkout + HMAC-SHA512 webhook
│               ├── sms.py            # Africa's Talking SMS
│               └── payment_rail.py   # PaymentRail facade (loop / sasapay / payhero)
├── lib/                         # Flutter app (mobile product + web demo)
│   ├── main.dart                # Trust Teal theme
│   ├── constants.dart           # AppColors brand + rail tints
│   ├── screens/                 # legacy treasurer app (dashboard, members, more…)
│   └── workforce/               # ★ the product
│       ├── workforce_models.dart        # WfWorker, WfCollection, WfPaymentTask, WfBadge
│       ├── workforce_service.dart       # seeded Kamau Metalworks data + queries
│       ├── workforce_login_screen.dart  # role gate (foreman / worker)
│       ├── workforce_register_screen.dart  # KYC + CSV + QR onboarding
│       ├── foreman_home_shell.dart      # dashboard / collections / workers / more
│       ├── foreman_dashboard_screen.dart
│       ├── collections_screen.dart
│       ├── collection_detail_screen.dart  # who-paid grid + 9-state lifecycle
│       ├── create_collection_screen.dart  # obligation + rail selector
│       ├── workers_screen.dart
│       ├── worker_home_screen.dart        # due/past, streak, badges
│       ├── worker_payment_flow_screen.dart# pay → proof receipt
│       ├── workforce_more_screen.dart     # evidence console, rails, pricing
│       └── web_demo_screen.dart           # auto-playing web demo
├── tools/                       # Terminal testers + review tooling
│   ├── loop_api_test.py / loop_matrix.py / loop_probe*.py / loop_discover.py
│   ├── recon.py                 # TLS, headers, exposed-path review
│   └── loop_security_review.md  # Public-surface security findings
└── pubspec.yaml
```

## 4. LOOP Gateway Integration (verified on sandbox)

- **Base**: `https://sandbox.loop.co.ke`
- **Auth**: OAuth2 `client_credentials` at `/oauth2/token` (consumer key/secret)
- **Signing**: HMAC-SHA256 of `"merchantTill|timestamp|nonce"` with the till secret
- **Call**: `POST /gateway/{product}/{version}/services/process-request`
- **Envelope**: `{ "serviceCode": "MRCHNT_SENDMONEY", "txnReference", "requestParameters" }`

Confirmed live products (all HTTP 200 `COMPLETED`):

| Product | Gateway path | Result |
|---|---|---|
| LOOP M-Pesa Prompt | `mpesa-prompt/2.0` | `COMPLETED` `TAM2026…` |
| Pay to M-Pesa Till | `pay-to-mpesa-till/1.0` | `COMPLETED` |
| Pay to M-Pesa Paybill | `pay-to-paybill/1.0` | `COMPLETED` |
| Send Money – M-Pesa | `send-money-mpesa/1.0` | `COMPLETED` |

Note: the sandbox **simulates** M-Pesa rails (instant `COMPLETED`, no real STK).
Send Money – Loop is stubbed (`404`), Pesalink returns `403` unless subscribed.

## 5. Backend Setup

```bash
cd django-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # fill LOOP_*, SASAPAY_*, AT_* keys

createdb tapverify
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

## 6. Flutter App Setup

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d <device>     # Android/iOS — the real product
flutter run -d chrome       # web — the demo
```

Entry points: More screen → **TapVerify Workforce** tile, or the login screen's
"New factory? Register with KYC".

## 7. API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/login/` | POST | Staff login (phone + PIN) |
| `/api/v1/members/` | GET | List workspace members |
| `/api/v1/collections/` | GET/POST | Obligations (with PaymentTasks) |
| `/api/v1/collections/<id>/tasks/` | GET | Who-paid grid per collection |
| `/api/v1/tasks/<id>/advance/` | POST | Move a task through the 9-state lifecycle |
| `/api/v1/verify/` | POST | Verify payment + send SMS |
| `/api/v1/stats/` | GET | Dashboard statistics |
| `/api/v1/reminders/send/` | POST | Bulk payment reminders |
| `/api/v1/payment-link/create/` | POST | Create member payment link |
| `/api/v1/rail/info/` | GET | Active payment rail info |
| `/api/v1/webhooks/loop/` | POST | LOOP IPN webhook |
| `/api/v1/webhooks/sasapay/` | POST | SasaPay signed callback |
| `/api/v1/demo/setup/` | POST | Create demo workspace |
| `/r/<token>/` | GET/POST | PIN-protected receipt portal |
| `/p/<token>/` | GET | Member payment link page |

## 8. Tech Stack

- **Backend**: Django 4.2, Django REST Framework, PostgreSQL
- **Payments**: LOOP (NCBA) verified; SasaPay Checkout ready; PayHero legacy
- **SMS**: Africa's Talking (SMS / USSD / Airtime)
- **Mobile**: Flutter 3.x → web + Android + iOS; Hive offline storage
- **Proof**: signed webhooks + optional Avalanche attestation for badges
- **Receipts**: PIN-protected web portal with GPS verification, signed PDFs

## 9. Pricing

| Tier | Price | Includes |
|---|---|---|
| Starter | KES 1,500/mo | Up to 50 workers · SMS · one rail |
| Growth | KES 3,500–5,000/mo | Up to 200 workers · all rails · API |
| Business | Custom | Unlimited · on-prem proof · onboarding |

Optional 2% platform fee on collected value; SMS costs passed through.
