# TapVerify — Trust Infrastructure for Group Finance

**Positioning**: We build the verification layer between group obligations and payment confirmation.

---

## The Deeper Business

TapVerify is not a payment app.

TapVerify is not a wallet.

TapVerify is not a fundraising platform.

TapVerify is **financial infrastructure** that proves who paid, when, and how reliably.

---

## The Three Layers

```
Layer 1: VERIFY
    "Did John pay?"
    TapVerify → confirms via SasaPay webhook
    Receipt → SMS to member
    Dashboard → treasurer sees status

Layer 2: COLLECT
    "How much has the group collected?"
    Reconciliation → automatic
    Reports → real-time
    Analytics → patterns

Layer 3: TRUST
    "How reliable is John?"
    Contribution history → 12/12 months on-time
    Reliability score → 94%
    Avalanche attestation → portable proof
```

---

## The Real Product: Financial Behavior Verification

Once you have:
- Member identity
- Payment history
- On-time behavior
- Contribution patterns
- Group participation

You have something very valuable:

**Behavioral financial data.**

Not just:
"John paid KES 500."

But:
"John has contributed KES 36,000 over 12 months, 11/12 contributions on time, current streak 8 months."

---

## Verification API

```json
GET /api/v1/member/reputation/{credential}

{
  "verified": true,
  "member_id": "hashed",
  "group": "hashed",
  "contribution_streak": 12,
  "on_time_rate": 0.94,
  "total_contributions": 36000,
  "credential_status": "active",
  "issued": "2026",
  "issuer": "TapVerify"
}
```

Now you're not only selling a dashboard.

You're selling **financial behavior verification**.

---

## Use Cases

### 1. Group Collections
- Chama treasurer creates collection
- Members pay via SasaPay
- TapVerify tracks and verifies
- Dashboard shows who paid

### 2. Loan Eligibility
- Bank asks: "Is this person reliable?"
- TapVerify API: "12/12 on-time, 94% reliability"
- Loan decision: data-backed

### 3. Insurance Pricing
- Insurer asks: "What's this person's financial behavior?"
- TapVerify: "Consistent contributor, no defaults"
- Premium: lower

### 4. Employment Verification
- Employer asks: "Is this person financially responsible?"
- TapVerify: "8-month streak, 97% on-time"
- Reference: data-backed

---

## Avalanche Integration

**Not**: "John paid KES 500 → crypto token"

**Instead**:
```
REAL PAYMENT
    ↓
SasaPay confirms
    ↓
TapVerify verifies
    ↓
Contribution recorded
    ↓
Achievement / reputation event
    ↓
Avalanche attestation
```

The blockchain is a **proof layer**, not the payment mechanism.

---

## Attestation Structure

```json
{
  "type": "12-Month Contribution Attestation",
  "member_id": "hashed",
  "group": "hashed",
  "contribution_period": "12 months",
  "on_time_rate": "100%",
  "total_contributions": "KES 36,000",
  "issued": "2026",
  "issuer": "TapVerify",
  "chain": "Avalanche Fuji"
}
```

No sensitive personal data on-chain. Only proof hashes.

---

## The Stack

```
                TRUST INFRASTRUCTURE
                       │
       ┌───────────────┼────────────────┐
       │               │                │
   VERIFY           COLLECT          SETTLE
       │               │                │
   TapVerify       SasaPay          TrustLayer
       │               │                │
       └───────────────┼────────────────┘
                       │
                 REPUTATION
                       │
                  Avalanche
```

---

## Revenue Layers

| Layer | What | Revenue |
|-------|------|---------|
| SaaS | Collection coordination | KES 500-5,000/month |
| Usage | SMS, USSD, API calls | Per-use fees |
| Verification | Financial behavior API | Per-verification fees |
| Data | Anonymized patterns | Enterprise licensing |

---

## Why This Matters

The most valuable thing TapVerify can build is not a payment interface.

It's a **trust layer** for group finance.

Once you have:
- 10,000 groups
- 500,000 members
- Millions of contribution events
- Verified financial behavior

You have infrastructure that institutions can build on.

---

## One Line

> "We prove who paid, when, and how reliably — then make that proof portable."
