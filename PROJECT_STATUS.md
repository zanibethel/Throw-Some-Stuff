# PROJECT_STATUS

## Current repository snapshot
- Repository contents at initial Roblox-foundation start: a single `/project.godot` file for a Godot project named `Benjamin`.
- No existing Roblox source tree, Rojo project file, lint config, formatter config, package manager config, or automated validation workflow was present before the Roblox foundation work.
- No existing gameplay scripts, remotes, rooms, UI, assets, or save-data systems were present for the Roblox game concept before the Roblox foundation work.

## Existing systems
- **Godot artifact:** `/project.godot` exists and was left untouched because it is unrelated to the requested Roblox foundation.
- **Roblox systems before the foundation PR:** None verified.
- **Roblox systems now present:** minimal Rojo mapping, shared config/types/utilities, server bootstrap, client bootstrap, runtime state service/controller skeleton, and a full server-authoritative interaction framework (Hold/Instant modes, exclusive/shared locking, session lifecycle, rate limiting, cooldowns, reset API, demo interactions, pure-logic test suite).
- **Post-merge repair status:** bootstrap lifecycle failure handling was repaired after the initial foundation merge so failed startup no longer leaves server/client/module guards locked.

## Current workflow
- Work is being done on a focused branch, not `main`.
- Repository-first validation is separated from manual Roblox Studio testing.
- New work should start by reviewing the docs and then inspecting `/src` and project config.
- Repository automation now runs JSON parsing, TOML parsing, StyLua, Selene, and a Rojo build on pull requests and pushes to `main`.
- Repository automation does not replace Roblox Studio testing for lifecycle, replication, lighting, audio, or device input behavior.

## Verified functionality
- Repository inspection verified that no Roblox tooling or Lua source layout existed before the Roblox foundation work.
- `default.project.json` now defines a Rojo-compatible DataModel mapping for shared, server, and client code.
- Bootstrap scripts and `ModuleBootstrap` now distinguish in-progress startup from successful startup and clean partial work on failure.
- Runtime bootstrapping fails safely when required shared modules or folders are missing, and failed startup does not permanently block a later controlled retry.
- GitHub Actions validates repository-visible JSON/TOML syntax, formatting, linting, and Rojo buildability.
- `InteractionService` implements a full server-authoritative session lifecycle: server-generated session IDs, Hold mode with Heartbeat-driven completion, Instant mode, exclusive and shared locking, 18-point validation pipeline, per-player rate limiting, per-target cooldowns, session expiry, safe pcall-wrapped extension points, and public reset API (`cancelPlayerInteractions`, `cancelTargetInteractions`, `resetAll`, `resetDefinitions`).
- `InteractionController` manages ProximityPrompt creation and operation dispatch; handles race-safe hold cancellation, attribute-change reactivity, and character-death cleanup.
- `DemoInteractions` registers two demo interactables (`demo_instant_button`, `demo_hold_lever`) demonstrating Instant+shared and Hold+exclusive behaviors.
- `InteractionTests` provides 18 pure-logic tests covering session ID uniqueness, exclusive locking, cooldowns, expiry, replay rejection, ownership, session limits, rate limiting, and concurrent cancellation.
- `docs/INTERACTION_FRAMEWORK.md` documents architecture, client/server sequence diagrams, session lifecycle, definition schema, interaction modes, security model, rate limits, handler interface, cancellation/reset behavior, Studio setup, and known limitations.

## Missing foundation
- No implemented searchable-object system yet.
- No remotes beyond the interaction request/state-changed pair yet.
- No inventory, keys, doors, puzzles, entities, hiding, flashlight, stun, UI, audio, or save data.
- No automated test framework such as TestEZ yet; `InteractionTests` is a standalone pure-logic module.
- No Roblox Studio place file or in-Studio scene verification in this repository.

## Risks
- The repository started from a non-Roblox state, so Studio-side integration still needs validation.
- Because Roblox Studio was unavailable, playability, instance placement, replicated runtime behavior, and lifecycle behavior in live Studio sessions remain unverified.
- Future remote-based systems can introduce trust-boundary bugs if server validation rules are not enforced consistently.
- Reset logic will become a major source of bugs unless every new system adopts the cleanup/lifecycle pattern from the start.

## Architecture decisions
- Use a three-way `src/shared`, `src/server`, and `src/client` layout under Rojo.
- Keep config in shared modules and keep behavior in focused services/controllers.
- Use a generic module bootstrap pattern with explicit `Init`, `Start`, and cleanup hooks.
- Track shared runtime state in `ReplicatedStorage.GameRuntime` for early vertical-slice observability.
- Prefer safe logging and graceful degradation over hard crashes when expected instances are absent.

## Testing limitations
- Automated repository validation can only cover file structure and CLI-available checks.
- Roblox character replication, respawn behavior, local server behavior, lighting, audio, and device-specific UX require Roblox Studio.
- No repository test suite or CLI type checker is present yet, so automated validation currently focuses on syntax, formatting, linting, and Rojo project buildability.

## Recommended next milestone
- **Next milestone:** 3. Searchable-object system.
- Reason: the interaction framework is now in place; the next gameplay step is to make containers and props searchable using it.

## Assumptions
- The requested Roblox game foundation should coexist with unrelated repository files unless explicitly told to remove them.
- Rojo will be the source-of-truth sync workflow for future Roblox development.
- `ReplicatedStorage.GameRuntime` is acceptable as a temporary shared runtime state surface for early development.
- Future place-building and validation will happen in Roblox Studio once access is available.
