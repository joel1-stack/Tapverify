# TapVerify — Group Collection Operating System

## What we built

TapVerify is a **Group Collection Operating System** for Kenyan SACCOs, chamas, churches, schools, and individual collectors. One dashboard to create collections, generate per-member payment links, share via WhatsApp, and verify every shilling with a signed receipt.

## The problem

Every month, a SACCO treasurer or church secretary manually messages 30-200 members asking for contributions. Members pay via M-Pesa but forget to send screenshots. The treasurer manually matches payments to names in a notebook. Nobody knows who has paid until the treasurer updates the list. Late payers get confronted awkwardly. There's no proof of payment, no streaks, no accountability.

**Current tools:** WhatsApp groups, Excel sheets, notebook ledgers, M-Pesa statements.

## How it works

1. **Treasurer creates a collection** — title, amount, due date, selects members
2. **System generates per-member SasaPay checkout links** — each link is unique, tied to one member and one obligation
3. **Links shared via WhatsApp** — treasurer copies bulk messages or system sends SMS
4. **Member taps link** — pays via M-Pesa, card, or SasaPay wallet on a branded checkout page
5. **Webhook verifies instantly** — SasaPay callback confirms payment, updates dashboard in real-time
6. **SMS receipt sent** — member gets a signed receipt with collector name, amount, date, and transaction reference
7. **Streak tracked** — on-time payments build streaks (3/6/12 months), badges minted on Avalanche Fuji

## What makes it different

| Feature | WhatsApp/Excel | M-Pesa Portal | TapVerify |
|---------|---------------|---------------|-----------|
| Per-member tracking | Manual | Statement only | Per-person dashboard |
| Payment verification | Screenshot trust | Bank statement | Cryptographic receipt |
| Streak accountability | None | None | 3/6/12-month streaks + badges |
| USSD for feature phones | No | No | *384*123# menu |
| Web dashboard | No | Limited | Full treasurer view |
| WhatsApp distribution | Manual | No | One-click bulk send |

## Revenue model

**SaaS subscription** — KES 500-5,000/month per group based on member count. Not transaction fees. The treasurer is the buyer; the system saves them hours every month.

## Tech stack

- **Frontend:** Flutter (mobile app) + Django templates (web dashboard)
- **Backend:** Django REST Framework, PostgreSQL
- **Payments:** SasaPay Checkout API (OAuth2, HMAC-SHA512 webhooks)
- **SMS/USSD:** Africa's Talking (Bulk SMS, Airtime rewards, USSD menu)
- **Attestation:** Avalanche Fuji (badge minting for payment streaks)
- **Distribution:** WhatsApp links, SMS with checkout URLs

## 9-state lifecycle

```
CREATED → NOTIFIED → PENDING → COMPLETED → VERIFIED → STREAK → BADGE → REWARD → ARCHIVED
```

Every state transition is recorded. Every payment has a cryptographic receipt. Every streak has an on-chain attestation.

## Target users

- **Primary buyer:** SACCO treasurer, church secretary, school bursar (manages 30-200 members)
- **End user:** Group members (pay via link, no app download required)
- **Individual collectors:** Someone running one fundraiser (funeral, hospital, school project)

## What we demonstrated

- SasaPay Checkout integration (OAuth2 token, checkout creation, webhook verification)
- Per-member payment link generation with unique references
- Web dashboard (login, collection management, member tracking)
- SMS receipt delivery via Africa's Talking
- USSD menu for feature phone users (*384*123#)
- Streak tracking and badge system
- Flutter mobile app for collectors
