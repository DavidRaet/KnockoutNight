# L4 — Local 1v1 dispatch

Implemented October 23, 2026 under the [approved L4–L9 plan](../L4-L9_Implementation_Plan.md). **David signed off L4 gameplay on October 23, 2026.** L5–L6 are also implemented and accepted; L7–L9 are deferred to another session. No publishing is authorized.

## Owner acceptance

David explicitly signed off the completed L4–L6 local flow on October 23, 2026. This accepts the implemented behavior within its recorded limits; it does not establish that outstanding multiplayer, latency or performance checks passed. L7–L9 and milestone/release gates remain separate.

## Behavior

A complete FIFO pair starts a three-second countdown. Queue membership is sampled before assignment at expiry. A changed/incomplete pair cancels/restarts the countdown without reordering survivors; extras wait. One allocation moves the pair to a separate safe intermission blockout with movement/jumping and no combat. The board displays the countdown or occupied state. Return to Lobby, disconnect, reset/death, or character loss cancels the temporary intermission and returns connected participants outside the queue with an explanation. Stale/nonparticipant returns cannot cancel a session. The next pair waits until return completes.

`L4Dispatch` contains deterministic countdown/allocation rules. `L3Lobby` owns character handoff, intermission geometry, lifecycle cleanup, replicated dispatch state and the Return remote. Existing lobby characters stay excluded from combat/lives. `L3Client` presents countdown, occupied state and intermission return; the existing controller permits intermission movement. Developer arena behavior is unchanged.

## Technical verification

- `tests/run_l4_checks.ps1`: formatting, Selene, Luau compilation and generated fixture compilation pass. Existing 590 combat deterministic assertions, 120 queue assertions and 112 new dispatch assertions pass.
- Isolated Studio lifecycle fixtures: 23 existing L3 assertions and 14 L4 assertions pass. The L4 fixture uses synthetic players/signals and controlled server time against the actual lobby implementation. It covers expiry departure, FIFO assignment, extra entrants, no arena-life admission, duplicate prevention, stale/nonparticipant return, return without requeue, allocation reuse, pre-GO death, disconnect and shutdown cleanup.
- Real single-client Play interaction creates a lobby character; server positioning onto the pad produces one queued member and no countdown/allocation without an opponent.
- Runtime sources compared against connected Knockout Night Studio; only L3Config, L3Lobby, new L4Dispatch, F1Controller and L3Client required sync. Changed sources read back successfully. Temporary verification modules removed after checks.
- Studio log contains the existing asset-type warnings for `rbxassetid://203785492` and the expected deliberate L3 fixture spawn-failure warning; no unexpected L4 script error observed.

## Owner check

1. Start a local server with at least three clients; click Play and enter the pad in order. Confirm the first two see a three-second countdown while the extra player keeps their position.
2. Leave/reset/disconnect during countdown. Confirm survivors retain order and the replacement pair gets a fresh countdown.
3. Let dispatch finish. Check both participants move to intermission, can walk/jump and look with right mouse, cannot fight, and have Return to Lobby. The extra client must remain in the lobby.
4. Return, reset or disconnect in intermission. Confirm connected participants return outside the queue, explanation appears, and the next complete pair can dispatch after cleanup. Repeat with another pair.

Actual multi-client input/replication, real two-player dispatch/return, agent visual intermission review, target latency, low graphics and reference-hardware performance remain unverified. Owner gameplay acceptance is complete by David's October 23, 2026 sign-off. L5 voting/arena handoff and L6 loadouts/start are subsequently implemented and accepted; see [L5–L6 verification](../L6/L5-L6_Implementation_and_Verification.md). L7 full HUD, L8 complete lifecycle coverage and L9 settings/presentation remain deferred to another session.
