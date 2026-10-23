# F2 Spring Fist physics evaluation

**Status:** Orders 1–3 are complete for the F2 prototype decision. The product owner approved **temporary server ownership during knockback**, with client-owned ordinary movement and return after recovery. The [Order 3 decision](F2_Next_Steps.md#order-3-decision-approved-physics-approach) records transitions, validation policy, evidence, and known limits. [Order 2 measurements and numeric-gate disposition](F2_Order2_Investigation.md#engineering-recommendation) remain recorded without converting failed checks to passes. Combat implementation and acceptance remain outstanding.

This implements the evaluation-first decision from the Spring Fist interview. It does not implement attacks, hit detection, damage, scoring, or combat respawning. [PRD DD02 and section 17](Knockout_Night_v0.1_PRD.md) remain the behavioral source of truth.

For the completed process, outstanding decisions, and ordered handoff to combat implementation, see [F2 Next Steps](F2_Next_Steps.md).

## Experiment

The existing F1 controller has Studio-only hooks for a controlled launch. Without fixture attributes, normal F1 movement remains active. Published clients do not load the study module or honor its attributes. The server/client fixture scripts live under `tests/` and are temporarily installed for testing.

Compare two classic replication candidates:

- `client`: explicitly retain the subject player's network ownership; the server commands a replacement launch and the owning client applies it.
- `server`: temporarily give the server ownership and suspend the Humanoid motor during displacement, then return ownership when the experimental recovery condition is met.

Both use replacement velocity of **50 horizontal / 12 upward studs/s**. The Humanoid motor is suspended during displacement because ordinary movement must not erase the launch. Recovery is independent of the future 0.15-second reaction and 0.35-second protection timers.

The server supplies the pre-launch motor state explicitly. The controller must not infer that state after a delayed disable has replicated. Re-enabling the motor also restarts its locomotion state through Freefall so grounded movement can resume. Automated input overrides also run in unfocused Studio clients; this exception requires explicit fixture attributes and does not apply to ordinary controls.

The starting experiment uses steering acceleration of **3 studs/s²**, minimum flight of **0.12 seconds**, and recovery on landing or horizontal speed at most **18 studs/s** with vertical speed at most **8 studs/s**. These are experimental thresholds, not approved combat balance. A trial timeout restores the motor and ownership even if natural recovery is not observed.

The fixture records server, subject, and observer trajectories at approximately 20 Hz, launch assignment, acknowledgement, first observed movement, ownership transitions, recovery, and correction counts. Client samples are untrusted diagnostics; they do not authorize server outcomes. Original sample rows are `[elapsedSeconds, x, y, z, velocityX, velocityY, velocityZ]`; client elapsed times start when each client receives the trial, so they are not synchronized server timestamps. The October 21 instrumented client fixture appends estimated server time, motor enabled (0/1), and study mode (none/client/server as 0/1/2); the original captures retain their seven-column format.

## Movement validation

- Reject unknown launch modes, malformed requests, requests less than two seconds apart, and all client launch requests during automated trials. Manual launches can target only the requester; the server computes direction and velocity.
- Check finite position/velocity and a horizontal movement budget based on ordinary speed or a server-issued launch. Allow a 0.2-second replication burst plus 3 studs of slack; preserve the launch envelope through the trial to allow residual motion after recovery.
- Correct budget violations to the last accepted transform, stop velocity, take server ownership, and log the event. No kicks or bans.
- Record resisted launches diagnostically. A collision can also stop motion, so lack of movement alone does not justify punishment.

This is an evaluation validator, not a production anti-cheat. It does not prove vertical flight prevention, wall traversal prevention, or secure movement after the fixture ends. Its slack, launch envelope, and recovery rules require further review before reuse in combat.

Ordinary walk/jump and abuse probes remain client-owned in both groups: the server candidate changes ownership only during a launch. The comparison does not test permanently server-owned locomotion.

## Recorded results — October 20, 2026

Test place: **MY PLACE**, place ID **2336816683**. Both players served as subject and observer, under each ownership mode.

| Run | Measured remote RTT | Trials | Result |
| --- | --- | --- | --- |
| [Baseline evidence](evidence/F2Physics_baseline.json) | 31.5–50.3 ms | 44 | Recording and behavior checks passed |
| [Delayed evidence](evidence/F2Physics_latency.json) | 131.6–149.9 ms | 44 | Recording and behavior checks passed |
| [Direct locomotion regression](evidence/F2Physics_locomotion_regression.json) | Approximately 131–136 ms | 12 | Launch → walk → jump passed for both roles/modes |

The delayed profile added 50 ms inbound and 50 ms outbound, with zero configured jitter/loss. The baseline used zero added delay. Each full matrix recorded **zero false corrections** in legitimate scenarios and corrections for **all eight teleport/excess-speed probes**. Each rejected all six automated client launch requests. The helper self-check and original nine-assert F1 movement check passed; F1's separate two-client rig/spawn/collision test also passed after removing the F2 fixtures.

Manual K/L triggers accepted a launch in each mode and restored the client to `Running` with its motor enabled. This verified the controls, not product-owner feel acceptance. All temporary fixture/verification scripts and Edit-time capture objects were removed, and all seven inspected NetworkSettings values were restored to their original zero values. Fixtures remain available under `tests/` for the next review.

The experiment exposed and corrected two integration failures: unfocused test clients initially skipped scripted locomotion; delayed motor-disable replication could corrupt the saved motor state. A focused walk-before-jump regression then required explicit locomotion-state restart. The delayed final matrix also runs walking before jumping so a jump cannot mask that failure.

### Findings that still gate architecture approval

| Idle launch metric | Client-owned | Temporarily server-owned |
| --- | --- | --- |
| Baseline sampled X travel | 14.43–14.81 studs | 6.87–7.87 studs |
| Delayed sampled X travel | 13.90–14.18 studs | 7.08–8.16 studs |
| Deliberate initial-launch resistance | Flagged in both roles, both full runs | Initial launch survived in both roles, both full runs |

Travel is maximum X displacement from the first server sample during the trial, not total path length or an approved balance target. These ranges contain only two idle trials per mode/profile. Both modes assigned the configured launch velocity, but the resulting travel differs substantially. Do not interchange them without reviewing trajectory, recovery, ownership handoff, and perceived fairness. Client ownership allows a compromised owner to resist the commanded launch; the horizontal budget alone does not resolve that weakness. Temporary server ownership protects the initial launch in these probes, but returns movement to a client afterward.

The product owner has completed Order 1 and recorded lag and direction concerns. Acceptable launch-variation tolerances and final physics architecture approval remain open. Passing the basic behavior checks establishes that the experiment works; it does not establish production combat fairness or security. See [Order 2](F2_Order2_Investigation.md) for the saved-evidence replay, repeated experiments, and proposed review thresholds.

## Repeatable checks

1. Allow Script Sync to load `ReplicatedStorage/F2PhysicsStudy.luau` and the updated F1 controller.
2. Temporarily install `tests/F2PhysicsStudy.server.luau` as a Script in ServerScriptService and `tests/F2PhysicsStudy.client.luau` as a LocalScript in StarterPlayerScripts, both named `F2PhysicsStudy`.
3. Run `tests/F2PhysicsStudy.spec.luau` in the Studio Edit context.
4. From a plugin/Edit context run `game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, {test = "F2Physics"})`.
5. Save the returned table as JSON before displaying it; large nested results can be collapsed by the Studio bridge. StringValue chunks must each be smaller than 200,000 bytes.
6. Remove the two temporary fixture scripts afterward. Restore all NetworkSettings values changed for testing.

The default matrix gives each player both ownership modes and covers idle launch, opposing steering, airborne launch, obstruction, deliberate launch resistance, teleporting, sustained excess speed, ordinary jumping/walking, replacement launches, and death/character replacement. Optional `probes` and `repeats` test arguments select a focused repeat. Keep runs within the fixture's 180-second timeout.

Walking deliberately follows the first launch, before jumping, to catch a motor that is enabled but stuck in an inactive locomotion state. Scripted server steering is known at launch; manual review must separately assess input transit and handoff feel.

`passed` means the recorder, required reports, request rejection, and lifecycle assertions completed. `behaviorChecksPassed` separately evaluates the trial's movement/correction checks. Neither means architecture approval. The small movement thresholds only confirm the probe actually ran; they are not fairness or launch-consistency acceptance tolerances.

For hands-on review, install the same fixtures, set `workspace:SetAttribute("F2PhysicsStudy", true)` in Edit, and start a two-client session. **K** switches the requested ownership mode; **L** launches the local character backward, opposite its facing (changed and verified October 21 through the manual request path for both players/modes). This is a self-launch fixture, not a combat hit-direction rule. Use WASD during flight, inspect both clients, try near edges and walls, and compare recovery and control return. Clear the attribute and remove fixtures afterward. Manual server-owned steering uses a validated, rate-limited input channel.

## Architecture gate and Spring Fist follow-up

The installed Studio exposes neither `UseFixedSimulation` nor `NextGenerationReplication` through this bridge, restricts reads of `AuthorityMode` and `PlayerScriptsUseInputActionSystem`, and currently has streaming disabled. Server Authority availability is therefore **not established**. No settings were migrated and no Server Authority prototype was built. Check beta availability and the complete setup in a separate viable environment before investing in controller migration. [Roblox Server Authority](https://create.roblox.com/docs/projects/server-authority)

Before approving a candidate, review repeated trajectories under normal conditions and measured **100–150 ms RTT**, false corrections, resisted launches, handoffs, input reversal, and product-owner hands-on feel. If neither candidate is acceptable, investigate further rather than commit combat to a failing path. Added inbound/outbound delay is not itself measured RTT. [Roblox Network Simulator](https://create.roblox.com/docs/studio/network-simulator)

After approval, finalize Spring Fist's exact hit volume, server action/request contract, and latency treatment, then implement the approved **0.08/0.10/0.32-second** phases, 70% movement, committed facing, disabled jumping, airborne/no-lift behavior, one late buffer in the final **0.12 seconds**, 5-stud unobstructed reach, once-per-target contact, startup interruption, active trades, reaction, and displacement protection. Use temporary readable visuals; respawn protection remains F3.

Camera-specific review, broad desktop/low-graphics checks, reference-hardware 60 FPS verification, and final tuning remain open. No standalone Luau analyzer is installed in this workspace.
