# AIDesigner canvas reference (linked MCP session)

Use MCP `list_canvases` / `get_canvas` on the project AIDesigner server for full HTML when iterating on layout.

**Do not port:** full-bleed outer frame borders (black/blue/editor chrome) around mocks — app screens are edge-to-edge in the safe area only.

| Screen | Canvas name | Slug | UUID |
|--------|-------------|------|------|
| Profile Setup | Profile Setup | signup-2 | `1a52a238-e8f4-42a4-85a2-0956baa00f28` |
| Verify Local Status | Verify Local Status | verify-local | `97b8a82c-e4dc-4ac4-9b41-899320024461` |
| Welcome | Welcome | localsonly-home | `0d11d6e8-ddd1-4e4c-a0ca-2f89a23cc346` |
| Select Tastes | Select Tastes | cravings | `cace7aa4-6944-4b79-97e9-0dcac9e16763` |
| Community | Community | testimonials | `1416641c-970e-449b-9c6f-b60aefd42d69` |
| Sign Up | Sign Up | signup | `7369e4fc-2e80-4b7c-88ad-5bb65847ed7a` |
| Saved Spots | Saved Spots | saved | `3eda6a90-d131-4add-b91e-4add61aa8999` |
| Social Feed | Social Feed | user-feed | `8d038d37-7ca5-4282-ab12-361b900b4bde` |
| User Profile | User Profile | profile | `5004d298-3e38-45fe-838b-f21f37550c21` |
| Top Locals Spots | Top Locals Spots | explore-2 | `a0a7763d-14bd-4d3a-860e-0cfea98cf468` |
| Add Review | Add Review | log-spot | `22abafd6-1c42-4d02-b19a-b837037344ed` |

## SwiftUI deltas (repo)

- **Profile Setup:** native SwiftUI after **Sign up with Email** (`ProfileSetupScreen.swift`); DEBUG uses `dev-login` until `/auth/register` exists.
- **Verify Local Status:** layout from `verify-local` HTML in `VerifyLocalStatusScreen.swift`; full-bleed window background matches **Select Tastes** (same `tastesScreenBackgroundFill`: sand `#EFEFEF` + blurred orbs).
- **Saved Spots:** match layout from canvas; colors use coastal tokens (not canvas-specific dark theme).
- **Explore (`explore-2`):** `feedCanvas*` tokens, `Top Ranks 🌴` header + category pills, ranked cards (`TopLocalPlaceRankRow`), hidden-gems CTA; search via overflow menu. **List | Map** segmented control retained; **Map** uses `MapExploreView` + `placesNearby()`.
- **Add Review (`log-spot`):** `RateScreen` + `RateWavesPicker`; sand header (X / Log a Spot / Post), place card, square dashed photo, wave score, vibe chips, notes; item + visit/privacy kept for API.
- **User Profile (`profile`):** `feedCanvas*` tokens; gear header; centered avatar + stats + taste ocean card; **Recent Logs** / **Saved Lists** tabs; 2-col log grid + Log New cell.
