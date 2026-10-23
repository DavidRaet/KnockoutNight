# Knockout Night v0.1 Engineering Roadmap

**Status:** Approved roadmap; P1 scope revised by the product owner on October 23, 2026 to build all maps before the local 1v1 journey, defer 2v2 to P3, and place loadout selection in the arena; F1 implemented with Studio verification; F2 Spring Fist signed off for its current combat flow on October 22, 2026; F3 implemented, technically verified, synced, and signed off by the product owner on October 22, 2026; [F4 implemented, technically verified, and signed off by the product owner on October 22, 2026](F4/F4_Implementation_and_Verification.md). [F5 implemented, technically verified, and signed off by the product owner on October 22, 2026](F5/F5_Implementation_and_Verification.md). The complete M1 combat roster and match loop remain unfinished.

**Approved:** October 20, 2026.  
**Source of truth:** [Knockout Night v0.1 PRD](Knockout_Night_v0.1_PRD.md), document version 0.5.
**Design authority:** PRD sections 2.2 and 2.3 supersede conflicting earlier proposals. Confirmed behavior stays fixed; section 17 values remain configurable prototype starting settings.

The product owner approved the slice size, dependency order, and breakdown, including moving sudden death into P0 so the first complete combat milestone can finish tied matches. Roadmap approval does not resolve the engineering decisions listed below or authorize implementation, asset generation/export, or publishing.

Before taking each next step, announce the intended action to the product owner. F1-F11 were subsequently authorized. F10 authorization includes Bounce and the temporary ability selector beside the weapon selector. The product owner signed off F3, F4, and F5 on October 22, 2026. F6 is implemented and technically verified; owner gameplay acceptance is pending. The product owner signed off F7 at its current prototype tuning on October 22, 2026. David signed off F8 at its current 15-second-cooldown prototype tuning on October 22, 2026. David signed off the current F9 Magnet prototype on October 22, 2026. F10 is implemented and technically verified; David signed off current gameplay and Bounce tuning on October 23, 2026. F11 is implemented and technically verified within its recorded limits; David signed off F11 gameplay on October 23, 2026, at the current nine-stud radius and 55/13 launch tuning. Later slices, polishing, and publishing require separate authorization.

## Planning approach

This roadmap applies Matt Pocock's specification, vertical-slice, and module-design guidance. Each slice delivers observable behavior, declares its blockers, and includes acceptance checks. The slices are approved planning items, not published tracker tickets.

Every slice includes its necessary server behavior, client presentation, cleanup, and verification. Tests should exercise observable outcomes through the highest practical interface rather than depend on internal script structure.

## Priorities and milestones

| Priority | Milestone | Outcome |
|---|---|---|
| **P0 — Foundations** | **M1: Complete two-player combat** | Two players finish understandable matches on The Platform using the complete starter roster. |
| **P1 — MVP completion** | **M2: Complete local 1v1 flow** | Finish the three-map set, then complete the menu → lobby → 1v1 queue → map vote → arena loadout → match → results → lobby journey locally. |
| **P1 — MVP completion** | **M3: Reserved match servers** | Complete lobby → reserved match → lobby journey, including failure recovery. |
| **P2 — Polish** | **M4: Friends-and-family beta** | Refine presentation and provisional tuning, verify technical targets, and obtain beta acceptance. |
| **P3 — Later feature** | **Milestone TBD: 2v2** | Add 2v2 after the P1 local-flow and reserved-server milestones; detailed milestone placement remains open. |

Required readability, accessibility, security, and failure handling belong in P0/P1 as their features arrive. P2 refines those features; it does not postpone required functionality.

All three weapons, all three abilities, and all three maps are in the P1 1v1 flow. 2v2 is deferred to P3. No gameplay mechanics are added by this roadmap.

## Major systems and technical dependencies

These are proposed ownership seams, not a commitment to separate scripts or a framework.

| System | Owns | Technical dependencies |
|---|---|---|
| Character controls | Camera aim, movement, cursor capture, standardized rig behavior | Playable geometry; coordination with action and displacement state |
| Combat actions | Weapon phases, committed aim, abilities, interruption, protection, Ground Slam | Controls; server validation; shared configuration; geometry queries |
| Player lives | Elimination commitment, safe spawning, protection, cooldown continuity | Arena bounds/spawn candidates; combat cleanup; match phase |
| Match lifecycle | Countdown, deadlines, teams, score, sudden death, departures, terminal results | Combat and lives; authoritative session identity |
| Arenas | Playable surfaces, bounds, safe spawns, Dungeon blockout, reset | Shared arena contract; lifecycle reset |
| Lobby and intermission | Physical 1v1 queue, dispatch roster, map votes; arena owns private loadout selection | Membership ownership; session lifecycle; available arena/loadout definitions |
| Presentation | HUD, feedback, spectating, settings, results/recovery screens | Authoritative state; presentation must not gate gameplay |
| Reserved sessions | Destination admission, complete-roster assembly, bounded retries and return | Proven local lifecycle and queue handoff |

The critical path is:

**Movement → validated launch → elimination/scoring → complete match → roster validation → local journey → reserved journey → beta acceptance.**

Additional weapons, abilities, maps, and presentation can progress when their declared prerequisites are complete. They do not need artificial dependencies on unrelated content. Milestone gates also require all slices in that milestone, even where individual slices have fewer blockers.

## Roblox Brain skill conventions

- Names in the slice tables are exact `roblox-*` skill suffixes: `physics` means `roblox-physics`.
- `collaboration-mode` applies throughout.
- Implementation slices use `architecture`, `luau-core`, and `luau-patterns`; `luau-types` applies when defining typed contracts.
- Every client/server request path also requires `networking` and `security`.
- Multiplayer verification uses `studio-mcp`; tooling changes use `tooling`.
- The per-slice column names additional domain skills.

## P0 — M1: Complete two-player combat

Use a developer-controlled local launch path initially. Player-facing queues and selection screens arrive in P1.

| ID / vertical slice | Blocked by | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **F1 — Move and aim on The Platform** | None | Two standardized characters move, strafe, jump, and aim in 3D on the circular greybox. No body blocking or held-jump repetition. Verify mouse capture/release, camera clipping, ordinary air steering, and symmetric initial positions. | `building`, `camera`, `input`, `physics` |
| **F2 — Land and punish a Spring Fist attack** | F1 | One click produces startup, active contact, and recovery. Aim stays committed; movement is reduced and jumping disabled during the action. Launch replaces velocity. Test misses, obstruction, vertical overlap, once-per-target contact, startup interruption, active trades, protection, and one late buffered attack. | `physics`, `animation-vfx` |
| **F3 — Fall, score, and safely respawn** | F2 | Lower-plane/outer-bound commitment scores exactly once for the opponent. Reset/death also counts once; disconnect does not count as a fall. Verify recovery cutoff, safe spawn choice, visible protection, protection ending on action, and cooldown continuity. Show fall, survivor spectating, and respawn countdown. | `physics`, `camera`, `gui` |
| **F4 — Complete regulation and results** | F3 | Countdown enables movement, combat, and timer together. Both clients agree on score, deadline, winner, and results. Only pre-deadline eliminations count. Exercise duplicate callbacks, delayed requests, repeated sessions, and active 1v1 forfeit. | `gui` |
| **F5 — Resolve tied matches** | F4 | Enter untimed sudden death with tied scores preserved and a complete reset. No ordinary respawn. First decisive loss ends the match; an opposing loss within the configured simultaneity window resets it. Test both event orders and pending regulation respawns. | `gui`, `physics` |
| **F6 - Fight with Wrecking Hammer** | F2 | **Implemented and technically verified October 22, 2026; owner gameplay acceptance pending.** Shared combat supports its broader sweep, heavier launch, greater commitment, and punishable recovery without ordinary armor. Two-client technical dodge/punish checks passed; owner evaluates readability and feel. [Implementation and verification](F6/F6_Implementation_and_Verification.md). | `animation-vfx`, `physics` |
| **F7 — Apply Paddle Pops pressure** | F2 | **Implemented, technically verified, and owner gameplay accepted October 22, 2026.** F9 follow-up tuning: 6-stud forward reach and 30/8 studs-per-second launch. The revised reach awaits owner gameplay review; prior sign-off covered 4.5 studs. Individual activations alternate hands with short reach and fast timing; base locomotion remains unchanged. Protected contacts cannot refresh protection. Technical checks demonstrate a defender response before protection expires; owner accepted the current pressure/readability prototype. Target-latency verification and later balance/art gates remain separate. [Implementation and verification](F7/F7_Implementation_and_Verification.md). | `animation-vfx`, `physics` |
| **F8 - Use Gust for positioning** | F2 | **Implemented, technically verified, and owner gameplay accepted October 22, 2026.** Current tuning: 15-second cooldown, 12-stud/60-degree cone, 35/6 launch, 0.25-second stun with startup interruption, and 0.12/0.20-second startup/recovery. Active attacks retain shared trade rules. Miss/interrupted activation spends cooldown; rejection spends nothing. Geometry/protection/lifecycle checks pass. [Implementation, verification, and sign-off](F8/F8_Implementation_and_Verification.md). Target-latency and milestone/release gates remain separate. | `physics`, `animation-vfx` |
| **F9 - Pull with Magnet** | F2 | **Implemented and owner gameplay accepted October 22, 2026.** David signed off the current tuning. With Magnet selected, Q activates Magnet: 12-second cooldown, 20-stud/60-degree cone, 28-stud/s pull for up to 0.55 seconds (15.4-stud travel), stopping three horizontal studs short. Server selects by alignment/distance/stable UserId; target retains attack/ability responses and gains displacement protection. 555 deterministic checks, 15 Magnet geometry checks, 79 weapon geometry regressions, 50 isolated engine integration checks, and single-client feedback checks pass. Two-live-client networking/target latency remain unverified. [Implementation and verification](F9/F9_Implementation_and_Verification.md). | `physics`, `animation-vfx` |
| **F10 — Recover using Bounce** | F3 | Valid grounded, airborne, and ordinary-knockback use replaces velocity. Direction follows camera-relative movement input; no input launches straight up. Verify primary delay, death-persistent cooldown, elimination cutoff, and no self-action cancellation. | `input`, `physics`, `animation-vfx` |
| **F11 — Perform Aerial Ground Slam** | F6, F10 | **Implemented, technically verified within recorded limits, and owner gameplay accepted October 23, 2026.** [Implementation and verification](F11/F11_Implementation_and_Verification.md). Current owner-requested tuning: nine-stud radius and 55/13 launch. Only Bounce flight unlocks the opportunity. Test consumption/expiry, telegraph, armored but displaceable descent, redirected descent after a weapon hit, and one weaker radial shockwave on valid top surfaces. Walls, undersides, gaps, void, and disappearing surfaces produce no invalid impact. | `physics`, `animation-vfx`, `building` |

### M1 acceptance and playtest gate

Required checks cover the applicable portions of PRD AC06–AC08, AC10–AC13, and AC21–AC26.

- Two players complete repeated regulation and tied matches on The Platform.
- Exercise **all nine loadouts**, including ordinary airborne attacks and cooldown/interruption behavior.
- Validate Hammer avoidance, Paddle Pops response opportunities, useful but fallible Bounce recovery, and central-position survivability.
- Repeat critical combat scenarios at the PRD's provisional **100–150 ms round-trip latency** target.
- Record whether players understand their losses and voluntarily want another match. Do not invent a numerical enjoyment threshold.

**Exit:** The complete starter roster works in two-player combat, authoritative outcomes agree, and the combat is worth expanding. Final art and teleports do not gate this milestone.

## P1 — M2: Complete local 1v1 flow

Build the two additional arenas before wiring the complete player journey. M2 keeps the menu, lobby, queue, intermission, map vote, arena, match, results, and return flow within one server; players move between areas in that server. M2 covers 1v1 only. Reserved-server teleports remain in M3, and 2v2 is deferred to P3.

| ID / vertical slice | Blocked by | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **L1 — Build Sky Bridges** | F3 | **Gameplay accepted by David October 23, 2026.** Center and side islands have all three connections. Essential routes work without Bounce. Verify safe spawns, camera legibility, ordinary traversal, ring-outs, and slam rejection across island gaps in 1v1. | `building`, `physics`, `camera` |
| **L2 — Build Dungeon blockout** | F5, F11 | Approved October 23, 2026; replaces The Ring and retires collapse cycles. Flat 80 × 80 square with open edges, centered stationary 10-stud mock ball (bottom 8 studs above floor) and simple chain supported by an overhead frame; mock/frame collision/touch/query disabled. Opposing inward-facing spawns ±20 studs from center, mirrored safe respawns and central fallback. Verify local 1v1 bounds, scoring, protection, and resets. [Verification and owner acceptance](P1/L2/L2_Implementation_and_Verification.md); **David signed off L2 gameplay, including the support frame, October 23, 2026.** Art and active hazards deferred. | `building`, `physics` |
| **L3 — Enter the menu, lobby, and 1v1 queue** | F1, L1, L2 | After the three-map set is built, title/blurred 3D background and Play lead to the shared lobby. The physical 1v1 zone shows FIFO waiting order and next roster. Repeated contacts/input never create duplicate membership. Incomplete queues wait. | `building`, `camera`, `input`, `gui` |
| **L4 — Dispatch a local 1v1 group** | L3, F4 | A full group receives a countdown and one local session assignment to the intermission area in the same server. Pre-dispatch departures preserve queue order; extra entrants wait. | `gui` |
| **L5 — Vote and enter an arena** | L4 | Offer all three maps in intermission; resolve ties among vote leaders and empty votes among all maps. Move both players to the selected arena within the same server. Reuse clears old collisions, hazards, actions, effects, and callbacks. | `building`, `gui` |
| **L6 — Select arena loadouts and start** | L5, F6–F10 | In the arena, each player privately selects one weapon and one ability during a 15-second window. If both confirm early or time expires, lock valid choices, independently default missing choices, and show a 3-second countdown before enabling the match. Reject invalid/late changes. | `gui`, `input` |
| **L7 — Follow the complete 1v1 match HUD** | L6 | Show score, authoritative timer/cooldowns, radial cooldown, feed, respawn countdown, and sudden death. Verify final-30/final-10 urgency, attribution expiry, blocked-contact exclusion, feed cap, and missing-asset fallback. | `gui`, `animation-vfx` |
| **L8 — Finish, return, and reuse the local session** | L4, L6, L7 | Exercise departures during queue, intermission, arena selection/countdown, and active 1v1; preserve the approved forfeit/cancellation rules. Results and cancellation return players to a usable local lobby without stale membership or callbacks. | `gui` |
| **L9 — Read combat and control presentation** | L2, L7 | Weapon/ability feedback remains distinguishable in 1v1. Settings provide sensitivity, optional subtle shake, and separate music/effects volume. Essential information remains readable without color alone and at low graphics settings. | `gui`, `camera`, `audio`, `animation-vfx` |

### M2 acceptance and playtest gate

**L1 — October 23, 2026:** [Sky Bridges is implemented and technically checked](P1/L1/L1_Implementation_and_Verification.md), including three walkable connections, home-island respawns, arena bounds, seam-aware slam, live traversal, and a two-client spawn/scoring/respawn check. **David signed off L1 gameplay on October 23, 2026; gameplay acceptance is complete for this slice.** Agent visual camera/readability review remains unverified because Studio captures returned blank frames. L2 was separately authorized October 23, 2026; current launch selects Dungeon, with Sky Bridges and The Platform retained in `F1Config.Arena`. Publishing remains separately gated. Full-match, latency, and milestone acceptance gates remain separate.

- Pass the 1v1 local-flow acceptance criteria, including AC01 and the applicable AC04–AC18 and AC21–AC26 scenarios.
- Complete the **three maps × 1v1** matrix with varied loadouts.
- Exercise combat and sudden death with two clients; exercise departures, consecutive sessions, stale timers/requests, arena cleanup, and map transitions. Test parallel local sessions only if the approved local allocation supports them.
- Have an unfamiliar tester complete menu → lobby → queue → selection → match → results → lobby without guidance.

**Exit:** A new player can complete the full 1v1 journey locally, across all three maps, before transport infrastructure is introduced.

## P1 — M3: Reserved match servers

| ID / vertical slice | Blocked by | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **R1 — Assemble one reserved match** | M2 accepted | A full local roster reaches its intended destination and initializes exactly one session. Destination admission validates server-owned session/roster data. No intermission starts before complete arrival. Test duplicate, unrelated, and late arrivals. | `security`, `networking` |
| **R2 — Recover failed outbound dispatch** | R1 | Exercise dispatch errors and partial arrivals. Apply the configured total arrival bound and retry cap without extending waiting indefinitely. Cancel incomplete groups, release lobby-side players, return arrivals, and prevent unintended partial matches or duplicate starts. | `security`, `gui` |
| **R3 — Return or retain usable recovery** | R1, R2 | Results/interruption/cancellation can return to a valid public lobby. Failed returns use bounded automatic retries, clear errors, and a persistent manual button. Rejoining enters a lobby; no previous-match reconnection/backfill. Test two simultaneous reserved matches for isolation. | `gui`, `security` |

### M3 acceptance and playtest gate

- Pass **AC19** and repeat AC01, AC14, AC18, and AC26 across the actual place transition.
- Test full and partial arrival, failures before/after dispatch begins, destination departures, arrival timeout, late arrival after cancellation, and failed returns.
- Run 1v1 in the published multiplayer test environment and verify independent reserved sessions. 2v2 remains deferred to P3.
- Publishing/configuring that environment is a later explicit approval gate; this roadmap authorizes no publishing.

**Exit:** The production-shaped journey and its recovery paths work without stranded players or split matches.

## P2 — M4: Polish and beta acceptance

| ID / vertical slice | Blocked by | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **B1 — Refine combat and arena presentation** | M2 | Improve approved animation, sound, effects, camera response, and layouts using original/licensed assets. Preserve hit alignment and warning clarity. Compare before/after on low graphics and representative desktop viewports. | `animation-vfx`, `audio`, `camera`, `gui`, `lighting`, `building` |
| **B2 — Tune the approved roster and maps** | M3 | Adjust provisional configuration through observed 1v1 playtests. Recheck all nine loadouts across maps; investigate compulsory Bounce, unavoidable pressure, unreadable Hammer/slam, and bridge/hazard bias. | `game-design`, `physics` |
| **B3 — Verify and accept the beta build** | B1, B2 | Review the acceptance criteria for the approved beta scope with evidence; resolve critical failures. Verify chosen desktop hardware, provisional lobby/match capacity, latency, low-graphics readability, and session cleanup. Obtain owner acceptance of tuning and remaining risks. | `performance`, `security`, `publish-checklist` |

### M4 acceptance and playtest gate

Friends-and-family 1v1 sessions must record fairness, clarity, controls, combat enjoyment, completion/failure causes, and voluntary repeat play. Manual notes and targeted logs are sufficient initially; a persistent analytics system is not required. P3 2v2 remains a separate acceptance gate.

**Exit:** Complete acceptance-matrix review, resolved critical gameplay/flow failures, and product owner acceptance of current tuning. No unapproved retention or win-rate threshold is introduced.

## Approved F1 prototype decisions

The product owner approved these choices after reviewing the F1 implementation outline:

- **Rig:** Use a standardized R15 rig, preserving compatible avatar appearance. Review its look in the prototype; this choice may be revised later.
- **Camera:** Tune distance, zoom bounds, pitch bounds, and sensitivity in the prototype under PRD DD01. No final camera values are approved yet.
- **Physics:** Use the existing character simulation as the F1 baseline. Evaluate network ownership and movement validation before F2; the baseline does not establish the final combat physics approach.
- **Slice scope:** F1 verifies traversal and ordinary character placement/replacement. Scored elimination, safe combat respawns, and protection remain in F3.

These approvals resolve the listed F1 planning choices. They do not assert implementation or playtest completion.

## P3 — Deferred feature: 2v2

2v2 is deferred until after the P1 local 1v1 flow and reserved-server work. Its exact milestone placement and release gate remain to be planned; it is not part of M2 or M3 acceptance.

## P3 - Stretch feature: Dev Special

| ID / vertical slice | Priority | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **X1 - Add Poop Hammer and Eat Poop** | P3 stretch; outside v0.1 | Keep both weapon and ability developer-only. Eat Poop targets the nearest opponent, applies the poop smear, and makes that opponent slippery and more susceptible to knockback, doubling the knockout potential of the user's Poop Hammer. Verify the effect is limited to this special interaction and does not become part of ordinary loadouts. Tune detailed values and presentation before implementation; hands-on playtest required. | `architecture`, `luau-core`, `luau-patterns`, `networking`, `security`, `physics`, `animation-vfx` |

This stretch slice is independent of the v0.1 milestone gates. Its inclusion in the roadmap records future scope only and does not authorize implementation or alter the beta release criteria.

## Risks, unresolved details, and approval points

Roadmap approval accepts the breakdown and sequence. Proposed treatments below remain subject to review unless marked resolved by an approved slice decision.

| Decision or risk | Needed before | Proposed treatment for review |
|---|---|---|
| **Physics ownership and movement validation** | F2 | [Controlled experiment and review gate](F2_Physics_Evaluation.md) implemented for classic client ownership and temporary server ownership. Review measured evidence and hands-on feel before committing the architecture. Server Authority viability remains unverified. |
| **Failure to spawn safely** | F3; later maps | Approved in PRD section 2.3: check candidates during the normal countdown, use the permanent-surface fallback at its deadline, and stop the local session with a clear error if that fallback is unsafe. F3 technically exercises this on The Platform; later maps must integrate surface availability. |
| **Coincident departures, deadline, and decisive elimination** | F5; expanded in L9 | F4 ordering is resolved by the approved decisions recorded in the [F4 implementation and verification](F4/F4_Implementation_and_Verification.md). F5 ordering is implemented: inclusive 0.2-second server commitment window, complete mutual reset, and departures before pending outcomes. See the F5 verification document. |
| **Local allocation/full-capacity behavior** | L3 | Approved October 23, 2026: one active local match for M2, with additional players waiting in FIFO order. L3 presents the next pair; L4 owns dispatch. Reserved-server production architecture remains unchanged. |
| **Exact tuning and presentation choices** | Throughout | Use section 17 starts; validate hit volumes, air control, pull speed, spawns, camera, and warning timing. Escalate any proposed behavioral change rather than presenting it as tuning. |
| **Transport admission and retry timing** | R1/R2 | Review server-owned handoff design, destination configuration, and retry schedule within DD09's bounded policy. No distributed matchmaking backend is assumed. |
| **Reference hardware and supported desktop coverage** | Technical signoff | Select hardware/viewports before claiming the provisional 60 FPS target passes. |
| **Owners, dates, beta participants** | Scheduling/M4 | Remain unassigned. Estimate delivery after roadmap review and early physics evidence. |
| **Asset generation/export and publishing** | Any such action | Require separate authorization. Existing Hammer remains a visual reference; no regeneration/export is implied. |
| **Final balance and beta release** | M4 | Product owner approves tuning and release readiness after reviewing evidence. |

The principal delivery risks remain inconsistent knockback, protection that fails under two attackers, compulsory Bounce, incorrect slam surface handling, deadline races, state leakage, and teleport recovery. Their tests appear early enough to expose problems before content polish.

## Deferred scope and asset constraints

Deferred scope remains deferred: progression/economy, monetization, parties, ranked or cross-server matchmaking, additional mechanics/content, mobile/controller implementation, backfill/reconnection, direct rematches, individual statistics, and sudden-death anti-stalling.

Follow the project's asset organization rules. Future Blender source files belong under the appropriate `assets/blender/` directory; exports and UI assets belong under their designated `assets/` directories. The Hammer source is `assets/blender/weapons/WreckingHammer.blend`. Do not regenerate/export assets without a request. Do not organize or move files in the Roblox Script Sync directories.

## Verification status and next step

F1 implementation and its Studio checks are recorded in [F1 Implementation and Verification](F1/F1_Implementation_and_Verification.md). Two-client rig, spawn, collision, movement, camera, input, and character-replacement checks have been exercised; product-owner F1 feel/camera review remains outstanding. The [F2 physics evaluation](F2/F2_Physics_Evaluation.md) passed baseline and target-latency launch-fixture checks. The [Spring Fist implementation and verification](F2/F2_Order5_Implementation_and_Verification.md) records combat checks, including delayed multiplayer runs. The product owner signed off the current F2 combat flow on October 22, 2026.

The [F3 implementation and verification](F3/F3_Implementation_and_Verification.md) records 17 deterministic F3 checks, 35 two-client lifecycle checks, the passing 28-check F2 combat regression, the F1 rig/spawn/collision regression, and normal Play/HUD inspection. Runtime scripts match the connected Studio place and temporary fixtures are removed. The product owner signed off F3 gameplay on October 22, 2026. [F4 implementation, verification, and owner acceptance](F4/F4_Implementation_and_Verification.md) are recorded separately. F10 two-live-client verification, F9 live multiplayer verification, F3 target-latency coverage, F6 owner acceptance, F7/F8 target-latency coverage, F11 two-live-client/latency verification, reference-hardware performance, reserved-server publishing/release gates, and asset export remain incomplete.

[F5 implementation and verification](F5/F5_Implementation_and_Verification.md) records 254 deterministic checks and two-client reset/result/departure checks. The owner published the updated place, confirmed sudden death works, and signed off F5 on October 22, 2026. [F6 implementation and verification](F6/F6_Implementation_and_Verification.md) records the authorized Wrecking Hammer ordinary attack: 29 deterministic checks, 27 geometry checks, 41 two-client combat assertions, the 28-assertion Fist regression, and 104 repeated sudden-death assertions with Hammer equipped. The owner-authorized temporary centered weapon picker is also implemented; its two-client follow-up passed 48 assertions, including staging selection and countdown locking. **F6 awaits owner hands-on gameplay evaluation and sign-off.** An intermittent Roblox ChatScript initialization error remains separately reported in the F5 regression evidence. The owner subsequently approved the F7 design and explicitly authorized its implementation, superseding the previous F7 wait instruction only. F6 gameplay sign-off remains separately unrecorded. F7 is implemented and technically verified: 29 new deterministic checks (500 with regressions), 79 geometry checks across all three weapons, 55 Paddle integration assertions, 48 Hammer and 28 Fist regression assertions, and 110 sudden-death assertions with Paddles equipped. See [F7 implementation and verification](F7/F7_Implementation_and_Verification.md). **F7 owner acceptance: David signed off the current 4.5-stud, 30/8 launch prototype on October 22, 2026.** F7 gameplay acceptance is complete for this slice. **F8 is implemented, technically verified, and owner gameplay accepted: David signed off the current prototype on October 22, 2026.** [F8 implementation and verification](F8/F8_Implementation_and_Verification.md) records 25 current deterministic checks (525 with regressions), 74 two-client Gust checks, 55 mixed-weapon regression assertions, and 79 weapon geometry checks. At F8 sign-off, Q activated Gust with the approved 15-second cooldown, 12-stud/60-degree cone, 35/6 launch, 0.25-second stun with startup interruption, and 0.12/0.20-second startup/recovery. The owner requested this range/stun revision after the initial implementation; it supersedes the initial no-startup-interruption design. Current tuning evidence is linked from the F8 document; David accepted the current 15-second-cooldown revision on October 22, 2026. Cooldown persists through death and resets for fresh matches/sudden-death rounds. Temporary cues, wind burst, bundled sound, and cooldown/rejection feedback are included. F7/F8 target-latency coverage, later balance/art work, and milestone/release gates remain open. F8 gameplay acceptance is complete for this slice. F9 was subsequently authorized and implemented; at F9 sign-off Q activated Magnet without an ability picker. F10 subsequently added the owner-requested temporary ability selector. See [F9 implementation and verification](F9/F9_Implementation_and_Verification.md). **F9 owner acceptance: David signed off the current 20-stud-range, 0.55-second-pull prototype on October 22, 2026.** Its isolated engine and geometry checks pass; two-live-client networking and target latency remain unverified. F9 gameplay acceptance is complete for this slice. **F10 gameplay acceptance is complete: David signed off the current 48 horizontal / 90 upward studs/s Bounce tuning on October 23, 2026.** See [F10 implementation and verification](F10/F10_Implementation_and_Verification.md). Bounce cooldown integration and the temporary staging ability selector are complete. Two-live-client and target-latency verification remain open. F11 was separately authorized and is now implemented and technically verified for local 1v1 on The Platform, within the limits in its [implementation and verification record](F11/F11_Implementation_and_Verification.md). Its 590 offline checks, 126 isolated F11 engine assertions, 74 Bounce and 50 Magnet regressions, and 12 single-live-client assertions pass. All 27 runtime sources match Studio and temporary probes are removed. David signed off F11 gameplay on October 23, 2026, including the current nine-stud radius and 55/13 launch tuning. F11 gameplay acceptance is complete; two-live-client/target-latency and complete-match verification remain open. No next slice is authorized by this sign-off. Polishing and publishing remain separately gated. Deferred abilities, future-map integration, 2v2, remaining verification, and milestone/release gates are unchanged. [F2 Next Steps](F2/F2_Next_Steps.md) records the approved temporary server ownership during knockback; Spring Fist retains its separately confirmed 10-stud center reach.

**L2 — October 23, 2026:** Dungeon blockout is implemented and technically checked: 590 offline regressions, 140 geometry assertions after the decorative support-frame revision, 21 isolated lives assertions, and 22 two-client assertions passed. All 29 runtime sources match Studio; temporary fixtures are removed. **David signed off L2 gameplay, including the decorative support frame, on October 23, 2026; gameplay acceptance is complete for this slice.** See [L2 implementation and verification](P1/L2/L2_Implementation_and_Verification.md) for evidence and limitations. Agent visual review, full-match/reuse, target latency, low graphics, reference-hardware performance, and multiplayer repetition after the frame change remain open. L3 was subsequently authorized; see its status below. Map voting (L5), active dungeon hazards, detailed art, 2v2, and publishing remain separate work.

**L3 — October 23, 2026:** David approved the L3 design and authorized implementation. Menu, compact safe lobby, and server-owned physical FIFO 1v1 queue are implemented. Local checks pass (590 existing deterministic assertions plus 120 queue assertions); 23 isolated Studio lifecycle assertions and real single-client entry/jump/death checks pass. The 12-row presentation fixture verifies overflow and a pinned next pair. All 33 runtime sources were compared and synced; temporary fixtures were removed. See [L3 implementation and verification](P1/L3/L3_Implementation_and_Verification.md). **David signed off L3 gameplay on October 23, 2026; gameplay acceptance is complete for this slice.** Actual multi-client verification, reset-button interaction, long-queue mouse-wheel checks, low graphics, target latency, and reference-hardware performance remain open. David confirmed the 3D view renders correctly despite later dark captures. Next planned slice is L4 dispatch; await separate authorization before starting it. Remaining L3 technical checks and milestone/release gates stay open. The queue deliberately waits even with a full pair. No publishing is authorized.
