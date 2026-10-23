# L1 — Build Sky Bridges

**October 23, 2026:** Approved design implemented and technically checked. **David signed off L1 gameplay on October 23, 2026.** L2 and later slices, publishing, final art, and 2v2 are separate work.

## Owner acceptance

David explicitly signed off the current L1 Sky Bridges implementation on October 23, 2026. Gameplay acceptance is complete for this slice. This records acceptance of the current layout and behavior; it does not claim that every manual scenario or outstanding technical check was exercised. Agent visual review, low-graphics and viewport coverage, full-match/reuse verification, target latency, and the documented slam sampling limit remain separate. Sign-off does not authorize L2, polishing, or publishing.

## Approved design

- One 50-stud central island and two 30-stud side islands, level and symmetric between the players. The center supports the main fight; sides provide escape and alternate approaches. This role remains a playtest hypothesis.
- All three connections have 12-stud-wide bridges and approximately 25 studs of open distance between island edges. Bridges overlap curved shores at their full width, so their actual part lengths are approximately 27.5/28 studs. No essential route requires jumping or Bounce.
- Players start at opposite side-island centers, facing the center. Each home island has five supported respawn candidates. The existing central emergency fallback is retained if the home pool is unavailable; an unsafe fallback stops the session visibly rather than placing a player unsafely.
- Open edges and no active hazards. Simple stone islands/bridges, floating rock undersides, broken columns, and cloud shapes establish the theme. All scenery is noncollidable and excluded from queries/touches, so it cannot catch falls, block attacks, or shorten camera distance.
- Retain the approved player-focused camera. Slam crosses supported island/bridge seams within normal range and elevation limits; an intervening gap or obstruction rejects the target.

## Implementation

`ServerScriptService/L1SkyBridges.luau` builds the native-part map at `F1Config.PlatformCenter`. No external assets, Blender files, or exports are needed. `F1Config.Arena = "SkyBridges"` selects it for the current prototype launch; `"ThePlatform"` retains the original arena. Geometry is generated when Play starts, following the existing Platform pattern. Map voting and arena transitions remain L5 work.

`F1Prototype` supplies initial frames and home identifiers to the existing lives system. `F3Lives` reads server-owned arena bounds, filters respawn candidates by home, and retains existing support/clearance/opponent checks, spawn protection, emergency fallback, and failure handling. Platform keeps its existing bounds and unrestricted candidate selection. Sky Bridges uses the same lower fall plane as Platform and a larger outer radius encompassing every island and bridge. Falling through the triangle interior therefore uses the same elimination/scoring path as an outer-edge fall.

`F2Contact.slamTarget` no longer requires the victim and impact to share a single Part. Its existing playable-top, range, elevation, obstruction, and quarter-stud support checks remain. `F2Combat` and the F11 fixture use the simplified call. The sampling limitation is documented in code: gaps thinner than a quarter stud may escape detection. This map's route seams intentionally overlap; its tested shoreline and island gaps reject slam.

## Technical verification

Run `./tests/run_l1_checks.ps1` from the project root. It includes all existing F2–F11 deterministic suites, formatting, Selene, Luau compilation, and generated combat/lives fixtures. It does not execute engine-dependent specs automatically.

| Check | Result |
| --- | --- |
| Existing deterministic regressions | 590 passed |
| Formatting, lint, standalone compilation | Passed; zero lint errors/warnings |
| Sky Bridges engine geometry/contact checks | 158 assertions passed |
| Current-source lives fixture with two synthetic participants | 21 assertions passed |
| Slam / Bounce / Magnet engine regressions | 128 / 74 / 50 assertions passed |
| One live client walking all three routes | 9 assertions passed; no jumping, Bounce, or seam drop |
| Two real Studio clients | 22 assertions passed |
| Source synchronization and temporary fixture cleanup | 28 runtime sources compared; final result recorded in raw evidence |

[Raw evidence](../../evidence/L1SkyBridges.json) records each assertion and traversal samples. Geometry checks sample the full bridge width at half-stud intervals, verify every spawn's five support rays, cross each island/bridge seam with slam, and reject shots cutting across actual concave shoreline void. The isolated lives fixture exercises home pools, emergency fallback, protection, lower-plane elimination, round resets, duplicate elimination, and bounded failure.

The traversal fixture uses the existing Studio study-input hook with the ordinary live Humanoid motor. It walks the three routes at normal speed and records root height; it does not replace a player's control/feel assessment. The two-client fixture uses normal production countdown, lives, match state, and scoring: both clients start on opposite islands, reach GO, receive one opposing point per fall, respawn at home with protection, and agree on the match snapshot. Both report no script errors at 1607×873 and retain the default 16-stud camera distance.

The isolated failure-path and combat fixtures intentionally emit the existing unsafe-spawn, excessive-movement correction, and displacement-cleanup warnings. Clean live traversal and the later clean Play run report only the pre-existing unrelated `rbxassetid://203785492` asset-type mismatch. An initial traversal probe invoked through the command executor did not share the production module state; the successful probe ran as a normal temporary server Script instead. No production change was required for that probe issue. A temporary two-client fixture's unused import was removed and the full local suite and multiplayer run passed again afterward.

Studio screen capture returned blank frames on all attempts. Camera configuration, distance, and scenery query exclusion were checked, but visual readability, presentation, low-graphics behavior, and broad viewport coverage are **unverified**. No full regulation/results/reuse sequence or latency matrix was repeated for L1. A full Roblox type analyzer is not installed. Technical checks do not establish gameplay acceptance.

## Repeat engine checks

After local checks and source comparison/sync, temporarily install these ModuleScripts in ServerStorage: `L1SkyBridges.spec` as `L1SkyBridgesSpec`, `L1Lives.spec` as `L1LivesSpec`, generated `.tools/L1HarnessLives.luau` as `L1HarnessLives`, and generated `.tools/F9HarnessCombat.luau` plus the F11/F10/F9 runtime specs for combat regressions. In Play's Server context, invoke each spec and inspect its returned result. The lives and combat specs accept their respective generated harness as an argument.

Run `tests/L1Traversal.luau` through a normal temporary server Script after a real player is admitted. For two-client checks, install `tests/L1Match.server.luau` and `tests/L1Match.client.luau` as temporary `L1MatchFixture` scripts in ServerScriptService and StarterPlayerScripts. In Edit invoke `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="L1Match"})`. Remove all fixtures afterward, compare runtime sources, and return Studio to Edit. The legacy F3 world-specific fixture requires `Arena = "ThePlatform"`; it is not a Sky Bridges fixture.

## Owner playtest checklist (retained for regression testing)

1. Start Server & Clients with two players. Choose varied loadouts and use the existing developer Start control, or call `require(game.ServerScriptService.F4Match).begin()` in the server Command Bar. Wait for GO.
2. Walk all three bridges, pass/dodge an opponent, pursue from the center, and escape along the side route. Judge width, route usefulness, opponent visibility, and camera behavior.
3. Fight near bridge and island edges. Check ring-out readability, one opposing point per fall, safe home respawns, and protection. With Hammer + Bounce, test slam across a bridge seam and beside a shoreline gap.
4. Report regressions or requested refinements. L1 gameplay was accepted October 23, 2026; later changes, L2, and publishing require separate authorization.
