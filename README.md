# TapVerify

**Stop asking people if they have paid. Open this and see.**

TapVerify gives group secretaries, treasurers and welfare officers one simple
live list: **who has paid, who has not, how much is collected, and how much is
still out.** Digital payments are detected automatically. Cash payments are
marked with one tap.

Built for chamas, factory welfare groups, school contributions and every other
collection in Kenya.

---

## The one job

Every month, secretaries chase people with *"Umelipa?"* and *"Tuma screenshot"*.
Screenshots get lost in WhatsApp, the notebook and M-Pesa messages never match,
and arguments start. TapVerify replaces all of that with one screen.

## How it works

1. **Secretary logs in** with a phone number. OTP only, no password, no sign up.
2. **Creates a collection**: title, amount per person, pasted phone numbers and
   where money should be sent (Till / Paybill / Personal number / Bank).
3. **Every member gets an SMS** with the amount and a personal payment link.
4. **Members pay normally.** No app, no account, no password.
5. **The list updates itself.** Till and Paybill payments arrive through the
   SasaPay webhook, so the secretary only marks cash.
6. **One tap** sends reminders to everyone still unpaid.
7. **Share or download** the list at any time (WhatsApp text or CSV).

## Payment detection

| How the secretary receives money | Detected automatically | Who marks it Paid |
|---|---|---|
| Till Number (**Recommended**) | Yes, via SasaPay webhook | System |
| Paybill (**Recommended**) | Yes, via SasaPay webhook | System |
| Personal M-Pesa / Airtel | No | Secretary, one tap |
| Bank Account | No | Secretary, one tap |
| Cash | No | Secretary, one tap |

Edge cases handled: a wrong amount is flagged on the member row, every incoming
payment is stored in the `Payment` table, and a payer who is not in any
collection lands there as unmatched for review in the Django admin.

## The two sides

**Secretary app (Flutter, Android and Web)**

Five screens: Login, My Collections, Create Collection, Live List, Member
detail. The web build also serves the public landing page that sells the
product.

**Member experience (no app)**

SMS, then a personal link `/p/<code>/`, then a fast page showing the amount, the
Till or Paybill instructions and a **Pay with M-Pesa** button, then a success
state. The secretary sees the update as soon as the next refresh.

## Tech stack

| Layer | Technology |
|---|---|
| Secretary app | Flutter 3 (Android, Web), deployed on Vercel |
| Backend API | Django 4.2 + Django REST Framework, SQLite in dev |
| SMS, OTP and reminders | Africa's Talking |
| Payments and webhooks | SasaPay |
| Member payment page | Server rendered HTML, works on any phone |

## Project structure

```
tapverify/
├── lib/                                  # Flutter secretary app
│   ├── main.dart                         # Theme, session state, root gate
│   ├── api.dart                          # API client, Bearer token, timeouts
│   ├── models.dart                       # Collection / Member models
│   ├── utils/format.dart                 # Money, phone and date formatting
│   ├── widgets/app_feedback.dart         # Brand mark, motion, error messages
│   ├── screens/
│   │   ├── landing_screen.dart           # Public marketing page
│   │   ├── login_screen.dart             # Phone then OTP
│   │   ├── home_screen.dart              # My Collections
│   │   ├── create_collection_screen.dart
│   │   ├── live_list_screen.dart         # The most important screen
│   │   └── member_detail_sheet.dart      # Mark paid, remind one person
│   └── services/                         # CSV download (web and mobile)
├── django-backend/tapverify/
│   ├── config/                           # Settings, all secrets from .env
│   └── apps/core/
│       ├── models.py                     # Secretary, LoginOTP, Collection, Member, Payment
│       ├── views.py                      # API, member page, webhook
│       ├── authentication.py             # Bearer token auth
│       ├── utils.py                      # Kenyan phone parsing
│       ├── services/sms.py               # Africa's Talking and message templates
│       ├── services/sasapay.py           # SasaPay client, webhook verification
│       └── templates/core/pay_page.html  # Member payment page
├── tools/make_logo.py                    # Regenerates the app brand mark
├── assets/images/                        # Brand marks and app icon
└── vercel.json                           # Web deploy
```

## Setup

### Backend

```bash
cd django-backend
pip install -r requirements.txt
cp .env.example .env        # then fill in your keys
python manage.py migrate
python manage.py runserver
```

The dev database lives at `django-backend/tapverify/db.sqlite3` and is **not
tracked by git**, because it holds real phone numbers and live login tokens. If
one is ever exposed, rotate the tokens with:

```bash
python tools/rotate_dev_token.py
```

### App

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
# Android emulator talking to a backend on your machine:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`API_BASE_URL` defaults to `http://127.0.0.1:8000`, so a fresh clone runs
against the local backend with no extra setup.

### Web

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-backend-host
```

Vercel builds from `vercel.json`. **Update the `API_BASE_URL` in that file to
your real backend host before you rely on the deploy**, otherwise the published
site points at a machine that is not running.

## API

| Endpoint | Auth | Purpose |
|---|---|---|
| `POST /api/auth/otp/` | none | Send login code by SMS |
| `POST /api/auth/verify/` | none | Verify code, receive Bearer token |
| `GET /api/me/` | Bearer | Session check |
| `GET /api/collections/` | Bearer | My collections with stats |
| `POST /api/collections/` | Bearer | Create and SMS everyone |
| `GET /api/collections/<id>/` | Bearer | Live list |
| `POST /api/collections/<id>/remind-unpaid/` | Bearer | Remind everyone unpaid |
| `GET /api/collections/<id>/export.csv` | Bearer | Download the list |
| `POST /api/members/<id>/mark-paid/` | Bearer | Mark Paid (cash or other) |
| `POST /api/members/<id>/remind/` | Bearer | Remind one person |
| `GET /p/<code>/` | none | Member payment page |
| `POST /api/p/<code>/pay/` | none | Start an M-Pesa payment |
| `POST /api/webhooks/sasapay/` | none | Payment notifications |

## Demo notes

With `AFRICASTALKING_SANDBOX=True` the login code comes back in the OTP
response as `dev_code` and is shown on the login screen, so no real SMS is
needed.

With `SASAPAY_MOCK_MODE=True` paying through a member link confirms instantly,
so the whole flow (create, SMS, pay, list turns green) works with no real money.

## Before you go live

Both demo switches default to their safe for demo, unsafe for production value.
Check these before taking real money:

1. `DEBUG=False` in `django-backend/.env`. While `DEBUG=True` the OTP response
   includes `dev_code`, which would let anyone log in as any phone number.
2. `SASAPAY_MOCK_MODE=False`. While mock mode is on the webhook accepts any
   caller, so a stranger could mark members as paid.
3. `AFRICASTALKING_SANDBOX=False` and real credentials, so members receive SMS.
4. `SASAPAY_CALLBACK_URL` must point at
   `https://<your-api-host>/api/webhooks/sasapay/`. A wrong path means live
   payments are never detected.
5. `PAYMENT_LINK_BASE` must be a public HTTPS host that serves this Django app,
   because it is the domain inside every SMS payment link.
6. `ALLOWED_HOSTS` must list your API host.
7. `SECRET_KEY` must be a fresh random value, not the example.

## What is deliberately not in V1

No member app, no dashboards, no roles, no NFC, no blockchain, no AI, no
disbursements and no heavy reports. Only the core job: **knowing who has paid.**

## Brand

| Token | Hex | Use |
|---|---|---|
| Trust Teal | `#0D9488` | Primary actions, brand |
| Success / Danger | `#16A34A` / `#DC2626` | Paid / Not paid |
| Mark | `assets/images/logo_horizontal.png` | Shield plus wordmark |

`tools/make_logo.py` regenerates the mark from
`assets/images/logo_transparent.png`, cropping the transparent padding and
removing the decorative dashes from the tagline.

## Links

- **Web**: https://tapverify.vercel.app
- **GitHub**: https://github.com/joel1-stack/Tapverify
- **Contact**: WhatsApp +254 715 641 339
