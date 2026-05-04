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
