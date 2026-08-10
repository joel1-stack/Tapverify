# TapVerify

**Proof of payment for Kenya's informal economy, powered by Loop.**

TapVerify replaces the chama notebook with an SMS receipt that cannot be lost. A treasurer taps a member's name, and that member instantly gets proof of payment with GPS, time, and PIN protection.

## Project Structure

```
tapverify/
├── django-backend/              # Django REST API
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env.example
│   └── tapverify/
│       ├── config/              # settings, urls, wsgi
│       └── apps/core/
│           ├── models.py        # 8 models: Workspace, Staff, Member, VerificationEvent,
│           │                      MpesaTransaction, PaymentReminder, PaymentLink
│           ├── views.py         # Login, members, verify, stats, reminders, webhooks,
│           │                      payment links
│           ├── urls.py          # All API routes + receipt + payment link portals
│           ├── admin.py         # Django Admin config
│           ├── serializers.py   # DRF serializers
│           ├── services/
│           │   ├── sms.py       # Africa's Talking SMS integration
│           │   └── payment_rail.py  # Payment rail abstraction (Loop + PayHero)
│           └── templates/core/
│               ├── receipt_pin.html    # PIN entry page
│               ├── receipt.html        # Green receipt page
│               ├── payment_link.html   # Member payment page
│               ├── payment_success.html
│               └── payment_expired.html
├── lib/                         # Flutter mobile app
│   ├── main.dart                # App theme + auth wrapper
│   ├── screens/
│   │   ├── login_screen.dart    # Phone + PIN login
│   │   ├── dashboard_screen.dart # Stats + recent activity
│   │   ├── member_list_screen.dart # Searchable member list
│   │   ├── confirm_screen.dart  # Amount + payment type
│   │   └── success_screen.dart  # Approval + receipt PIN
│   ├── services/
│   │   ├── api_service.dart     # HTTP client with offline fallback
│   │   └── hive_service.dart    # Local cache + pending queue
│   └── models/
│       ├── member.dart          # Hive model
│       └── pending_event.dart   # Offline queue model
└── pubspec.yaml
```

## Backend Setup

```bash
cd django-backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your credentials

# Database (PostgreSQL)
createdb tapverify
python manage.py migrate
python manage.py createsuperuser

# Run server
python manage.py runserver 0.0.0.0:8000
```

## Flutter App Setup

```bash
# Generate Hive adapters
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device
flutter run
```

## Payment Rails

TapVerify supports multiple payment rails via a pluggable architecture:

### Loop (Primary)
- **Request to Pay**: Sends M-Pesa prompt to member's phone
- **IPN Webhook**: Auto-confirms payment and sends SMS receipt
- **Payment Links**: Members pay on their own phone

### PayHero (Legacy)
- STK Push integration
- M-Pesa callback handling

Switch rails by setting `ACTIVE_PAYMENT_RAIL=loop` or `ACTIVE_PAYMENT_RAIL=payhero` in `.env`.

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/login/` | POST | Staff login (phone + PIN) |
| `/api/v1/members/` | GET | List workspace members |
| `/api/v1/verify/` | POST | Verify payment + send SMS |
| `/api/v1/stats/` | GET | Dashboard statistics |
| `/api/v1/reminders/send/` | POST | Bulk payment reminders |
| `/api/v1/payment-link/create/` | POST | Create member payment link |
| `/api/v1/rail/info/` | GET | Active payment rail info |
| `/api/v1/webhooks/loop/` | POST | Loop IPN webhook |
| `/api/v1/webhooks/mpesa/` | POST | M-Pesa callback (PayHero) |
| `/api/v1/demo/setup/` | POST | Create demo workspace |
| `/r/<token>/` | GET/POST | PIN-protected receipt portal |
| `/p/<token>/` | GET | Member payment link page |

## The Flow

1. **Treasurer** opens app → Login → Dashboard
2. Tap **COLLECT PAYMENT** → Select member → Enter amount → Confirm
3. **Django** creates VerificationEvent → Sends SMS via Africa's Talking
4. **Member** receives SMS with receipt link + PIN
5. Opens link → Enters PIN → Sees green receipt with GPS, time, amount
6. **Offline**: Payments save locally → Sync when connected → SMS fires

## Tech Stack

- **Backend**: Django 4.2, Django REST Framework, PostgreSQL
- **SMS**: Africa's Talking API
- **Payments**: Loop API (primary), PayHero (legacy)
- **Mobile**: Flutter 3.x, Hive offline storage
- **Receipts**: PIN-protected web portal with GPS verification

## Hackathon Demo

"Chamas meet in church basements with no data. TapVerify works offline. The treasurer collects from 200 members, everything saves locally. When they walk outside and get signal, one tap syncs all 200 payments and fires 200 SMS receipts simultaneously."
