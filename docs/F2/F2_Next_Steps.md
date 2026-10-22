# F2 Spring Fist: progress and next steps

**Updated:** October 21, 2026.  
**Current state:** Orders 1–3 are complete for the F2 prototype decision. The product owner explicitly selected **option 2: client-owned ordinary movement, temporary server ownership during knockback, then return to the client after recovery**. Ordinary and verified 115–133 ms RTT feel is accepted. [Measurements and disposition of the proposed numeric gates](F2_Order2_Investigation.md#engineering-recommendation) remain recorded. Order 4, the concrete Spring Fist implementation outline, is next; combat is not implemented.

This is the handoff and work order for finishing F2. The [physics evaluation](F2_Physics_Evaluation.md) contains the detailed measurements, evidence files, fixture instructions, and limitations. The [PRD](Knockout_Night_v0.1_PRD.md), especially DD01/DD02 and section 17, remains the source of truth for gameplay. The [roadmap](Knockout_Night_v0.1_Engineering_Roadmap.md) defines the slice boundaries.

Order 4 update: the product owner subsequently confirmed the hit-volume, timing/presentation, collision, input, and cleanup decisions and authorized the [implementation outline](F2_Order4_Implementation_Outline.md). That outline now records the concrete plan for review; no combat implementation or acceptance is claimed. The [conversation handoff](F2_Order4_Handoff.md) retains the earlier discussion/workspace state and predates these decisions.

## Process completed

| Step | What we did | Outcome |
| --- | --- | --- |
| Ground the design | Reviewed F1's controller, existing tests, approved Spring Fist rules, and unresolved ownership decisions. | Preserved approved mechanics and identified the physics decision as the prerequisite to combat. |
| Agree on the evaluation | Interviewed the product owner about scope, ownership candidates, enforcement, presentation, and approval gates. | Agreed to a controlled launch fixture first, measured evidence plus hands-on review, no automatic punishment, and temporary combat visuals later. |
| Build the experiment | Added Studio-only controller hooks, launch fixtures, minimal steering/recovery, a movement validator, and trajectory recording. | Compared client ownership with temporary server ownership during displacement. No attack or hit detector was needed. |
| Exercise multiplayer behavior | Recorded both players as subject and observer in each ownership mode, at baseline and delayed network conditions. | 44 baseline trials, 44 delayed trials, and 12 focused locomotion trials passed their recording and behavior checks. |
| Fix integration failures | Corrected unfocused scripted input, delayed motor-state capture, and locomotion-state restoration after launch. | Walking immediately after launch works without requiring a jump to restart movement. |
| Check regression and clean up | Passed helper checks, the original F1 movement assertions, a separate F1 two-client rig/spawn/collision test, and manual K/L trigger checks. | Removed temporary Studio fixtures/capture objects and restored network settings. Reusable fixtures and evidence remain in the repository. |

The recorded matrix covered launches, reverse steering, airborne use, obstruction, launch resistance, teleporting, sustained excess speed, ordinary walking/jumping, replacement launches, and character death/replacement. These are physics-fixture checks; they do not establish combat correctness.

## What the evidence tells us

- **The fixture works under the target latency range.** Measured remote RTT was 31.5-50.3 ms at baseline and 131.6-149.9 ms in the delayed full matrix. Both full runs recorded zero false corrections in legitimate scenarios and detected every teleport/excess-speed probe.
- **Client ownership does not enforce a launch against its owner.** Deliberate launch resistance was flagged in both player roles. The horizontal movement budget does not close that weakness.
- **Temporary server ownership protected the initial launch in these probes.** It still returns movement to the client afterward and needs review of input delay, handoffs, and control return.
- **The candidates produce different travel.** Delayed idle trials recorded approximately 13.90-14.18 studs of sampled X travel for client ownership versus 7.08-8.16 studs for temporary server ownership, despite the same assigned launch velocity. These are small-sample observations, not accepted balance targets or total path lengths.
- **Roblox Server Authority viability remains unverified.** Required settings were unavailable or restricted through the installed Studio bridge. No migration or Server Authority prototype was performed.

The validator is experimental. Vertical flight prevention, wall traversal prevention, and secure movement outside the fixture have not been established. Its thresholds are not approved production tuning.

## Remaining work, in order

| Order | Work | Responsible role | Completion evidence |
| --- | --- | --- | --- |
| 1 | Review both ownership modes hands-on using the existing two-client fixture, at ordinary conditions and measured 100-150 ms RTT. Compare launch readability, steering, recovery, walls/edges, input transit, and handoff artifacts. | Product owner, supported by engineering | Written observations for both modes and a list of acceptable/unacceptable behavior. Manual trigger verification already completed does not replace this review. |
| 2 | Investigate the travel difference and any problems found during review. Repeat identical-input trials; propose acceptable variation, steering/recovery thresholds, and validation tolerances from the evidence. | Engineering, with product-owner tuning review | Repeatable measurements and documented proposed tolerances. If neither candidate is acceptable, continue investigation; assess Server Authority only if its support is established. |
| 3 | Select and approve the physics approach and movement-validation policy for F2. | Product owner and engineering | A recorded decision covering ownership transitions, launch application, motor/control restoration, correction behavior, known limits, and the checks that support it. |
| 4 | Finalize the Spring Fist implementation outline against that decision. Set exact hit-volume dimensions/placement, action and request contracts, authoritative timing, latency treatment, interruption/trade ordering, buffer behavior, and cleanup. | Engineering, with product-owner review of gameplay-affecting choices | A concrete F2 outline with tests and no unresolved architecture choice. Use the approved rules below; do not silently introduce new mechanics. |
| 5 | Implement the Spring Fist vertical slice with temporary readable presentation and the selected physics/validation path. | Engineering | A playable two-player attack, miss, hit, launch, recovery, and protection flow on The Platform. |
| 6 | Verify the actual combat flow and obtain F2 acceptance. | Engineering and product owner | Passing combat checks at ordinary and target latency, regression evidence, and hands-on acceptance of the attack's readability and punishability. |

**Immediate next action:** Finalize Order 4's Spring Fist outline against the approved decision below: hit volume, authoritative action/request timing, latency treatment, interruption/trades, buffer behavior, movement restrictions, and cleanup tests. Preserve the approved mechanics. No further ownership-choice approval is needed. Temporary fixtures have been removed from the parent place and client network delay restored.

## Order 3 decision: approved physics approach

**Decision:** The product owner explicitly confirms option 2 after comparing the alternatives and testing both modes under ordinary and target-latency conditions. Ordinary movement is client-owned. The server owns the victim's physics throughout server-issued knockback, then returns ownership after recovery. This is classic temporary network ownership, not a migration to Roblox's separate Server Authority system.

| Concern | Decision and implementation requirement |
| --- | --- |
| Starting knockback | The server validates the hit, computes the launch, takes ownership, and applies replacement velocity. The client does not choose whether the launch happens, its strength, its direction, or when authority returns. Spring Fist starts at 50 horizontal / 12 upward studs/s; hit direction comes from authoritative hit geometry, not the victim's facing used by the self-launch fixture. |
| Control during displacement | Suspend the normal Humanoid motor so walking cannot erase the launch. Preserve the server-captured pre-launch motor state explicitly. Retain the tested limited horizontal steering, initially 3 studs/s², using validated/rate-limited input; steering adds no vertical lift and does not grant ownership. |
| Recovery and handoff | The server determines recovery using the accepted landing/slowdown behavior. Retain the tested 0.12-second minimum and landing or ≤18 horizontal / ≤8 absolute vertical speed as prototype starting values, with observed launch motion before natural release. Restore the saved motor state and locomotion, including the tested Freefall restart so walking resumes without a jump. Return ownership to the current player after release. Ground-query details and timer integration must be explicit in Order 4 and verified in actual combat; the numeric consistency proposals are not certified. |
| Independent timers | Knockback-control recovery does not replace or extend the approved 0.15-second hit reaction or 0.35-second displacement protection. A grounded victim can recover physical control while a separate combat restriction/protection is still active. Restore only movement permissions allowed by the combined current states. |
| Replacement and teardown | A replacement launch replaces velocity and keeps the new displacement server-owned. Track which character and displacement owns each release so an old timer cannot return ownership or restore controls during a newer launch. Death, character replacement, departure, and session teardown clean up owned state. A bounded failsafe must prevent a stranded disabled motor/ownership state; fixture timeouts are cleanup evidence, not natural-recovery passes. |
| Movement-validation policy | Validate finite data, reject malformed/stale/spammed requests, and enforce a server-side movement budget that accounts for issued launches and residual motion. Retain the experimental 0.2-second replication burst and 3-stud slack as initial values. Correct violations to the last accepted transform, stop velocity, take server ownership for correction, and log the event; do not add automatic kicks or bans. A production correction/release path must compose with active knockback and character replacement. |
| Trust after recovery | Ordinary movement becomes client-owned again and remains untrusted. Validate relevant movement and authoritative gameplay outcomes after handoff; temporary server ownership is not complete movement security. Do not punish a stopped launch automatically because a collision can also stop movement. |

The starting values above preserve the tested prototype; they are not final balance or a production anti-cheat certification. The selected server mode must be used consistently for knockback: the client-owned comparison produced substantially different travel despite the same assigned velocity.

**Evidence and accepted limits:** The [Order 2 investigation](F2_Order2_Investigation.md) includes repeated trajectories, legitimate movement and abuse probes, motor restoration, replacement/death checks, and corrected airborne execution. The [feel review](F2_Ownership_Feel_Review.md) accepts backward launch, limited sideways influence, immediate walking, recovery timing, and the brief transition pause, with no noticeable worsening at measured 115–133 ms RTT. Server ownership preserved initial launches against resistance in the probes; client ownership did not. Recorded pauses, catch-up steps, cross-profile variation, and failed alternative experiments remain recorded. Vertical flight prevention, wall traversal prevention, larger-player-count/server-load behavior, reference-hardware performance, and actual combat latency are not established by these fixtures. Orders 4–6 must verify the integrated combat path before F2 acceptance.

**Alternatives:** Client-owned knockback is rejected for F2 because the owner can resist it. Permanently server-owned ordinary movement is not selected and was not tested. Roblox Server Authority remains unverified in this environment and is not part of this decision. No controller migration, new punishment policy, asset export, or publishing is authorized by this choice.

## Approved behavior to carry into implementation

- Spring Fist starts at **0.08 / 0.10 / 0.32 seconds** for startup, active contact, and recovery; **11-stud forward hit-volume extent** after the October 21 playtests; replacement launch of **50 horizontal / 12 upward studs/s**.
- Commit horizontal facing throughout the action, allow **70% base movement**, disable jumping during the action, and permit ordinary airborne attacks without lift or hover.
- One click requests one attack. Holding does not repeat. Permit one buffered next attack during the final **0.12 seconds** of recovery.
- Require suitable vertical overlap and an unobstructed hit path. An activation may hit multiple eligible enemies once each. Weapon hits interrupt startup; already-active attacks retain their hit opportunity so trades remain possible.
- Include **0.15-second hit reaction** and **0.35-second displacement protection**. Blocked contacts must not extend protection. Reaction, protection, and knockback-control recovery are separate concerns.

These are approved prototype starting values and behavioral rules, not claims of final balance. Exact hit-volume dimensions, physics application, and steering/recovery coefficients still need the work above.

## Outstanding reviews and F2 completion criteria

| Item | Status and relationship to F2 |
| --- | --- |
| Product-owner physics feel review and architecture approval | Orders 1–3 complete for the prototype decision. Temporary server ownership during knockback is approved; actual combat implementation and acceptance remain Orders 4–6. |
| Camera/control-feel review, including focus lifecycle and camera tuning | Open; can continue in parallel. The physics study does not sign it off. |
| Actual attack latency | Open; the launch fixture passed target RTT tests, but attack requests, hit detection, interruption, buffering, and trades do not exist yet. |
| Broad desktop/low-graphics coverage and reference-hardware 60 FPS | Open; required for later technical signoff. No performance pass is claimed by these trials. |
| Standalone Luau analysis | Not run; Studio compilation/runtime checks passed. |
| Final assets and polish | Later work. F2 will use temporary readable visuals; asset generation/export requires its own request. |

F2 is complete only when two players can demonstrate readable startup, contact, a punishable miss, recovery, committed aim, action movement/jump restrictions, and replacement launch behavior. Verify obstruction, vertical overlap, once-per-target hits, startup interruption, active trades, protection and blocked contacts, the single late buffer, malformed/stale/spammed requests, and cleanup across character replacement and repeated sessions. Repeat the critical combat cases at measured 100-150 ms RTT and rerun relevant F1 regressions.

Scored elimination, safe combat respawning, and **respawn protection** remain F3 work. F2's **post-hit displacement protection** is required for F2 acceptance. Other weapons, abilities, match lifecycle, queues, teleports, and publishing remain in their later slices.
