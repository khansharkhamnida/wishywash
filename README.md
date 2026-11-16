# 🫧 WishyWash

A bubblegum-modern iOS app for finding and booking washers and dryers at self-service laundromats around Singapore. Built with UIKit.

## What it is

WishyWash lets people **find, reserve and pay for a washer or dryer** at a self-service laundromat, so they do not
turn up to find every machine busy. You see which machines are free, reserve one now or for later, get told when to
leave so you arrive on time, check in at the machine, pay, and watch the cycle run. Three mini games keep you busy
while you wait.

> **Status:** a complete iOS app on **sample data**, with a finished backend that is **not connected yet**.
> Reservations, check-in, the payment flow, arrive-on-time reminders, bookings, profile and the games all work, and the
> booking rules have unit tests. By default, laundromats, machines, bookings and payments are simulated on the device.
> Email sign-in and register screens are built too, but they are off until you turn on live mode
> ([`docs/dev/AUTH_IMPLEMENTATION.md`](docs/dev/AUTH_IMPLEMENTATION.md)). The Supabase database and booking rules are
> written and tested, but no Supabase project is running yet. The split between frontend and backend is in
> [`docs/dev/ARCHITECTURE.md`](docs/dev/ARCHITECTURE.md).

## Screenshots

| Home | Bookings | My Laundry |
|:---:|:---:|:---:|
| <img src="docs/screenshots/home.png" width="240"> | <img src="docs/screenshots/bookings.png" width="240"> | <img src="docs/screenshots/my-laundry.png" width="240"> |

| Profile | Choose Laundromat | Arrive on time |
|:---:|:---:|:---:|
| <img src="docs/screenshots/profile.png" width="240"> | <img src="docs/screenshots/choose-laundromat.png" width="240"> | <img src="docs/screenshots/arrive-on-time.png" width="240"> |

### Reserving, checking in and paying

| 1. Reserve now | 2. Or reserve for later | 3. Held for you |
|:---:|:---:|:---:|
| <img src="docs/screenshots/reserve-now.png" width="240"> | <img src="docs/screenshots/reserve-later.png" width="240"> | <img src="docs/screenshots/my-laundry-reserved.png" width="240"> |

| 4. Check in at the machine | 5. Pay | 6. Cycle running |
|:---:|:---:|:---:|
| <img src="docs/screenshots/reservation-options.png" width="240"> | <img src="docs/screenshots/payment-sheet.png" width="240"> | <img src="docs/screenshots/my-laundry-running.png" width="240"> |

### Mini games

| Games hub | Bubble Pop | Sock Match | Laundry Sort |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/games-hub.png" width="200"> | <img src="docs/screenshots/game-bubble-pop.png" width="200"> | <img src="docs/screenshots/game-sock-match.png" width="200"> | <img src="docs/screenshots/game-laundry-sort.png" width="200"> |

### Dark mode

| Home | My Laundry | Laundry Sort |
|:---:|:---:|:---:|
| <img src="docs/screenshots/home-dark.png" width="220"> | <img src="docs/screenshots/my-laundry-dark.png" width="220"> | <img src="docs/screenshots/game-laundry-sort-dark.png" width="220"> |

## Features

### Home
- Welcome header with a shortcut to your profile
- Selected laundromat card with a shop awning, open/closed status and a **Change location** link
- Grid of machines drawn as little cartoon washing machines, with a control panel, knob and a porthole with bobbing bubbles
- Each machine shows availability, type and capacity, price per cycle, and cycle length or time until free
- Tap a machine to **reserve** it. Choose **Now** or **Later**:
  - **Now:** a free machine starts straight away. A busy machine that frees up within 15 minutes can be reserved for when it frees up.
  - **Later:** pick a day (today and two more) and a free time slot, every 30 minutes between 7 AM and 11 PM. Times already taken, or too close to another booking, are not offered.
  - After the start time you have **10 minutes to check in**, or the booking expires and the machine is released. Nothing is charged until you check in.
  - Up to 5 upcoming bookings at once, and one reservation waiting for check-in at a time.

### Bookings
- The full schedule and history: every booking with its price and status
- Tap a booking you have not checked in to yet to **cancel it for free**
- **Upcoming / Past** toggle
- Booking cards with machine, laundromat, date and time, price, and a status badge (In progress, Reserved, Confirmed, Pending, Completed, Cancelled, Expired)

### Payments
You pay when you check in, not when you reserve. The payment sheet offers cards (Visa, Mastercard), PayNow and Apple Pay, and the cycle only starts once the payment succeeds.

- The app uses a built-in test payment sheet, so the whole flow works with no payment provider. No real money moves.
- If the machine is lost while you are paying, the payment is refunded and you are told.

### Arrive on time
Open it by tapping a booking in **Bookings**, or a reservation or the next booking in **My Laundry**, then **Check if I can arrive on time**.

- Gets your location once (Core Location), asks Apple Maps (MapKit) for the travel time by car, on foot or by public transport, and compares your arrival with the booking's start time
- Works out when to leave, with a 10 minute safety buffer. For a 5:00 PM start and a 25 minute trip, that is 4:25 PM
- Says whether you are fine, should leave now, would be late but still inside the 10 minute check-in window, or would miss the booking
- **Remind me to leave** schedules a local notification (UserNotifications) for the leave time. Recalculating replaces it, and cancelling or checking in removes it
- The estimate is labelled as an estimate, and **Recalculate** works it out again at any time
- A "leave in X min" countdown shows in the sheet, and the next booking on My Laundry shows "leave by" and then "Time to leave" in the app, so it works even without notifications

| Location | Notifications | What happens |
|---|---|---|
| Denied | Denied | Enter a starting place or travel time by hand. A countdown and "Time to leave" show in the app. Nothing is scheduled. |
| Denied | Allowed | Same manual input, and a notification is scheduled. |
| Allowed | Denied | Travel time comes from Apple Maps. The countdown and "Time to leave" show in the app, with a shortcut to Settings. |
| Allowed | Allowed | Travel time comes from Apple Maps and a notification is scheduled. Location is requested once, not tracked. |

Departure reminders can also be switched off in Profile > Notifications.

### My Laundry
- The live view: what is running right now and what is next, with no prices or history
- Summary card showing how many cycles are running
- Tap the next booking to cancel it or check your arrival time
- **Reserved** machine with a countdown. Tap it to **check in and start** (stands in for scanning the QR code on the machine). Checking in is when you **pay**. Or cancel it for free. If the previous user is still at the machine, check-in waits. An unused reservation expires and the machine is released.
- **Running now** cycles with a live-style progress bar and time left
- **Plan your way back** on a running cycle: Apple Maps travel time from where you are, the time to leave so you are back as the cycle ends, and an optional leave reminder
- **Up next** section for the next booked cycle
- **All bookings** button that jumps to the Bookings tab
- **Play while you wait** card that opens the mini games

### Mini games
Reached from the **Play while you wait** card on My Laundry. The hub lists three games with your best score for each, saved on the device.

- **Bubble Pop:** pop as many floating bubbles as you can in 30 seconds. Small bubbles rise faster and score more.
- **Sock Match:** a memory game that gets harder with every level. Each level shows all the cards for a moment, then you match the pairs against a countdown.
  - The grid grows from 3 pairs up to 12 (3, 4, 6, 8, 10, 12).
  - The preview gets shorter and wrong pairs flip back faster.
  - From level 3, a wrong pair costs 2 seconds.
  - After level 6 the grid stays at 12 pairs, but the clock keeps tightening.
  - Your best is the highest level cleared.
  - **Daily challenge:** the calendar button in the nav bar switches to a deck that is the same for everyone on the same day. It never adapts, and its best is kept per day.
- **Laundry Sort:** tap the Lights, Darks or Colors basket for the lowest falling item before it hits the bottom. It speeds up as you score, and you have three lives.

#### Built with GameplayKit
Shared pieces live in [`Modules/Games/Gameplay/`](ios/wishywash/Modules/Games/Gameplay).

- **State machines** (`GKStateMachine`): ready, playing and over for the arcade games, and a round flow for Sock Match (peeking, picking, resolving, won, lost). Delayed work such as the flip-back is dropped when the state moves on.
- **Entities and components** (`GKEntity`, `GKComponentSystem`): bubbles and garments are entities with view, motion, score and tone components.
- **Agents** (`GKAgent2D`, `GKGoal`): bubbles wander and separate from each other so they do not pile up.
- **Distributions** (`GKShuffledDistribution`, `GKGaussianDistribution`): bubble colours, garment types and spawn lanes cycle fairly, and bubble sizes cluster around the middle.
- **Rule system** (`GKRuleSystem`): fuzzy rules over accuracy, streaks and recent misses set the pace (Chill, Steady or Frantic). It changes spawn rate and speed in Bubble Pop and Laundry Sort, and the preview and flip-back timing in Sock Match.
- **Seeded random source** (`GKMersenneTwisterRandomSource`): deals the same Sock Match deck for the daily challenge.

### Profile
- Gradient profile card with avatar, email and member badge
- Stats for bookings, completed and total spent
- Menu rows that each open their own page:
  - **Payment Methods:** saved cards, e-wallets and Apple Pay. Tap one to set it as default or remove it, and use + to add one.
  - **Saved Laundromats:** heart a laundromat to save it. Saved ones are listed first, and the choice is kept on the device.
  - **Notifications:** switches for cycle finished, booking reminders, machine available and offers, kept on the device.
  - **Help & Support:** common questions, plus email links to contact support.

### Choose Laundromat
- Real laundromats near you from Apple Maps, using your location (the app asks for permission)
- Search a place or postal code to see laundromats there instead; clearing the search goes back to near you
- Partner laundromats (with machines) are listed alongside, when they are within 25 km
- A **Sort by** row of chips: Distance, Rating, Name, Price and Open now
- Store cards with open/closed status, distance, rating and the address. Laundromats from Apple Maps have no machine, rating or hours data yet, and say so
- Free washer and dryer counts for every laundromat
- A heart on each card to save the laundromat; saved ones appear under Profile > Saved Laundromats
- Currently selected store is highlighted

## Design: "Bubblegum modern, cartoon laundromat"

- **Palette:** pastel pink, blue, lilac, mint and peach on a soft pink background
- **Type:** rounded system font
- **Cartoon details:** thick plum outlines, hard pink "sticker" shadows, striped scalloped shop awnings and washing machine portholes
- **Dark mode:** supported throughout
- The design system lives in [`Shared/`](ios/wishywash/Shared): `Theme.swift` (colors, fonts, bar styling), `CardView.swift` (cards, gradient hero, icon bubble, progress bar) and `LaundryDecor.swift` (awning and porthole). The game-only views (score pills, game-over card) live in `Modules/Games/Support/`

## Architecture

The repo has two sides. The **frontend** is the app people hold. The **backend** decides and remembers: it enforces the
booking rules, keeps the data and handles the money. **The app does not use the backend yet.** It still runs on sample
data and plays the part of the backend itself. The backend (database, booking rules, security and a scheduled job, with SQL tests) is written
and has a step-by-step guide in [`backend/README.md`](backend/README.md). Only sign-in can use it today, and only when live mode is on. See [`docs/dev/ARCHITECTURE.md`](docs/dev/ARCHITECTURE.md)
for the diagrams, who is responsible for what, and how the frontend moves to the real backend.

```
.
├── ios/               FRONTEND: the iOS app (UIKit, VIPER)
│   ├── wishywash.xcodeproj
│   ├── wishywash/      App source, described below
│   └── wishywashTests/ Unit tests for the booking rules
├── backend/           BACKEND: Supabase database, rules and tests (only sign-in can use it, and only in live mode)
└── docs/              Developer docs (docs/dev) and screenshots
```

## iOS app structure

Everything below is inside `ios/wishywash/`.

```
wishywash/
├── App/             AppDelegate, SceneDelegate, MainTabBarController
├── Entities/        Plain models: Machine, Laundromat, Booking, Payment, User, ArrivalPlan
├── Modules/         One folder per screen flow. Each has a presenter, interactor, router and Views/
│   ├── Home/
│   ├── Booking/
│   ├── Reserve/
│   ├── MyLaundry/
│   ├── ArrivalCheck/
│   ├── ReturnCheck/   Plan your way back while a cycle runs
│   ├── LaundromatList/
│   ├── Auth/          Login and register (live mode only)
│   ├── Profile/       with sub-pages for payments, saved laundromats, notifications and help
│   └── Games/         Games hub, Bubble Pop, Sock Match, Laundry Sort
│       ├── Gameplay/  GameplayKit pieces (state machines, entities, difficulty rules, random)
│       └── Support/   Game loop, saved best scores and the shared game views
├── Services/        What the screens call. Interactors get these through their init, so tests can swap them
│   ├── Auth/          AuthService, the sample version (default) and the Supabase version (opt-in), Keychain storage
│   ├── Bookings/      BookingService (protocol), LocalBookingService (the rules, on the device), BookingRules
│   ├── Payments/      PaymentService, the test payment sheet, payment and saved-method stores
│   ├── Arrival/       Travel time, leave-by maths, location and arrival plans
│   ├── Laundromats/   Selected and saved laundromats, Apple Maps search, partner list
│   ├── Notifications/ Local notifications and the user's preferences
│   └── Storage/       LocalStore, the only code that touches UserDefaults
├── SampleData/      Seed machines and bookings for the first launch
└── Shared/          Theme, reusable cartoon views, Money
```

Screens talk to a `BookingService` protocol. `LocalBookingService` answers on the device today, and a server version can replace it without touching any screen.

## Getting started

1. Open `ios/wishywash.xcodeproj` in Xcode.
2. Pick an iPhone simulator (the deployment target is iOS 26).
3. Press **Run**.

The app opens in **sample mode** by default, with no login. Live sign-in is opt-in and needs a Supabase project (see
[`docs/dev/AUTH_IMPLEMENTATION.md`](docs/dev/AUTH_IMPLEMENTATION.md)).

To run the tests from the terminal:

```bash
# iOS app: booking rules and sign-in
cd ios
xcodebuild test -project wishywash.xcodeproj -scheme wishywash \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO

# backend: SQL tests on a throwaway Postgres
cd backend && npm install && npm test
```

## Progress and plans

*Updated 16 Nov 2026.*

### Where things stand

| Part | State |
|---|---|
| iOS app (screens, booking rules, test payment, arrive-on-time, games) | Done, runs on sample data |
| Email sign-in and register | Built, opt-in, off by default |
| Backend (Supabase: tables, security, booking rules, scheduled job, SQL tests) | Written and tested, **not deployed**: no Supabase project exists yet |
| App talking to the backend for bookings | Not started. Only sign-in can use the backend |
| Real payments | Not started. The app uses a test payment sheet |
| Real machines | Early experiment only, kept outside the app and backend. A Beko washer-dryer was read and started from code over Bluetooth (unofficial method, needs manual set-up on the machine each cycle). Nothing is connected to the app yet |

**Current focus:** create the Supabase project and apply the database, so the app has something real to talk to.

### Done

- [x] Home, Bookings, My Laundry, Profile and Choose Laundromat, each as its own VIPER module
- [x] Reserve now, finishing-soon and later bookings, with check-in, free cancel, expiry and overlap checks
- [x] Payment at check-in with a test sheet, and a refund if the machine is lost while paying
- [x] Arrive-on-time check with a leave reminder, and a plan-your-way-back check for a running cycle
- [x] Three mini games
- [x] Services layer behind protocols, so a server can replace the on-device logic without touching any screen
- [x] Unit tests for the booking rules
- [x] Supabase backend: tables, row-level security, booking rules as database functions, a scheduled job and SQL tests
- [x] Email sign-in and register with Supabase Auth (opt-in, off by default)

### Next, in order

1. [ ] Create the Supabase project and apply the database
2. [ ] Make the app read and write bookings through the backend (live mode), keeping sample mode working exactly as it does now
3. [ ] A machine gateway: one small program per shop that reads machine status and writes it to the backend
4. [ ] Live machine status in the app
5. [ ] Real payments, with a webhook that checks you in
6. [ ] Laundromat details page
7. [ ] Trigger the games from a running cycle, for example when a wash is about to finish

### Later

- [ ] Check in by scanning the QR code on the machine
- [ ] Push notifications
- [ ] Staff and owner roles, cash recording and a dashboard
- [ ] Survey real shops to see which machines they use, then choose how to connect each brand
- [ ] Other currencies and opening hours per country
