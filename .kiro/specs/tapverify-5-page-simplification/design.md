# Design Document — TapVerify 5-Page Simplification (Chama/SACCO Pivot)

## Overview

This design describes the complete transformation of TapVerify from a 15-screen manufacturing SME app into a focused 5-page chama/SACCO treasurer tool. The architecture stays the same (Flutter + in-memory WorkforceService + Django backend placeholder), but every screen is either deleted, replaced, or rewritten. The web dashboard is simplified from 11 sidebar items to 5.

---

## Architecture

### File Structure After Change

```
lib/
├── main.dart                          (unchanged — routing)
├── constants.dart                     (unchanged)
├── pay/                               (unchanged)
├── services/                          (unchanged)
├── web/
│   ├── landing_page.dart              (unchanged)
│   ├── web_about.dart                 (unchanged)
│   ├── web_contact.dart               (unchanged)
│   ├── web_payer.dart                 (unchanged)
│   ├── web_login.dart                 (simplified — remove register link)
│   └── web_dashboard.dart             (REWRITTEN — 5 sections only)
└── workforce/
    ├── app_background.dart            (unchanged)
    ├── splash_screen.dart             (unchanged)
    ├── workforce_models.dart          (UPDATED — chama language)
    ├── workforce_service.dart         (UPDATED — chama seed data + new methods)
    ├── workforce_login_screen.dart    (SIMPLIFIED — no register, no forgot PIN)
    ├── treasurer_home_shell.dart      (REWRITTEN — 3-tab shell: Home/Proof/Me)
    ├── home_screen.dart               (NEW — Page 1: The Notebook)
    ├── collect_screen.dart            (NEW — Page 2: Ask for Payment)
    ├── person_screen.dart             (NEW — Page 3: Member Detail)
    ├── proof_screen.dart              (NEW — Page 4: Group Proof)
    └── me_screen.dart                 (NEW — Page 5: Treasurer Profile)
```

### Files to Delete

```
lib/workforce/ussd_simulator_screen.dart
lib/workforce/bulk_sms_screen.dart
lib/workforce/evidence_console_screen.dart
lib/workforce/revenue_report_screen.dart
lib/workforce/credit_profile_screen.dart
lib/workforce/badges_screen.dart
lib/workforce/workforce_register_screen.dart
lib/workforce/workforce_forgot_password_screen.dart
lib/workforce/collections_screen.dart
lib/workforce/members_screen.dart
lib/workforce/collection_settings_screen.dart
lib/workforce/sms_test_screen.dart
lib/workforce/workforce_more_screen.dart
lib/workforce/treasurer_dashboard_screen.dart
lib/workforce/create_collection_screen.dart
lib/workforce/collection_detail_screen.dart
```

---

## Data Model Updates (`workforce_models.dart`)

No structural changes to Dart classes — only label/comment updates:

- `WfCollection`: rename display references from "order" → "collection", "customer" → "member"
- `WfMember`: add `currentStreak` (already present) — this is the individual paid-months streak
- `WfCollection`: add `groupStreak` field (int) representing consecutive months the whole group paid

### New fields on `WfCollection`
```dart
final int groupStreak;  // consecutive months all members paid
```

### New fields on `WfMember`
```dart
// currentStreak already exists — keep as individual streak
// bestStreak already exists — keep
```

---

## Service Layer Updates (`workforce_service.dart`)

### Seed Data — Three Chama Groups

**Primary group: "Kamau Welfare"** (active, groupStreak=12)
- 12 members, 10 paid this month, 2 pending
- totalCollected = Ksh 288,000 (12 months × 12 members × Ksh 2,000)

**Second group: "Stima SACCO"** (active, groupStreak=7)
- 8 members, 6 paid, 2 pending
- totalCollected = Ksh 112,000

**Third group: "Jua Kali Fund"** (active, groupStreak=4)
- 6 members, 6 paid (all paid this month)
- totalCollected = Ksh 48,000

### New Methods

```dart
// Returns the active collection for the primary group
static WfCollection get activeGroupCollection

// Returns consecutive paid months for a member
static int individualStreak(String memberId)

// Returns group streak (consecutive full-payment months)
static int get groupStreak

// Returns 'bronze' | 'silver' | 'gold' | 'none' for the group
static String groupBadgeTier()

// Returns 'bronze' | 'silver' | 'gold' | 'none' for a member
static String memberBadgeTier(String memberId)

// Sends a reminder SMS to a member (stub — logs in demo)
static void sendReminderSms(String memberId, String collectionId)

// Total collected across all collections
static double get totalVerified
```

### Badge Tier Logic
```
Group tiers:
  Gold   = totalVerified >= 1,000,000 AND groupStreak >= 12
  Silver = totalVerified >= 500,000   AND groupStreak >= 6
  Bronze = totalVerified >= 100,000   AND groupStreak >= 3
  None   = below Bronze threshold

Member tiers (by individualStreak):
  Gold   = streak >= 12
  Silver = streak >= 6
  Bronze = streak >= 3
  None   = streak < 3
```

---

## Screen Designs

### Page 1: HomeScreen (`home_screen.dart`)

**Layout:**
```
AppBar: Group name + month/year
Body (scrollable):
  ┌─ Hero card ────────────────────────┐
  │  Ksh 288,000 collected · Sept 2026 │
  │  🔥 12-month streak · 10/12 paid   │
  │  [████████░░] progress bar         │
  └────────────────────────────────────┘
  
  MEMBERS (12) label
  ─────────────────
  🔴 John Kamau    Ksh 2,000  2d late  [>]
  🔴 Mary Wanjiku  Ksh 2,000  1d late  [>]
  🟢 Peter Ochieng  Paid ✓             [>]
  🟢 Grace Otieno   Paid ✓             [>]
  ... (all members)

Bottom bar:
  [➕ ASK FOR PAYMENT]  [📤 SHARE PROOF]
```

**State management:** `StatefulWidget` + `setState`, refresh on pop from CollectScreen.

**Navigation:**
- Tap member row → `Navigator.push(PersonScreen(member, collection))`
- Tap "ASK FOR PAYMENT" → `Navigator.push(CollectScreen())`
- Tap "SHARE PROOF" → `Navigator.push(ProofScreen())`

---

### Page 2: CollectScreen (`collect_screen.dart`)

**Layout:**
```
AppBar: "Ask for Payment"  [← Back]
Body (scrollable):
  What for?
  [Sept Welfare              ]
  
  How much each? (Ksh)
  [2000                      ]
  
  Who? (tap to deselect)
  ☑ John Kamau   ☑ Mary Wanjiku  ☑ Peter Ochieng
  ☑ Grace Otieno ...  (grid or list of chips)
  
  [📤 SEND PAYMENT LINKS]
```

**Validation:** title non-empty + amount > 0 before submit.

**On submit:**
1. Call `WorkforceService.createCollection(...)` with selected members
2. Show success snackbar
3. `Navigator.pop()` back to HomeScreen

---

### Page 3: PersonScreen (`person_screen.dart`)

**Layout — Not Paid:**
```
AppBar: Member name  [← Back]
Body:
  ┌─ Status card ──────────────────────┐
  │  🔴 NOT PAID                       │
  │  Ksh 2,000 due · 2 days late       │
  │  Phone: 0712 345 678               │
  └────────────────────────────────────┘
  
  [📱 SEND REMINDER SMS]
```

**Layout — Paid:**
```
AppBar: Member name  [← Back]
Body:
  ┌─ Status card ──────────────────────┐
  │  🟢 PAID                           │
  │  Sept 5, 2026 · 14:32              │
  │  Ref: SPEJ2026091401               │
  └────────────────────────────────────┘
  
  ┌─ Reputation card ──────────────────┐
  │  🔥 7-month streak                  │
  │  🥈 Silver Payer                    │
  │  Tx: 0x7e8b...c4d2 (if Gold/Silver)│
  └────────────────────────────────────┘
  
  [📤 SHARE RECEIPT]
```

**Badge display logic:**
- Bronze 🥉: streak 3–5 months
- Silver 🥈: streak 6–11 months
- Gold 🥇: streak 12+ months
- No badge label if streak < 3

---

### Page 4: ProofScreen (`proof_screen.dart`)

**Layout:**
```
AppBar: "Group Proof"  (tab)
Body (scrollable):
  ┌─ Group badge card ─────────────────┐
  │  🏆 Group Proof for Lenders        │
  │  Kamau Welfare Group               │
  │  Verified by TapVerify             │
  │                                    │
  │  ✓ Ksh 288,000 total verified      │
  │  ✓ 12 members · 83% consistency    │
  │  ✓ 12 months · Zero disputes       │
  │                                    │
  │  🥇 GOLD GROUP BADGE               │
  │  Attested on Avalanche             │
  │  Tx: 0x3f2a...b91c                 │
  │  [View on Snowtrace →]             │
  └────────────────────────────────────┘
  
  Progress to next tier (if not Gold):
  ┌─ Next milestone ───────────────────┐
  │  Progress to Silver: 74%           │
  │  Need Ksh 212K more + 2 months     │
  └────────────────────────────────────┘
  
  [📤 SHARE TO WHATSAPP]
  "Send this to your SACCO officer"
```

---

### Page 5: MeScreen (`me_screen.dart`)

**Layout:**
```
AppBar: "Me"  (tab)
Body:
  ┌─ Profile card ─────────────────────┐
  │  [avatar initials]                 │
  │  Peter Kaunda                      │
  │  Treasurer, Kamau Welfare          │
  └────────────────────────────────────┘
  
  ┌─ Gamification ─────────────────────┐
  │  🔥 12 collections in a row        │
  │  Trusted Treasurer 🏅              │
  └────────────────────────────────────┘
  
  ── Settings ──
  [✏️ Change group name]  >
  [❓ Help]               >
  
  [🚪 LOG OUT]  (danger red button)
```

---

### Login Screen Updates (`workforce_login_screen.dart`)

Remove:
- "Don't have an account? Sign up" row
- "Forgot PIN?" TextButton

Keep:
- Phone field
- Send OTP / OTP boxes
- PIN field
- Sign in button

Demo hint text: "Demo: 0715641339 · OTP 1234 · PIN 1234"

---

### Web Dashboard Updates (`web_dashboard.dart`)

**Sidebar nav items (5 only):**
| Icon | Label | Body widget |
|---|---|---|
| `group_rounded` | Group | `_groupBody()` — HomeScreen equivalent |
| `add_circle_rounded` | Collect | `_collectBody()` — CollectScreen equivalent |
| `people_rounded` | Members | `_membersBody()` — member list + inline detail |
| `verified_rounded` | Proof | `_proofBody()` — ProofScreen equivalent |
| `settings_rounded` | Settings | `_settingsBody()` — simplified settings |

Remove from sidebar: USSD Simulator, Bulk SMS, Revenue, Evidence Console, Badges (as standalone nav item).

**Settings body (simplified):**
- Group name (editable inline)
- Phone (editable inline)
- SasaPay Merchant ID (editable inline)
- Logout button

---

## pubspec.yaml Changes

Remove unused packages:
- `geolocator: ^10.1.0` — not used in any retained file
- `mobile_scanner: ^3.5.5` — not used in any retained file

All other packages retained as-is.

---

## Gamification — Where It Lives

| Element | Location | Implementation |
|---|---|---|
| 🔥 Group streak | HomeScreen hero card | `WorkforceService.groupStreak` |
| 38/47 progress | HomeScreen hero card | `collection.paidCount / members.length` |
| Red/green dots | HomeScreen member list | `WfPaymentState.completed` check |
| 🔥 Member streak | PersonScreen reputation card | `WorkforceService.individualStreak(id)` |
| 🥉🥈🥇 Member badge | PersonScreen reputation card | `WorkforceService.memberBadgeTier(id)` |
| 🥇 Group badge | ProofScreen badge card | `WorkforceService.groupBadgeTier()` |
| 🔥 Treasurer streak | MeScreen gamification card | `WorkforceService.groupStreak` (same as group) |
| Trusted Treasurer 🏅 | MeScreen | streak >= 3 |

No separate Badges screen. No separate Leaderboard. No separate Points Store.

---

## Navigation Flow

```
SplashScreen
    ↓
WorkforceLoginScreen
    ↓ (phone + OTP 1234 + PIN 1234)
TreasurerHomeShell (3 tabs)
    ├── Tab 0: HomeScreen
    │       ├── → CollectScreen (push, pop back)
    │       ├── → PersonScreen (push, pop back)
    │       └── → ProofScreen (push, or switch to Tab 1)
    ├── Tab 1: ProofScreen
    └── Tab 2: MeScreen
            └── Logout → WorkforceLoginScreen
```

Web: `kIsWeb` → `WebLandingPage` → `WebLoginPage` → `WebDashboard` (5-section sidebar)

---

## Data Models

### `WfCollection` (updated)

```dart
class WfCollection {
  final String id;
  final String title;           // e.g. "Sept Welfare"
  final double amount;          // per-member contribution amount (Ksh)
  final List<WfMember> members;
  final DateTime createdAt;
  final int groupStreak;        // NEW: consecutive months all members paid
  // existing fields retained...
}
```

### `WfMember` (existing, no structural change)

```dart
class WfMember {
  final String id;
  final String name;
  final String phone;
  final WfPaymentState paymentState;  // completed | pending | overdue
  final DateTime? paidAt;
  final String? paymentRef;
  final int currentStreak;   // consecutive paid months (individual)
  final int bestStreak;
  // existing fields retained...
}
```

### Badge Tier Enum (conceptual)

```
BadgeTier: none | bronze | silver | gold

Group badge thresholds:
  gold:   totalVerified >= 1,000,000 AND groupStreak >= 12
  silver: totalVerified >= 500,000   AND groupStreak >= 6
  bronze: totalVerified >= 100,000   AND groupStreak >= 3
  none:   below bronze

Member badge thresholds (by individualStreak):
  gold:   streak >= 12
  silver: streak >= 6
  bronze: streak >= 3
  none:   streak < 3
```

### Seed Data Summary

| Group | Members | Paid | Pending | GroupStreak | TotalCollected |
|---|---|---|---|---|---|
| Kamau Welfare | 12 | 10 | 2 | 12 | Ksh 288,000 |
| Stima SACCO | 8 | 6 | 2 | 7 | Ksh 112,000 |
| Jua Kali Fund | 6 | 6 | 0 | 4 | Ksh 48,000 |

---

## Components and Interfaces

### Screen Components

| Component | File | Type | Inputs |
|---|---|---|---|
| `HomeScreen` | `home_screen.dart` | `StatefulWidget` | none (reads from `WorkforceService`) |
| `CollectScreen` | `collect_screen.dart` | `StatefulWidget` | none |
| `PersonScreen` | `person_screen.dart` | `StatelessWidget` | `WfMember member`, `WfCollection collection` |
| `ProofScreen` | `proof_screen.dart` | `StatelessWidget` | none |
| `MeScreen` | `me_screen.dart` | `StatelessWidget` | none |
| `TreasurerHomeShell` | `treasurer_home_shell.dart` | `StatefulWidget` | none (3-tab scaffold) |
| `WorkforceLoginScreen` | `workforce_login_screen.dart` | `StatefulWidget` | none |

### Service Interface (`WorkforceService`)

```dart
abstract class WorkforceService {
  // Collections
  static WfCollection get activeGroupCollection;
  static Future<void> createCollection(String title, double amount, List<String> memberIds);

  // Streaks
  static int individualStreak(String memberId);
  static int get groupStreak;

  // Badges
  static String groupBadgeTier();     // 'none' | 'bronze' | 'silver' | 'gold'
  static String memberBadgeTier(String memberId);

  // Messaging
  static void sendReminderSms(String memberId, String collectionId);

  // Totals
  static double get totalVerified;
}
```

### Web Dashboard Sections

| Nav Item | Label | Renders |
|---|---|---|
| `_groupBody()` | Group | HomeScreen-equivalent summary |
| `_collectBody()` | Collect | CollectScreen-equivalent form |
| `_membersBody()` | Members | Member list + inline PersonScreen detail |
| `_proofBody()` | Proof | ProofScreen-equivalent badge card |
| `_settingsBody()` | Settings | Group name, phone, merchant ID, logout |

---

## Error Handling

### Login Screen
- Invalid OTP: show inline error "Incorrect OTP. Try again."
- Invalid PIN: show inline error "Incorrect PIN."
- Empty fields: disable the submit button until all required fields are non-empty.

### CollectScreen
- Empty title: show validation error below the title field.
- Amount ≤ 0: show validation error below the amount field.
- No members selected: disable "SEND PAYMENT LINKS" button.
- `createCollection` failure: show a `SnackBar` with "Failed to create collection. Please try again."

### PersonScreen
- `sendReminderSms` failure (stub): log to console; show `SnackBar` "Reminder sent" regardless (demo mode).

### ProofScreen / MeScreen
- No data available: show a centered `CircularProgressIndicator` during load; if still empty, show "No data available."

### General
- Unknown routes: `main.dart` onUnknownRoute returns a fallback screen with "Page not found."
- Deleted screen routes still referenced in `main.dart` must be removed to prevent `RouteNotFoundException` at runtime.

---

## Testing Strategy

### Unit Tests (`WorkforceService`)
- `individualStreak(memberId)` returns correct consecutive paid-month count.
- `groupStreak` returns 12 for "Kamau Welfare" seed data.
- `groupBadgeTier()` returns `'gold'` when totalVerified >= 1,000,000 AND groupStreak >= 12.
- `memberBadgeTier(memberId)` returns correct tier for streak values 0, 3, 6, 12.
- `totalVerified` sums across all collections correctly (288,000 + 112,000 + 48,000 = 448,000).

### Widget Tests
- `HomeScreen` renders hero card with correct totalCollected, streak, and paid/total count.
- `HomeScreen` member list shows red dot for unpaid and green dot for paid members.
- `CollectScreen` disables submit button when title is empty or amount ≤ 0.
- `PersonScreen` shows "SEND REMINDER SMS" button when member is not paid.
- `PersonScreen` shows "SHARE RECEIPT" button and reputation card when member is paid.
- `ProofScreen` renders correct badge tier from seed data.

### Property-Based Tests
- For any member with `individualStreak >= 12`, `memberBadgeTier` must return `'gold'`.
- For any member with `individualStreak` in [6, 11], `memberBadgeTier` must return `'silver'`.
- For any member with `individualStreak` in [3, 5], `memberBadgeTier` must return `'bronze'`.
- For any member with `individualStreak < 3`, `memberBadgeTier` must return `'none'`.
- `groupBadgeTier()` must be monotonically non-decreasing as totalVerified and groupStreak increase.

### Integration / Smoke Tests
- Full flow: launch → login (demo credentials) → HomeScreen loads with seed data → tap member → PersonScreen → back → tap "ASK FOR PAYMENT" → CollectScreen → fill form → submit → back to HomeScreen (refreshed).
- Web flow: landing → login → WebDashboard shows 5 nav items only.

---

## Correctness Properties

### P1 — Badge Tier Monotonicity
`memberBadgeTier(m)` must be monotonically non-decreasing as `individualStreak(m)` increases. A member can never lose a badge tier as their streak grows.

### P2 — Group Streak Consistency
`groupStreak` must equal the length of the longest suffix of consecutive months where `paidCount == members.length` for the active collection.

### P3 — Collection Immutability
Once a `WfCollection` is created, its `id`, `title`, `amount`, and `createdAt` fields must not change. Only payment states of members may be updated.

### P4 — Total Verified Accuracy
`totalVerified` must equal the sum of `(amount × paidCount)` across all collections. No collection is counted twice.

### P5 — Navigation Safety
Every route that was deleted (16 screens) must be removed from the router. Navigating to any deleted route must not throw a `RouteNotFoundException`; it must return the fallback screen.

### P6 — Seed Data Integrity
On app cold start, `WorkforceService` must always initialise with exactly 3 groups, with member counts and `totalCollected` values matching the specified seed data (12/8/6 members, Ksh 288K/112K/48K).
