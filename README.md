# TapVerify

SMS payment receipts for Kenyan chamas and groups. Tap a member's name, collect payment, and that member instantly gets proof of payment with GPS, time, and PIN protection.

## Project Structure

```
tapverify/
├── django-backend/          # Django REST API backend
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env.example
│   └── tapverify/
│       ├── config/          # Django settings
│       └── apps/core/       # Core app (models, views, services)
├── lib/                     # Flutter mobile app
│   ├── main.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── member_list_screen.dart
│   │   ├── confirm_screen.dart
│   │   └── success_screen.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── hive_service.dart
│   └── models/
│       ├── member.dart
│       └── pending_event.dart
└── pubspec.yaml
```

## Backend Setup (Django)

```bash
cd django-backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
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

## Testing End-to-End

1. Open app → Tap "Create Demo Workspace"
2. Login with phone `254712345678`, PIN `1234`
3. Tap "Collect Payment" → Select a member
4. Enter amount → Confirm
5. Check phone for SMS receipt
6. Tap receipt link → Enter PIN → View receipt

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/login/` | POST | Staff login (phone + PIN) |
| `/api/v1/members/` | GET | List workspace members |
| `/api/v1/verify/` | POST | Verify payment + send SMS |
| `/api/v1/stats/` | GET | Dashboard statistics |
| `/api/v1/reminders/send/` | POST | Bulk payment reminders |
| `/api/v1/webhooks/mpesa/` | POST | M-Pesa callback |
| `/api/v1/demo/setup/` | POST | Create demo workspace |
| `/r/<token>/` | GET/POST | PIN-protected receipt portal |

## Tech Stack

- **Backend:** Django 4.2, Django REST Framework, PostgreSQL
- **SMS:** Africa's Talking API
- **M-Pesa:** PayHero / Daraja integration
- **Mobile:** Flutter 3.x with Hive offline storage
- **Receipts:** PIN-protected web portal with GPS verification
