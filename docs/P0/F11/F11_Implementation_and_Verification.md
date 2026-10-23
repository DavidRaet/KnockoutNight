# F11 — Perform Aerial Ground Slam

Implemented and technically verified within the limits below on **October 23, 2026**, for the current local 1v1 prototype on The Platform. **David signed off F11 gameplay on October 23, 2026, at the current nine-stud radius and 55 horizontal / 13 upward studs/s launch tuning.** No other slice, map, 2v2, polish, asset generation/export, or publishing is included.

## Behavior and integration

An accepted Q Bounce grants one server-owned opportunity. Landing, an incoming weapon hit, character/equip cleanup, or elimination expires it. Ordinary jumping/falling cannot grant it. Hammer's first eligible primary consumes it and starts Ground Slam. The existing 0.15-second primary delay rejects early input without buffering. Slam never changes Bounce's cooldown or spends it again.

`F11Slam` defines the approved 0.25-second Hammer-raise telegraph, minimum 90 studs/s downward velocity, nine-stud radius, 55 horizontal / 13 upward replacement launch, and 0.65-second landing recovery. Descent preserves horizontal momentum with steering acceleration limited to eight studs/s². Gravity continues through telegraph and descent; there is no upward boost or hover. The existing temporary Hammer proxy visibly raises above the root and lowers for recovery; impact displays a short nine-stud-radius disc.

`F2Combat` owns the action and server physics drive. `F2SpringFist.resolve` allows incoming hits against an armored slam while preventing startup cancellation until landing. Weapon reaction temporarily replaces the drive; descent resumes on the incoming horizontal trajectory after reaction, without restarting telegraph. Gust and Magnet retain their existing displacement and protection rules. Landing clears downward velocity and settles the feet on the verified surface before restoring the motor and client ownership. Recovery rejects attacks and abilities; the player remains vulnerable to incoming launch and ring-out.

The existing movement budget includes the limited slam steering. A consumable 18-stud vertical replication allowance expires after 0.2 seconds when taking ownership from ordinary Bounce flight. This accommodates the authorized launch's replication burst; it cannot replenish each frame. An explicit excessive-teleport check still produces a correction. Character retirement, death, departure, fresh-match, and round reset use existing action/displacement teardown. No new remote or client-authoritative landing decision is added.

`F1Prototype` marks only The Platform's generated surface with `F11Playable`. `F2Contact` requires a currently present, collidable, tagged top with upward normal at least 0.95. Downward support checks account for the previous root height so fast descent can cross the contact boundary between updates. Character bodies are excluded. Untagged scenery, sides, undersides, void, and removed surfaces cannot impact.

Shockwave targets must be enemies within nine horizontal studs, with support no more than two studs below their expected feet and within two studs of impact elevation. At F11 sign-off, targets had to stand over the **same surface instance** as the landing. The subsequently approved [L1 Sky Bridges implementation](../../P1/L1/L1_Implementation_and_Verification.md) permits continuous supported floor across island/bridge Part seams. A clear ray above the surface and quarter-stud support samples still reject obstruction and gaps; sub-quarter-stud gaps remain a sampling limitation. The shared resolver applies protection, records each encountered enemy once, and uses radial launch with committed horizontal facing as the exact-center fallback. There is no ordinary Hammer sweep during slam and no direct-hit stacking.

## Conflicts reconciled

- The PRD still listed 96/180 Bounce launch and pending F10 owner acceptance. Its implementation entry and tuning table now reflect the signed-off **48/90**, accepted October 23, 2026. `F10Bounce` behavior did not change.
- `F10Runtime.spec` still asserted 96/180 after the tuning changes. Expectations now match 48/90. Its Hammer aerial-primary case now acknowledges F11 selection instead of describing that input as an ordinary aerial swing.
- Roadmap statements that F11 remained unauthorized/unimplemented are superseded by the explicit F11 request. Later slices and release gates remain separate.
- Studio comparison found pre-existing text/encoding differences in `F4Rules`, `F4Match`, and `F3Client`. Checked local sources were synced as required; those local files have no F11 diff.

## Technical verification

Run `./tests/run_f11_checks.ps1` from the project root. It runs the existing F2–F10 suites, F11 rules, formatting, lint, standalone compilation, and the current-source isolated combat harness build.

| Check | Result |
| --- | --- |
| Offline deterministic checks | 590 passed: 579 F2–F10 regressions plus 11 F11 rules |
| StyLua, Selene, Luau compilation | Passed; zero lint errors/warnings |
| Isolated R15 F11 engine fixture | 125 assertions passed |
| Current-tuning Bounce engine regression | 74 assertions passed |
| Magnet engine regression | 50 assertions passed |
| One live client using actual keyboard Q and mouse click | 12 server assertions passed |
| Client presentation probe | Hammer height rose through telegraph to four studs above root; exactly one impact event |
| Final source comparison / cleanup | All 27 runtime scripts match Studio; six temporary test scripts removed; Studio in Edit |

[Raw evidence](../evidence/F11Slam.json) records engine assertions, live physics samples, client presentation samples, regressions, and an earlier live attempt. `F11Runtime.spec` uses the existing generated harness with synthetic roster/remotes and a controlled clock; the live fixture uses production scripts, input, remote, physics, and ownership. The one-client fixture temporarily provides an active-match gate and snapshot, then restores staging. It does not establish two-player match behavior.

Engine checks cover eligibility, opportunity consumption/expiry, early-click rejection, timing boundaries, retained momentum and limited steering, armor during actual weapon startup contact, weapon/Gust/Magnet redirection and resumption, protected targets, once-only effects, friendly exclusion, exact-center launch, landing recovery, movement validation, and elimination/retirement cleanup. Geometry checks include valid tops, scenery, sides, undersides, character tops, disappearing surfaces, range/elevation, an upper floor, walls, and separate islands.

The first successful live probe exposed a `vertical-reset` correction at Bounce-to-slam ownership transfer. The expiring consumable handoff allowance fixes that case; the final live rerun logged no movement corrections or project runtime errors. Landing handoff also now clears downward velocity. Engine tests intentionally exercise the excessive-teleport correction and the existing displacement failsafe, so their warning messages are expected. The unrelated `rbxassetid://203785492` asset-type mismatch remains visible in Studio Output.

Two-live-client replication, 100–150 ms RTT, adversarial ownership timing under latency, and complete regulation/countdown/sudden-death matches with F11 were not run. Existing match gates/reset operations and their offline regressions pass; isolated retirement checks are not full-match verification. A full Roblox type analyzer is not installed; standalone compilation and lint passed. Reference-hardware performance and final art remain unverified. David's gameplay acceptance is recorded separately below; it does not close the remaining technical verification items.

To repeat Studio checks, first run the local suite and compare/sync all runtime sources. Install the generated `.tools/F9HarnessCombat.luau` as `ServerStorage.F11Harness`, and the runtime specs as `ServerStorage.F11Runtime`, `F10Runtime`, and `F9Runtime`. In Play's Server VM, call `require(game.ServerStorage.F11Runtime)(require(game.ServerStorage.F11Harness))`, and similarly for the regressions. For the one-client input probe, temporarily install the paired `F11Live` server/client scripts and set the server script's `F11Verification` attribute before Play; press Q then click after the primary delay. Read their `Result` attributes. Remove all probes and compare sources again afterward.

## Owner gameplay checklist (retained for regression testing)

1. Start Server & Clients with two clients. Select **Wrecking Hammer + Bounce**, start the local match, and wait for GO. Press Q, wait at least 0.15 seconds, then click while airborne. Judge telegraph readability, retained momentum, steering, impact radius, and recovery.
2. Try an early click without clicking again, an ordinary jump attack, and landing before clicking. These must not produce a slam. After a successful slam, try attacking/Bouncing during recovery and confirm Bounce's original cooldown continues.
3. Use the opponent's weapon, Gust, and Magnet to redirect the slam. Judge the reaction and resumed descent; test edge redirection/ring-out. Avoid the landing area, then punish recovery.
4. Check nearby versus distant/elevated/covered opponents, death/respawn, and a tied round reset. Report gameplay acceptance or requested F11 corrections.

**Owner acceptance — October 23, 2026:** David confirmed that F11 looks good for now and explicitly signed off the current local 1v1 Platform prototype, including the nine-stud radius and 55/13 launch tuning. Gameplay acceptance is complete for this slice. Remaining technical checks and milestone/release gates stay open. No automatic polishing, later slice, or publishing is authorized.


## Owner tuning follow-up — October 23, 2026

David requested a slight increase in blast radius and knockback. Radius increases from 8 to **9 studs**; replacement launch increases from 50/12 to **55 horizontal / 13 upward studs/s**. Timing, steering, armor, and Bounce cooldown behavior are unchanged. All 590 offline checks, formatting, lint, compilation, and the harness build pass. The updated engine suite passes 126 assertions, including an enemy at 8.5 studs and the revised launch. [Tuning evidence](../evidence/F11SlamTuning.json). All 27 runtime sources match Studio; temporary probes are removed and Studio is in Edit. The earlier live-client probe and original evidence above describe 8 studs and 50/12; that live probe was not repeated for this tuning. David signed off this tuning and F11 gameplay on October 23, 2026. Remaining technical verification and release gates are separate.
