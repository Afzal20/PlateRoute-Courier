# Courier App — Implementation Plan

| Field | Value |
| --- | --- |
| Source design | `backend/docs/design/COURIER_APP_UI.md` v1.0 |
| Requirements | PROJECT_PLAN §8.5 (MOB-CUR-01..08) + §8.2 common (MOB-C-*) |
| Modules | M4 (fulfillment) is the core; NFR-16 location privacy is a hard gate |
| Default theme | **Dark is the default** (sunlight/OLED); light mirrors customer palette |

## 1. Requirement analysis

| ID | Requirement | Screens involved | Backend endpoints consumed | Risk notes |
| --- | --- | --- | --- | --- |
| MOB-CUR-01 | Shift console: online/offline toggle with vehicle check snapshot | S2, S8 | CourierProfile, FR-DLV-02/03 | Persistent top-right pill on every Today state — never strand offline anxiety |
| MOB-CUR-02 | Task offer card with expiry countdown + atomic claim (FR-DLV-03) | S3 | `delivery/offers/`, claim endpoint | Atomic claim: spinner morph, in-place transform to ActiveTask; loss = neutral gray "Claimed first", never red shame |
| MOB-CUR-03 | Active task tri-panel driven by stage (TO-PICKUP → PICKED → OUT → AT-DROPOFF) | S4 | `delivery/tasks/{uuid}/trip/` | COD amount boxed separately — never inside earnings (double-count confusion guard) |
| MOB-CUR-04 | Proof-of-delivery capture with order id stamped in image metadata | S5 | S3 signed uploads, FR-DLV-03 | Shutter locked until focus stable; minimal chrome |
| MOB-CUR-05 | Earnings ledger with expandable per-task math (FR-DLV-05) | S6 | ledger_entries | Numbers derive solely from ledger_entries; COD separated; payout cycle date always visible |
| MOB-CUR-06 | Background location ingestion with battery-honesty settings | S2, S8 | `delivery/pings` (dispatch_sweep retention) | NFR-16: purpose-string pre-prompts, opt-in, persistent indicator, ping-interval cost explainer (%/hour) |
| MOB-CUR-07 | Offline action queue flushed on connectivity return | global | batch endpoints | Banner "3 actions saved, will send" + manual retry sheet; state chips Local-saved→Synced |
| MOB-CUR-08 | Task history with status trail + issue ticket deep links | S7 | task history endpoints | Status icons mirror order events |
| MOB-C-01..14 | Common requirements; **Courier-only** offline queue per MOB-C-06 | cross-cutting | all | Motion gating: interactive cards collapse to inert summary at GPS speed >~7 km/h; emergency call always exempt |

**Critical-path analysis:** the offer→claim→trip→delivered loop (MOB-CUR-02/03/04) IS the livelihood flow — haptics outrank audio (helmets muffle speakers), one decision per screen state, and earnings math must be auditable before accepting any task. The integration test `online-offer-claim-trip-delivered` must pass on a 2GB low-end device profile.

## 2. Page list (12 screens)

- S1 Login (courier role)
- S2 **Today** (bottom tab 1) — offer feed top-pinned, active task card, shift pill top-right, offline queue banner
- S3 OfferCard state (pinned top of Today) — 120dp CountdownRing around payout, distance chip, zone word; final 8s crimson pulse + buzz family B; "Missed - next one soon" for 4s
- S4 Active task tri-panel — stage-driven: giant address block (venue name over street), distance/ETA chip, action rows [Navigate 64dp][Call][Chat]; stage AT-DROPOFF unlocks [I arrived] → Delivered flow
- S5 Proof-of-delivery camera — minimal chrome, focus-locked shutter, auto order-id metadata stamp
- S6 **Earnings** (bottom tab 2) — period totals, expandable per-task rows (base, distance bonus, tip split), COD boxes separate, payout cycle date
- S7 Task history — status trail icons, issue ticket deep links
- S8 **More** (bottom tab 3) — vehicle & documents (expiry: warning @14d, danger @3d)
- S9 Settings — ping interval preset explainer w/ battery %/hour (NFR-16), gloves mode (1.25× padding), language, customer block list
- S10 Offline retry sheet — queue contents, manual flush
- S11 Support/issue ticket thread (deep-linked from history)
- S12 Parked-required bottom sheet ("Pull over to continue") — motion-gated actions; guidance, never a hard block
- Bottom tabs: exactly 3 — Today / Earnings / More. Offer + ActiveTask live inside Today (no teleport navigation on claim).

## 3. Component list

1. `OfferCard` — slides in pinned TOP; payout in offerAccent yellow 24 Bold tabular; atomic-claim morph to ActiveTask
2. `CountdownRing` (120dp) — ring-position urgency + haptic cadence + text label (never hue alone); final-8s pulse + double-buzz
3. `ActiveTaskCard` — stage-driven tri-panel, address block border flips blue near geofence ("You are near the gate")
4. `AddressBlock` — venue name prominent over street line, hint-line swap on accuracy thresholds
5. `ActionRow` — [Navigate 64dp full-width][Call 56dp][Chat 56dp]
6. `PaymentKindChip` — COD collected-later amount in separate box
7. `PodCameraScreen` — focus-stable shutter lock, EXIF order-id stamp
8. `EarningsFormulaExpander` — per-task base/distance-bonus/tip audit (FR-DLV-05)
9. `ShiftPill` — persistent online/offline toggle, top-right on all Today states
10. `VehicleDocRow` — expiry countdowns (warning 14d / danger 3d)
11. `OfflineQueueBanner` + `SyncStatusChip` — "3 actions saved, will send"
12. `MotionGate` — collapses interactive cards to inert breathing-outline strips above speed threshold; emergency call exempt
13. `GlovesModeWrapper` — 1.25× spacing multiplier via core_ui tokens (never per-screen)
14. `ScreenBorderFlash` — 300ms flash redundancy for sound events (glare-legible)
15. Shared core_ui components (overview §3)

## 4. Color palette (dark default; light mirrors customer tokens)

| Token | Dark (default) | Light | Role / rule |
| --- | --- | --- | --- |
| color.canvas | #0B1220 | #F8FAFC | OLED-friendly true dark below cards |
| color.surface | #16213A | #FFFFFF | Cards, sheets; 4.6:1 separation vs canvas (dark) |
| color.border | #2C3A55 | #E2E8F0 | **Card outlines mandatory — no shadows (sun kills shadows)**; ≥1.5dp stroke |
| offerAccent | #FACC15 | #FACC15 | Offer countdown ring, money highlights — yellow reads fastest peripherally while riding |
| color.primary | #60A5FA | #2563EB | Links, selected rail item; 7.0:1 on canvas (dark) |
| cta.background | #2563EB solid | #2563EB | Big nav/accept buttons; white Bold ≥18sp (large-text AA at 3.0+) |
| success | #22C55E | #16A34A | Delivered confirmations, earnings credits |
| warning | #FBBF24 | #D97706 | Queue pending, weak GPS, doc-expiry 14d |
| danger | #EF4444 | #DC2626 | Hard failures (claim lost, login expired) — **never for deadline pressure inside offers** |
| textPrimary / Secondary | #F1F5FB / #A9B6C9 | #0F172A / #475569 | 11:1 / 4.7:1 on dark canvas |

Type: one size up from customer ramp — Body 17, Body S 15, offer totals 24 Bold tabular, countdown digits 40 Bold ring-center. Weight skews Medium/SemiBold (thin strokes vanish in glare). Gloves mode: 1.25× paddings via core_ui spacing tokens, smallest chips disabled.

## 5. External APIs used

- PlateRoute REST: `auth`, CourierProfile/vehicle endpoints, `delivery/offers/` (poll + claim), `delivery/tasks/{uuid}/trip/` (stage transitions), ping ingestion, ledger/earnings endpoints, `support/tickets`, `notifications/devices`, `v1/config`
- PlateRoute WS: offer push, task deltas, countdown sync
- FCM **silent data messages** for courier offers (role topics) + local fallback
- OSRM routing/Navigation handoff + OSM tiles via MapPane; Google Maps SDK display only; geolocator foreground service with ping-interval presets (battery %/hour disclosed)
- S3 signed uploads (proof-of-delivery, scan hook server-side), Sentry, Firebase App Distribution

## 6. Safety & privacy engineering notes

Motion gating: GPS speed >~7 km/h collapses interactive cards to inert breathing-outline strips; action taps raise "Pull over to continue" sheet — guidance, never a hard block of trip-status completion; emergency call exempt. Lockscreen notifications never contain dropoff addresses (NFR-16 privacy at pickup points). Background location: explicit purpose-string pre-prompts, opt-in, persistent visibility indicator, 30-day ping retention (NFR-13). Instrumentation: `offer_shown`, `offer_response_ms` (reconciled vs server `delivery_offer.response_ms`), `claim_success_rate` by ring-second cohort, `pod_capture_seconds`, `offline_queue_flush_lag` p95, `screen_dark_mode_usage`.

## 7. Git commit plan — target **80–100 commits**

| Phase | Content | Commits |
| --- | --- | --- |
| P0 | Scaffold, dark-default flavor, theme wiring, ARB, gloves-mode token | 7–9 |
| P1 | Auth + role gating: S1 | 6–8 |
| P2 | Today shell + shift pill + vehicle snapshot: S2, S8 [MOB-CUR-01] | 8–10 |
| P3 | Offer feed + CountdownRing + atomic claim + miss state: S3 [MOB-CUR-02] | 12–14 |
| P4 | Active task tri-panel + stage transitions + geofence hint: S4 [MOB-CUR-03] | 12–14 |
| P5 | POD camera + metadata stamp: S5 [MOB-CUR-04] | 7–9 |
| P6 | Earnings ledger + formula expander: S6 [MOB-CUR-05] | 8–10 |
| P7 | Background location service + ping ingestion + battery explainer: [MOB-CUR-06] | 8–10 |
| P8 | Offline queue + retry sheet + sync chips: S10 [MOB-CUR-07] | 7–9 |
| P9 | History + docs expiry + settings + block list: S7, S8, S9 [MOB-CUR-08] | 5–7 |
| P10 | Motion gating, haptic families A–E, low-end 2GB integration journey, a11y | 5–7 |
| | **Total** | **85–107** |

## 8. App-specific concepts to learn (beyond overview §9)

1. Android **foreground service** lifecycle: location type, persistent notification rules, battery-honesty disclosure, play-services location request intervals
2. "While-in-use" vs "always" location permissions; purpose-string pre-prompt pattern (NFR-16)
3. Geofencing / accuracy-threshold logic ("You are near the gate") and GPS-speed heuristics for motion gating
4. Atomic claim UX: optimistic morph + server arbitration on racing claims (simultaneous courier claims is an explicit backend concurrency test)
5. Offline-first queue: Isar/Hive-backed action log, connectivity-triggered flush, honest Local-saved→Synced chip reconciliation
6. Camera2 via plugin: focus-state gating, EXIF/metadata stamping for POD
7. Vibration pattern composition + screen-border flash redundancy (haptics outrank audio in helmets)
8. OLED-dark design discipline: border-based elevation, glare-legible yellow, no shadow dependencies
9. Battery/end-to-end testing on 2GB RAM emulator profile

## 9. Definition of done

All MOB-CUR-01..08 map to shipped screens; integration journey `online-offer-claim-trip-delivered` passes emulator matrix incl. 2GB profile (Courier §14); NFR-16 flows audited (purpose strings, opt-in, indicator, retention); offline queue flush p95 instrumented; earnings math verified against ledger_entries in tests; dark-first flag per flavor shipped.

