# F2 Order 5: Spring Fist implementation

October 21, 2026. The temporary Spring Fist slice implements the [approved outline](F2_Order4_Implementation_Outline.md). Order 6 combat acceptance remains open. Nothing was published, modeled, or exported.

## Implementation

| File | Responsibility |
| --- | --- |
| `ReplicatedStorage/F2Config.luau` | Approved action, volume, launch, protection, buffer and presentation parameters |
| `ReplicatedStorage/F2SpringFist.luau` | Deterministic timeline, input eligibility, aim validation and contact ordering |
| `ServerScriptService/F2Contact.luau` | Actual R15 body collision geometry, initial overlap, continuous box casts, wall cap and exposed-region checks |
| `ServerScriptService/F2Combat.luau` | Request validation, generations, action/buffer state, contact collection/resolution, temporary ownership, recovery, movement correction and cleanup |
| `ServerScriptService/F2Prototype.server.luau` | Starts and shuts down the combat path |
| `StarterPlayerScripts/F2Client.luau` | Immediate local prediction, reconciliation, glove/extension/debug volume, confirmed impact/protection cues and motor restart |
| `StarterPlayerScripts/F1Controller.local.luau` | Fresh mouse presses, existing focus gates, committed horizontal facing and combined movement/jump restrictions |

Every F1 character starts with the temporary fist equipped. Server code may set its `F2Equipped` attribute false/true; each change issues a new generation and invalidates the old action and buffer. This is a single-weapon prototype, without an inventory or ability framework.

The inspected standardized R15 upper torso center is 0.19998 studs above the root. `StrikeHeight = 0.20` aligns the glove and gameplay volume to that center. The active glove occupies the authoritative 4 × 5 × 2 box. Startup is yellow, active red, recovery muted blue, protection cyan, and confirmed impact flashes white. Set `workspace:SetAttribute("F2DebugVolumes", true)` to show the translucent active overlay. Visual parts are local, anchored, noncolliding, nontouching and nonqueryable.

The server uses its current clock and observed positions. It processes elapsed active intervals across slow frames, consumes each encountered victim once, resolves candidates before applying launches, and orders incoming hits by reconstructed contact time, action ID and UserId. Startup interruption and active trades share that resolver. Buffered startup rechecks eligibility and reads the latest validated aim. Input never carries a target, hit result, trusted timestamp or launch value.

Displacement reuses the physics study's steering, minimum duration, recovery-speed checks and burst/slack budget. The live path always takes server ownership before assigning replacement velocity, preserves the original motor state across replacement launches, distinguishes departure from the initial floor, and logs the 1.5-second failsafe as cleanup. A release also supplies a generation/displacement-checked pose and velocity snapshot: delayed tests exposed older client poses resuming at handoff. Reaction, protection and physical recovery remain separate.

Server teleports must call `require(game.ServerScriptService.F2Combat).resetMovement(player)` after moving the character. Ordinary violations restore the last accepted transform, stop velocity, briefly retain server ownership and invalidate the previous damaging sweep. There are no automatic kicks or bans. The F1 multiplayer fixture now resets this history after its deliberate overlap teleport.

## Verification

Evidence is recorded in [`../evidence/F2SpringFist_Order5.json`](../evidence/F2SpringFist_Order5.json), including failed development checks rather than only passing runs.

| Check | Result |
| --- | --- |
| Standalone deterministic action checks | 25 passed: exact phase/buffer boundaries, slow updates, stale volumes, malformed aim, startup interruption, active trades, multiple targets, contact ordering and protected-contact consumption |
| Engine geometry checks | 19 passed: point blank, forward/side/height limits, limb-only overlap, full-window extension, attacker movement and airborne placement, current target pose, thin/full/edge/corner obstruction, partial exposure, wall-stop persistence and accessory exclusion |
| Two-client combat fixture | 28 checks passed at ordinary conditions and measured target latency: real client request/prediction path, launch assignment, ownership, travel, natural recovery, restrictions, trades, buffer/latest aim, and equip generations |
| Target latency on final handoff run | Both clients measured 116.38–117.26 ms RTT with 40 ms inbound/outbound simulation applied to each client process |
| Prediction/feedback diagnostics on final delayed run | Attacker prediction/start mismatch about 48.47 ms; acceptance age about 67.97 ms; confirmed impact arrival about 53.14–77.21 ms after reconstructed server contact. These are observations, not acceptance thresholds |
| Existing helpers | Nine F1 movement/jump assertions and the F2 physics helper spec passed |
| F1 multiplayer regression | Two matching R15 rigs, 16 body parts, symmetric spawns and no character blocking passed |
| Actual mouse/keyboard observations | Each 1.1-second held click produced one accepted action; WASD moved both players; an actual click launched the opponent; W walking resumed after recovery without jumping; disabled gameplay and the Roblox menu blocked attacks |
| Offline checks before sync | StyLua check and AST-verified formatting, Selene with zero errors/warnings/parse errors, standalone Luau compilation and deterministic tests passed |
| Full standalone Roblox type analysis | Not established. The downloaded analyzer lacks the Roblox type environment and reports unknown `Vector3`; compilation and live execution are separate evidence |

An early fixture used exact equality against a float property; that check was corrected to use tolerance. Another sampled launch velocity after collision response; pre-simulation traces establish the actual assignment of 50 horizontal / 12 upward. One earlier delayed run failed the final-displacement check. Repeated traces showed handoff pose rollback, prompting the authoritative release snapshot; the subsequent target-latency run passed. This is not proof that all network handoff artifacts are eliminated.

The separate actual-input session reached its bounded safety timeout before subsequent text-focus and jump probes. Its successful observations are recorded separately from the passing automated combat suite. The idle two-player viewport was inspected at 1719 × 873; this does not establish active animation readability or owner acceptance.

## Repeating the checks

Run `powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_f2_checks.ps1`. It uses the existing temporary Selene/StyLua tools and standalone Luau binaries under `%TEMP%/KnockoutNight-F2Checks`; it adds no project dependency. Pass `-Tools` to use another check-tool directory. The runner compiles changed sources and executes the actual shared timeline/selection code, with only the config's unused engine vector constructor stubbed for the standalone pure tests.

For engine checks, temporarily sync `tests/F2SpringFist.spec.luau` and `tests/F2Contact.spec.luau` as ModuleScripts in ServerStorage. Call the first with `F2SpringFist` and `F2Config`, and call the second without arguments. Remove temporary modules afterward. Restart or clone test modules when rerunning after edits to avoid cached `require` results.

For combat, temporarily sync `tests/F2Combat.server.luau` into ServerScriptService and `tests/F2Combat.client.luau` as a LocalScript in StarterPlayerScripts. Run `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="F2Combat"})`. For delayed checks add `waitNetwork=true`, configure both spawned client processes, and set `F2CombatNetworkReady=true` in the test server. Measure ping/pong RTT; parent Studio settings alone do not configure the clients. Restore client simulation settings before the session exits. Remove both fixture scripts afterward.

## Limits and remaining Order 6 work

The moving box is continuously cast through the sampled attacker segment against current target collision geometry. Target history is not rewound. Curved motion between samples and targets that enter and leave entirely between updates cannot be reconstructed. Exposed-region search uses closest-surface projections and a 0.25-stud grid; tiny exposed slivers and obstruction-dependent contact ordering remain approximation limits to refine if combat checks expose misses. Previously traversed space stays harmless.

The automated checks do not establish owner acceptance of readability, punishable misses, camera/control feel, spacing, or prediction correction under load. Record hands-on combat with both players in each role. Broaden integrated checks for wall/airborne/edge recovery, limited steering and immediate walking after a hit, repeated replacement launches, forced failsafe cleanup, death/respawn/departure, sustained malformed/spam traffic, real menu/text/focus lifecycle, and low-rate moving-target/partial-exposure cases. Deterministic/helper coverage is identified separately from live combat coverage above.

Movement validation is a prototype budget and discontinuity guard, not a certification against flight or wall traversal. Reference-hardware performance, larger rosters, final art, scoring, safe respawn/respawn protection, other weapons and publishing remain outside this slice.
