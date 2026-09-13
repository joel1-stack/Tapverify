# TapVerify

**We replaced the treasurer's notebook with 5 screens, and replaced the SACCO's doubt with one Avalanche transaction.**

---

## What it does

A chama treasurer in Kariobangi opens TapVerify instead of opening a notebook. She sees who paid (green), who didn't (red), and reminds them with one tap. Over 12 months, her group builds a verified payment history. When she walks into the SACCO with the Gold Group Badge, the loan is approved in 3 days instead of 3 months.

## The 5-page app

| Page | What it does |
|------|-------------|
| **Home** | The notebook. Ksh 288K collected. Red/green dots. One-tap REMIND. |
| **Collect** | Ask for Payment. Type name + amount. Send SMS links to everyone. |
| **Person** | One member. Streak, badge, payment proof, share receipt. |
| **Proof** | Group attestation for SACCOs. Avalanche tx hash. Share to WhatsApp. |
| **Me** | Profile, streak, settings, logout. |

## How streaks become real money

| Streak | Badge | Real Value |
|--------|-------|------------|
| 3 months | Bronze | SACCO pre-approval |
| 6 months | Silver | 5% loan interest discount |
| 12 months | Gold | Instant Ksh 50K loan, no collateral |

The streak is the collateral. The badge is the proof.

## Business model

| Who | Pays | Why |
|-----|------|-----|
| **Treasurer** | Ksh 1,500/mo | Stop chasing people. Get SACCO proof. |
| **Member** | Free | SMS receipt. Payer score. Loan access. |
| **SACCO/Lender** | Ksh 50,000/mo | Verified borrower data. Reduced defaults. |

## Tech stack

| Layer | Technology |
|-------|-----------|
| **Mobile** | Flutter 3.x (Android + Web) |
| **Payments** | SasaPay Sandbox (OAuth2, HMAC-SHA512) |
| **SMS** | Africa's Talking (Bulk SMS, USSD) |
| **Attestation** | Avalanche Fuji (Gold/Silver/Bronze badge minting) |
| **Backend** | Django 4.2, PostgreSQL |

## Project structure

```
tapverify/
├── lib/
│   ├── main.dart                  # Theme + routes
│   ├── constants.dart             # Brand colors
│   ├── workforce/
│   │   ├── splash_screen.dart     # Loading screen
│   │   ├── workforce_login_screen.dart  # Phone + OTP + PIN
│   │   ├── treasurer_home_shell.dart    # 3-tab nav (Home/Proof/Me)
│   │   ├── home_screen.dart       # Page 1: The notebook
│   │   ├── collect_screen.dart    # Page 2: Ask for payment
│   │   ├── person_screen.dart     # Page 3: Member detail
│   │   ├── proof_screen.dart      # Page 4: Group attestation
│   │   ├── workforce_models.dart  # Data models
│   │   └── workforce_service.dart # Business logic
│   └── web/
│       ├── landing_page.dart      # Marketing page
│       ├── web_login.dart         # Web login
│       ├── web_dashboard.dart     # Web dashboard (5 sections)
│       ├── web_about.dart         # About page
│       └── web_contact.dart       # Contact page
├── android/                       # Android build
├── web/                           # Web build
└── pubspec.yaml                   # Dependencies
```

## Setup

```bash
flutter pub get
flutter run -d <device>
```

## Demo credentials

- Phone: `0715641339`
- OTP: `1234`
- PIN: `1234`

## Brand

| Token | Hex | Use |
|-------|-----|-----|
| Trust Teal | `#0D9488` | Buttons, nav, verified states |
| Avalanche Red | `#E84142` | CTAs, badges, streaks |
| Gold | `#C9A227` | Gold Group Badge |
| Success/Danger | `#16A34A` / `#DC2626` | Paid/Not Paid |

## Links

- **Web**: https://tapverify.vercel.app
- **GitHub**: https://github.com/joel1-stack/Tapverify
- **Contact**: WhatsApp +254 715 641 339

## Pitch

> "I cut the app from 15 screens to 5. Because the treasurer in Kariobangi does not want 'Bulk SMS' or 'Evidence Console.' He wants to know: who paid, who didn't, and how do I prove it to the SACCO?
> TapVerify is 5 taps: Open → See red dots → Tap name → Send reminder → Done."
