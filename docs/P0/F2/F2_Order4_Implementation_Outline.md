# F2 Order 4: Spring Fist implementation outline

October 21, 2026. The product owner confirmed the design discussion and authorized this outline. This document plans Order 5; it does not authorize or claim implementation, testing, asset generation, or F2 acceptance.

The [Order 3 physics decision](F2_Next_Steps.md#order-3-decision-approved-physics-approach) remains authoritative. The current conversation resolves the previously open Spring Fist choices. The older [conversation handoff](F2_Order4_Handoff.md) records the state before those choices were resolved.

## Approved prototype contract

| Concern | Behavior |
| --- | --- |
| Action timeline | Startup 0.08 s, active 0.10 s, recovery 0.32 s; total 0.50 s. Only the active interval detects hits. |
| Moving volume | Oriented box, 4 studs wide, 5 tall, 2 deep. Center moves linearly from 1 to 4 studs ahead of character center during active time. Far edge never exceeds 5 studs relative to the character. Dimensions are provisional tuning. |
| Height and aim | Center vertically on the greybox glove's strike position. Horizontal aim commits at startup and remains locked through recovery; camera pitch does not aim the punch vertically. Character motion carries the volume, including vertical motion and knockback. |
| Contact | Actual body-part overlap, including partial arm/leg overlap, counts. Accessories and weapons do not. Self and allies are excluded. An already-overlapping opponent is eligible when active time starts. Multiple eligible enemies may be hit once each per activation. |
| Travel | Sweep the moving volume between updates so a fast strike cannot skip contact. Previously traversed space is not persistently dangerous. Do not activate the whole lane at once. |
| Walls | Solid arena geometry blocks contact and stops extension for that activation. Moving around the wall cannot restart extension; normal action recovery still completes. Require a clear path to an overlapping body region. |
| Locomotion | 70% base movement during the action; no jumping. Ordinary airborne attacks add no lift/hover. Hit reaction and displacement restrictions take precedence. |
| Launch | Replace velocity with 50 studs/s along committed horizontal punch aim plus 12 upward. Server takes physics ownership before applying launch. Do not use victim facing or add to old velocity. |
| Hit restrictions | 0.15 s hit reaction and 0.35 s displacement/interruption protection from successful hit; independent from physical recovery. Protected contact applies neither launch nor reaction, does not extend protection, and consumes that activation's opportunity against that target. |
| Interruption | A successful weapon hit cancels startup and clears the buffer. An already-active attack retains its remaining active opportunity, follows the displaced character, and clears its next-attack buffer. |
| Simultaneous contact | Mutual active hits resolve as trades. Multiple attackers reaching one unprotected target during one update produce one winning incoming hit, chosen by earliest reconstructed contact, then a stable tie-breaker. Protection blocks the others. |
| Input | One click, one request; holding does not repeat. One next attack may buffer during the final 0.12 s of ordinary attack recovery (0.38–0.50 s after uninterrupted start). Extra clicks do not replace or extend it. No buffer during hit reaction or knockback recovery. |
| Buffered aim | Choose aim when the buffered action starts, then commit it. Invalidated buffers are discarded, never deferred until eligibility returns. |
| Online presentation | Local animation begins immediately. Server accepts/rejects the request and owns action time and results. Successful impact feedback waits for server confirmation. Rejected prediction ends/corrects. |
| Latency baseline | Server processing time and server-observed positions; no client-time backdating or rewind. Measure local/server mismatch in actual combat. |
| Teardown | Death, character replacement, departure, unequip, and session shutdown clear current action, hit volume, buffers, and presentation. Late events cannot affect a new character/equip. |

## Implementation sequence

### 1. Greybox and debug geometry

Use simple runtime parts for the glove and extension, with a toggleable translucent hit-volume overlay. Mark startup, active, and recovery visibly. Visual/debug parts must not collide or participate in hit queries. Use the standardized F1 rig and a fixed strike-height offset aligned to its torso/glove; record that offset in configuration after inspecting the rig. It is an alignment detail, not permission to change the approved height or reach.

Show start/end coverage against point-blank, side, elevated, and five-stud boundary targets before final art. The box is the gameplay authority; the glove presentation must match it. No Blender model or export is needed for this step.

### 2. Minimal action state and request boundary

Keep timing and geometry in one shared F2 configuration; keep deterministic timeline/contact-selection helpers separately testable. Add one server combat entry point and integrate attack input and movement permissions with the existing F1 controller. Avoid a general weapon/ability framework for this slice.

Proposed internal records:

- Per character: character/equip generation, current action, optional one-slot buffer, reaction/protection deadlines, displacement state, and last accepted movement state.
- Per action: server action ID, start time, committed horizontal aim, phase, prior volume transform, wall-stop state, and encountered-target set.
- Per displacement: generation token, original motor state, launch time, observed-motion flag, and release/failsafe ownership.

Request contract: attack press carries a monotonically increasing sequence, current server-issued character/equip generation, and finite horizontal intended aim. It carries no target, hit result, reach, launch, or trusted action timestamp. Validate identity, alive/equipped state, finite nonzero aim, duplicates/stale generations, request rate, and action eligibility. Normalize valid aim. Ignore/reject invalid requests without delayed execution.

For a buffered action, obtain the latest validated horizontal aim when it starts. A bounded aim-update message may update that value while waiting; it cannot rotate the current action, trigger an attack, or supply timestamps. Client presentation and server startup must use the same aim convention. Exact transport names are implementation details.

Server events identify character/equip generation, request sequence where applicable, action ID, server phase times/aim, acceptance/rejection, and confirmed contact outcomes. Correlate prediction with acceptance rather than playing the attack twice. Discard obsolete events.

### 3. Authoritative timeline and contact resolution

Advance actions against a monotonic server clock. Process elapsed active segments even when an update crosses a phase boundary; never stretch a 0.10-second window to compensate for a slow frame. Do not infer hits from visible model touches.

Collect candidates from swept volume/body intersections, reconstruct contact time within the sampled interval, and check obstruction. Broad-phase overlap alone is insufficient for limb-edge acceptance or contact ordering. Include starting overlaps. Cap travel at the first solid obstruction using the volume's extent, not just a center ray. Verify partial exposure without allowing contacts through covered body regions.

Resolve one update in two stages: first collect contact opportunities from the actions active at those contact times; then choose and apply results. This preserves mutual active trades. Sort incoming candidates by reconstructed contact time, then server action ID and attacker UserId for exact ties. Apply existing protection deadlines at contact time, select the first eligible incoming hit, and establish new protection before later candidates. Consume protected contacts once per activation. A startup canceled before its active boundary produces no later contacts.

Sweep history represents the attacker's sampled movement, not teleport permission. Movement correction/reset invalidates the previous sweep segment so it cannot create a map-spanning attack. No rewind of target history is introduced. Verify the contact algorithm against moving targets and low update rates; keep its approximation limits explicit.

### 4. Integrate approved knockback and recovery

Reuse the study's tested behavior, not its two-mode experiment controls. The live F2 path always uses temporary server ownership during displacement. Preserve motor state before suspension; validate and rate-limit limited steering (initially 3 studs/s²) without vertical lift.

Use the accepted minimum 0.12 s displacement duration and landing or horizontal speed <=18 with absolute vertical speed <=8 as prototype recovery conditions, after observed launch motion. Ground checks must exclude the character and temporary visual parts, identify walkable support under the standardized rig, and distinguish departure from the initial floor from a real landing. Exercise wall stops and airborne starts explicitly.

Restore the saved motor and tested locomotion restart, then return ownership to the current player when physical recovery permits. Combined action/reaction restrictions still determine walking/jumping permissions. Keep reaction and protection deadlines separate. Preserve the existing study's bounded failsafe duration during extraction and record it in configuration; timeout release is logged as failsafe cleanup, never a natural recovery pass.

Generation tokens prevent an older release, correction, or timer from restoring controls/ownership during a newer displacement. Preserve the Order 3 movement budget (initial 0.2 s burst, 3-stud slack), last-accepted-transform correction, logging, and no automatic kicks/bans. Corrections compose with active displacement and cannot create a damaging sweep.

### 5. Input, presentation, and lifecycle

Use the existing controller's focus/menu/text-entry gates. Bind mouse press edges, not held state. Apply the buffer using server time and eligibility; clear it on successful incoming hit, death, character/equip change, and teardown. At buffered startup, recheck eligibility and capture current validated aim; otherwise discard it.

Render immediate temporary punch motion, reconcile to accepted server time, and show confirmed impact and displacement protection distinctly. Rejection/cancellation must remove predicted presentation. An active punch surviving a hit keeps only its remaining opportunity, not permission to bypass hit recovery. All cleanup paths are idempotent and scoped to the current generation.

## Verification and completion evidence

Run applicable build/analysis, deterministic tests, Selene, and StyLua checks before changed code reaches Studio. Locate the existing temporary check tools rather than introducing new dependencies. Every Luau assert needs a descriptive failure message. State explicitly if a standalone build/type-analysis tool is unavailable; do not claim it passed.

| Check group | Required cases |
| --- | --- |
| Timing/input | Exact phase boundaries, one click versus hold, buffer at either boundary, extra clicks, current aim at buffered start, invalid input discarded, focus/menu gates. |
| Geometry | Point-blank; exact forward/side/height boundaries; limb-only overlap; accessories excluded; multiple targets once each; no trailing damage; fast extension; walking/jumping attacker; moving target; corrected/teleported attacker. |
| Obstruction | Full wall, thin wall, corner, partial exposure, volume edge hitting wall before its center, movement after wall stop. |
| Collision ordering | Startup interruption, active mutual trade, active trade during displacement, multiple incoming contacts and exact tie, existing/new protection, protected contact consumed without extending timers. |
| Physics | Correct committed-aim replacement launch, server ownership before launch, limited steering, ordinary/airborne/wall/edge recovery, immediate walking after recovery, combined jump restrictions, replacement launch, failsafe diagnostics. |
| Requests/lifecycle | Malformed/nonfinite aim, duplicates, stale generations, spam, rejected prediction, delayed events, death/respawn/unequip/departure, repeated sessions, old release during newer knockback. |
| Multiplayer feel | Both players as attacker/victim/observer, ordinary conditions and measured 100–150 ms RTT; startup readability, spacing, punishable miss, prediction mismatch, trades and protection. |
| Regression | Relevant F1 movement, focus, rig/spawn/collision checks and existing F2 physics helpers. Fixture success does not establish actual combat acceptance. |

Order 5 delivers the temporary playable slice. Order 6 requires recorded combat checks and owner hands-on acceptance; geometry and feel may need refinement. Scoring, safe combat respawn/respawn protection, other weapons/abilities, final art, publishing, and broader performance/security certification remain outside this slice.

## Weapon production workflow

| Stage | Spring Fist work |
| --- | --- |
| Greybox | Temporary glove, extension, debug volume, and phase/protection cues. |
| Implement | Authoritative action/contact flow, requests, movement restrictions, knockback, buffer, and cleanup. |
| Playtest | Two-player actual combat at ordinary and measured target latency. |
| Refine | Adjust provisional dimensions/alignment and presentation from observations; bring gameplay changes back for review. Repeat playtesting. |
| Model | Once silhouette, reach, and motion requirements are stable, create requested source under assets/blender/weapons/. Export only when requested to assets/exports/weapons/. |
| Polish | Align final animation/model with authoritative volume, add final feedback, and rerun combat/readability checks. |

Playtest and refine form a loop. Modeling follows stable mechanics; final art integration still receives another playtest pass. F2 can be accepted with readable temporary presentation before final modeling/polish.
