# LocalsOnly Backend

Modular monolith on **Vapor 4** + **Fluent** with a **PostgreSQL** driver. One process for v1; routes are split into domain modules under `Sources/App/Modules/`.

## Modules

Registered in `Sources/App/Shared/Module.swift` (order is registration order):

| Module | Purpose |
|--------|---------|
| `auth` | Sessions / authentication |
| `users` | Profiles and user-facing account behavior |
| `places` | Venues and place metadata |
| `ratings` | Scores and rating content |
| `friendships` | Social graph between users |
| `feed` | Activity feed (e.g. friends, popular) |
| `eligibility` | Local contributor / trust states |
| `moderation` | Admin and safety actions |
| `uploads` | File uploads |
| `tags` | Tagging |
| `bookmarks` | Saved items |
| `lists` | User lists |
| `cosigns` | Cosign / endorsement flows |
| `notifications` | Notifications |
| `invites` | Invites |

## Boundary guidance

- Keep feature logic in its owning module.
- Use shared types in `Sources/App/Shared` only for cross-cutting contracts.
- Avoid module-to-module coupling that bypasses clear boundaries.

## Entry points

- **`Sources/App/main.swift`** — builds the Vapor `Application`, calls `configure(_:)`, runs the server.
- **`Sources/App/configure.swift`** — middleware, static files / uploads directory, Postgres configuration from environment variables, then **`routes(_:)`**.
- **`Sources/App/routes.swift`** — registers every module in `AppModules.all`.

## Database and migrations

Schema is evolved with **plain SQL** files in `migrations/` at the repo root of `backend/` (not Fluent migrations). From the repository root, `make migrate` (via `make up` / `make run`) applies them in order.

Environment variables (defaults match `docker-compose.yml` for local Docker):

- `DATABASE_HOST` (default `127.0.0.1`)
- `DATABASE_PORT` (default `5432`)
- `DATABASE_USER` (default `postgres`)
- `DATABASE_PASSWORD` (default `postgres`)
- `DATABASE_NAME` (default `localsonly`)

Server bind: `SERVER_HOSTNAME` (default `0.0.0.0`), `SERVER_PORT` (default `8080`).
