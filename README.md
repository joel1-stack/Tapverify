# TapVerify

**Verifiable revenue history for manufacturing SMEs.**

Turn M-Pesa chaos into lender-ready revenue proof. A jua kali welder in Kariobangi can now walk into a bank with Ksh 2 million in verified transactions instead of a notebook.

---

## What it does

When a customer pays — M-Pesa, Airtel, card, or bank — the payment hits TapVerify. SasaPay sends a cryptographically signed callback. We verify the HMAC-SHA512 signature. Every payment becomes a permanent, tamper-proof record.

Over 6 months, a manufacturer builds verified revenue history. Not screenshots. Not notebooks. Cryptographic proof.

Now when they walk into a lender, they show a dashboard: Ksh 2.3 million verified across 47 transactions. Average order: Ksh 49,000. Consistency: 94%. Disputes: zero. The lender says yes.

## How it works

1. **Business owner records a customer payment** — customer name, amount, order description
2. **System generates a SasaPay checkout link** — unique per customer per order
3. **Link shared via WhatsApp or SMS** — customer taps to pay
4. **Webhook verifies instantly** — SasaPay callback confirms payment, updates dashboard
5. **SMS receipt sent** — customer gets a signed receipt with transaction reference
6. **Revenue history builds** — over months, a credit profile emerges
7. **Credit profile** — verified revenue, consistency score, dispute rate

## The 9-state lifecycle

```
CREATED → NOTIFIED → PENDING → COMPLETED → VERIFIED → STREAK → BADGE → REWARD → ARCHIVED
```

Every state transition is recorded. Every payment has a cryptographic receipt.

## Tech stack

| Layer | Technology |
|-------|-----------|
| **Backend** | Django 4.2, Django REST Framework, PostgreSQL |
| **Payments** | SasaPay Checkout API (OAuth2, HMAC-SHA512 webhooks) |
| **SMS/USSD** | Africa's Talking (Bulk SMS, USSD, Airtime rewards) |
| **Attestation** | Avalanche Fuji (badge minting for payment consistency) |
| **Mobile** | Flutter 3.x (Android + iOS + Web) |
| **Distribution** | WhatsApp links, SMS with checkout URLs |

## Project structure

```
tapverify/
├── django-backend/           # Django REST API
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env                  # Keys (gitignored)
│   └── tapverify/
│       ├── config/           # settings, urls, wsgi
│       └── apps/core/
│           ├── models.py     # Workspace, Customer, Order, PaymentRecord
│           ├── views.py      # API + web dashboard views
│           ├── urls.py
│           ├── services/
│           │   ├── sasapay.py       # SasaPay OAuth + checkout + HMAC
│           │   ├── africastalking.py # AT SMS + USSD + Airtime
│           │   ├── avalanche.py     # Fuji badge attestation
│           │   ├── payment_rail.py  # PaymentRail facade
│           │   └── router.py        # PaymentRouter orchestration
│           ├── webhook_handler.py   # SasaPay callback handler
│           ├── ussd_handler.py      # AT USSD menu
│           └── templates/core/      # Web dashboard (7 templates)
├── lib/                      # Flutter app
│   ├── main.dart             # Theme + entry
│   ├── constants.dart        # Brand colors + images
│   ├── workforce/            # Core screens
│   │   ├── workforce_login_screen.dart
│   │   ├── workforce_register_screen.dart
│   │   ├── workforce_forgot_password_screen.dart
│   │   ├── treasurer_home_shell.dart  # 3-tab nav
│   │   ├── treasurer_dashboard_screen.dart
│   │   ├── collections_screen.dart    # Orders
│   │   ├── members_screen.dart        # Customers
│   │   ├── create_collection_screen.dart  # Record payment
│   │   ├── collection_detail_screen.dart
│   │   └── workforce_service.dart     # Core logic
│   └── pay/                  # Payment links module
└── PITCH-GROUP-COLLECTION-OS.md
```

## Setup

### Backend

```bash
cd django-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # fill in keys

createdb tapverify
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### Flutter

```bash
flutter pub get
flutter run -d <device>
```

## API endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/login/` | POST | Login (phone + password) |
| `/api/v1/customers/` | GET | List customers |
| `/api/v1/orders/` | GET/POST | Customer orders |
| `/api/v1/verify/` | POST | Verify payment + send SMS |
| `/api/v1/stats/` | GET | Revenue dashboard stats |
| `/api/v1/reminders/send/` | POST | Bulk payment reminders |
| `/webhooks/sasapay/` | POST | SasaPay signed callback |
| `/ussd/` | POST | Africa's Talking USSD menu |
| `/p/<token>/` | GET | Customer payment link |

## Pricing

| Plan | Price | Includes |
|------|-------|----------|
| Starter | KES 1,500/month | 1 business, 50 verified payments |
| Growth | KES 3,500/month | 1 business, 500 verified payments |
| Enterprise | KES 8,000/month | 5 businesses, unlimited payments |

## Revenue model

SaaS subscription — not transaction fees. The business owner is the buyer. TapVerify saves them hours of manual matching and gives them something they never had: proof.

## Brand

| Token | Hex | Use |
|-------|-----|-----|
| Trust Teal | `#0D9488` | Main buttons, navigation, verified states |
| Avalanche Red | `#E84142` | CTAs, badges, streaks |
| SasaPay Blue | `#1E40AF` | Payment rails, checkout |
| Success/Warning/Danger | `#16A34A` / `#D97706` / `#DC2626` | Status semantics |
