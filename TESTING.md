# TESTING

## Validation categories
- **Static checks:** formatting, linting, project-file validation, and similar repository-only checks.
- **Automated checks:** CLI commands that run outside Roblox Studio.
- **Manual Roblox Studio testing:** playtests, local server sessions, replication checks, UX checks, and exploit-resistance checks.

## Automated validation run for this task
- `python -m json.tool default.project.json`
- `python -m tomllib` parse for `aftman.toml`, `stylua.toml`, and `selene.toml`
- `git diff --check`

## Manual Roblox Studio test checklists

### Solo play
- Start a one-player play session.
- Confirm server bootstrap logs once.
- Confirm client bootstrap logs once.
- Confirm `ReplicatedStorage.GameRuntime` exists.
- Confirm `GameTitle`, `MaxPlayers`, `CurrentRoomId`, `PlayerCount`, and `Phase` attributes populate.
- Stop and restart play to confirm no duplicate initialization warnings appear unless intentionally duplicated.

### Two-player local server
- Start a two-player local server session.
- Confirm each client runs the client bootstrap once.
- Confirm `PlayerCount` updates to 2.
- Confirm both clients observe the same `Phase` and room attributes.
- Confirm reconnecting a test player updates runtime state safely.

### Six-player local server
- Start a six-player local server session.
- Confirm runtime state remains stable as all six clients join.
- Confirm `PlayerCount` updates correctly during join and leave events.
- Confirm logs remain readable and no runaway loops appear.

### Simultaneous interaction
- Once the interaction system exists, have multiple players attempt the same interaction at the same time.
- Verify only valid outcomes are accepted.
- Verify server state stays authoritative.
- Verify no duplicate rewards or state changes occur.

### Character death
- Kill a player during play.
- Confirm the server does not retain invalid references to the dead character.
- Confirm any player-specific listeners are either rebound safely or cleaned up.

### Respawn
- Respawn a player after death.
- Confirm bootstrap systems do not duplicate.
- Confirm character-related listeners reconnect exactly once.
- Confirm the player can resume normal interaction flow.

### Player disconnection
- Disconnect a player during an active local server session.
- Confirm runtime state updates cleanly.
- Confirm no orphaned player state or errors remain.
- Confirm the remaining players can continue.

### Room reset
- Trigger a room reset once a room system exists.
- Confirm temporary instances, puzzle states, searchables, and entity state are restored.
- Confirm players are not left locked in invalid spots.

### Round reset
- Trigger a full round reset.
- Confirm player state, room state, progression, and temporary objects all reset.
- Confirm repeat reset cycles do not create duplicate connections or stale state.

### Missing instances
- Temporarily remove an expected folder or module in Studio.
- Confirm the relevant bootstrap path fails safely with a readable warning.
- Confirm the rest of the game does not enter an uncontrolled error loop.

### Duplicate event connections
- Start and stop play several times.
- Exercise respawn and reset flows.
- Confirm repeated actions produce one response, not multiple stacked responses.

### Invalid remote arguments
- Once remotes exist, send malformed, nil, extra, wrong-type, and out-of-range arguments.
- Confirm the server rejects them safely.
- Confirm rejected requests do not mutate gameplay state.

### Remote spam
- Once remotes exist, spam high-frequency valid and invalid requests.
- Confirm rate limits or safe guards prevent server overload and duplicate effects.

### Attempts to fake inventory, keys, doors, rewards, or progression
- Once those systems exist, use the client console or exploit simulation tools to fake ownership or completion.
- Confirm the server rejects every unauthorized state change.
- Confirm no client-authored progression is accepted.

### Mobile
- Test on the mobile emulator or device.
- Confirm prompts are readable and touch targets are large enough.
- Confirm low-light visuals remain usable.

### Controller
- Test with a controller.
- Confirm focus movement, interaction prompts, and item use remain clear.
- Confirm no critical action depends on mouse-only input.

### Keyboard and mouse
- Test movement, camera, interaction flow, and item use.
- Confirm core actions are discoverable and responsive.

## Pull request test-results template

```md
## Test Results

### Static checks
- [ ] Formatting
- [ ] Linting
- [ ] Type checks
- [ ] Rojo project validation/build
- Notes:

### Automated checks
- [ ] Repository commands completed
- Notes:

### Manual Roblox Studio testing
- [ ] Solo play
- [ ] Two-player local server
- [ ] Six-player local server
- [ ] Simultaneous interaction
- [ ] Character death
- [ ] Respawn
- [ ] Player disconnection
- [ ] Room reset
- [ ] Round reset
- [ ] Missing instances
- [ ] Duplicate event connections
- [ ] Invalid remote arguments
- [ ] Remote spam
- [ ] Fake inventory / keys / doors / rewards / progression attempts
- [ ] Mobile
- [ ] Controller
- [ ] Keyboard and mouse
- Notes:

### Known limitations
- 
```
