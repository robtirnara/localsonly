# LocalsOnly Backend (v1)

This backend is a modular monolith with domain-focused modules.
It is intentionally one deployable app for v1 speed and operational simplicity.

## Modules

- `auth`
- `users`
- `places`
- `ratings`
- `friendships`
- `feed`
- `eligibility`
- `moderation`

## Boundary guidance

- Keep feature logic in its owning module.
- Use shared types from `Sources/App/Shared` for cross-cutting contracts only.
- Avoid direct module-to-module data coupling that bypasses clear interfaces.

## Entry point

- `Sources/App/main.swift` registers all module routes.
