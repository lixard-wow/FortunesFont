# PROJECT

Consolidated internal working docs for Fortune's Font (architecture/state, dev rules, TODO, issues, testing, and the dev changelog all live here in one file). CLAUDE.md and the root CHANGELOG.md remain separate — CLAUDE.md is auto-loaded by Claude Code, and CHANGELOG.md is a standard convention file external tools (CurseForge, GitHub releases) expect to find under that exact name.

## Table of Contents
- [Addon Context](#addon-context)
- [Dev Rules](#dev-rules)
- [TODO](#todo)
- [Issues](#issues)
- [Testing](#testing)
- [Changelog (Dev)](#changelog-dev)

---

## Addon Context

### Addon Identity
- Addon Name: Fortune's Font
- Primary Purpose: Spins a Price-is-Right-style wheel to randomly pick a Mythic+ keystone from the group's pool of keys, then announces the winner in party/raid chat
- Expansion Target: Midnight-era client (Interface 120001)

### Core Features
- Maintains a pool of Mythic+ keystones: the player's own key (auto-refreshed via `C_MythicPlus` on `PLAYER_ENTERING_WORLD`/`BAG_UPDATE_DELAYED`) plus keys broadcast by other group members
- Uses LibKeystone (a shared BigWigs-ecosystem library also embedded in KeyMaster) to request/receive keystone info from anyone in the group running any addon that embeds it — they don't need Fortune's Font installed themselves
- Main window lists up to 5 pool entries (name, dungeon, key level) with per-entry remove buttons, plus Request/Spin/Clear action buttons
- Slot-machine-style spin wheel: builds a randomized reel sequence with a pre-rolled winner, animates a vertical reel (eased deceleration, ~3.4s, 5 loops) with distance-based scale/alpha falloff, then glows the winning slot and announces it in party/raid chat
- Custom from-scratch red-and-gold "game show" flat UI skin (UIKit.lua) — deliberately avoids Blizzard dialog templates
- Minimap launcher icon (LibDataBroker/LibDBIcon): left-click opens the main window, right-click clears the pool
- Slash commands: `/fortunesfont`, `/ff` — subcommands `spin`, `clear`, `request`, `debug` (toggles debug logging); no argument opens the main window

### Architecture Overview
- `Core.lua` — addon init, SavedVariables defaults, event registration (`ADDON_LOADED`, `PLAYER_ENTERING_WORLD`, `GROUP_ROSTER_UPDATE`, `BAG_UPDATE_DELAYED`), slash command dispatch, `Print`/`Debug` helpers
- `UIKit.lua` — from-scratch flat-color UI primitives (panels, title bars, buttons, close buttons, marquee dot strips) in the red/gold palette; no Blizzard templates
- `Pool.lua` — the keystone pool data store (`entries`/`order` tables): add/update/remove/clear, own-key refresh via `C_MythicPlus`, dungeon name/icon lookup via `C_ChallengeMode.GetMapUIInfo`
- `KeystoneSync.lua` — LibKeystone integration: registers a callback for incoming keystone broadcasts from the group and requests keys via `LKS.Request("PARTY")`
- `Minimap.lua` — LibDataBroker launcher object + LibDBIcon minimap button registration
- `MainWindow.lua` — the pool-list window (up to 5 rows) with Request/Spin/Clear buttons
- `Wheel.lua` — the spin window: sequence building with a pre-rolled winner index, `OnUpdate`-driven reel animation with easing, winner glow/announcement
- Embedded `Libs/` (third-party, not linted/edited): LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0, LibKeystone

### SavedVariables
- `FortunesFontDB` (account-wide) — currently stores only `minimap = { hide = false }` (minimap button visibility, managed via LibDBIcon)

### Known Constraints
- None logged yet

### Known Issues
- None logged yet

### Current Focus
- Session initialization; no active task

### Notes for AI
- Do not guess APIs
- Do not expand scope
- Keep solutions minimal
- Follow CLAUDE.md and this file's Dev Rules section strictly

---

## Dev Rules

### Project Baseline
- WoW addon project
- Interface version: 120001
- Lua only
- No external libraries unless explicitly approved
- Prefer custom UI over Blizzard templates/assets

### Non-Negotiables
- No guessing on WoW APIs
- Verify uncertain API behavior before implementation
- Never do math on secret/protected values
- Never attempt to expose, infer, or bypass restricted values
- Respect combat lockdown and secure frame limitations
- Do not add hidden scope or unrelated cleanup

### Scope Control
- Do only what was requested
- Keep changes minimal and targeted
- Do not rewrite surrounding systems unless required for the task
- If a broader refactor would help, propose it instead of silently doing it

### Structure
- Keep files responsibility-focused
- Avoid duplicate helpers or duplicate implementations
- Reuse existing module boundaries where possible
- Prefer data-only extraction first
- Split growing files before they become unmanageable
- Do not create unnecessary conceptual layers

### Performance
- Event-driven first
- Avoid unnecessary OnUpdate usage
- Cache reused values
- Avoid repeated allocations in hot paths
- Gate disabled features so they stop doing work
- Use dirty/queued refreshes when appropriate instead of constant rebuilding

### SavedVariables
- Use one canonical SavedVariables table
- Keep defaults centralized
- Do not scatter persistence logic across unrelated files

### Localization
- All player-facing strings should be localized
- enUS is source of truth
- Avoid string concatenation for localized UI text
- Missing locale strings should be obvious during development

### UI / Layout
- Support different UI scales and resolutions
- Avoid clipping and zero-width layout states
- Avoid fragile offsets
- Prefer measured or bounded sizing for dynamic content
- Test layouts in narrow and wider frame states

### File and Docs Workflow
Project docs live in docs/PROJECT.md (a single consolidated file).

Maintain these sections when the workflow is active:
- TODO
- Issues
- Changelog (Dev)
- Testing

Definition of done includes:
- requested code change completed
- relevant docs updated
- obvious regressions checked
- completion marker printed in chat

### Required Pre-Flight Check
Before making changes, confirm:
- scope is clear
- solution is minimal
- no duplicate helper is being introduced
- localization rules are being followed
- event-driven approach is preferred
- debug/dev-only code stays isolated when applicable

### Completion Marker
When finishing a prompt or task, print:
PROMPT X COMPLETE

---

## TODO

### Active
- None yet

### Backlog
- None yet

### Completed
- Move finished items here and mark with prompt number/date if desired

---

## Issues

- None logged yet

---

## Testing

- None logged yet

---

## Changelog (Dev)

### Format
- PROMPT X
  - Intent:
  - Files changed:
  - Result:
  - Notes:

### Entries
- (none yet — this section grows as work happens)
