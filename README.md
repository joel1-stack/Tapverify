# TapVerify — LOOP Hackathon 2026 Submission

**Team:** TapVerify
**Product:** Proof of payment for Kenya's chamas, mchangos, and small businesses
**Built on:** LOOP (NCBA)

> The trust layer for group payments.

---

## 1. Platform Architecture (V2)

TapVerify is a two-app, multi-organization trust infrastructure with KYC, member
lifecycle, and LOOP payment integration.

### 1.1 The Two-User System

From the login screen, the app splits into two entry points sharing one backend:

| | Board App (staff) | Member App |
|---|---|---|
| **Who** | Chairman, Treasurer, Assistant, Secretary | Anyone added to an org — parent, chama member, SACCO shareholder |
| **Login** | Phone + PIN | Phone + OTP — no password to remember |
| **Sees** | One dashboard per org they manage, with role-limited actions | All their organizations in one list, regardless of type |

A member can belong to unlimited organizations (school + burial group + chama)
under one phone number — the app shows all of them, but each organization only
sees that member within its own boundary.

### 1.2 KYC-Gated Organization Creation

An organization cannot collect a single shilling until verified. This stops the
platform being used to scam strangers.

| Status | Org can… |
|---|---|
| **Draft** | Fill in details, upload a member CSV (members marked pending) — cannot collect |
| **Pending KYC** | Waiting on document review — cannot collect |
| **Verified** | Full access: create contributions, connect payment channels, disburse, export |
| **Suspended / Rejected** | Read-only, or frozen entirely if fraud is flagged |

Required documents scale with org type: a chama needs the chairman's ID + a
bank/M-Pesa statement; a SACCO needs its SASRA certificate, KRA PIN, and a signed
board resolution; a school needs Ministry of Education registration. An admin
reviews and approves/rejects from one queue.

### 1.3 Organization Types Share One Engine

Same database, same APIs — the rules engine changes what each org type sees and does:

| Type | What's different |
|---|---|
| **Chama / Burial** | Simple contributions, merry-go-round or emergency mode, plain SMS receipt |
| **SACCO** | Share tracking, loan management, dividend calculation, credit scoring |
| **School** | Parents linked to students; announcements, trip consent, fee balances |
| **Church** | Tithes, pledges, project funds, optional anonymous giving |

### 1.4 Member Lifecycle

Members are not permanent. The system tracks the full path:
**invited → active → (suspended or left) → reinstated or banned**.

| Event | What Happens |
|---|---|
| **Invited** | Treasurer uploads CSV → member gets SMS/WhatsApp invite → claims identity via OTP, becomes Active |
| **Leaves voluntarily** | Stops all notifications; keeps read-only access to past receipts; cannot pay going forward |
| **Suspended by treasurer** | E.g. for non-payment — stops receiving prompts; can request reinstatement with a message |
| **Reinstatement** | Treasurer reviews and Approves (back to Active) or Denies (moves to Banned, permanent unless staff override) |

### 1.5 Transparency & Statements

Every organization sets its own visibility rules — total balance, who's paid, who
hasn't, whether members can see each other's balances. A member can request a
personal statement (auto-approved or treasurer-approved, org's choice); it
generates as a signed PDF they can print or share to WhatsApp, and expires after
7 days.

### 1.6 Loan Eligibility via LOOP Transaction Inquiry

For SACCOs, a member's own payment history becomes their credit file. When they
apply for a loan, TapVerify pulls 12 months of local payment records and
cross-checks them against LOOP's Transaction Inquiry/History APIs — if the two
match, the treasurer gets a verified, tamper-checked eligibility report (total
contributed, on-time rate, consistency score, recommended loan ceiling) before
approving.

### 1.7 The 8 LOOP APIs, Mapped

| # | API | Used For |
|---|---|---|
| 1 | Mpesa Prompt | Member pays a contribution or loan repayment (STK Push) |
| 2 | Pay to Till | In-person or manual collection, routed to the org's till |
| 3 | Pay to Paybill | Orgs using a Paybill + account number instead of a till |
| 4 | Transaction Inquiry | Check a single payment's status; verify one member's history for a loan |
| 5 | Transaction History | Monthly reconciliation, annual/SASRA reports, loan eligibility reports |
| 6 | Send Money – M-Pesa | Loan disbursement, refunds, emergency payouts to a bereaved family |
| 7 | Loop Prompt | Zero-fee collection for members who already hold a Loop wallet |
| 8 | Send Money – Loop | Internal transfers — SACCO to member, org to vendor |

### 1.8 Out of Scope (Cut From Earlier Draft)

AI-based fraud pattern detection, government ID cross-checking, and the
funeral-vendor payment integration — ideas worth revisiting once the core
platform (KYC, lifecycle, LOOP rails) is live and used by real organizations.

---

## 2. Problem Statement

Kenya's group money runs on trust that keeps breaking down.

Every day chamas, funeral mchangos, hospital-bill harambees, wedding kitties, and
small-business tills move billions of shillings on M-PESA. The "proof" that
anyone paid is a screenshot of an M-PESA SMS pasted into a WhatsApp group.
Screenshots get edited. Reference numbers get typed wrong. Members claim they
paid when they haven't. Treasurers are accused of skimming when they didn't. A
single cycle of a 20-person chama costs the treasurer 30–60 minutes of
reconciling WhatsApp screenshots against SMS threads and a paper book.

The same trust gap hits small businesses. A shopkeeper with 30 customers on
account cannot tell in real time who has actually paid — the till confirmation
lives on one phone, and the customer's screenshot is what everybody argues over.

The result: disputes, delayed payouts, and money that moved on Kenyan rails a day
ago still sitting in reconciliation limbo. This is the everyday, high-frequency
version of a problem that a bank's back office solves with a core banking system
— and that a chama or shopkeeper solves with a screenshot.

## 3. Solution Summary

TapVerify is a proof-of-payment layer that sits on top of LOOP and M-PESA rails.
Every inbound payment becomes a verified, uneditable record the whole group can see.

1. **Register once.** A group — chama, mchango committee, or small business — is
   set up in TapVerify. Every member or customer is tied to a phone number.
   Contribution cycles and targets are configured (e.g. "Funeral mchango, target
   KES 80,000 by Sunday").
2. **Pay through LOOP.** A member pays via LOOP Prompt (request-to-pay to their
   wallet) or directly to the group's LOOP till. TapVerify catches the callback,
   verifies the HMAC signature, matches the transaction to the right cycle, and
   updates the live group feed.
3. **Trusted communication channels.** Every verified payment fires trusted
   communication channels to the officials of the organisation, providing instant
   record and reducing the window within which monetary mishaps tend to happen.
   The record is TapVerify's, not a forgeable screenshot. When someone claims
   they paid, the group opens TapVerify and sees the truth.

The primary use case is common, everyday occurrences that tend to arrive
unannounced — the funeral mchango, the hospital-bill harambee, the wedding kitty
— where trust matters most and forgery is easiest. Chamas are the recurring use
case. Small business cash-flow verification is the natural extension (same
primitives, different UI).

We are not another chama-digitising app. Products already exist for that (M-PESA
Chama, Chamasoft, KCB Mobi Chama). What none of them solve is the easy, automated
proof systems that go beyond manual, error-prone methods that currently erode
trust within financial providers and customers.

## 4. Target Market

**Primary — social payments where trust breaks**

- **Chamas:** the Kenya Association of Investment Groups estimates ~300,000
  registered chamas holding around KES 300 billion in assets, most of which are
  operated within manual, error-prone methods such as WhatsApp screenshots and
  M-Pesa statement sending.
- **Mchangos and harambees:** funerals, hospital bills, weddings, school fees.
  Every Kenyan household participates in several a year. Trust is highest-stakes
  here — grieving families, medical emergencies — and forgery is easiest.
- **The everyday reality:** WhatsApp is already the coordination layer. What's
  missing is the verified and automated record-keeping layer above it. TapVerify
  slots in there.

**Secondary — small business cash-flow verification**

- Shopkeepers, kibandas, service providers with 20+ customers who pay to till,
  more often simply personal phone accounts.
- Today's tool: "check the phone" and argue over pasted screenshots.
- TapVerify turns the till into a live, per-customer ledger without changing how
  the customer pays.

**Signals from the current market**

- Existing tools (M-PESA Chama, Chamasoft, KCB Mobi Chama, Chamasoft PLUS)
  digitise the "who" of a chama — membership, contributions, minutes. None of
  them close the proof gap — the moment where a member claims to have paid and
  the group has to trust or disbelieve a screenshot.
- Manual, low-proof methods remaining the receipt of record is the gap.
- CBK's Kenya National Payments Strategy 2022–2025 explicitly targets richer
  digital audit trails on informal flows. TapVerify is that audit trail at the
  group level.

**Route to bank pilots**

Tier-1 Kenyan banks (NCBA, KCB, Equity, Coop, ABSA, Stanbic) already run chama
account products and merchant till books. TapVerify slots on top:

- The bank keeps the rail — deposits, floats, KYC, custody.
- TapVerify adds the trust layer — verified payment record, live group feed, one
  trusted SMS.
- Distribution happens through the bank's existing merchant and chama-officer
  network, which is faster than direct-to-consumer.

---

## 5. Project Structure

```
tapverify/
├── django-backend/              # Django REST API
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env.example             # LOOP_* + Africa's Talking keys
│   └── tapverify/
│       ├── config/              # settings, urls, wsgi
│       └── apps/core/
│           ├── models.py        # Workspace, Staff, Member, VerificationEvent,
│           │                      MpesaTransaction, PaymentReminder, PaymentLink
│           ├── views.py         # Login, members, verify, stats, reminders, webhooks
│           ├── urls.py          # All API routes + receipt + payment link portals
│           ├── services/
│           │   ├── loop/client.py   # Verified LOOP gateway contract
│           │   ├── sms.py           # Africa's Talking SMS integration
│           │   └── payment_rail.py  # Payment rail abstraction (Loop + PayHero)
│           └── templates/core/      # receipt_pin, receipt, payment_link portals
├── lib/                         # Flutter app (web + Android + iOS)
│   ├── main.dart                # LOOP-orange theme
│   ├── constants.dart           # AppColors palette
│   ├── screens/                 # dashboard, more, board_demo, member_demo, …
│   ├── widgets/loop_value_strip.dart  # 8-API value panel
│   ├── services/                # api_service, hive_service, demo_service
│   └── models/                  # member, pending_event (Hive)
├── tools/                       # Terminal testers + review tooling
│   ├── loop_api_test.py         # OAuth2 + HMAC sandbox tester
│   ├── loop_matrix.py           # Full 8-product matrix vs live gateway
│   ├── loop_probe*.py           # Gateway route discovery
│   ├── loop_discover.py         # JWT scope + WSO2 store probing
│   ├── recon.py                 # TLS, headers, exposed-path review
│   └── loop_security_review.md  # Public-surface security findings
└── pubspec.yaml
```

## 6. LOOP Gateway Integration (verified on sandbox)

- **Base**: `https://sandbox.loop.co.ke`
- **Auth**: OAuth2 `client_credentials` at `/oauth2/token` (consumer key/secret)
- **Signing**: HMAC-SHA256 of `"merchantTill|timestamp|nonce"` with the till secret
- **Call**: `POST /gateway/{product}/{version}/services/process-request`
- **Envelope**: `{ "serviceCode": "MRCHNT_SENDMONEY", "txnReference", "requestParameters" }`

Confirmed live products (all return HTTP 200 `COMPLETED`):

| Product | Gateway path | Result |
|---|---|---|
| LOOP M-Pesa Prompt | `mpesa-prompt/2.0` | `COMPLETED` `TAM2026…` |
| Pay to M-Pesa Till | `pay-to-mpesa-till/1.0` | `COMPLETED` |
| Pay to M-Pesa Paybill | `pay-to-paybill/1.0` | `COMPLETED` |
| Send Money – M-Pesa | `send-money-mpesa/1.0` | `COMPLETED` |

Note: the sandbox **simulates** M-Pesa rails (instant `COMPLETED`, no real STK).
Send Money – Loop is stubbed (`404`), Pesalink returns `403` unless subscribed.

## 7. Backend Setup

```bash
cd django-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # fill LOOP_* + Africa's Talking keys

createdb tapverify
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

## 8. Flutter App Setup

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d <device>     # Android/iOS
flutter run -d chrome       # web
```

## 9. API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
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

## 10. Tech Stack

- **Backend**: Django 4.2, Django REST Framework, PostgreSQL
- **Payments**: LOOP (NCBA) — OAuth2 + HMAC-signed gateway (primary)
- **SMS**: Africa's Talking API
- **Mobile**: Flutter 3.x, Hive offline storage → web + Android + iOS
- **Receipts**: PIN-protected web portal with GPS verification, signed PDFs