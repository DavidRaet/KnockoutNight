# L3 — Menu, lobby, and 1v1 queue

**October 23, 2026:** Approved design implemented. Technical verification and limitations are recorded below. **David signed off L3 gameplay on October 23, 2026; gameplay acceptance is complete for this slice.** L4 dispatch is separate work.

## Owner acceptance

David explicitly signed off L3 on October 23, 2026. This accepts the current menu, lobby, and queue experience; it does not assert that every outstanding technical scenario was exercised. Actual multi-client verification, reset-button interaction, long-queue mouse-wheel checks, low graphics, target latency, and reference-hardware performance remain open. Sign-off does not authorize L4, polishing, or publishing.

## Approved design

David approved these decisions during the L3 planning interview on October 23, 2026, then authorized implementation:

- Title over a blurred fixed view of the compact lobby; one Play button. Players have no character before Play. Repeated input creates one lobby entry.
- Safe spawn outside one physical 1v1 pad. Movement and jumping work; combat, abilities, and collisions between players are disabled.
- Server-owned FIFO queue, one membership per player. Membership follows the root's horizontal pad bounds, with vertical allowance for jumping. Leaving removes membership on the next server check; re-entry joins at the back.
- Reset/death removes membership and respawns outside the pad without reopening the menu. Disconnect removes membership immediately.
- Board shows numbered usernames, the next pair pinned above a scrollable waiting list, and instructions. A personal HUD shows queue position.
- One active local match for M2; additional players wait. L3 ends at waiting/“Next pair ready,” with no roster locking, countdown, dispatch, or arena assignment. L4 implements those operations.
- Existing combat testing remains available through a separate developer arena mode; normal lobby players do not see prototype loadout/start controls.

## Implementation

`F1Prototype` retains the existing R15 spawner and arena setup. With `F1Config.DeveloperArenaMode = false` (default), `L3Lobby` owns player admission, lobby geometry, the Play remote, respawning, queue membership, and replicated roster snapshots. Lobby characters are marked before assignment so `F2Combat` does not equip them, and they are never admitted to `F3Lives`.

`L3Queue` contains the membership and zone rules. `L3Lobby` samples roots every 0.1 seconds, permits roots 0–15 studs above the pad center, and publishes only changed membership. Play is state-gated and throttled to one attempt per second. Character creation failures expose Retry Play. Respawns wait one second and stale callbacks are discarded after departure/shutdown.

`L3Client` owns the menu, local blur, world board, and personal HUD. The existing controller supplies movement/camera with lobby combat input disabled. Hold right mouse to look in the lobby; the free cursor permits board scrolling. `L3Config` places the 72 × 64 stud blockout at `(0, 40, 220)`, away from the arena, with an 18 × 16 stud queue pad. Lobby avatars currently use the standard prototype R15 template.

To exercise the original combat staging path, stop Studio, set `F1Config.DeveloperArenaMode = true`, run checks, sync, and start a separate test session. This bypasses the lobby and retains the original two-slot admission, loadout pickers, and authorized developer console. Restore `false`, recheck, and sync before lobby testing. Existing combat engine fixtures also remain available.

## Verification

Recorded results: [L3 evidence](../../evidence/L3Lobby.json).

- `tests/run_l3_checks.ps1`: formatting, Selene, and Luau compilation pass; 590 existing deterministic regression assertions and 120 L3 queue assertions pass. The check also builds and compiles an isolated lobby lifecycle harness.
- Studio source comparison: all 33 local runtime sources matched after sync. Temporary fixture modules were removed after testing.
- Real single-client input: clicked Play, sent 20 repeated Play requests, walked onto the pad with W, and jumped. One character remained; queue membership and the personal HUD updated; jumping retained membership.
- Real server/client checks: no arena life admission or equipped weapon; character parts use the noncolliding character group; a direct ability request is rejected. Death removes queue membership, replaces the character outside the pad, and keeps the menu/blur dismissed.
- Isolated Studio lifecycle fixture: **23 assertions passed** using synthetic players/signals and the current server implementation. Covers four entrants, next pair/extras, FIFO exit/re-entry, jumping, death/respawn, disconnect, spawn failure/retry, pending-callback shutdown, and owned-instance cleanup. This does not establish actual multiplayer replication or network timing.
- Client presentation fixture: 12 rows produce a 504-pixel canvas in a 278-pixel scroll window; next pair remains outside the scrolling frame, and the personal HUD correctly shows position 12 of 12. Synthetic snapshot was restored afterward.
- Developer arena mode: a separate Studio run published a waiting arena life with score zero, a frozen character at the Dungeon spawn, and the original loadout UI; lobby admission was absent. Default lobby mode was restored and verified afterward. A command-context `require(F3Lives).roster()` check did not reflect the running script's life state, so the repeat check used the live replicated life attributes instead. Full combat replay remains separate.
- Initial menu and lobby captures rendered correctly. Later captures showed UI over a dark 3D view, but David confirmed on October 23 that Studio renders correctly and that he likes the blurred background. Treat later dark captures as a capture limitation, not evidence of a dark in-game scene. David subsequently signed off L3 gameplay on October 23, 2026.

## Remaining verification scenarios

1. Start with developer arena mode disabled. Confirm the blurred lobby background and Play are clear; click Play and assess spawn view, movement, camera, and queue-pad visibility.
2. Walk onto/off the pad and jump in place. Confirm your position appears once, clears on exit, and returns at the back on re-entry.
3. Run with at least three actual clients. Check identical FIFO order and next pair on each client, leave/rejoin, reset, and disconnect. Two or more players must continue waiting without dispatch in L3.
4. Check the world board's readability and mouse-wheel scrolling with a long queue, and confirm the personal HUD remains readable.

Actual multi-client input/replication, reset-button interaction, long-queue mouse-wheel checks, low graphics, target latency, and reference-hardware performance remain unverified by the agent; owner gameplay acceptance is complete. Studio also emitted asset-type warnings for `rbxassetid://203785492`; no L3 code introduces that asset reference. The intentional lifecycle-fixture spawn failure produces one expected warning during the test.

L4–L8, active hazards, detailed art, mobile/controller gameplay support, 2v2, reserved servers, and publishing are outside this slice. Owner sign-off does not close the outstanding technical checks or authorize L4; await separate authorization before starting the next slice.
