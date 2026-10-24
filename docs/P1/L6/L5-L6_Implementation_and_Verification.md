# L5–L6 — Map voting, arena entry and private loadouts

Implemented October 23, 2026 under the [approved plan](../L4-L9_Implementation_Plan.md). David explicitly requested continuing through L6 without stopping at L5, then **signed off the completed L4–L6 gameplay on October 23, 2026.** L7–L9 are deferred to another session. No publishing is authorized.

## Owner acceptance

David explicitly signed off the implemented local flow through L6 on October 23, 2026. Gameplay acceptance is complete for L4–L6. This sign-off does not close the outstanding technical scenarios below, accept M2 as a whole, or authorize publishing. Resume with L7–L9 in a later session at David's request; do not continue automatically.

## Implemented behavior

- Three-second FIFO dispatch starts a full ten-second editable vote among The Platform, Sky Bridges and Dungeon. Counts are public; own vote is highlighted without a voter roster. Random selection includes only tied leaders, or all maps with no votes.
- The selected arena replaces the previous geometry. Both participants move within the same server to opposing frozen spawns. Intermission movement is permitted; combat remains disabled.
- A private fifteen-second selection begins after arena arrival. Each session starts blank, with one weapon and one ability. Edits clear Ready. Both Ready or expiry locks valid choices and independently supplies Spring Fist/Gust for missing fields. Defaults are explained briefly during countdown.
- Choices remain in server-only state with acknowledgements sent only to their owner; public snapshots contain counts, phases and deadlines. Public equipment attributes and arena combat characters are assigned only at opening countdown.
- The existing three-second match countdown enables movement, weapons, abilities and the authoritative timer together at GO. Server validates participant/session/phase/deadline/identifier and throttles selection requests. Stale/invalid/late requests cannot change locked equipment.
- Return to Lobby is available while voting/selecting. Pre-GO reset/death/character removal/disconnect or setup failure cancels without a result and returns connected participants outside the queue.
- The existing match HUD/countdown/results now display for local match participants. Existing results support individual immediate return and eight-second automatic return. The allocation remains occupied until all participants return, then lives/session state are cleared before the next dispatch. Waiting players retain FIFO order. Full L7 presentation and L8 scenario coverage are separate.

## Implementation reach

`L5Flow` owns deterministic vote/selection rules; `L3Lobby` owns the local session, handoffs and private request channel. `L5Arenas` reuses the existing map builders and extracts the existing Platform builder from F1 startup without changing its geometry. `F3Lives.setArena` requires an empty previous roster and replaces bounds/spawn definitions. `F4Match` accepts the assigned roster, provides local return/opening-loss hooks and session cleanup, retaining its original developer path. The F1 controller restores combat mouse capture/spectating in local matches. `L5Client` supplies vote/selection UI; F3 HUD visibility and score panels follow the current roster.

## Technical evidence

- `tests/run_l6_checks.ps1`: formatting, Selene, Luau compilation and generated harness compilation pass. **886 deterministic assertions:** 590 combat regressions, 120 queue, 112 dispatch, 64 vote/loadout assertions. The latter cover all nine loadouts, empty/tied votes, vote editing, throttle, invalid/nonparticipant/stale/late requests, independent defaults, Ready edits and once-only transitions.
- Isolated Studio journey: **29 assertions pass** using synthetic players/signals and controlled server time, with the current lobby, lives, match and arena-building implementations. Combat is stubbed in this fixture. Covers all three arena loads, old-model destruction, frozen spawns, private acknowledgements/no public choice leak, independent defaults, lock, countdown/GO, participant-only admission, stale changes, individual/automatic return, reuse, timeout, opening/selection reset and deliberate load failure.
- Existing Studio lobby fixtures still pass: **23 L3 assertions and 14 L4 assertions.**
- Existing isolated safe-spawn/lives fixture passes **21 assertions each on Sky Bridges and Dungeon** through the extracted map builder: mirrored starts, scoring/respawn, home pools, fallback, lower plane, reset, and unsafe-fallback failure. These are engine fixtures, not live multiplayer matches.
- Real single client: Play opens the lobby without unexpected script errors. Controlled client presentation snapshots display the ten-second vote and fifteen-second selection, all six choices, Ready and default explanation. A real click on Dungeon sends the expected session/map request through the actual remote. Screens were visually inspected at the current desktop viewport. These synthetic presentation snapshots do not establish real two-client state replication.
- All **37 runtime sources** compared against connected Studio and synced; writes read back. Temporary verification modules and presentation snapshots removed by stopping play and removing the owned fixture folder. Studio left in Edit mode.
- Logs include the existing asset-type warnings for `rbxassetid://203785492`, deliberate L3 spawn/load-failure warnings, and the two expected unsafe-fallback warnings from the lives fixtures. No unexpected runtime error observed in these runs.

## Owner check

1. Start a server with three clients. Play and queue two; the third waits. After dispatch, vote/change votes and confirm the full ten seconds elapses.
2. Confirm both players enter the voted arena, frozen at opposing spawns. Select different equipment; the opponent must not see it before countdown. Edit after Ready and confirm Ready clears.
3. Confirm both early, then repeat without input. Check missing fields independently become Spring Fist/Gust, the opening countdown lasts three seconds, and GO enables play/timer together.
4. Reset/disconnect before GO; check cancellation and usable lobby return without scoring. Complete a match; try immediate and automatic return, then dispatch another pair. Repeat across maps.

## Limits

Actual multi-client input/replication, real network privacy under two clients, complete live combat across all maps/loadouts, target latency, low graphics, smaller desktop viewports and reference-hardware performance remain unverified by the agent. The isolated journey uses a combat stub and does not establish combat feel; David's separate October 23, 2026 sign-off completes owner gameplay acceptance for L4–L6. L7's complete HUD treatment/radial cooldown, L8's complete lifecycle acceptance matrix and L9 settings/presentation remain unfinished and deferred to another session. Existing combat, art, latency and release gates remain separate; no asset generation/export, new music, persistence, reserved servers, 2v2 or publishing was added.
