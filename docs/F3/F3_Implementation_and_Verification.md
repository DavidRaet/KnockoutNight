# F3 — Fall, score, and safely respawn

**Date:** October 22, 2026. **Status:** Implemented, technically verified, synced to the connected Knockout Night Studio place, and signed off by the product owner on October 22, 2026.

## Approved decisions

The owner approved F3 interview Q1–Q7 and authorized implementation after confirming the shared design:

- Check normal spawn candidates during the 3-second countdown. At the deadline use the designated permanent-surface fallback if no normal candidate is valid. If the fallback is also unsafe, stop the local session with a clear error; never invent another elimination, score, or winner.
- Among valid candidates, maximize the minimum horizontal distance from living opponents. Rotate exact ties. Occupied or unsupported positions are ineligible.
- Recreate the standardized R15 character each life, retaining compatible appearance. Score and future ability cooldown ownership remain outside the character lifetime.
- Use a visible shield for the provisional 3-second respawn protection. Movement remains available; an accepted attack ends protection before its action starts. Falling still eliminates.
- Follow the fall for approximately 0.75 seconds after commitment, then follow a survivor until respawn. With no survivors, use a fixed arena view.
- F3 presents 1v1 score, knockout notifications, and respawn countdown. Regulation timer, results, and sudden death belong to F4/F5.

## Implementation

- `ServerScriptService/F3Lives.luau` owns player life identifiers, single elimination commitment, score, attribution, countdowns, safe-point selection, protection, and terminal spawn failure. Character callbacks carry their original life identifier. Departure removes the record without committing an elimination.
- `ServerScriptService/F1Prototype.server.luau` retains the circular greybox and standardized character setup. It caches compatible avatar models once per player, then clones locally for respawns. Initial starts remain symmetric at ±18 studs on X. Eight normal candidates sit 18 studs from center; the emergency candidate is at center.
- `ServerScriptService/F2Prototype.server.luau` advances lives before combat in one server simulation callback. Combat requests also check current life eligibility, so input cannot bypass an already-crossed elimination boundary between updates.
- `ServerScriptService/F2Combat.luau` retires eliminated characters, ends spawn protection at accepted attack activation, and records successful displacement attribution. The shared contact resolver consumes a shielded contact without displacement, interruption, or timer extension.
- `StarterPlayerScripts/F3Client.luau` presents score, avatar portraits with text fallback, capped knockout notifications, countdown/error state, and spectator target selection. The existing F1 camera retains clipping checks and returns to the newly spawned character. The default player list is hidden while this HUD owns the score area and restored on teardown.
- `ReplicatedStorage/F3Config.luau` holds the provisional times and bounds. The Platform top is Y=42, so the lower plane is Y=17; horizontal fallback bounds are radial at 95 studs from center. Passing the horizontal arena edge remains recoverable above the lower plane.

Safe placement checks the support footprint, upward-facing collidable arena surfaces, available surface/marker flags, a clear character-sized volume, and separation from other living characters. Countdown samples are never permission to use a stale position: geometry and occupancy are rechecked at the deadline. F3 uses `F3SpawnAvailable=false` to exercise unavailable markers/surfaces; later arena slices must connect their hazard ownership to this contract.

## Verification

| Check | Result |
| --- | --- |
| StyLua, Selene, standalone Luau compilation | Passed for the changed runtime and fixture scripts; zero lint warnings/errors |
| Spring Fist deterministic checks | 28 passed, including shield contact consumption, no stacking, and exact protection expiry |
| F3 deterministic checks | 17 passed: lower/radial bounds, candidate distance/ties, invalid candidates, duplicate/stale life callbacks, countdown commitment |
| F3 two-client lifecycle fixture | 35 passed; [evidence](../evidence/F3Lives.json) |
| Existing F2 two-client combat fixture | 28 passed; [evidence](../evidence/F3_F2Combat_Regression.json) |
| Existing F1 two-client regression | Passed: two standardized R15 rigs, 16 matching body parts, symmetric starts, no body blocking |
| Normal Studio Play | Actual character death advanced life 1 → 2, replaced the character, and installed a visible spawn shield. HUD/portrait/text rendered at 1607×873; the default player list was disabled |
| Studio source readback and cleanup | Runtime sources compared with local files; temporary F1/F2/F3 test scripts removed; Studio returned to Edit |

The lifecycle fixture exercises the real client attack remote, natural Spring Fist launch → fall → point, attribution, horizontal-edge recovery, lower/outer cutoffs, duplicate death callbacks, stale input, respawn timing, farthest safe point, blocked shield contacts, shield cancellation/expiry, falling while protected, emergency center spawning, simultaneous falls/respawns, survivor/no-survivor camera, replicated scores/feed/countdown, actual disconnect, and bounded failure when the fallback surface disappears.

An early fixture sampled UI state before the client presentation frame had processed replicated life state. It now waits for the expected client status, a render frame, and 0.05 seconds before inspecting UI. The final lifecycle run passes with those presentation checks retained. Existing Studio plugin icon/legacy avatar asset warnings still occur; they are not F3 script exceptions.

## Reproduce technical checks

Run from the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_f3_checks.ps1
```

The runner uses the existing `.tools/RobloxChecks` executables, runs the F2 checks, and adds F3 formatting/lint/compilation/rule tests. It introduces no dependency.

For the engine fixture, temporarily sync `tests/F3Lives.server.luau` into ServerScriptService as a Script named `F3LivesFixture` and `tests/F3Lives.client.luau` into StarterPlayerScripts as a LocalScript with the same name. **Do not overwrite the runtime F3Lives ModuleScript.** Run `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="F3Lives"})`, then remove both fixtures. Run the F1/F2 fixtures separately with their existing test arguments; keep distinct fixture names to preserve runtime modules.

## Owner gameplay review

Start a two-client local Studio session:

1. Knock the opponent off near the edge, then walk off yourself. Confirm the opposing score increases once for each committed fall, and the feed distinguishes the successful Fist hit from an environmental fall.
2. Watch the fall, survivor camera, countdown, and return to your new character. Judge whether the 0.75-second transition and 3-second respawn feel readable.
3. Move during the shield, take an enemy punch, and then attack. Confirm movement works, the protected punch does not launch you, and your attack removes the shield. Let another shield expire naturally; walk off while protected.
4. Reset your avatar once and confirm one point and one respawn. Have both players fall together; confirm the temporary fixed arena view and separate respawn positions.

The product owner reviewed F3 and signed it off on October 22, 2026 (“F3 looks good for now”). The gameplay review checklist above remains available for future feedback; F4 is now the next roadmap slice.

## Limits

- This remains the developer-controlled local 1v1 slice on The Platform. Extra players get a waiting message; FIFO queues, 2v2, complete matches, departure outcomes, and lobby recovery arrive in their roadmap slices.
- Abilities are not implemented yet. Death-persistent ability cooldown behavior and ending protection on ability activation must be integrated and exercised in F8–F10. F3 does not add an unused ability/cooldown subsystem.
- The new F3 fixture ran at ordinary local conditions. The existing F2 delayed evidence remains separate; this run does not establish F3 behavior at 100–150 ms RTT, low graphics, broad viewport/hardware coverage, or 60 FPS.
- Full standalone Roblox type analysis remains unavailable. Compilation and live execution passed; they do not substitute for that analysis.
- No publishing, asset generation, or asset export occurred.
