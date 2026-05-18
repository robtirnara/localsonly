# LocalsOnly MVP Start and Test Guide

## Quickstart (recommended)

From repo root:

```sh
make up
make run
```

In a second terminal:

```sh
make test
make ios
```

## 1) Start Postgres

From `backend`:

```sh
docker compose up -d
```

## 2) Configure backend environment

```sh
export DATABASE_HOST=127.0.0.1
export DATABASE_PORT=5432
export DATABASE_USER=postgres
export DATABASE_PASSWORD=postgres
export DATABASE_NAME=localsonly
export ADMIN_BEARER_TOKEN=local-admin-token
```

## 3) Run SQL migrations manually (MVP)

```sh
psql "postgresql://postgres:postgres@127.0.0.1:5432/localsonly" -f backend/migrations/0001_base_schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:5432/localsonly" -f backend/migrations/0002_eligibility_and_moderation.sql
psql "postgresql://postgres:postgres@127.0.0.1:5432/localsonly" -f backend/migrations/0003_user_sessions.sql
psql "postgresql://postgres:postgres@127.0.0.1:5432/localsonly" -f backend/migrations/0004_moderation_action_type_suppress_rating.sql
```

## 4) Start backend API

```sh
cd backend
swift run
```

Health check:

```sh
curl http://127.0.0.1:8080/health
```

## 5) Run backend tests

```sh
cd backend
swift test
```

## 6) Start iOS app

- Open `ios/LocalsOnlyApp.xcodeproj` in Xcode.
- Add environment variable `LOCALSONLY_API_BASE_URL=http://127.0.0.1:8080` to the Run scheme.
- Run on iOS Simulator.

## 7) Manual smoke checklist

> When primary navigation changes, update this checklist in the same PR (see master plan section 6 Phase 0 and [`docs/plans/README.md`](plans/README.md)).

Signed-in primary navigation uses the **custom bottom bar** aligned to the **Social Feed** reference canvas: blurred card shell (`rounded-t-[40px]`, upward shadow), **ocean** active and **concrete** inactive tab chrome (`text-xs` bold), **Home** (`.feed`), **Explore** (`.ranks`), center **sky FAB + plus** (`.rate`), **Saved**, **Profile**. **Map** (reviewed places with pins) lives inside **Explore** via the **List | Map** segmented control at the top of Explore. Default **Explore** list shows **Top Locals** ranked places with category chips (All Spots, Tacos, Coffee, Margs, Seafood); overflow menu has dish search, place search, and suggest-a-place. Settings (appearance, sign out, legal links): **Profile → gear → Settings**.

When signed out, the app shows the **full-screen onboarding + auth funnel** (Welcome → Community → Select Tastes → Sign Up → **Profile Setup** (after **Sign up with Email**) → optional **Verify Local** on first successful registration on device). Use the back chevron on **Community** to return to Welcome if needed. **Sign out** returns you to that funnel; **Verify Local** is skipped after it has been completed once on the device.

1. Walk onboarding screens (on **Welcome**, tap **Drop In**; on **Community**, tap **Continue** or **Skip**), then on **Sign Up** choose **Sign up with Email** and complete **Profile Setup** (username, password, birthday). **Join the Locals** completes sign-in in DEBUG via **Dev login** behavior when the API allows `POST /auth/dev-login` and a user exists; release builds show a “coming soon” toast until email signup is wired.
2. (DEBUG builds) From onboarding **Sign Up** sheet you may still use **Dev login** under local testing when shown.
3. On first registration on a fresh install, complete **Verify Local** (tap **Submit Verification**), then confirm you reach the signed-in shell.
4. Sign out from Settings and confirm onboarding appears again; sign in again and confirm **Verify Local** is skipped.
5. Tap `Recheck Eligibility` and confirm non-`browse_only` state if signals permit.
6. Suggest a place with **Suggest a place** (from Explore overflow menu).
7. Search and select the place.
8. Submit a rating as `public`.
9. Open **Profile** ratings and verify it appears.
10. Open **Home** (feed) popular section and verify public ratings affect aggregates.
11. Submit a rating as `private` and verify it does not appear in popular feed.
12. (Optional) Call admin moderation endpoint with `ADMIN_BEARER_TOKEN` and verify suppression behavior.
13. Open **Explore**: confirm **Top Locals** list, category chips, and **List | Map**; on **Map**, pan/zoom and tap a pin to open place detail.
14. Open **Saved** tab: confirm stash header, segments, collections row, and bookmark grid use **coastal** colors (sand background, ink/coral accents).
15. With **Explore** overflow → **Find dishes (trending)**, type a dish (e.g. `taco`); results should use the dish-first card layout and open the place when tapped.
16. (Optional) `curl 'http://127.0.0.1:8080/feed/popular-items?city=SanDiego&filter=food'` returns JSON with `itemName`, `placeName`, and `neighborhood` fields.
17. Open **Profile**, tap the **gear**, open **Settings**; change **Appearance** and confirm the theme updates; use **Sign Out** and confirm you return to the onboarding + auth flow.
