# Knockout Night v0.1 Engineering Roadmap

**Status:** Approved roadmap; F1 implemented with Studio verification; F2 Spring Fist signed off for its current combat flow on October 22, 2026; F3 implemented, technically verified, synced, and signed off by the product owner on October 22, 2026; [F4 implemented, technically verified, and signed off by the product owner on October 22, 2026](F4/F4_Implementation_and_Verification.md). [F5 implemented, technically verified, and signed off by the product owner on October 22, 2026](F5/F5_Implementation_and_Verification.md). The complete M1 combat roster and match loop remain unfinished.

**Approved:** October 20, 2026.  
**Source of truth:** [Knockout Night v0.1 PRD](Knockout_Night_v0.1_PRD.md), document version 0.4.
**Design authority:** PRD sections 2.2 and 2.3 supersede conflicting earlier proposals. Confirmed behavior stays fixed; section 17 values remain configurable prototype starting settings.

The product owner approved the slice size, dependency order, and breakdown, including moving sudden death into P0 so the first complete combat milestone can finish tied matches. Roadmap approval does not resolve the engineering decisions listed below or authorize implementation, asset generation/export, or publishing.

Before taking each next step, announce the intended action to the product owner. F1-F7 were subsequently authorized. The product owner signed off F3, F4, and F5 on October 22, 2026. F6 is implemented and technically verified; owner gameplay acceptance is pending. The product owner signed off F7 at its current prototype tuning on October 22, 2026. F8 and later slices require their own authorization.

## Planning approach

This roadmap applies Matt Pocock's specification, vertical-slice, and module-design guidance. Each slice delivers observable behavior, declares its blockers, and includes acceptance checks. The slices are approved planning items, not published tracker tickets.

Every slice includes its necessary server behavior, client presentation, cleanup, and verification. Tests should exercise observable outcomes through the highest practical interface rather than depend on internal script structure.

## Priorities and milestones

| Priority | Milestone | Outcome |
|---|---|---|
| **P0 — Foundations** | **M1: Complete two-player combat** | Two players finish understandable matches on The Platform using the complete starter roster. |
| **P1 — MVP completion** | **M2: Complete local flow** | Menu, queues, private selections, both modes, all maps, HUD, departures, and clean session reuse work locally. |
| **P1 — MVP completion** | **M3: Reserved match servers** | Complete lobby → reserved match → lobby journey, including failure recovery. |
| **P2 — Polish** | **M4: Friends-and-family beta** | Refine presentation and provisional tuning, verify technical targets, and obtain beta acceptance. |

Required readability, accessibility, security, and failure handling belong in P0/P1 as their features arrive. P2 refines those features; it does not postpone required functionality.

All three weapons, all three abilities, all three maps, and both modes remain in beta scope. No gameplay mechanics are added by this roadmap.

## Major systems and technical dependencies

These are proposed ownership seams, not a commitment to separate scripts or a framework.

| System | Owns | Technical dependencies |
|---|---|---|
| Character controls | Camera aim, movement, cursor capture, standardized rig behavior | Playable geometry; coordination with action and displacement state |
| Combat actions | Weapon phases, committed aim, abilities, interruption, protection, Ground Slam | Controls; server validation; shared configuration; geometry queries |
| Player lives | Elimination commitment, safe spawning, protection, cooldown continuity | Arena bounds/spawn candidates; combat cleanup; match phase |
| Match lifecycle | Countdown, deadlines, teams, score, sudden death, departures, terminal results | Combat and lives; authoritative session identity |
| Arenas | Playable surfaces, bounds, safe spawns, Ring hazards, reset | Shared arena contract; lifecycle reset |
| Lobby and intermission | Physical queues, dispatch roster, votes, private selections | Membership ownership; session lifecycle; available arena/loadout definitions |
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
| **F7 — Apply Paddle Pops pressure** | F2 | **Implemented, technically verified, and owner gameplay accepted October 22, 2026.** Current tuning: 4.5-stud forward reach and 30/8 studs-per-second launch. Individual activations alternate hands with short reach and fast timing; base locomotion remains unchanged. Protected contacts cannot refresh protection. Technical checks demonstrate a defender response before protection expires; owner accepted the current pressure/readability prototype. Target-latency verification and later balance/art gates remain separate. [Implementation and verification](F7/F7_Implementation_and_Verification.md). | `animation-vfx`, `physics` |
| **F8 — Use Gust for positioning** | F2 | A valid activation spends cooldown even on miss/interrupted startup; rejection spends nothing. Cone respects geometry and protection, can affect multiple eligible enemies, and does not cancel their attacks or add lift. | `physics`, `animation-vfx` |
| **F9 — Pull with Magnet** | F2 | Server selects one target by aim alignment, then distance. Obstruction/protection excludes targets; a miss spends cooldown. Pull stops short, permits target attacks, and protects until the later required deadline. | `physics`, `animation-vfx` |
| **F10 — Recover using Bounce** | F3 | Valid grounded, airborne, and ordinary-knockback use replaces velocity. Direction follows camera-relative movement input; no input launches straight up. Verify primary delay, death-persistent cooldown, elimination cutoff, and no self-action cancellation. | `input`, `physics`, `animation-vfx` |
| **F11 — Perform Aerial Ground Slam** | F6, F10 | Only Bounce flight unlocks the opportunity. Test consumption/expiry, telegraph, armored but displaceable descent, redirected descent after a weapon hit, and one weaker radial shockwave on valid top surfaces. Walls, undersides, gaps, void, and disappearing surfaces produce no invalid impact. | `physics`, `animation-vfx`, `building` |

### M1 acceptance and playtest gate

Required checks cover the applicable portions of PRD AC06–AC08, AC10–AC13, and AC21–AC26.

- Two players complete repeated regulation and tied matches on The Platform.
- Exercise **all nine loadouts**, including ordinary airborne attacks and cooldown/interruption behavior.
- Validate Hammer avoidance, Paddle Pops response opportunities, useful but fallible Bounce recovery, and central-position survivability.
- Repeat critical combat scenarios at the PRD's provisional **100–150 ms round-trip latency** target.
- Record whether players understand their losses and voluntarily want another match. Do not invent a numerical enjoyment threshold.

**Exit:** The complete starter roster works in two-player combat, authoritative outcomes agree, and the combat is worth expanding. Final art and teleports do not gate this milestone.

## P1 — M2: Complete local flow

| ID / vertical slice | Blocked by | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **L1 — Play a complete 2v2 match** | F5–F11 | Four players receive random server-owned teams and symmetric team spawns. Verify no harmful allied weapon, Gust, Magnet, or slam effects; multi-enemy contacts; two-attacker protection; and first-player-loss sudden death. | `physics`, `gui` |
| **L2 — Enter the menu, lobby, and queues** | F1 | Title/blurred 3D background and Play lead to the shared lobby. Separate physical zones show FIFO waiting order and next roster. Repeated contacts/input never create duplicate membership. Incomplete queues wait. | `building`, `camera`, `input`, `gui` |
| **L3 — Dispatch one full local group** | L2, F4 | Full groups receive a countdown and exactly one local session assignment. Pre-dispatch departures preserve remaining queue order. Extra entrants wait; capacity handling follows the approved local allocation decision. | `gui` |
| **L4 — Privately select loadouts** | L3, F6–F10 | One timed intermission screen permits edits until deadline; confirmation means ready. Keep opponent selections private in replicated data. Independently default missing choices, explain assignments, reject invalid/late choices, and reveal equipment at arena entry. | `gui`, `input` |
| **L5 — Fight on Sky Bridges** | F3 | Central and two side islands have all three connections. Essential routes work without Bounce. Test safe spawns, camera legibility, ordinary traversal, ring-outs, and slam rejection across island gaps. | `building`, `physics`, `camera` |
| **L6 — Survive The Ring hazard cycle** | F5, F11 | Permanent center remains safe. Select two nonadjacent sections excluding previous-cycle selections. Warnings use pattern/animation and sound. Test escape, safe restoration, unavailable spawn surfaces, surface disappearance under slam, and sudden-death reset to safe phase. | `building`, `physics`, `audio`, `animation-vfx` |
| **L7 — Vote, load, and reset every arena** | L4–L6 | Offer all three maps; resolve ties among leaders and empty votes among all maps. Run both modes on each map. Arena reuse removes old collisions, hazards, actions, effects, and callbacks. | `building`, `gui` |
| **L8 — Follow the complete match HUD** | L1, L4 | Specified placements show mode-specific scores, authoritative timer/cooldown, clockwise radial cooldown, feed, respawn countdown, and sudden death. Verify final-30/final-10 urgency, attribution expiry, blocked-contact exclusion, feed cap, and missing-asset fallback. | `gui`, `animation-vfx` |
| **L9 — Leave or finish without stranding others** | L1, L3, L4 | Exercise every phase-specific departure rule, intermission cancellation, 1v2 continuation, batched departures, no winner when both sides empty, immutable results, and shutdown interruption. Results/cancellation return to a usable local lobby without stale membership. | `gui` |
| **L10 — Read combat and control presentation** | F11, L6, L8 | Required weapon/ability feedback is distinguishable in busy 2v2. Settings provide sensitivity, optional subtle shake, and separate music/effects volume. Essential information remains readable without color alone and at low graphics settings. | `gui`, `camera`, `audio`, `animation-vfx` |

### M2 acceptance and playtest gate

- Pass **AC01–AC18** locally and exercise the relevant AC21–AC26 scenarios.
- Complete the **three maps × two modes** matrix with varied loadouts.
- Run two-attacker pressure, allied-target eligibility, reproducible Magnet targeting, and Ground Slam redirection tests with four clients.
- Exercise consecutive sessions, stale timers/requests, departures during transitions, and arena cleanup. Test parallel local sessions only if the approved local allocation supports them.
- Have an unfamiliar tester complete menu → lobby → queue → selection → match → results → lobby without guidance.

**Exit:** Complete local beta functionality works before transport infrastructure is introduced.

## P1 — M3: Reserved match servers

| ID / vertical slice | Blocked by | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **R1 — Assemble one reserved match** | M2 accepted | A full local roster reaches its intended destination and initializes exactly one session. Destination admission validates server-owned session/roster data. No intermission starts before complete arrival. Test duplicate, unrelated, and late arrivals. | `security`, `networking` |
| **R2 — Recover failed outbound dispatch** | R1 | Exercise dispatch errors and partial arrivals. Apply the configured total arrival bound and retry cap without extending waiting indefinitely. Cancel incomplete groups, release lobby-side players, return arrivals, and prevent unintended partial matches or duplicate starts. | `security`, `gui` |
| **R3 — Return or retain usable recovery** | R1, R2 | Results/interruption/cancellation can return to a valid public lobby. Failed returns use bounded automatic retries, clear errors, and a persistent manual button. Rejoining enters a lobby; no previous-match reconnection/backfill. Test two simultaneous reserved matches for isolation. | `gui`, `security` |

### M3 acceptance and playtest gate

- Pass **AC19** and repeat AC01, AC14, AC18, and AC26 across the actual place transition.
- Test full and partial arrival, failures before/after dispatch begins, destination departures, arrival timeout, late arrival after cancellation, and failed returns.
- Run both modes in the published multiplayer test environment and verify independent reserved sessions.
- Publishing/configuring that environment is a later explicit approval gate; this roadmap authorizes no publishing.

**Exit:** The production-shaped journey and its recovery paths work without stranded players or split matches.

## P2 — M4: Polish and beta acceptance

| ID / vertical slice | Blocked by | Acceptance check and required playtest | Additional Brain skills |
|---|---|---|---|
| **B1 — Refine combat and arena presentation** | M2 | Improve approved animation, sound, effects, camera response, and layouts using original/licensed assets. Preserve hit alignment, warning clarity, and 2v2 visibility. Compare before/after on low graphics and representative desktop viewports. | `animation-vfx`, `audio`, `camera`, `gui`, `lighting`, `building` |
| **B2 — Tune the approved roster and maps** | M3 | Adjust provisional configuration through observed playtests. Recheck all nine loadouts and both modes across maps; investigate compulsory Bounce, unavoidable pressure, unreadable Hammer/slam, and bridge/hazard bias. | `game-design`, `physics` |
| **B3 — Verify and accept the beta build** | B1, B2 | Review AC01–AC26 with evidence; resolve critical failures. Verify chosen desktop hardware, provisional lobby/match capacity, latency, low-graphics readability, and session cleanup. Obtain owner acceptance of tuning and remaining risks. | `performance`, `security`, `publish-checklist` |

### M4 acceptance and playtest gate

Friends-and-family sessions must record fairness, clarity, controls, combat enjoyment, completion/failure causes, and voluntary repeat play. Manual notes and targeted logs are sufficient initially; a persistent analytics system is not required.

**Exit:** Complete acceptance-matrix review, resolved critical gameplay/flow failures, and product owner acceptance of current tuning. No unapproved retention or win-rate threshold is introduced.

## Approved F1 prototype decisions

The product owner approved these choices after reviewing the F1 implementation outline:

- **Rig:** Use a standardized R15 rig, preserving compatible avatar appearance. Review its look in the prototype; this choice may be revised later.
- **Camera:** Tune distance, zoom bounds, pitch bounds, and sensitivity in the prototype under PRD DD01. No final camera values are approved yet.
- **Physics:** Use the existing character simulation as the F1 baseline. Evaluate network ownership and movement validation before F2; the baseline does not establish the final combat physics approach.
- **Slice scope:** F1 verifies traversal and ordinary character placement/replacement. Scored elimination, safe combat respawns, and protection remain in F3.

These approvals resolve the listed F1 planning choices. They do not assert implementation or playtest completion.

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
| **Local allocation/full-capacity behavior** | L3 | Recommend one active local match initially, with additional players waiting in FIFO queues. This is a proposed test allocation, not a change to reserved-server production architecture. |
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

The [F3 implementation and verification](F3/F3_Implementation_and_Verification.md) records 17 deterministic F3 checks, 35 two-client lifecycle checks, the passing 28-check F2 combat regression, the F1 rig/spawn/collision regression, and normal Play/HUD inspection. Runtime scripts match the connected Studio place and temporary fixtures are removed. The product owner signed off F3 gameplay on October 22, 2026. [F4 implementation, verification, and owner acceptance](F4/F4_Implementation_and_Verification.md) are recorded separately. Ability cooldown integration/verification, F3 target-latency coverage, F6 owner acceptance, F7 target-latency coverage, F8-F11 implementation, reference-hardware performance, reserved-server publishing/release gates, and asset export remain incomplete.

[F5 implementation and verification](F5/F5_Implementation_and_Verification.md) records 254 deterministic checks and two-client reset/result/departure checks. The owner published the updated place, confirmed sudden death works, and signed off F5 on October 22, 2026. [F6 implementation and verification](F6/F6_Implementation_and_Verification.md) records the authorized Wrecking Hammer ordinary attack: 29 deterministic checks, 27 geometry checks, 41 two-client combat assertions, the 28-assertion Fist regression, and 104 repeated sudden-death assertions with Hammer equipped. The owner-authorized temporary centered weapon picker is also implemented; its two-client follow-up passed 48 assertions, including staging selection and countdown locking. **F6 awaits owner hands-on gameplay evaluation and sign-off.** An intermittent Roblox ChatScript initialization error remains separately reported in the F5 regression evidence. The owner subsequently approved the F7 design and explicitly authorized its implementation, superseding the previous F7 wait instruction only. F6 gameplay sign-off remains separately unrecorded. F7 is implemented and technically verified: 29 new deterministic checks (500 with regressions), 79 geometry checks across all three weapons, 55 Paddle integration assertions, 48 Hammer and 28 Fist regression assertions, and 110 sudden-death assertions with Paddles equipped. See [F7 implementation and verification](F7/F7_Implementation_and_Verification.md). **F7 owner acceptance: David signed off the current 4.5-stud, 30/8 launch prototype on October 22, 2026.** F7 gameplay acceptance is complete for this slice. **Next planned slice: F8 - Use Gust for positioning; await separate authorization.** F7 target-latency coverage, later balance/art work, and milestone/release gates remain open; this sign-off does not authorize implementation of F8, polishing, or publishing. Deferred abilities, future-map integration, 2v2, remaining verification, and milestone/release gates are unchanged. [F2 Next Steps](F2/F2_Next_Steps.md) records the approved temporary server ownership during knockback; Spring Fist retains its separately confirmed 10-stud center reach.
