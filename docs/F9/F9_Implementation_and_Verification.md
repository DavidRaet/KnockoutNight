# F9 - Pull with Magnet

Implemented October 22, 2026. **Owner gameplay acceptance: signed off by David on October 22, 2026.** Scope: local 1v1 on The Platform. F9 does not authorize another slice or publishing.

## Behavior

Q now activates Magnet for both players. This supersedes the F8 prototype's temporary default-Q binding; no ability picker was added. Gust's server/client implementation and separate cooldown remain available for technical regression fixtures.

| Setting | Value |
| --- | --- |
| Cooldown | 12 seconds from accepted activation |
| Startup / recovery | 0.12 / 0.20 seconds |
| Target root range / full cone | 20 horizontal studs / 60 degrees |
| Body overlap band | 5 studs high, centered on the user's root |
| Pull | 28 horizontal studs/second for at most 0.55 seconds |
| Stop distance | 3 horizontal studs from the user's current root position |
| Target protection | From pull start until the later of completion or 0.35 seconds after start |
| User movement | Normal movement and jumping; no weapon overlap |
| Target response | No steering/jumping during pull; weapons and otherwise-valid abilities remain available |

`F9Magnet` holds the profile and deterministic selection/speed helpers. `F2Combat` validates requests through the existing generation, monotonic sequence, finite horizontal aim, traffic, alive/equipped, match, action, and reaction gates. Aim locks at acceptance. The server checks current target geometry after startup, ranks eligible opponents by alignment, distance, then ascending Player UserId, and never accepts a nominated target. `F2Contact` reuses Gust's R15 body overlap and solid obstruction checks with the Magnet profile. Cone comparisons allow a 1e-7 dot-product tolerance for engine Vector3 boundary precision.

The ordered shared resolver cancels Magnet when a weapon contact precedes its startup boundary, including contacts collected in the same update. A Magnet contact does not cancel the target's existing attack or add hit reaction. Its protection blocks later displacement/interruption; the user receives no protection. A later hit on the user leaves the separate pull state running.

Pulling uses server-owned, velocity-driven physics, preserving current vertical velocity. Each simulation update follows the user's current position, clamps the final frame to remaining duration/stop distance, checks physical body/root casts against solid geometry, and ends on a blocked path or stalled horizontal movement. It never teleports the target through a wall. Horizontal pull velocity stops on release; motor state, ownership, attributes, and ordinary movement restore through shared displacement cleanup. Source removal/generation changes, target death, equip changes, match retirement, departure, and shutdown terminate stale pulls. Magnet participates in existing hit attribution as “Magnet.”

Player-owned cooldown ledgers survive death, character replacement, and equip cleanup. Fresh-match retirement, including the existing sudden-death reset path, clears both ability ledgers. Misses and interrupted startup spend the accepted deadline; rejected requests cannot create/extend it.

Temporary feedback consists of inward-moving red/blue magnetic strokes, a brief link on successful pull, a bundled `electronicpingshort.wav` cue, visible shared protection, and bottom-center Q/cooldown/rejection text. Effects are noncolliding and expire automatically or on character cleanup. Assets were not exported or regenerated.

## Technical verification

| Check | Result |
| --- | --- |
| `tests/run_f9_checks.ps1` | Passed: 554 deterministic checks, including 29 F9 checks and 525 F2-F8 regressions |
| StyLua, Selene, Luau compilation | Passed through the chained project runners; zero lint errors/warnings |
| F9 engine geometry | 15 checks passed: inclusive range/cone/upper and lower height boundaries, exclusions, solid/nonsolid obstruction, exposed alternate candidate, non-body exclusion |
| Weapon geometry regression | 79 checks passed: 20 Fist, 27 Hammer, 32 Paddles |
| Isolated engine integration | 45 checks passed with two synthetic players and real R15 physics |
| Single live client presentation | Magnetic cues, loaded bundled sound, cooldown HUD, rejection text, and cue cleanup verified |
| Source comparison/readback | All 25 local runtime scripts compared with Studio; differences synced after checks; temporary fixtures removed after verification |

The engine integration fixture covers staging/invalid/stale/busy/cooldown rejection; miss feedback and spent cooldown; user movement/jumping; exact 28-stud/second server-owned velocity; approximately three-stud stopping; motor/protection cleanup; target startup preservation and new weapon/ability responses; a counterattack hitting the unprotected user; startup interruption without refund; ordinary knockback activation after reaction; protected-target exclusion; source removal, death/respawn persistence and shared round reset; a newly introduced obstacle; airborne gravity; and target-death cleanup.

`tests/build_f9_harness.ps1` generates a temporary copy of the checked combat source under `.tools/`. It substitutes the roster, remote, and clock for synthetic players, always keeps their network owner on the server, and parents the probe to the real Workspace. `F9Runtime.spec.luau` exercises this copy. This is **not** a two-live-client networking test. Existing deterministic tests use the Luau CLI; engine geometry modules and the generated runtime harness are temporary Studio ModuleScripts invoked during Play. Evidence: `docs/evidence/F9Magnet.json`.

The single-client presentation probe injects accepted/burst/rejected events with temporary character attributes to exercise the real client renderer; it does not establish end-to-end multiplayer acceptance. No project script errors appeared during final checks. Studio logged an unrelated asset-type mismatch for `rbxassetid://203785492`.

## Outstanding verification and owner handoff

Two-live-client input/replication and network-ownership handoff, target-latency behavior, and exact physical timing under server stalls remain unverified. Engine physics is sampled at simulation boundaries; the three-stud stop is horizontal, with vertical velocity/gravity preserved. David accepted the current F9 prototype gameplay on October 22, 2026. Later balance/art work and the technical verification gaps remain separate.

1. Start a local server with two players on The Platform. Choose weapons and use the existing developer Start flow.
2. Face the opponent from 6-20 studs and press Q. Confirm inward feedback and up to 15.4 studs of pull travel (the three-stud stop applies when close enough), and the 12-second HUD countdown. Try turning after activation and moving while pulling.
3. As the target, hold movement/jump and counter with left click or Q. Movement/jumping should pause during the pull; valid actions should still work. Try an attack already in startup before being pulled.
4. Try facing away, standing beyond twenty studs, differing elevations, and placing a solid obstacle between players. Misses spend cooldown; blocked/protected targets do not move. Try introducing a wall after pull begins.
5. Hit Magnet's user during startup, then after the pull starts. The first cancels without refund; the second can hit the user while the pull continues. Try close follow-ups against the target's brief protection.
6. Use Magnet airborne, die/respawn during cooldown, and start a fresh match or sudden-death round. Check gravity, cleanup, persisted cooldown after respawn, and reset for a new round.

Owner gameplay review is complete for F9. F10 (Bounce) is the next planned slice and requires separate authorization; polishing, other maps, 2v2, loadout selection, exports, and publishing remain separately gated.

## Earlier range-only tuning (superseded by the pull revision below)

David requested doubling Magnet range: 10 to 20 horizontal studs (+100%). Pull speed/duration, stop distance, cone, cooldown, and protection remain unchanged. Maximum pull travel remains approximately seven studs (28 studs/s × 0.25 seconds), so a target acquired at 20 studs will not necessarily finish three studs away. Range boundary tests and the runtime miss fixture were updated for the new reach. The full 554-check offline suite, formatter, lint, and compilation passed before Studio comparison/sync. Engine integration and geometry results above describe the initial implementation; they were not rerun for this range-only adjustment. Owner acceptance was pending at this earlier tuning step; see the current sign-off below.

## Paddle reach and pull-distance revision

David requested six-stud Paddle Pops reach and a Magnet pull that brings distant targets within that reach. Paddle volume is now 3 wide × 4 high × 5.5 deep, centered 3.25 studs forward (near edge 0.5; front edge 6). Its proxy extension follows the new reach. Magnet keeps its 20-stud targeting range, 28-stud/s speed, and three-stud minimum stop; maximum pull duration increases from 0.25 to **0.55 seconds**, allowing **15.4 studs** of travel. A stationary target starting at 20 studs should finish roughly **4.6 studs** away, before physics/frame variation. Moving users, counterattacks, and obstacles can change the endpoint.

Protection lasts throughout the longer pull, then ends at the later of actual completion or 0.35 seconds from pull start. Early completion trims the initial maximum deadline, so close-range pulls do not grant an unnecessary full 0.55-second shield. The user can act after the original 0.32-second activation action, even while a distant pull is still running; target responses remain available.

Verification: all **555 deterministic checks** pass (30 Magnet checks plus existing regressions), with clean formatting/lint/compilation. The updated engine fixture passes **50 assertions**, including a 19.8-stud target finishing about **4.77 studs** away and a successful six-stud Paddle follow-up after protection expires. All **32 Paddle geometry checks** pass, including mirrored centers and new front edges. Evidence: `docs/evidence/F9PaddlePullTuning.json`. Synthetic-player engine checks are not two-live-client networking or owner gameplay acceptance.

Hands-on check: choose Paddle Pops, face a stationary opponent from 18–20 studs, use Q, then attack after the pull finishes. Also try a close pull and a moving/counterattacking target. David subsequently signed off F9 at this Magnet tuning with the six-stud Paddle integration on October 22, 2026.

## Owner sign-off — October 22, 2026

David explicitly signed off F9. Acceptance covers the current local 1v1 Platform prototype: Q activation, 20-stud/60-degree targeting, 12-second cooldown, 28-stud/s pull for up to 0.55 seconds, three-stud minimum stop, preserved target responses, and the demonstrated six-stud Paddle follow-up. This records gameplay acceptance; it does not claim completion of two-live-client networking, target-latency verification, later balance/art work, or milestone/release gates. F10 remains the next planned slice, awaiting separate authorization. Nothing is published by this sign-off.
