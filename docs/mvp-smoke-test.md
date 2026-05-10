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

> When primary navigation changes, update this checklist in the same PR (see master plan §6 Phase 0 and [`docs/plans/README.md`](plans/README.md)).

Signed-in primary navigation uses the **custom coastal bottom bar** (reference design: inactive gray + outline icons, active coral + filled icons, elevated center palm FAB — no system `TabView` strip). Items left to right: **Feed**, **Ranks**, **Log** (palm), **Map**, **Profile**. Saved places: **Profile → Saved**.

1. Tap `Send Code` (dev code should be `111111`).
2. Tap `Verify + Sign In`.
3. Tap `Recheck Eligibility` and confirm non-`browse_only` state if signals permit.
4. Suggest a place with `Suggest Place`.
5. Search and select the place.
6. Submit a rating as `public`.
7. Open `My Ratings` and verify it appears.
8. Open `Popular` feed and verify public ratings affect aggregates.
9. Submit a rating as `private` and verify it does not appear in popular feed.
10. (Optional) Call admin moderation endpoint with `ADMIN_BEARER_TOKEN` and verify suppression behavior.
11. Open **Ranks** (The Local List): **Trending nearby** should list **dishes or drinks** as the main title, **place name** on the next line, then **neighborhood** (or “Nearby”); use category chips (e.g. Top Eats, Surf Coffee) and confirm the list updates; when more than one neighborhood appears in the list, use the horizontal **neighborhood** pills to filter.
12. With search on the default **items** mode, type a dish (e.g. `taco`); results should use the same dish-first card layout and open the place when tapped.
13. (Optional) `curl 'http://127.0.0.1:8080/feed/popular-items?city=SanDiego&filter=food'` returns JSON with `itemName`, `placeName`, and `neighborhood` fields.
