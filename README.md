# LocalsOnly

San Diego–focused local discovery: a **SwiftUI iOS app** and a **Vapor 4** API backed by **PostgreSQL**. The server is a single deployable app with domain modules; the client talks to the API over HTTP (JSON).

## Repository layout

| Path | Purpose |
|------|---------|
| `ios/LocalsOnlyApp.xcodeproj` | Xcode project for the iOS app |
| `ios/LocalsOnlyApp/` | SwiftUI screens, networking, design system |
| `backend/Package.swift` | SwiftPM package; executable target `App` → product `LocalsOnlyBackend` |
| `backend/Sources/App/` | Vapor app: `configure.swift`, `routes.swift`, `Modules/`, `Shared/` |
| `backend/migrations/` | **SQL** schema and data migrations (numbered `0001_…` through `0015_…`) |
| `backend/docker-compose.yml` | Local **Postgres 16** (port 5432) |
| `backend/uploads/` | Runtime upload directory (created at startup; not for committing user data) |
| `docs/` | PRD, eligibility, moderation, smoke-test notes |
| `Makefile` | **MVP workflow**: Postgres, migrations, `swift run` / `swift test`, open Xcode |

Swift Package Manager build output lives under `backend/.build/`; it is **gitignored** and must not be committed.

## Quick start

From the repo root:

```sh
make up      # Postgres (Docker if available) + all SQL migrations
make run     # API at http://127.0.0.1:8080 (includes make up)
```

In another terminal:

```sh
make test    # backend tests (includes make up)
make ios     # opens the Xcode project
```

See `make help` for options. Database credentials default to the values in `backend/docker-compose.yml` when using Docker (`postgres` / `postgres` / database `localsonly`); the Makefile can target a local Postgres install instead. Full step-by-step and health checks: `docs/mvp-smoke-test.md`.

## iOS app and API base URL

- **Simulator** uses `http://127.0.0.1:8080` when the `LOCALSONLY_API_BASE_URL` environment variable is unset (see `ios/LocalsOnlyApp/Networking/APIClient.swift`).
- For a **physical device**, either set `LOCALSONLY_API_BASE_URL` in the Xcode scheme to your Mac’s LAN URL (e.g. `http://192.168.x.x:8080`) or change the non-simulator default in `APIClient` so the phone can reach the API.

## Backend modules

Feature surfaces are registered in `backend/Sources/App/Shared/Module.swift`: **auth**, **users**, **places**, **ratings**, **friendships**, **feed**, **eligibility**, **moderation**, **uploads**, **tags**, **bookmarks**, **lists**, **cosigns**, **notifications**, **invites**.

More detail on boundaries and structure: `backend/README.md`.

## Policy framing

Contribution access is framed around Local Contributor eligibility, using independent trust, locality, and abuse-risk signals. Product and policy context: `docs/prd.md`, `docs/local-contributor-eligibility.md`.
