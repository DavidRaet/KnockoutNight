# L2 — Dungeon blockout

**October 23, 2026:** Approved design implemented and technically verified within the limits below. **David signed off L2 gameplay on October 23, 2026, including the decorative support frame. Gameplay acceptance is complete for this slice.** L3, active hazards, final art, 2v2, and publishing remain separate work.

## Owner acceptance

David explicitly signed off the current Dungeon blockout on October 23, 2026, after the support-frame revision. This accepts the current layout and presentation; it does not assert that every manual scenario or outstanding technical check was exercised. Agent visual review, full-match/reuse checks, target latency, low graphics, reference-hardware performance, and multiplayer repetition after the decorative frame change remain separate. Sign-off does not authorize L3, polishing, active hazards, or publishing.

## Approved design and implementation

Dungeon replaces The Ring; its segmented floor and collapse cycles are retired. `ServerScriptService/L2Dungeon.luau` builds a flat 80 × 80 stud square, 4 studs thick, centered at `F1Config.PlatformCenter`, with all four edges open. A stationary 10-stud sphere is centered over the floor with its bottom 8 studs above the surface; eight alternating vertical chain segments establish the placeholder. A metal overhead frame now connects the chain to two posts resting near opposite floor edges. Ball, chain, and frame are anchored with collision, touch, and queries disabled. Only the floor is tagged `F11Playable`.

Opening spawns are ±20 studs along X, facing inward. Each home has five mirrored supported respawn candidates. The existing central emergency fallback, spawn safety checks, protection, scoring, and round reset are retained. Arena attributes give the lives system a lower plane 25 studs below the floor top and a finite outer radius covering the square's corners plus the existing recovery margin. No combat or hazard subsystem changes are needed.

`F1Config.Arena = "Dungeon"` selects this map for the current local 1v1 launch. `"SkyBridges"` and `"ThePlatform"` remain supported. Geometry is generated on Play, following the existing arena pattern. Map voting and transitions remain L5. Detailed stonework, enclosing walls, props, lighting polish, moving ball behavior, and all additional dungeon hazards require a later approved milestone. No Blender assets or exports were created.

## Technical verification

Run `./tests/run_l2_checks.ps1` from the project root. It runs the existing L1/F2–F11 checks, formatting, lint, and compilation; engine specs require Studio. The existing lives fixture accepts a builder argument, and the existing two-client match fixture accepts `test = "L2Match"` and uses the configured arena, avoiding duplicated lifecycle fixtures.

| Check | Result |
| --- | --- |
| Existing deterministic regressions | 590 passed |
| Formatting, Selene, Luau compilation | Passed; zero lint errors or warnings |
| Dungeon engine geometry | 140 assertions passed after support-frame revision |
| Isolated current-source lives fixture | 21 assertions passed |
| Two real Studio clients | 22 assertions passed before decorative support-frame revision; no client script errors |
| Source comparison and cleanup | All 29 local runtime sources match Studio; five temporary fixtures removed; Studio returned to Edit |

[Evidence](../../evidence/L2Dungeon.json) records geometry/lives assertions and multiplayer results. Geometry checks cover dimensions, mock clearance and interaction flags, full spawn support, inward facing, open edges, square corners within bounds, and lower-plane elimination. The isolated lives fixture covers protected home respawns, duplicate elimination rejection, central fallback, round reset, and visible failure when no safe spawn is available. It intentionally emits the existing unsafe-spawn warning. Two clients exercise staging, mixed loadouts, GO, exactly one opposing point per fall, protected home respawns, matching match snapshots, and the default 16-stud camera distance at 1607 × 873.

The clean final Play run reports the pre-existing `rbxassetid://203785492` asset-type mismatch and no new script error. Studio screenshots show a blank 3D viewport, so agent visual presentation and camera readability review remain unverified. Full regulation/results/reuse, target latency, low graphics, reference-hardware performance, and 2v2 were not tested. A full Roblox type analyzer is not installed. Automated evidence does not establish owner gameplay acceptance.

To repeat engine checks after local checks and source comparison/sync, temporarily install `tests/L2Dungeon.spec.luau`, `tests/L1Lives.spec.luau`, and generated `.tools/L1HarnessLives.luau` as ServerStorage ModuleScripts. In Play's Server context, run the geometry spec and call the lives spec with the generated harness and `require(game.ServerScriptService.L2Dungeon).build`. For two clients, temporarily install `tests/L1Match.server.luau` and `tests/L1Match.client.luau` as `L1MatchFixture` in ServerScriptService and StarterPlayerScripts, then run `StudioTestService:ExecuteMultiplayerTestAsync(2, {test = "L2Match"})` in Edit. Remove fixtures and compare runtime sources afterward.

## Owner playtest checklist (retained for regression testing)

Start Server & Clients with two players, select loadouts, and use the developer Start control (or `require(game.ServerScriptService.F4Match).begin()` in the server Command Bar). Judge combat spacing, edge readability, the suspended mock, and camera visibility. Walk beneath the ball, fight near edges, and check protected home respawns after falls. L2 gameplay was accepted October 23, 2026; use these checks for later regression testing.

**Support-frame follow-up — October 23, 2026:** David approved the map’s appearance and requested visible support for the hanging ball. Two 28-stud posts at X ±38 rest on the floor and support a 78-stud beam meeting the top chain link. The frame is decorative and does not affect movement, combat, or camera queries. All 590 offline regressions and 140 geometry assertions passed; no new runtime errors appeared. The pre-existing asset-type mismatch persists. Multiplayer was not repeated for this decorative change. David subsequently signed off L2, including the updated frame, on October 23, 2026. Gameplay acceptance is complete; the recorded technical limitations remain open.
