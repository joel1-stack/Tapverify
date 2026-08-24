# TapVerify — Payment Coordination for Groups

**Positioning**: We connect WhatsApp groups to SasaPay for automated collection and reconciliation.

---

## The 30-Second Pitch

"Every month, 50 people in a WhatsApp group agree to pay KES 500. The treasurer sends a reminder. People pay via M-Pesa. They screenshot. They send it. The treasurer checks Excel. Someone disputes. They search WhatsApp. Conflict.

We fix that.

Treasury creates a collection. System generates payment links. Links go in WhatsApp. Members tap and pay. Webhook confirms. Dashboard updates. Done.

No app download. No Excel. No disputes."

---

## What We Built

### Treasurer Dashboard (Web)
- Create collection in 60 seconds
- Paste member phone numbers
- Generate SasaPay payment links
- Copy all links → paste in WhatsApp
- See who paid, who didn't, in real-time
- Send SMS reminders to unpaid members

### Member Experience (No App)
- Receive WhatsApp link
- Tap link → SasaPay checkout
- Pay via M-Pesa, Airtel, or card
- Receive SMS receipt
- Done

### Backend
- SasaPay OAuth + checkout integration
- Webhook verification (HMAC-SHA512)
- Africa's Talking SMS/USSD
- Avalanche attestation (proof of contribution)

---

## How It Works

```
TREASURER
    │
    ▼
Create Collection
    │
    ▼
Paste Phone Numbers
    │
    ▼
Generate Links
    │
    ▼
Share in WhatsApp
    │
    ▼
MEMBER
    │
    ▼
Tap Link
    │
    ▼
SasaPay Checkout
    │
    ▼
Pay (M-Pesa/Airtel/Card)
    │
    ▼
WEBHOOK
    │
    ▼
Verify Payment
    │
    ▼
Update Dashboard
    │
    ▼
Send SMS Receipt
    │
    ▼
TREASURER SEES:
"47 members, 38 paid, 9 pending"
```

---

## Technology

| What | How |
|------|-----|
| Payment | SasaPay (M-Pesa, Airtel, Card) |
| SMS | Africa's Talking |
| USSD | Africa's Talking (*384*123#) |
| Proof | Avalanche Fuji (attestation) |
| Distribution | WhatsApp (link sharing) |
| Dashboard | Django + PostgreSQL |
| Mobile | Flutter (optional) |

---

## Revenue

| Source | Price |
|--------|-------|
| Starter plan | KES 500/month |
| Growth plan | KES 1,500/month |
| Pro plan | KES 5,000/month |
| SMS credits | KES 0.80/SMS |
| USSD sessions | KES 1.00/session |

---

## Traction

- Backend: Django + PostgreSQL, production-ready
- Payment: SasaPay sandbox integrated, real keys configured
- SMS: Africa's Talking integrated
- USSD: Service code configured
- Proof: Avalanche Fuji testnet
- Mobile: Flutter app (optional)
- Web: Treasurer dashboard (live)

---

## Team

Built by a systems engineer who understands that the payment rail isn't the product — the coordination around it is.

---

## One Line

> "We connect WhatsApp groups to SasaPay for automated collection and reconciliation."
