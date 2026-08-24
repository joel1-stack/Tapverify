# TapVerify — Group Collection Operating System

**Positioning**: The software layer that coordinates group contributions, not the payment itself.

---

## The Problem

Kenya doesn't have a payment problem. M-Pesa already moves the money.

Kenya has a **coordination problem around payments**.

The current workflow in every chama, SACCO, church group, and school:

```
WhatsApp group
    ↓
"Guys remember to pay"
    ↓
M-Pesa payment
    ↓
"John nimepay"
    ↓
Screenshot
    ↓
Treasurer checks Excel
    ↓
Someone disputes
    ↓
Search WhatsApp for proof
    ↓
Conflict
```

**The payment rail works. The administrative layer is broken.**

---

## The Solution

TapVerify is a **Group Collection Operating System**.

We don't process payments. SasaPay handles that.

We coordinate everything around the payment:

1. **Treasurer creates a collection** (name, amount, due date, members)
2. **System generates individual payment links** (SasaPay checkout URLs)
3. **Treasurer shares links via WhatsApp** (copy all, paste in group)
4. **Members tap link → pay via SasaPay** (M-Pesa, Airtel, card)
5. **Webhook confirms payment** → automatic reconciliation
6. **Dashboard shows**: 47 members, 38 paid, 9 pending, 3 overdue
7. **SMS reminders** sent to unpaid members via Africa's Talking
8. **Contribution history** builds reliability score
9. **Avalanche attestation** creates portable proof of financial behavior

---

## Architecture

```
                    TAPVERIFY
                        │
            ┌───────────┴───────────┐
            │                       │
      COLLECTION ENGINE       MEMBER/OBLIGATION
            │                       │
            └───────────┬───────────┘
                        │
                  SASAPAY
                        │
       ┌────────────────┼────────────────┐
       │                │                │
     M-PESA           Airtel           Card
                        │
                    Payment
                        │
                    Callback
                        │
                  TAPVERIFY
                        │
       ┌────────────────┼─────────────────┐
       │                │                 │
 Reconciliation     Reminders         Analytics
       │                │                 │
       └────────────────┼─────────────────┘
                        │
                 TRUST / HISTORY
                        │
              ┌─────────┴─────────┐
              │                   │
          Avalanche             USSD
          attestation          / SMS
```

**Key insight**: The payment is not your product. The coordination around the payment is your product.

---

## Revenue Model

### Layer 1 — SaaS Subscription

| Plan | Price | Features |
|------|-------|----------|
| Starter | KES 500/mo | Collections, member list, payment tracking, dashboard |
| Growth | KES 1,500/mo | Automated reminders, recurring collections, reports, SMS, reconciliation |
| Pro | KES 5,000/mo | Multiple treasurers, advanced analytics, loan tracking, exports, API |

**Primary buyer**: The treasurer. They pay for software that saves them hours of WhatsApp chaos.

### Layer 2 — Usage Revenue

- SMS credits (reminders, receipts)
- USSD session fees
- API calls for verification

### Layer 3 — Financial Reputation

- Contribution history → reliability score
- Verification API for institutions
- Portable proof via Avalanche attestations

---

## Unit Economics

```
50-person chama
    × KES 500/month contribution
    = KES 25,000/month coordinated

TapVerify subscription: KES 1,500/month
    = 6% of collection value
    = Treasurer saves 5+ hours/month
    = No WhatsApp disputes
    = Complete audit trail
```

---

## Market Size

```
10,000 groups × KES 1,500/month
= KES 15 million/month
= KES 180 million/year

500,000 members
= millions of contribution events
= verified financial behavior
= APIs / institutions
```

---

## Why This Works in Kenya

1. **M-Pesa penetration** — 97% of adults have used mobile money
2. **Group culture** — Chamas, SACCOs, churches, schools all collect recurring contributions
3. **WhatsApp dominance** — Groups already coordinate on WhatsApp
4. **SasaPay** — Modern payment infrastructure with checkout links
5. **Africa's Talking** — SMS/USSD reach for non-smartphone users
6. **No app download required** — Members pay via link, not app

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Coordination | TapVerify | Collection creation, reconciliation, dashboard |
| Payment | SasaPay | Checkout links, M-Pesa/Airtel/Card |
| Communication | Africa's Talking | SMS reminders, USSD status checks |
| Proof | Avalanche Fuji | Portable contribution attestations |
| Distribution | WhatsApp | Link sharing (no app download) |
| Accessibility | USSD | *384*123# for non-smartphone users |

---

## Competitive Advantage

| Feature | TapVerify | Excel/WhatsApp | Other Fintechs |
|---------|-----------|----------------|----------------|
| No app download | ✓ | ✓ | ✗ |
| Automated reconciliation | ✓ | ✗ | Partial |
| SMS reminders | ✓ | ✗ | ✗ |
| Payment links | ✓ | ✗ | ✗ |
| Contribution history | ✓ | ✗ | ✗ |
| Reliability score | ✓ | ✗ | ✗ |
| USSD access | ✓ | ✗ | ✗ |
| Avalanche proof | ✓ | ✗ | ✗ |

---

## 90-Day Roadmap

### Month 1 — MVP
- Web dashboard for treasurers
- SasaPay integration
- WhatsApp link sharing
- SMS reminders
- Basic reconciliation

### Month 2 — Growth
- Recurring collections
- Member management
- Contribution history
- USSD status checks

### Month 3 — Scale
- Avalanche attestations
- Verification API
- Multi-group support
- Subscription billing

---

## The Ask

**For judges**: This is not a payment app. This is the coordination infrastructure that makes existing payment systems work for groups.

**For users**: Try it with your chama. One collection. Real money. Real reconciliation.

**For partners**: SasaPay gets transaction volume. Africa's Talking gets SMS/USSD traffic. Avalanche gets ecosystem adoption. TapVerify gets the coordination layer.

---

## Tagline

> "Kenya doesn't have a payment problem. Kenya has a coordination problem around payments."

> "We help groups coordinate recurring contributions without forcing members to download an app."

> "SasaPay handles the money. TapVerify handles everything else."
