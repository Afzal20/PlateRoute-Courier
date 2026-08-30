# Courier App — UI Design Instructions

| Field | Value |
| --- | --- |
| Document | docs/design/COURIER_APP_UI.md |
| Version | 1.0 |
| Date | 2026-08-27 |
| Owner | Design lead |
| Related | PROJECT_PLAN.md sections 8.5 and 17, ARCHITECTURE.md sections 9 and 13, NFR-16 location privacy |

---

## 1. Who we are designing for

The courier works outdoors at vehicle speed with one thumb, in monsoon rain glare or noon sun, on a mid-range phone mounted on handlebars, sometimes wearing gloves. Every extra second looking at the screen is a safety risk; every unclear earning number is a resignation letter.

| Persona snapshot | Context | Emotional driver | Design answer |
| --- | --- | --- | --- |
| Sumon, full-time rider | Phone mounted, engine idling at pickup gates | Income certainty over everything | Earnings math visible before accepting any task; no hidden multipliers ever |
| Rain-shift rider | Gloves, wet screen, dark road edges | Fear of losing an offer while fumbling | Offer claims protected by large zones, countdown honesty, offline tolerance |
| Part-timer evenings | Checks app between other jobs | Suspicion of exploitation | Transparent acceptance statistics back to them; no streak-loss pressure mechanics |

Core insight: this is the only app of the three where reading is dangerous and trust is earned in taka, not tooltips. Interfaces are glance-sized statements, not menus of possibility.

## 2. Experience principles

1. Glance-safe first. One decision per screen state; primary answer legible from arm's length at a stop light.
2. Hands respect speed. Interaction surfaces shrink automatically under motion heuristics (GPS speed above threshold) to "Parked required" mini-states instead of blocking abruptly.
3. Offline is a state, not an error. Actions queue locally with visible counts and sync truthfully later; nothing silently vanishes.
4. Fairness shown, not told. Fees, distance bonus, and tip split render as an expandable formula the rider can audit against their own trip numbers.
5. Battery honesty beats silence. The tracking service exposes its cost in settings (estimated percent per hour) because riders pay for data and charge cycles themselves.
6. Safety nudges, never blocks livelihood. The app warns toward parking before critical actions but cannot strand someone without income ability mid-trip.

## 3. Color system (dark-first)

Dark is the default theme for sunlight legibility and battery on OLED panels; a light theme ships for front-door paperwork moments.

| Token | Dark value | Role | Notes |
| --- | --- | --- | --- |
| canvas | #0B1220 | Screen base | OLED-friendly true dark surface below cards |
| surface | #16213A | Cards, sheets | 4.6:1 separation against canvas |
| offerAccent | #FACC15 | Task offer countdown ring, money highlights | yellow reads fastest in peripheral vision riding check |
| color.primary | #60A5FA | Interactive links, selected rail item on dark | 7.0:1 on canvas |
| cta.background | #2563EB solid | Big nav/accept buttons | white Bold >=18sp label = large-text AA compliant at 3.0-plus |
| success | #22C55E | Delivered confirmations, earnings credits | |
| warning | #FBBF24 | Queue pending, weak GPS | amber family consistent with merchant grammar |
| danger | #EF4444 | Hard failures: claim lost, login expired | never used for deadline pressure inside offers |
| textPrimary / Secondary | #F1F5FB / #A9B6C9 | | body pairs clear 11:1 / 4.7:1 on canvas |
| border | #2C3A55 | Card outlines mandatory (no shadows; sun kills shadows) | 1.5dp minimum stroke |

Light theme mirrors customer palette tokens exactly so brand holds across apps on one device family; dark remains courier default because windshields and sunlight dominate their context.

## 4. Type and touch

Everything runs one size up from the customer ramp: Body is 17, Body S 15, offer totals 24 Bold tabular, countdown digits 40 Bold for the ring center. Type weight skews Medium/SemiBold throughout because thin strokes vanish against road glare. Inter plus Noto Sans Bengali identical to other apps.

| Floor | Value |
| --- | --- |
| Primary action (Accept task, Navigate, Arrived) | 64dp height full-width bottom anchored |
| Secondary actions (call, chat) | 56dp icon+label rows in context strips |
| CountdownRing | 120dp diameter centered in OfferCard |

Gloves mode setting enlarges all paddings by 1.25x and disables the smallest inline chips behind a single toggle.

## 5. Information architecture

Three bottom destinations only: Today (offer feed plus active task), Earnings ledger, More (vehicle record, settings, documents expiry). Shift toggle lives as a persistent top-right pill visible on every Today state — going online is the day's first act and leaving it reachable at all times prevents stranded-offline anxiety.

## 6. Headline flows

Flow A — offer claim:

```
Offer arrives while Today list open: OfferCard slides in pinned TOP
   (thumb-stable even when scrolled), 25s CountdownRing around payout number,
   distance chip "2.4 km pickup - 3.1 km drop", zone word.
Last 8 seconds: ring pulses crimson once per second + distinct double-buzz
   vibration family B; card never auto-dismisses silently before showing
   final state text "Missed - next one soon" for 4s so loss feels processed,
   not punished with red shame screens.
Tap Accept (atomic claim per FR-DLV-03): button morphs into progress spinner;
   on success OfferCard transforms in place into ActiveTask card without any
   navigation jump — claim transitions must not teleport attention to a map
   already moving underneath hands.
On failure (another rider won): neutral gray card "Claimed first" dismiss
   auto after 3s; no streak shaming copy anywhere.
```

Flow B — active task tri-panel, stage-driven:

```
Stage TO-PICKUP: giant address block (venue name prominent over street),
   distance/ETA chip, action row [Navigate big blue] [Call restaurant] 
   [Chat]; arrival geofence hint flips address block border blue and swaps
   hint line "You are near the gate" using location accuracy thresholds.
Stage PICKED -> OUT: panel mirrors to DROPOFF address; payment kind chip if
   COD shows collected-later amount boxed separately (never inside earnings
   to prevent double-count confusion); same action row minus restaurant call.
Stage AT-DROPOFF: deliverable state unlocks [I arrived] then Delivered flow:
   proof-of-delivery camera screen with minimal chrome, shutter locked until
   focus stable, order id stamped into image metadata automatically (FR-DLV-03).
Every transition fires haptic family P2 short-tick so eyes stay on road.
```

Offline rule wired through both flows: banner strip under app bar persists whenever queue depth > 0 — "3 actions saved, will send" with tap opening manual retry sheet; background flush attempts per connectivity plugin events; nothing in history mutates silently after sync without a state chip flip Local-saved to Synced.

## 7. Remaining screens

| Screen | Primary question | Non-negotiables |
| --- | --- | --- |
| Earnings ledger | "What did I make and why?" | period totals plus expandable per-task rows showing base, distance bonus, tip split exactly as FR-DLV-05 defines; COD boxes separated; payout cycle date always visible |
| Task history | "What happened on that drop?" | status trail icons matching order events; issue tickets deep link |
| Vehicle and documents | "Can I keep working?" | expiry countdowns use warning at 14 days, danger at 3 — revenue-critical facts get calendar-grade urgency honestly |
| Settings | "What do I control?" | ping interval preset explainer mapping battery cost percent-hour estimate (NFR-16); gloves mode; language; block list management for abusive customers |

## 8. Sound and haptic grammar

Shares the merchant tone-family system so one brand trains one set of reflexes across staff and riders; rider mappings:

| Family | Event | Character | Haptic |
| --- | --- | --- | --- |
| A | New task offer | rising two-note chime once | strong double pulse |
| B | Offer final 8 seconds | soft urgent tick each second | short buzz per tick, escalating |
| C | Claim result (win/lose) | win single bright note; lose muted low note | win .medium, lose none |
| D | Stage unlocked (arrived, picked) | short confirm blip | P2 short-tick |
| E | Incoming call | 30s ringtone slot identical family E | continuous |

Vibration patterns outrank audio by design because helmets muffle speakers; all families also flash screen border 300ms for glare-legible redundancy.

## 9. Microcopy rules and starter strings

Shortest possible statements; every word earns its pixels at riding speed.

| ARB key | en | bn |
| --- | --- | --- |
| goOnlineBtn | Go online | অনলাইনে যান |
| offerPayout | You earn {amount} | আয় {amount} |
| claimBtn | Take this task | কাজটি নিন |
| missedOffer | Gone - next is coming | চলে গেছে - পরেরটা আসছে |
| navigateBtn | Start navigation | নেভিগেশন শুরু |
| arrivedStep | I have arrived | আমি পৌঁছেছি |
| deliveredConfirm | Delivered. Well done today. | ডেলিভারি সম্পন্ন। আজকের জন্য ধন্যবাদ। |
| offlineQueued | Saved ({count}). Sends when signal returns | সংরক্ষিত ({count})। নেট এলে পাঠাবে |

## 10. Safety and attention rules

While GPS speed exceeds the walking threshold (~7 km/h), interactive cards collapse to an inert summary strip and any action tap raises a bottom sheet first: "Pull over to continue" — guidance, never a hard block of trip-status completion; emergency call paths remain exempt from motion gating always. No animations render inside moving-state strips beyond a breathing outline so peripheral vision treats them as static. Notification content never includes dropoff addresses in lockscreen previews (privacy at pickup points where phones sit visible).

## 11. Accessibility checklist

Dynamic type to 1.4x verified with gloves mode layered; TalkBack journey covers online-offer-claim-complete loop; color independence: offer urgency encoded by ring position plus haptic cadence plus text label, never hue alone; contrast table in section 3 enforced including yellow-on-dark pair; large-text layouts must not push primary buttons off-screen — bottom-anchored constraint priority.

## 12. Psychology playbook

| Effect | Application | Ethical guardrail |
| --- | --- | --- |
| Variable reward ethics | offers arrive stochastically by demand reality | no artificial scarcity copy, no loss-streak shaming, miss cards neutral gray |
| Cognitive offload | one decision visible per state; details behind expansion | progressive disclosure never hides money terms |
| Feedback immediacy | optimistic local states + Synced chips distinguish local vs confirmed | reconciliation flips chips, never rewrites outcomes silently |
| Goal framing | earnings header shows shift progress as completed drops count | no countdown pressure to stay online against will |
| Trust through auditability | formula tooltip expands exact math per task (FR-DLV-05) | numbers derive from ledger_entries solely |
| Peak-End Rule | delivered confirmation acknowledges effort ("Well done today") before app sleeps | respect quiet hours settings absolutely |

## 13. UX instrumentation

offer_shown / offer_response_ms recorded client-side and reconciled against server column delivery_offer.response_ms (dictionary section 8.8) making UI-latency claims auditable; claim_success_rate by ring-second cohort exposing fairness perception data; nav_start_latency after claim; pod_capture_seconds; offline_queue_flush_lag p95; screen_dark_mode_usage share validating dark-first bet; call_ring_acceptance mirrors merchant family E health.

## 14. Developer handoff checklist

Dark theme ships as default flag per flavor; foreground service notification strings match section 10 privacy wording; gloves-mode padding multiplier integrated into core_ui spacing tokens not hardcoded screens; sound assets bundled per family list; integration_test journey online-offer-claim-trip-delivered passes emulator matrix incl. low-end 2GB device profile; location permission flows implement purpose-string pre-prompts exactly per NFR-16; traceability closed when all MOB-CUR-01..08 map to shipped screens in PROJECT_PLAN section 8.5.