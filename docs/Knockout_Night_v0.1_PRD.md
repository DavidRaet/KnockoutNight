# Knockout Night v0.1 Product Requirements Document

**Platform:** Roblox  
**Product:** Competitive multiplayer 3D arena fighter  
**Document version:** 0.4 (v0.1 release scope)
**Updated:** October 22, 2026
**Product owner:** ShorlingWild
**Release:** Friends-and-family beta  
**Design authority:** Section 2.2 records the approved core Grill Me decisions; section 2.3 records the subsequent F3 agreement. These supersede conflicting earlier proposals. Original confirmed decisions, Roblox Game Ideation, and HUD whiteboard remain supporting sources.

## Contents

1. [Product brief](#1-product-brief)
2. [Release scope and fixed decisions](#2-release-scope-and-fixed-decisions)
   - [Dedicated design decisions](#22-dedicated-design-decisions-approved-grill-me-agreement)
   - [Approved F3 decisions](#23-approved-f3-decisions)
3. [Player journey](#3-player-journey)
4. [Intermission and loadouts](#4-intermission-and-loadouts)
5. [Movement and camera](#5-movement-and-camera)
6. [Combat foundation](#6-combat-foundation)
7. [Starter weapons](#7-starter-weapons)
8. [Starter abilities and synergy](#8-starter-abilities-and-synergy)
9. [Arena requirements](#9-arena-requirements)
10. [Match rules elimination and scoring](#10-match-rules-elimination-and-scoring)
11. [Sudden death and departure rules](#11-sudden-death-and-departure-rules)
12. [HUD feedback and results](#12-hud-feedback-and-results)
13. [Engineering requirements and local architecture](#13-engineering-requirements-and-local-architecture)
14. [Reserved match-server architecture](#14-reserved-match-server-architecture)
15. [Validation and beta evaluation](#15-validation-and-beta-evaluation)
16. [Implementation phases](#16-implementation-phases)
17. [Provisional tuning register](#17-provisional-tuning-register)
18. [Remaining validation and implementation details](#18-remaining-validation-and-implementation-details)
19. [Deferred features and risks](#19-deferred-features-and-risks)
20. [Source and maintenance notes](#20-source-and-maintenance-notes)

## 1. Product brief

Knockout Night is a third-person arena fighter in which players knock opponents off elevated arenas to earn points. Players compete in 1v1 or 2v2 matches using one freely selected starter weapon and one active ability. Success depends on spacing, timing, movement, positioning, and loadout synergy.

The v0.1 objective is to build a fun, reliable, skill-based multiplayer knockout game that friends want to play again. The first development priority is a complete, enjoyable two-player combat match. The beta then adds the full local lobby flow, all three maps, 2v2, and reserved match servers.

Gameplay is fully 3D. Players move forward, backward, left, and right across the horizontal plane, with jumping and certain abilities providing vertical movement. The HUD is a minimal 2D overlay. There is no conventional health or damage system, traditional blocking, or parrying in v0.1.

### 1.1 Decision status

Every requirement uses the following distinction. A missing number or unresolved rule must not be treated as a finalized specification.

| Status | Meaning | Implementation treatment |
|---|---|---|
| **Confirmed** | Explicitly settled in the supplied design decisions or current request. | Implement for v0.1 unless the product owner revises the decision. |
| **Provisional** | An illustrative starting value or proposed behavior awaiting playtesting. | Keep configurable; evaluate before treating it as a release default. |
| **Open** | No decision has been made. | Resolve when needed for implementation; do not silently invent a final rule. |
| **Deferred** | Explicitly excluded from the v0.1 beta. | Do not include in the release requirements. |
| **Engineering recommendation** | A suggested implementation approach supporting confirmed behavior. | Review during implementation; this does not establish a new product decision. |

Functional requirements below are confirmed unless explicitly labeled otherwise. Numerical values are confirmed only where stated as such. Acceptance criteria depend on the approved configuration, rather than turning provisional values into fixed commitments.

### 1.2 Success definition

- Two players can finish a match, understand why they won or lost, and enjoy fighting each other.
- Every starter weapon and ability has a recognizable purpose and usable counterplay.
- Players can follow the menu-to-lobby-to-match-to-lobby journey without becoming stranded.
- Scoring, cooldowns, teams, eliminations, and match results remain consistent across clients.
- Friends voluntarily choose to play again. No numerical rematch or retention threshold has been approved.

## 2. Release scope and fixed decisions

| ID | Confirmed decision |
|---|---|
| D01 | Roblox Studio and Luau; third-person, fully 3D gameplay. |
| D02 | Ring-outs determine eliminations; no health-based combat, blocking, or parrying. |
| D03 | Both 1v1 and 2v2; server assigns 2v2 teams randomly; friendly fire disabled. |
| D04 | All players can select Spring Fist, Wrecking Hammer, or Paddle Pops. |
| D05 | Equip one weapon and one active ability: Gust, Magnet, or Bounce. |
| D06 | Left click attacks; Q activates the ability on keyboard. |
| D07 | Bounce plus Wrecking Hammer enables Aerial Ground Slam. Other combinations use natural synergy. |
| D08 | The Platform, Sky Bridges, and The Ring support both match modes. |
| D09 | Every regulation ring-out awards one point to the opposing side, regardless of cause. Sudden death awards no points. |
| D10 | A regulation tie enters untimed sudden death without respawns; the first team to lose a player loses. |
| D11 | Local physical lobby queues dispatch groups; queues are not permanently linked to arenas. |
| D12 | Intermission includes map voting and private weapon and ability selection. Equipment locks for combat. |
| D13 | Target architecture uses a public lobby place and a reusable match place with a reserved server per match. |
| D14 | The server validates combat, equipment, cooldowns, friendly fire, scoring, and match state. |
| D15 | Minimal HUD: timer, score, knockout feed, and ability cooldown. |

### 2.1 Beta content inventory

| Category | v0.1 content | Status |
|---|---|---|
| Modes | 1v1 and 2v2 | Confirmed |
| Weapons | Spring Fist, Wrecking Hammer, Paddle Pops | Confirmed |
| Abilities | Gust, Magnet, Bounce | Confirmed |
| Special interaction | Aerial Ground Slam for Hammer plus Bounce | Confirmed |
| Maps | The Platform, Sky Bridges, The Ring | Confirmed |
| Match length | 3 minutes | Provisional |
| Regulation respawn delay | 3 seconds | Provisional |
| Sudden death | Untimed; no respawns | Confirmed |
| Persistent economy and progression | None | Deferred |

All three maps and both modes belong to the complete beta scope. The Platform and two-player combat are the first milestone, not a reduction of the final scope.

### 2.2 Dedicated design decisions: approved Grill Me agreement

**Approval:** October 20, 2026. The product owner confirmed interview decisions Q1-Q76 and authorized this PRD update only. No implementation or asset generation/export is part of this revision. This section supersedes conflicting earlier proposals. Behavioral rules are confirmed; numerical values remain configurable prototype settings, not final balance. Section 17 records those settings.

#### DD01 Combat goals, controls, and characters (Q1-Q5, Q9-Q12, Q66, Q70, Q76)

- Accessible, playful presentation supports deliberate spacing, readable attacks, baiting, and punishable misses. Launch strength is fixed per attack; no accumulating damage or knockback meter.
- Desktop keyboard and mouse first. Mobile is a future design target; mobile/controller support and mappings are deferred for this beta.
- Combat captures the mouse for consistent shift-lock-style controls. Mouse movement rotates an elevated third-person camera; character facing follows horizontal camera aim. Players can strafe/retreat while aiming. No target lock or snapping; camera pitch does not arbitrarily aim ordinary melee vertically. Menus release the cursor and restore combat controls on close.
- Standardize combat rig proportions, collision dimensions, and movement while preserving Roblox avatar appearance where compatible. Disable character-to-character physical collision for allies and enemies.
- Normal jumps allow useful air steering; knockback allows minimal steering and cannot be immediately reversed through walking input. One ordinary jump, no automatic repeat from holding jump, double jump, sprint, dodge roll, or ledge grab.
- Camera distance, bounded third-person zoom, clipping avoidance, animation poses, effects, lobby decoration, menu background scene, and results layout are implementation choices reviewed in the prototype within approved readability rules. Do not introduce mechanics through presentation.

#### DD02 Weapon actions and displacement protection (Q6-Q7, Q13-Q17, Q59-Q63)

- Lock attack facing from activation through recovery even if the camera turns. Allow reduced movement throughout startup, active frames, and recovery; prevent jumping until recovery ends. Hammer commits most strongly.
- Ordinary airborne attacks retain weapon identity without granting hover or lift. One click requests one attack; holding does not repeat. Buffer at most one next attack near recovery's end. Paddle Pops alternates hands across individual activations; no combo chains.
- Each activation can hit multiple eligible enemies once each. Spring Fist uses a narrow forward strike, Hammer a broad frontal sweep matching its animation, and Paddle Pops a compact short strike. Require an unobstructed path and suitable vertical overlap.
- Weapon hits interrupt startup; an attack already active can complete its hit opportunity, allowing trades. Ordinary Hammer has no armor. Successful weapon hits cause a brief hit reaction.
- Successful displacement grants visible, opposing-team-wide protection against further weapon/ability displacement and attack interruption. Blocked contacts do not extend it. Protection grants no movement/recovery; the victim can act after the brief hit reaction.
- After protection expires, weapons and Gust replace velocity with configured launch rather than accumulating force. Launch follows committed horizontal aim plus an upward component. Ground Slam is radial; Magnet is a controlled pull; Bounce replaces velocity with its own launch.
- Ground Slam armor prevents cancellation, not knockback. An incoming weapon hit still launches the attacker and grants ordinary displacement protection; the slam continues.

#### DD03 Shared abilities, Gust, and Magnet (Q8, Q17-Q22, Q60, Q64-Q65, Q67, Q72-Q73)

- No ability cancels the user's weapon action. After an enemy hit interrupts that action, Bounce may activate during ordinary knockback, including its weapon-hit reaction. Gust's 0.25-second stun blocks Bounce. Gust/Magnet cannot activate during the brief hit reaction.
- Gust/Magnet work grounded or airborne without lift/hover, have startup and recovery, cannot overlap weapon attacks, and initially have no input buffer. Bounce launches immediately when valid, with a short primary-attack delay.
- Start cooldown on accepted activation, even on a miss. Rejected requests spend nothing. Weapon hits interrupt Gust/Magnet startup: spent cooldown remains spent, and an interrupted startup produces no effect. Already applied effects are not undone.
- Gust pushes multiple eligible enemies in a frontal cone and applies a 0.25-second stun that blocks new actions and interrupts startup. Attacks already active retain the shared trade rules. Respect solid geometry and displacement protection. Owner tuning revision, October 22, 2026; replaces the initial no-attack-cancellation rule.
- Magnet selects one eligible enemy in a frontal cone, prioritizing aim alignment, then distance, with ascending Player UserId for exact ties. Require a clear path; exclude protected targets. No eligible target means a miss that spends cooldown. Pull toward the user's current position at 28 horizontal studs/s for up to 0.55 seconds, stopping three horizontal studs short and preserving vertical velocity. The target cannot steer/jump during the pull but can attack or use an otherwise-valid ability; no stun or cancellation of existing attacks.
- Magnet grants displacement protection at pull start until the later of pull completion or the ordinary protection deadline. Weapon follow-ups must wait for protection to expire; no guaranteed immediate launch combo.
- Bounce alone provides upward recovery. Keep Gust/Magnet viable through offensive positioning value; frequent compulsory Bounce selection is a balance failure to investigate.

#### DD04 Bounce and Aerial Ground Slam (Q18-Q19, Q23-Q27, Q35, Q59, Q67, Q74)

- Bounce replaces current velocity. Camera-relative movement input determines horizontal direction; no input means straight up. After launch use ordinary airborne steering. Bounce can end an incoming Magnet pull, grants no new protection or armor, retains existing enemy-hit protection, and does not clear enemy knockout attribution. One activation per cooldown, no unlimited flight.
- Hammer plus Bounce unlocks one slam opportunity until landing, a weapon hit, or elimination. The first primary attack during eligible flight becomes Ground Slam; ordinary jumping does not unlock it.
- Raise the Hammer in a brief telegraph, then accelerate downward with very limited horizontal steering and retained horizontal momentum. No hovering or added upward boost.
- Once activated, the slam resists interruption through descent, but weapons, Gust, and Magnet can displace it. After an incoming weapon launch's brief reaction, resume descent on the redirected trajectory without replaying windup or granting another Bounce.
- Landing produces one radial shockwave per enemy with less launch strength than a direct Hammer hit; no separate direct-hit stacking. Landing has punishable recovery.
- Require the top of a playable surface, nearby targets at roughly the same elevation, and an unobstructed path on that surface. No shockwaves through floors or across separate island gaps. Walls, undersides, characters, and void boundaries cannot trigger impact; a disappearing surface means continued falling.
- Elimination ends the move. Armor gives no ring-out immunity. Slam neither refreshes nor spends Bounce again.

#### DD05 Elimination, spawning, and countdown (Q28-Q34, Q68)

- Passing a horizontal edge does not eliminate. Recovery remains possible until crossing the lower plane; commit elimination immediately then reject abilities. Distant outer bounds catch extreme launches.
- Use predefined safe regulation spawn points, favoring distance from enemies and avoiding character overlap and unavailable/collapsing surfaces. Initial positions are symmetric; teammates start on the same side.
- Visible respawn protection prevents dealing/receiving combat effects but allows movement. Any attack or ability ends protection before resolving. Falling still eliminates. Spawn and post-hit protection do not stack into longer protection.
- Cooldowns continue through death/respawn without pausing or refreshing. Fresh matches and sudden-death rounds start ready.
- Avatar reset or unexpected character death counts once as an elimination: opposing point and respawn in regulation; loss of that life in sudden death. Disconnects use departure rules instead.
- Briefly show the fall, then spectate a survivor. Show a regulation respawn countdown; no free camera or killcam initially.
- Reveal equipment on arena entry. Opening countdown disables movement/combat; GO enables movement, weapons, abilities, and the timer together.

#### DD06 Regulation and sudden death (Q36-Q39)

- Count only eliminations committed before the regulation deadline. Freeze combat at expiry and determine the result; pending falls do not count.
- On a tie reset all remaining connected players, including pending respawns, to fair spawns. Clear motion, actions, temporary protection, and effects; restore abilities/hazards and repeat the countdown. Departed players remain absent, including an existing 1v2.
- Retain tied regulation score and show SUDDEN DEATH. The first side to lose a player loses unless the opposing side also loses one within the simultaneity window. Keep gameplay running during that window, then confirm the winner or reset the round.
- Mutual elimination uses the same complete reset. The side that fell first does not win. No additional overtime points system, timer, shrinking arena, or anti-stalling mechanic.

#### DD07 Arenas and hazards (Q40-Q44)

- The Platform is circular. All essential Sky Bridges routes are walkable or use ordinary jumping; none requires Bounce. Bounce may offer shortcuts. Bridges permit approach, dodging, and fighting rather than single-file precision.
- The Ring has a permanent center and segmented outer ring. Server selects two nonadjacent sections per cycle, excluding sections selected in the previous cycle. Repeat safe, warning, collapse, and restoration phases.
- Warnings combine visible patterns, flashing boundaries, and sound, never color alone. Restoration must not trap or launch characters.
- Continue ordinary hazard cycles during sudden death, restarting at the safe phase each round. No accelerated collapse or shrinking arena.

#### DD08 Intermission and queues (Q45-Q48)

- Map voting and private loadout selection share one timed screen. Choices can change until deadline; confirmation means ready, not irreversibly locked. Keep the full window initially.
- Randomly choose among tied vote leaders; no votes means random among all maps. Independently default missing weapon/ability to Spring Fist/Gust, retaining valid choices and briefly explaining assigned defaults.
- Begin with one separated queue zone per mode. Extra entrants wait in arrival order for the next group; visibly identify the next roster. Leaving removes a waiting player; one membership per player.
- Full group starts dispatch countdown. Departure before teleport begins cancels dispatch, preserves remaining queue order, and restarts countdown when full. After teleport begins apply DD09.

#### DD09 Session failures and results (Q49-Q54)

- Require the entire expected roster before intermission, with bounded arrival timeout and outbound retries. Cancel incomplete groups instead of starting unintended 1v1/1v2; release lobby-side players and return destination arrivals. Retries cannot extend waiting indefinitely.
- Failed lobby returns retain usable results/recovery UI with bounded automatic retries, clear errors, and a manual Return to Lobby button that remains available. Cancelled matches use cancellation wording.
- No previous-match reconnection or backfill. Rejoining enters a public lobby; departure outcomes remain final.
- Resolve departures together at the end of the current server update. One remaining side wins by forfeit; neither remaining means no winner, not two competitive losses. Finalized results do not change.
- Shutdown before a finalized result abandons the match without winner, penalty, or restoration. Show interruption/attempt lobby return where possible; abrupt failure may require rejoining.
- Results show winner, team scores, and normal/sudden-death/forfeit outcome, then return to lobby. Include immediate Return to Lobby. Defer direct rematches and individual performance statistics.

#### DD10 Feed, presentation, and validation (Q55-Q58, Q69-Q70, Q75-Q76)

- Credit the most recent successful enemy displacement within the attribution window using its weapon/ability icon. Protected/blocked contacts do not qualify. Otherwise show an environmental fall. Clear attribution each life; credit never determines scoring.
- Cap feed lifetime/entries and replace the oldest at capacity. Keep names readable; use a generic icon if an asset fails.
- Provide sensitivity, optional subtle camera shake, and separate music/effects volume controls. Essential information uses shapes, text, or animation in addition to color. Avoid rapid full-screen flashes and preserve warnings at low graphics settings.
- Use simple original or clearly licensed placeholder effects/audio until combat is validated, then polish. Existing Hammer is a visual reference; this does not authorize regenerating/exporting it.
- Validate two-player combat on The Platform first: readable Hammer dodges, Paddle Pops response opportunities, central-position survivability, useful but fallible Bounce recovery. Final art/teleports follow combat validation.
- Initial targets: 12-player lobby, four-player match server, 60 FPS desktop, tests at 100-150 ms round-trip latency. Select reference hardware before performance signoff. No implementation/test completion is asserted.

### 2.3 Approved F3 decisions

**Approval:** October 22, 2026. The owner approved F3 interview Q1–Q7, confirmed the shared design, and authorized implementation. These choices refine DD05 and V03; they do not establish gameplay acceptance.

- Check predefined safe spawn candidates during the ordinary 3-second respawn countdown. At the deadline, use the designated fallback on a permanently playable surface if no normal candidate is valid. If the fallback is also unavailable, stop the local session with a clear error. Do not add another score, declare a winner, or leave an indefinite respawn.
- Exclude overlap and unavailable/unsupported surfaces. Among valid points, maximize the minimum horizontal distance from living opponents; rotate exact ties. Revalidate at placement time.
- Recreate a standardized R15 character per life while retaining compatible appearance. Keep score and future ability cooldown state outside the character lifetime.
- Show a visible shield during the provisional 3-second spawn protection. Allow movement; an accepted attack/ability ends protection before its action resolves; falling still eliminates.
- Follow the eliminated character for approximately 0.75 seconds after commitment, then follow a survivor until respawn. Use a fixed arena view when no survivor is available.
- Include the 1v1 score, knockout notifications, and respawn countdown in F3. The regulation timer/results and sudden death remain F4/F5.

The [F3 implementation and verification](F3/F3_Implementation_and_Verification.md) records implementation, technical checks, product-owner gameplay sign-off on October 22, 2026, and remaining limits. F4 is the next roadmap slice. Ability integration and target-latency coverage remain future validation work.

## 3. Player journey

**Confirmed flow:** Main Menu → Lobby → Queue → Intermission → Map Vote / Loadout Selection → Arena → Results → Lobby.

### 3.1 Main menu and lobby

**Purpose:** Give players one clear starting action and a shared space from which to find a match.

**Requirements**

- PF01: Show the Knockout Night title or logo over a blurred 3D background.
- PF02: Provide one prominent **Play** button. Do not add inventory or progression menus in v0.1.
- PF03: Play enters the shared 3D lobby. Reusing its scene as the menu background is a presentation implementation choice (DD01).
- PF04: Provide distinct physical matchmaking areas for 1v1 and 2v2. Multiple queue zones may exist.
- PF05: After results, return players to a public lobby where they can queue again.

**Technical constraints:** Menu presentation is client-side. Queue membership and match assignment are server-owned. The target architecture places the shared lobby in the public lobby place.

**Acceptance criteria**

- A newly joined player can identify Play and reach the lobby.
- Both queue modes are distinguishable in the lobby.
- Completing a match leads back to a usable lobby flow.
- No starter item requires an unlock, purchase, or inventory interaction.

**Edge cases:** Repeated Play input must not cause multiple transitions. A player who returns from a match must not retain an active membership in their old queue or match.

### 3.2 Queue behavior

**Purpose:** Form matches from players already present in the same lobby server.

- QU01: Entering a designated physical zone joins its queue.
- QU02: A 1v1 group requires two players; a 2v2 group requires four.
- QU03: A partially filled queue keeps waiting rather than repeatedly expiring.
- QU04: Leaving a queue removes the player, updates the count, and lets the remaining players continue waiting. There is no reward or penalty.
- QU05: When full, lock the group and transition it toward a match session.
- QU06: Queue areas act as entry points and are not permanently tied to individual arena instances.
- QU07: Match only players from the same public lobby server. Cross-server matchmaking is deferred.
- QU08: Assign 2v2 teams randomly on the server. No party formation or manual teammate selection.

**Confirmed:** Dispatch uses a provisional 3-second countdown. Before teleport, a departure cancels dispatch and preserves remaining queue order (DD08).

**Engineering recommendation:** Maintain one authoritative queue membership and dispatch record per player. Use a group identifier to prevent duplicate dispatch when zone contacts or join requests repeat.

**Acceptance criteria**

- A queue with fewer than its required players remains available and does not launch an incomplete match.
- Filling a queue creates one locked group and one dispatch attempt for that group.
- Leaving while waiting immediately releases membership and updates the visible count.
- Different groups cannot claim the same player.
- 2v2 starts with two server-assigned teams of two; clients cannot choose teammates.

**Resolved:** One separated zone per mode, first-in-first-out extra entrants, one membership per player, and visible next roster. Use DD08 before teleport, DD09 during arrival, and intermission cancellation after assembly.

## 4. Intermission and loadouts

**Purpose:** Let matched players choose an arena and a simple loadout without inventory management.

- IN01: Intermission occurs after matchmaking. In the target architecture, it runs in the reserved match server.
- IN02: Offer a vote among The Platform, Sky Bridges, and The Ring.
- IN03: Let each player select exactly one of the three starter weapons and one of the three starter abilities.
- IN04: Allow loadout confirmation or assign a default when no valid selection is completed.
- IN05: Do not reveal opponents' loadouts during intermission.
- IN06: Validate equipment choices on the server; reject invalid or unavailable identifiers.
- IN07: Lock equipment once combat starts.
- IN08: If anyone leaves during intermission, cancel the match in both modes, return the remaining players to the lobby, and issue no official match result or rewards.

| Item | Starting proposal | Status |
|---|---|---|
| Shared map-vote/loadout window | 15 seconds | Provisional duration; shared screen confirmed |
| Editing / confirmation | Editable until deadline; confirmation means ready | Confirmed |
| Missing selections | Independently default to Spring Fist / Gust, preserving valid choices and explaining assignments | Confirmed |
| Vote tie / no votes | Random among tied leaders / all maps | Confirmed |
| Voting and selection screen | Concurrent on one screen for full window | Confirmed |

**Technical constraints:** The server determines phase deadlines and accepted selections. Client display state cannot override a locked loadout. Loadout privacy must include replicated data, not just hiding portraits in the interface.

**Acceptance criteria**

- All three maps, weapons, and abilities are available in their respective choices.
- Every player enters combat with exactly one valid weapon and one valid ability.
- Missing selections resolve to the approved default rather than blocking the match.
- Late selection requests cannot change combat equipment.
- Opponent selections remain private during intermission.
- An intermission departure cancels the match and provides a return path for every remaining participant.

**Acceptance:** Exercise tied/empty votes, independent defaults, editable confirmation, and late rejection under DD08.

## 5. Movement and camera

**Purpose:** Support spacing, juking, positioning, and recovery in a fully 3D arena.

- MV01: Use a third-person view with movement across both horizontal axes: forward, backward, left, and right.
- MV02: Support jumping. Vertical movement also comes from applicable abilities and combat knockback.
- MV03: Keep initial character movement speed consistent across weapons. Paddle Pops' speed identity comes from attacks, not faster locomotion.
- MV04: Use committed knockback as the initial combat approach: a hit sends the target along a knockback trajectory.
- MV05: Bounce can be activated during ordinary knockback if available. There is no universal air-recovery input or specialized universal recovery system.

**Resolved:** DD01 defines desktop camera-directed horizontal aim, standardized rigs, noncolliding characters, and air control. DD02 defines attack commitment; section 17 supplies starting movement values. Camera distance, bounded zoom, and clipping handling are presentation implementation choices.

**Technical constraints:** Controls must support all approved actions without obscuring the HUD. Server validation must account for legitimate jumping, knockback, Bounce, and network delay; ordinary client-controlled character physics cannot be assumed trustworthy.

**Acceptance criteria**

- Players can approach and circle each other from any horizontal direction; movement is not restricted to a side-scrolling plane.
- All weapons use the same approved base movement settings.
- Jumping and valid Bounce activations work in the applicable character states.
- A normal hit produces a readable directional launch, while an available Bounce can attempt recovery.
- Once aiming and facing rules are chosen, visual attack direction and server hit direction agree.

**Resolved:** Reduced movement and no jumping during weapon actions; no self-action ability cancels. Bounce may act during ordinary knockback after interruption. Ground Slam uses its committed descent (DD02-DD04).

## 6. Combat foundation

**Purpose:** Make attacks readable, punishable, and mechanically consistent across the roster.

- CB01: Left mouse click initiates the equipped weapon's primary attack.
- CB02: Each attack has startup, active hitbox, and recovery phases.
- CB03: Hits apply directional knockback determined by configurable attack parameters. Do not introduce a conventional health or damage system.
- CB04: Missed attacks leave recovery that opponents can punish.
- CB05: Commit elimination at the lower plane or distant outer bounds, not at the horizontal edge; recovery stops immediately at commitment (DD05; section 17).
- CB06: Prevent indefinite stun-lock using visible displacement/interruption protection against the opposing team, with a brief weapon-hit reaction (DD02-DD03).
- CB07: Disable friendly fire in 2v2. Allies must not receive harmful weapon, ability, or Ground Slam effects.
- CB08: Use shared configurable weapon definitions rather than three separate combat systems.

**Technical constraints:** The server validates match membership, phase, equipped item, action timing, target eligibility, hit geometry, and friendly-fire rules before applying combat outcomes. Client animation and visual hits cannot directly award score or authorize force application.

**Engineering recommendation:** Give each attack activation a unique identifier and track valid target contacts for that activation. Decide intended repeat-hit behavior explicitly before implementing it; duplicate hitbox callbacks must not create unintended extra hits.

**Acceptance criteria**

- All attacks expose distinguishable startup, contact, and recovery behavior.
- A target outside the approved hit geometry is not hit; an allied target receives no harmful effect.
- A client cannot bypass recovery, substitute an unequipped weapon, or apply arbitrary launch values.
- Sustained Paddle Pops pressure cannot indefinitely remove every opportunity to respond.
- Ring-outs use the elimination system exactly once per life, independently of attack attribution.

**Resolved:** One-click attacks, one late buffer, once-per-target hits, ordinary air attacks, startup interruption, active trades, and protection follow DD02. Do not add combo chains, blocking, or parrying.

## 7. Starter weapons

All three weapons are freely available to every player. None should be categorically stronger than the others. Balance through startup, active duration, reach, horizontal and vertical launch, recovery, and attack frequency.

### 7.1 Spring Fist

**Confirmed identity:** Balanced. A spring-loaded boxing glove attached to a handheld mechanism.

Left click extends the glove forward in a quick spring-powered punch. Opponents within its attack hitbox receive knockback. It has minimal startup and moderate recovery, with reliable reach and launch strength. It should be responsive and versatile without specializing in maximum launch power or very fast repeated attacks.

**Acceptance:** The glove extension visibly corresponds to the active attack; the configured hitbox applies the intended directional launch. Its timing and reach remain distinguishable from both Hammer and Paddle Pops.

### 7.2 Wrecking Hammer

**Confirmed identity:** Heavy. A substantial demolition hammer that is deliberately not comically oversized.

Left click initiates a heavy swing with visible windup, greater reach than Spring Fist, high knockback, and longer recovery. The user is vulnerable to jukes and missed swings. Bounce enables its special Aerial Ground Slam interaction.

**Acceptance:** Opponents can recognize the windup, move to avoid it, and punish a miss. A successful direct hit delivers the intended heavy launch. The character silhouette and weapon scale remain readable.

### 7.3 Paddle Pops

**Confirmed identity:** Speed. A pair of lightweight foam paddles used for quick alternating slaps.

Left click initiates short-range strikes with low individual knockback and fast attack and recovery cycles. This creates close-range pressure with low attack commitment, at the cost of reach and individual launch power. Movement speed remains the same as other loadouts.

**Acceptance:** Alternating strikes visibly communicate the fast attack identity. The short reach requires approaching an opponent; repeated attacks cannot cause indefinite stun-locking.

**Approved F7 decisions, October 22, 2026:** The owner approved the design and authorized the local 1v1 Platform implementation. Start with right-hand slaps, alternating on accepted activation even on misses, protected contacts, or interrupted startup. Rejected requests and merely queued attacks do not consume a hand. Preserve alternation through pauses; reset to right on fresh match, respawn, sudden-death reset, or weapon change. Both hands share tuning and use mirrored boxes 3 studs wide by 4 tall, extending 0.5–4.5 studs forward from the character root at root height, offset 0.5 studs toward the attacking hand. Keep shared combat rules and use the provisional 0.10/0.08/0.16-second timing, 30/8 studs-per-second launch, 85% attack movement, and one buffer in the final 0.12 seconds. Protected contacts show a shield cue without a successful-hit effect or protection extension. Use two simple procedural foam-paddle proxies and include Paddle Pops in the existing centered staging picker.

**Implementation status:** Implemented, technically verified, and owner gameplay accepted October 22, 2026, at 4.5-stud forward reach and 30/8 studs-per-second launch. Target-latency verification, later balance/art work, and milestone/release gates remain separate. See [F7 implementation and verification](F7/F7_Implementation_and_Verification.md). F7 authorization does not authorize abilities, polishing, assets/export, or publishing.

### 7.4 Provisional weapon configuration

These are illustrative starting parameters, not approved final balance. Launch targets are intended velocities in studs/second, not literal Roblox force units.

| Parameter | Spring Fist | Wrecking Hammer | Paddle Pops | Status |
|---|---:|---:|---:|---|
| Startup | 0.08 s | 0.48 s | 0.10 s | Provisional |
| Recovery | 0.32 s | 0.65 s | 0.16 s | Provisional |
| Reach | 11 studs | 7 studs | 4.5 studs | Provisional; Spring Fist tuned after playtests |
| Horizontal launch target | 50 | 118 | 30 | Provisional; Hammer tuned toward 20 studs of grounded idle travel on October 22, 2026 |
| Vertical launch target | 12 | 16 | 8 | Provisional |
| Active duration | 0.10 s | 0.18 s | 0.08 s | Provisional |
| Hitbox identity | Narrow forward | Broad frontal sweep, about 100 degrees | Compact short strike | Shapes confirmed; angle provisional |

Attack cycles include startup, active duration, and recovery; DD02 defines input. Reach is forward hit-volume extent from the character, not extra distance beyond the model. Exact widths/heights follow animation and prototype validation. Paddle Pops need not have every timing parameter lower than Spring Fist.

## 8. Starter abilities and synergy

**Purpose:** Add positional choices and loadout variety without equipment superiority.

- AB01: Each player equips one active ability and activates it with Q on keyboard.
- AB02: The server enforces availability and cooldowns; clients display their state.
- AB03: Desktop keyboard/mouse first; controller/mobile support and mappings deferred, with mobile a future design target.

### 8.1 Gust

**Confirmed:** A short frontal cone of wind creates a brief directional push. Visually, wind begins behind the user and travels through and ahead of the character. Its principal role is positioning rather than large knockout force.

Use it to disrupt approaches, create distance, or move opponents toward an edge. It must not automatically cancel every opposing attack.

**Resolved:** Gust displaces and briefly stuns eligible enemies, interrupts startup, respects geometry/protection, and can hit multiple enemies. Active attacks retain shared trade rules. DD03 defines action rules; section 17 supplies current prototype values.

**Acceptance:** Visual wind origin and frontal gameplay hitbox communicate the same direction. Enemies inside the approved cone receive the intended push; allies do not. Gust interrupts startup and blocks immediate new actions for 0.25 seconds; attacks already active remain valid under shared trade rules.

### 8.2 Magnet

**Confirmed:** A short-range pull brings a nearby opponent in the intended direction toward the user. The target can still attack or respond; a skilled opponent may use the pull to create their own opportunity.

Use it to punish misses, close distance, or set up a weapon attack.

**Resolved:** DD03 defines aim-first single targeting, obstruction, stop distance, response permissions, and pull protection. Approved F9 settings: 12-second cooldown; 20-stud horizontal root range; 60-degree full cone; actual body overlap with a five-stud-high band centered on the user root; 0.12-second startup and 0.20-second recovery with normal user movement/jumping. Weapon hits interrupt startup without refund; already-started pulls continue after the user is hit. Targets receive displacement protection from pull start until the later of completion or 0.35 seconds. Section 17 supplies values.

**Prototype status, October 22, 2026:** F9 is implemented on The Platform in local 1v1. F9 originally defaulted Q to Magnet. F10 now routes Q through the temporary staging ability selector; the later private intermission selection remains deferred. [Implementation and technical verification](F9/F9_Implementation_and_Verification.md). David signed off the current F9 prototype on October 22, 2026. Live multiplayer/target-latency verification and later milestone/release gates remain open. F10 was subsequently authorized and implemented; its gameplay acceptance remains pending.

**Acceptance:** The pull moves an eligible enemy toward the user without inherently disabling all responses. DD03 target selection must be reproducible in 2v2; the server cannot accept an arbitrary client-nominated victim.

### 8.3 Bounce

**Confirmed:** Launches the user upward with directional movement. It works grounded, airborne, and during ordinary knockback when available. It has one activation per cooldown and enables escape, edge recovery, repositioning, and aerial initiation.

Bounce must not create unlimited flight or multiple air dashes. Offensive use consumes the same opportunity that could otherwise save the player from a later ring-out.

**Resolved:** Bounce uses camera-relative movement direction, otherwise straight up, replaces velocity, and then permits ordinary air steering. Cooldowns persist through death and reset for fresh matches/sudden-death rounds (DD03-DD06; section 17).

**F10 implementation, updated October 23, 2026:** Local 1v1 Platform prototype uses a 10-second cooldown, **48 horizontal / 90 upward studs/s** replacement launch, and a 0.15-second primary delay without buffering. Movement input is sampled on Q press with normalized diagonals; camera pitch is ignored. Bounce recovers during ordinary weapon-hit reaction and escapes Magnet, but cannot cancel an ongoing self-action or bypass Gust stun or elimination. The owner-authorized temporary ability selector sits beside the weapon selector, defaults to Bounce, locks at countdown, and is enforced on the server. Cooldowns persist through death and reset for fresh matches/sudden-death rounds. David signed off current F10 gameplay and 48/90 tuning on October 23, 2026. [Implementation and verification](F10/F10_Implementation_and_Verification.md) retains earlier tuning history; F11 verification reran 74 Bounce and 50 Magnet engine assertions at current tuning. Two-live-client/target-latency verification remains open. This corrects stale documentation without changing F10 behavior.

**Acceptance:** One valid activation is possible per cooldown. A player can attempt recovery during ordinary knockback, but cannot reactivate repeatedly while unavailable. Using Bounce offensively leaves it unavailable for recovery until the cooldown permits it.

### 8.4 Aerial Ground Slam

**Confirmed sequence:** Equip Wrecking Hammer and Bounce → activate Bounce with Q → use primary attack while airborne → prepare a downward hammer strike → land and create a short radial shockwave that pushes nearby enemies outward.

Its landing area and windup should be predictable enough for opponents to move away. Bounce is consumed, leaving the user without that escape option during cooldown. Wide coverage and lower launch strength than a direct Hammer hit are confirmed; exact values remain provisional.

**Resolved:** DD04 defines the Bounce-unlocked slam, armored descent with displacement counterplay, valid landing, shockwave-only impact, and recovery; section 17 supplies starting values.

**F11 implementation, October 23, 2026:** Local 1v1 on The Platform implements the approved 0.25-second telegraph, at-least-90 downward speed, nine-stud shockwave, 55/13 launch, and 0.65-second recovery. Only actual Bounce flight unlocks it; armor preserves the move while weapons, Gust, and Magnet redirect it. Valid tagged surface tops, same-surface support, elevation, obstruction, teams, protection, and once-only contact are enforced by the server. [Implementation and verification](F11/F11_Implementation_and_Verification.md) records 590 offline checks, 126 F11 engine assertions at current tuning, and an earlier one-client input/physics probe. David signed off F11 gameplay on October 23, 2026, at the nine-stud radius and 55/13 launch tuning. Two-live-client/latency verification and milestone/release gates remain open; this sign-off does not authorize another slice or publishing.

**Acceptance:** The input sequence reliably produces one valid landing shockwave; enemies in the approved radius are pushed outward and allies are unaffected. Falling into the void must not generate an unintended arena-wide impact. Apply DD04 armor/displacement rules; missing or invalid landing surfaces do not produce impact.

### 8.5 Natural loadout synergy

| Weapon | Gust | Magnet | Bounce |
|---|---|---|---|
| Spring Fist | Edge control and follow-up punches | Pull into punch range | Repositioning and aerial approaches |
| Wrecking Hammer | Force movement before a heavy swing | Pull into Hammer range | Aerial Ground Slam |
| Paddle Pops | Pressure toward exposed edges | Bring enemies into close range | Hit-and-run repositioning |

These describe intended opportunities, not guaranteed combos. Do not implement nine separate special attacks for v0.1.

## 9. Arena requirements

**Purpose:** Offer three distinct combat environments without changing the core ring-out objective. Every map supports both 1v1 and 2v2.

DD05 defines safe spawns, protection, and elimination commitment; DD07 defines topology/hazards. Section 17 supplies provisional dimensions/bounds. Exact spawn coordinates are greybox implementation details to validate before final art.

### 9.1 The Platform

| Attribute | Confirmed specification |
|---|---|
| Purpose | Fundamental combat testing and balanced competition |
| Theme | Calm, minimal, neutral; Japanese inspiration is provisional |
| Layout | One circular platform; provisional diameter in section 17 |
| Terrain | Almost entirely flat; no significant elevation changes or additional routes |
| Edges | Fully open |
| Hazards | None |
| Competitive role | Primary arena for weapon, spacing, timing, and positioning balance |

**Acceptance:** Both modes can complete matches on the map. All edges support the intended ring-out behavior. The arena introduces no active hazards or deliberate weapon advantage. Its simplicity must be evaluated for repetition during beta.

### 9.2 Sky Bridges

| Attribute | Confirmed specification |
|---|---|
| Theme | Floating islands above clouds, ancient stone bridges, scenic ruins |
| Main surfaces | One central island and two smaller side islands |
| Connections | Center to each side island; a third bridge connects the side islands |
| Footprint | Medium-large; provisional island/bridge dimensions in section 17 |
| Threats | Narrow bridges, exposed edges, surrounding void |
| Active hazards | None required |

**Acceptance:** All three bridge connections are traversable. Falling from islands or bridges invokes the same ring-out system. Both modes have safe spawn arrangements. Routes remain legible from the approved camera.

**Balance hypotheses:** Hammer may benefit from bridge knockback; Spring Fist may remain versatile; Paddle Pops may face approach risk while punishing slower attacks. These are hypotheses to test, not requirements to preserve an advantage. Watch for excessively frequent 2v2 ring-outs.

### 9.3 The Ring

| Attribute | Confirmed specification |
|---|---|
| Theme | Visually striking circular fighting arena |
| Layout | Medium circular platform, mostly flat, fully exposed outer edge |
| Active hazard | Outer ring sections periodically disappear or lose collision |
| Normal safe area | Center remains a reliable safe area during normal hazard cycles |
| Excluded motion | Continuous whole-arena rotation |

**Confirmed hazard cycle:** Safe period → selected outer sections warn players → marked sections collapse or lose collision → sections restore → repeat.

Warnings must be clear and allow adequate reaction time. Normal cycles must not create unavoidable eliminations. All loadouts should remain competitively viable.

**Resolved:** DD07 defines nonadjacent section selection without consecutive repeats, multimodal warning, safe restoration, and ordinary cycles in sudden death. Section 17 supplies cycle settings. No shrinking arena.

**Technical constraints:** The server controls hazard state and collision changes. Clients render matching warnings. Safe spawns must account for current hazard state; a visual-only warning cannot be the sole authority for whether a surface exists.

**Acceptance criteria for arenas**

- Each map runs in both modes with the correct roster and safe spawns.
- On The Ring, only warned sections collapse according to the approved pattern, the center remains reliable during normal cycles, and restored sections regain their intended collision.
- Players can recognize the hazard warning and escape under normal conditions using the approved movement configuration.
- Ring-out scoring behaves consistently whether a fall comes from combat, a bridge, or a collapsing section.
- Map cleanup resets surfaces, collision, hazards, and temporary effects before reuse in a local session.

## 10. Match rules, elimination, and scoring

### 10.1 Regulation

- MR01: Run two competing players in 1v1 or two teams of two in 2v2.
- MR02: Use a timed regulation period. **Provisional starting duration: 3 minutes.**
- MR03: Every ring-out awards **exactly one point to the opposing player or team**, regardless of cause.
- MR04: Respawn eliminated players during regulation. **Provisional delay: 3 seconds.**
- MR05: At regulation expiry, the side with more points wins; tied scores enter sudden death.
- MR06: The server owns the timer, score, elimination status, and winner.

| Ring-out example | Required score outcome |
|---|---|
| Player is knocked off by an enemy | Opposing side receives +1 |
| Player walks off accidentally | Opposing side receives +1 |
| Player intentionally jumps off | Opposing side receives +1 |
| A teammate falls during 2v2 | Opposing team receives +1 |
| Player falls because of The Ring hazard | Opposing side receives +1 |
| The same elimination triggers multiple callbacks | Still only +1 total |

### 10.2 Elimination lifecycle

Each life must produce at most one elimination event and one regulation score increment. Disable further scoring from that eliminated life. During regulation, show knockout feedback and a respawn countdown, then safely respawn the player according to approved spawn rules.

**Engineering recommendation:** Track a match identifier, player life identifier, and processed-elimination state. Commit the elimination and score together before broadcasting presentation events. Clear life-specific hit attribution on a new life.

**Resolved:** DD05 defines bounds, recovery cutoff, avatar reset/death, and safe respawns. Disconnects are not ring-outs. Failure-to-spawn recovery remains an engineering detail to validate (section 18).

### 10.3 Scoring and attribution are separate

The team score does not depend on determining who last hit the eliminated player. Individual knockout statistics may be tracked separately, but detailed assists and attribution are not required for initial scoring.

Use the latest successful enemy displacement within a provisional 5 seconds, displaying its weapon/ability icon. Protected contacts do not qualify. Otherwise show an environmental fall (DD10).

**Acceptance criteria**

- Every regulation ring-out adds one point to the opposing side, including self-inflicted and environmental falls.
- Multiple simultaneous callbacks for one life cannot add multiple points or schedule multiple respawns.
- Both clients display the same score, remaining phase, and authoritative result.
- The approved respawn delay is respected, and a respawn cannot place the player on an unavailable hazard section.
- Removing or changing feed attribution does not change team scoring.

## 11. Sudden death and departure rules

### 11.1 Sudden death

**Confirmed:** A regulation tie starts sudden death. It is untimed, has no respawns, and ends on the first decisive elimination. In 2v2, the first team to lose a player loses sudden death; it is not necessary to eliminate the entire team.

If both sides are eliminated effectively simultaneously, restart sudden death instead of arbitrarily choosing a winner. The HUD displays **SUDDEN DEATH** in place of the timer.

**Confirmed ordering and reset (DD06)**

- Only eliminations committed before the regulation deadline count; freeze combat at expiry.
- Reset every remaining connected participant, including pending respawns, to fair spawns; clear motion, actions, temporary protection, and effects; restore abilities/hazards and repeat the countdown. Departed players remain absent.
- Keep tied regulation scores; sudden death awards no overtime points. The approved F5 window is exactly 0.2 seconds from the first server elimination commitment. An opposing commitment at or before that deadline resets the round, including equality. Later commitments cannot extend the window through delayed scheduling; otherwise the first eliminated player's opponent wins when the window closes.
- Restarts use the same reset; The Ring restarts ordinary cycles from the safe phase.

**Approved F5 local 1v1 detail (October 22, 2026):** Reset both connected players, including pending regulation respawns, to their regulation mirrored starts with fresh life identities. Clear old motion, actions, buffers, protection, effects, and respawn timers; preserve chosen equipment and make abilities ready. Repeat the three-second opening countdown with both players locked until GO. No sudden-death respawn protection or ordinary respawns. Repeated mutual eliminations have no round cap or overtime timer. Committed eliminated attackers cannot register further hits, including already active attacks; a hit must resolve before its attacker's elimination commitment. Duplicate and stale life/session callbacks must be harmless.

During a sudden-death reset countdown or decision window, a departure awards the connected player a forfeit even if that player is already eliminated and would otherwise lose. Mutual eliminations produce one neutral knockout-feed entry, “DOUBLE KO — sudden death resets,” replacing the two individual entries. A decisive loss uses ordinary feed attribution. Results identify the sudden-death winner and retain the tied regulation score. F5 implements the local 1v1 Platform transition and map-independent reset seam; later map construction, ability/loadout systems, and 2v2 integration remain separate slices.

Anti-stalling behavior may be explored later. No overtime timer, forced draw, shrinking arena, or forced result is required in v0.1.

**Acceptance:** Tied regulation enters sudden death; it never performs an ordinary respawn. A decisive elimination selects the other team as winner, including the first lost player in 2v2. A simultaneous mutual elimination restarts sudden death under the agreed reset policy. No result depends on arbitrary callback ordering.

### 11.2 Player departures

| Phase or situation | Confirmed outcome |
|---|---|
| Waiting in queue | Remove player; update count; continue waiting; no reward or penalty |
| Intermission, either mode | Cancel match; return remaining players to lobby; no official result or rewards |
| Active 1v1 | Remaining player wins by forfeit |
| Active 2v2, one teammate leaves | Continue as 1v2 |
| Active 2v2, both members of one team leave | Other team wins by forfeit |
| Sudden death departure | Apply the same departure rules as active combat |

The leaver does not receive completion rewards. Progression and rewards are deferred, so this is a future reward-policy constraint, not a requirement to build a reward system now. Treatment of innocent remaining players' future rewards is open.

**Acceptance:** Every departure follows the correct phase rule. A single 2v2 departure does not incorrectly end the match, including in sudden death. A final forfeit result is emitted once. A departure does not also generate an unintended ring-out point.

**Resolved:** DD08-DD09 define dispatch cancellation, no reconnect/backfill, end-of-update departure batching, no winner if both sides empty, shutdown abandonment, and immutable finalized results.

## 12. HUD, feedback, and results

**Purpose:** Explain match state and combat outcomes while leaving the 3D arena visible.

| Element | Confirmed placement and behavior |
|---|---|
| Match timer | Top center; clock icon; minutes and seconds; subtle animation as time decreases |
| Timer urgency | Increased urgency in the final 30 seconds; dramatic final 10-second countdown |
| Overtime display | Replace time with SUDDEN DEATH |
| 1v1 score | Top right; Score label; two Roblox avatar portraits with tally beneath each |
| 2v2 score | Top right; two team panels, two portraits per team, team score |
| Knockout feed | Top left; small oval-style notifications |
| Attributed feed entry | Attacker → weapon icon → eliminated player |
| Unattributed feed entry | Environmental fall message |
| Ability indicator | Bottom right; icon, Ability label, input indicator Q, numeric cooldown |
| Cooldown animation | Dark radial overlay clears clockwise; bright ready state when available |
| Regulation elimination | Brief dramatic effect, feed entry, score update, respawn countdown |

The final-30-second and final-10-second presentation thresholds are confirmed design choices. They are separate from the provisional three-minute match duration. The original per-second down-flicker treatment is a presentation proposal within the confirmed subtle timer animation.

### 12.1 Combat feedback

Use weapon- and ability-specific animations, impact particles, sounds, and subtle camera response. Support readable wind, magnetic pull, Bounce effects, and a Ground Slam radial shockwave. A knockout gets a dramatic but brief elimination effect.

Avoid excessive screen shake and effects that obstruct combat visibility. No minimap, health bar, stamina bar, or inventory hotbar is required.

**Resolved:** DD10 specifies original/licensed placeholders, optional subtle shake, accessible signals, ability/weapon icons, and generic fallback. Feed begins at 4 seconds and three entries. Exact assets/styling are implementation choices; no effect library is selected.

### 12.2 Results

Results show winner, final team scores, and normal/sudden-death/forfeit outcome. Start with 8 seconds and immediate Return to Lobby. No direct rematch or individual performance statistics. Cancellation/interruption screens explain no-result outcomes (DD09).

**Technical constraints:** The server determines ability readiness and deadlines. The client interpolates visuals and countdowns from authoritative state. Avatar thumbnails, sounds, and effects must not block scoring or phase transitions if an asset fails to load.

**Acceptance criteria**

- Timer, score, feed, and ability status appear in the specified locations in both modes.
- The radial overlay clears clockwise and numeric cooldown agrees with server readiness.
- Final-30-second and final-10-second urgency occurs correctly; sudden death replaces the timer.
- Environmental falls remain understandable without false attacker credit.
- Regulation elimination shows a respawn countdown; sudden death does not promise a respawn.
- Results match the server's winner and provide the return flow.

**Engineering recommendation:** Check readability at supported screen sizes, avoid relying only on color for ready and hazard states, and keep effects readable at lower graphics settings. Desktop coverage and sensitivity, shake, and separate audio controls are established by DD01/DD10.

## 13. Engineering requirements and local architecture

### 13.1 Core constraints

- EN01: Build in Roblox Studio and Luau.
- EN02: Use reusable configuration modules for weapons and abilities.
- EN03: Keep combat validation, scoring, match state, cooldown enforcement, team assignment, and loadout validation authoritative on the server.
- EN04: Use client-side HUD, particles, animations, sound presentation, and other visual feedback.
- EN05: Implement a clear match lifecycle and independent match sessions.
- EN06: Prevent duplicate elimination processing and enforce friendly fire consistently.
- EN07: Support safe spawning, respawning, disconnects, and failed teleports.
- EN08: Prioritize simplicity and testability. Introduce infrastructure only when the working combat prototype needs it.

### 13.2 Recommended lifecycle

The following state names are an engineering recommendation representing the confirmed player flow:

```text
Lobby queue
  → Locked group and dispatch
  → Intermission
      → Map voting and loadout selection
  → Arena preparation
  → Regulation
      → Sudden death if tied
          → Sudden death restart if mutually eliminated
  → Results
  → Return to lobby

Intermission departure → Cancellation → Return to lobby
Active forfeit → Results → Return to lobby
```

Phase ownership must be explicit. An old timer, delayed callback, or repeated request must not change a session that has already moved on. Results and cancellation must be terminal for that match session.

### 13.3 Single-server phases

Start with one local session on The Platform. Expand to the complete local flow before introducing teleports. Independent sessions must isolate participant lists, teams, map state, score, timers, ability state, elimination events, and cleanup.

If multiple local matches are hosted simultaneously, their arenas, collisions, effects, and player interaction must be isolated. The number of concurrent local matches, arena allocation behavior, and what happens when capacity is full are open. Queue zones must remain independent of arena identity.

### 13.4 Validation and physics

**Engineering recommendations:** Validate request types and finite values; enforce per-action timing and sensible request limits; check distance, direction, state, ownership, target eligibility, and applicable obstruction rules. Treat client requests as intended actions rather than trusted hit or score reports.

Server-authoritative outcomes do not automatically mean all character physics is simulated by the server. Select a physics and network-ownership approach during the prototype. Account for latency and legitimate launch or Bounce trajectories when validating movement. Do not depend on an unverified platform beta feature as a release prerequisite.

**Acceptance:** A modified client cannot award points, use an unequipped item, bypass cooldowns, hit allies, or alter another session. Reusing an arena clears previous score, hazards, effects, and callbacks. The same validated combat configuration runs in local and reserved-server phases.

## 14. Reserved match-server architecture

**Confirmed target:** Public lobby place → reserved instance of a separate reusable match place → return to a public lobby. Each match server runs intermission, voting, arena gameplay, and results for its matched group.

### 14.1 Session handoff

1. The lobby server forms and locks a local group of two or four players.
2. The server creates or selects the reserved match-server destination and dispatches the group.
3. The destination initializes the intended match, mode, and roster.
4. Intermission collects map votes and loadouts in the match server.
5. The server runs regulation, any sudden death, and results.
6. Remaining players return to a public lobby.

**Engineering recommendation:** Use an explicit session identity and expected roster to prevent duplicate or unrelated arrivals from starting another match. Validate destination admission and server-owned team data. Do not treat client-provided teleport payloads as authority for rewards, equipment permissions, or match outcomes.

Team assignment must remain server-owned and random. The exact point of assignment and handoff mechanism are implementation choices. No particular cross-server database, distributed queue, or backend service is mandated.

### 14.2 Failure handling

Failed teleports must not leave players indefinitely locked in a queue or stuck without a return path. Handle dispatch errors, partial group arrival, arrival timeout, intermission departures, and failed return-to-lobby attempts.

**Confirmed:** Full-roster arrival has a provisional 20-second timeout and at most two outbound retries. Cancel incomplete groups; release lobby-side players and return arrivals. Failed returns get two automatic retries, then retain manual Return to Lobby and a clear error. Cancellation uses the same usable recovery screen (DD09).

Returning players need a route to any valid public lobby; returning to the exact original lobby instance is not a confirmed requirement. Public late joining, reconnecting to the previous match, and backfill are excluded from v0.1.

### 14.3 Platform constraints

Roblox documents server-side `TeleportAsync`, new reserved-server creation through `TeleportOptions.ShouldReserveServer`, and targeting an existing reserved server through `ReservedServerAccessCode`. Its teleport guidance includes protected calls, retries, and handling `TeleportInitFailed`. Choose the appropriate reservation path during implementation rather than assuming all options are used together.

See [Roblox teleport guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/teleport.md). Client-boundary and physics guidance is linked in section 20. Platform documentation informs engineering; it does not change the confirmed game rules.

**Acceptance criteria**

- A full local group reaches the intended reserved match server and starts exactly one session.
- Two dispatched matches cannot share combat, roster, or score state accidentally.
- Match intermission and results run in the match place.
- A failed dispatch, partial arrival, and failed lobby return each have an exercised recovery path under the approved policy.
- Departures use the correct phase rules after arrival.
- Cross-server matchmaking is not introduced as a dependency.

## 15. Validation and beta evaluation

### 15.1 Release acceptance matrix

These scenarios describe implementation acceptance work to perform during development; this PRD does not claim that a game implementation has already passed them.

| Gate | Scenario | Pass condition |
|---|---|---|
| AC01 | New player completes the full flow | Menu → lobby → queue → intermission → arena → results → lobby works |
| AC02 | Both modes fill local queues | 2 players form 1v1; 4 form 2v2; incomplete queues wait |
| AC03 | Queue entries or requests repeat | No duplicate membership, match assignment, or dispatch |
| AC04 | Intermission completes without input | Approved map-vote and default-loadout policies resolve; combat has valid equipment |
| AC05 | Client submits invalid loadout or late change | Server rejects it; locked equipment remains authoritative |
| AC06 | All weapon and ability choices are exercised | All nine loadouts work; only Hammer plus Bounce has the specified special attack |
| AC07 | Knockback, Bounce, and miss punishment | Fixed aim-directed replacement launch; committed knockback with limited steering; valid Bounce replaces velocity before elimination cutoff; misses expose recovery |
| AC08 | Repeated Paddle Pops pressure, including two attackers | Visible team-wide displacement/interruption protection prevents stun-lock; blocked hits do not extend protection or attribution; target can respond after hit reaction |
| AC09 | Ally is inside an attack, cone, pull, or shockwave | No harmful friendly-fire outcome |
| AC10 | Combat, accidental, intentional, and hazard falls | Opposing side receives +1 per regulation elimination |
| AC11 | One elimination has duplicate callbacks | One point, one elimination event, at most one regulation respawn |
| AC12 | Tied regulation and 2v2 sudden death | Untimed; no respawns; first lost player decides the losing team |
| AC13 | Sudden-death transition, deadline, and mutual elimination | Pre-deadline commitments alone score; all connected players reset with abilities ready; 0.2-second opposing loss window restarts; otherwise first lost player determines losing side |
| AC14 | Departures in every phase | Queue removal, intermission cancellation, 1v1 forfeit, 1v2 continuation, or team forfeit as specified |
| AC15 | Every map runs in both modes | Topology, safe spawns, fall bounds, and hazard behavior meet map requirements |
| AC16 | The Ring hazard cycles | Clear warning; only selected sections collapse; reliable center; collision restores |
| AC17 | HUD across combat phases | Correct mode-specific score, urgency, overtime label, feed, and authoritative cooldown |
| AC18 | Parallel or successive sessions | No leaked roster, score, cooldown, hazard, timer, or presentation state |
| AC19 | Dispatch, incomplete arrival, and lobby-return failure | Pre-teleport departure preserves queue order; 20-second full-roster timeout and at most two outbound retries; cancelled group recovers; failed return gets two retries and persistent manual button; no duplicate starts |
| AC20 | Friends complete repeated matches | Feedback records fairness, clarity, controls, combat enjoyment, and voluntary repeat play |
| AC21 | Inputs, airborne actions, and trades | One click per attack; at most one late buffer; once per enemy per activation; weapon hits interrupt startup; active trades possible; no hover or self-action ability cancels |
| AC22 | Ability startup, miss, and Magnet targeting | Accepted activation spends cooldown even if interrupted/missed; rejected activation does not; aim alignment precedes distance; protected targets excluded; pull retains attack response and protection |
| AC23 | Armored Ground Slam is redirected | Bounce-only eligibility; no interruption once activated; incoming launch changes trajectory, then descent resumes; one valid surface shockwave, no direct-hit stacking or cross-gap impact |
| AC24 | Respawn, reset, unexpected death, and cooldown persistence | Safe points and visible 3-second protection; attack/ability ends protection; falls still eliminate; reset/death scores once; cooldown runs through death |
| AC25 | Controls, accessibility, and desktop targets | Mouse capture/menu release; standardized rigs and no body blocking; sensitivity/shake/audio settings; non-color warnings; evaluate 60 FPS on chosen hardware and 100-150 ms latency |
| AC26 | Opening, results, and terminal session states | Countdown synchronizes start; eight-second results with immediate return; no reconnect/backfill; both sides empty means no winner; shutdown abandons unfinished result |

Apply section 2.2 rules and section 17 settings. Agreement is not test completion; exercise interruption, active trades, protection, armored slam redirection, safe spawning, deadline ordering, and failure paths.

### 15.2 Playtest questions

- Can players identify what hit them and why they fell?
- Does each weapon offer strengths worth choosing and weaknesses opponents can punish?
- Do players use Gust and Magnet for positioning rather than guaranteed disabling sequences?
- Is Bounce useful for both offense and recovery, with a meaningful cost for spending it?
- Can opponents recognize and avoid Ground Slam?
- Are all maps fair across loadouts and modes? Does The Ring provide enough warning?
- Do the controls, camera, cooldown display, and feed remain legible during busy 2v2 fights?
- Do players voluntarily queue again, and what causes them to stop?

**Engineering recommendation:** Record selected loadouts, maps, mode, match completion, cancellation or forfeit cause, ring-out counts, and repeat participation where practical. Define any collection and reporting approach proportionately; a persistent analytics service is not a beta prerequisite.

**Provisional targets:** Desktop 60 FPS, 12-player public lobbies, four-player match servers, and tests at 100-150 ms round-trip latency. Select reference hardware and local test allocation before technical signoff (section 18).

## 16. Implementation phases

### Milestone 1 Core combat prototype

**Scope:** Third-person 3D movement; two players; The Platform; shared weapon and ability configurations; all three weapons; all three abilities; Hammer plus Bounce Ground Slam; directional knockback; elimination; scoring; regulation respawns; timed match and results.

**Exit criteria:** Two players complete a match and understand its outcome. Combat acceptance criteria for attacks, cooldowns, friendly-fire preparation, duplicate elimination prevention, and recovery are exercised as applicable. Players find fighting enjoyable enough to continue. Final art and teleport infrastructure are not prerequisites for this milestone.

**Dependencies:** Apply approved DD01-DD05 action rules with section 17 settings; validate animation-aligned hit volumes, spawns, launch, and recovery in multiplayer.

### Milestone 2 Complete local player flow

**Scope:** Main menu; shared lobby; physical 1v1 and 2v2 queues; random teams; intermission; map voting; private loadout selection; all three maps; complete HUD and combat feedback; sudden death; departure rules; results and return flow.

**Exit criteria:** AC01–AC18 pass for the relevant local implementation under approved section 2.2 policies. Each map works in both modes. A departure or cancellation does not strand the remaining players. Local session reuse is clean.

**Dependencies:** Apply and exercise DD02-DD10 voting, sudden-death ordering/reset, safe spawning, protection, and 2v2 targeting.

### Milestone 3 Reserved match servers

**Scope:** Separate lobby and match places; reservation and group teleportation; destination initialization; intermission in the match server; failure and departure handling; lobby return.

**Exit criteria:** AC19 passes alongside the end-to-end flow in the published multiplayer environment. Full and partial arrival, dispatch failure, destination departure, and return failure have approved behavior and exercised recovery. Session isolation remains intact.

**Dependencies:** Complete local flow, DD09 arrival/retry policies, and lobby/match destination configuration. Cross-server matchmaking is not a prerequisite.

### Milestone 4 Friends and family beta

**Scope:** Play with friends; evaluate balance, map fairness, knockback, recovery, controls, visibility, and voluntary repeat play. Tune provisional values based on observation.

**Exit criteria:** The complete acceptance matrix is reviewed, critical gameplay and flow failures are resolved, and the product owner accepts the current tuning for the beta. No numerical retention or win-rate threshold has been fixed.

**Planning note:** Dates, staffing, effort estimates, and milestone owners remain open. Preserve this sequence so infrastructure follows evidence that the combat works.

## 17. Provisional tuning register

Approved configurable prototype starting settings, not final balance or claims of tested performance. Behavioral rules are confirmed in section 2.2. Revise numbers through multiplayer playtesting and update dependent acceptance scenarios. No runtime configuration was created by this documentation update.

| Area | Starting setting | Intended relationship / validation |
|---|---|---|
| Regulation / respawn delay | 3 minutes / 3 seconds | Pace and safe re-entry |
| Opening / dispatch countdowns | 3 seconds each | Fair start / clear queue departure opportunity |
| Shared intermission | 15 seconds | Concurrent editable map/loadout selection; full window initially |
| Walk speed / normal jump height | 16 studs/s / approximately 7 studs | Same base movement across weapons |
| Air steering | Moderate normally; minimal during knockback | Useful jumping without erasing launches; exact coefficients tuned in prototype |
| Attack movement speed | Fist 70%; Hammer 40%; Paddles 85% of base | Applies throughout action; Hammer commits most strongly |
| Weapon-hit reaction | 0.15 seconds | Brief interruption; Bounce available during knockback |
| Displacement protection | 0.35 seconds from first successful effect | Blocked contacts do not extend; Magnet lasts until later of pull end or ordinary deadline |
| Attack buffer | Final 0.12 seconds of recovery; one attack | Responsiveness without queued chains |
| Respawn protection | 3 seconds | Ends before any attack/ability resolves; falls still eliminate; no stacking extension |
| Spring Fist | Startup/active/recovery 0.08/0.10/0.32 s; reach 11 studs; launch 50 horizontal / 12 upward studs/s | Narrow balanced strike |
| Wrecking Hammer | Startup/active/recovery 0.48/0.18/0.65 s; reach 7 studs; about 100-degree sweep; launch 118/16 studs/s, targeting approximately 20 studs horizontal travel for a grounded idle opponent | Readable windup and broad coverage; owner tuning October 22, 2026; actual travel remains physics-dependent |
| Paddle Pops | Startup/active/recovery 0.10/0.08/0.16 s; reach 6 studs; launch 30/8 studs/s | Protection exceeds one attack cycle; close pressure without stun-lock |
| Gust | Cooldown 15 s; range 12 studs; 60-degree cone; launch 35/6 studs/s; stun 0.25 s | Multiple targets; stun blocks new actions and interrupts startup, active attacks retain trade rules; owner tuning October 22, 2026 |
| Magnet | Cooldown 12 s; range 20 studs; 60-degree cone; pull 28 horizontal studs/s for at most 0.55 s, stop 3 horizontal studs from user | Five-stud-high body band; aim, distance, stable Player ID ordering; target can attack/use valid abilities but cannot steer/jump during pull; user keeps movement/jump |
| Gust / Magnet action | Startup 0.12 s, then effect, recovery 0.20 s | Interruptible startup; no weapon overlap |
| Bounce | Cooldown 10 s; replacement launch 48 horizontal / 90 upward studs/s; no horizontal input means no horizontal launch | Current F10 tuning signed off October 23, 2026; predictable but fallible recovery |
| Bounce primary-attack delay | 0.15 s | Immediate launch, then attack; slam has its own telegraph |
| Ground Slam | Windup 0.25 s; downward speed at least 90 studs/s afterward; radius 9 studs; launch 55/13 studs/s; landing recovery 0.65 s | No hover; weaker than direct Hammer; displacement counterplay |
| The Platform | Circular, diameter 70 studs | Neutral two-player testing, then 2v2 |
| Sky Bridges | Center diameter 50 studs; side islands diameter 30 studs each; bridges width 12 studs, approximately 25 studs between island edges | Three connections, no required Bounce; room for fighting |
| The Ring geometry | Diameter 80 studs; permanent center diameter 48 studs; eight outer sections | Reliable center and exposed edges |
| Ring selection / cycle | Two nonadjacent sections, none repeated from prior cycle; safe 10 s, warning 3 s, collapsed 4 s, then restore | Readable escape opportunity; same cycles in sudden death |
| Lower elimination plane | 25 studs below lowest playable surface | Recover until crossing, then reject abilities |
| Outer fallback bounds | At least 60 studs beyond outermost playable geometry | Catch extreme launches |
| Sudden-death simultaneity | 0.2 seconds after first elimination | Continue play; opposing loss resets round |
| Arrival timeout / outbound retries | 20 seconds / at most two retries | Full-roster assembly with bounded waiting |
| Failed lobby return | Two automatic retries, then manual button remains | Usable recovery state |
| Results | 8 seconds plus immediate return button | Simple return-to-queue route |
| Feed attribution / display | Latest successful enemy displacement within 5 s; display 4 s; maximum three entries | Credit separate from score; oldest replaced at capacity |
| Capacity | 12 players per public lobby; four per match server | Desktop beta starting targets |
| Performance / network test | 60 FPS desktop target; test at 100-150 ms round-trip latency | Reference hardware to be selected; no verification claimed |

Reach is forward hit-volume extent from the character, not additional distance beyond the model. Launch numbers are intended velocity targets, not force units; physics application requires evaluation. Exact hit-volume widths/heights, air-control coefficients, and animation alignment are prototype tuning details within approved behavior, not permission to add mechanics.

## 18. Remaining validation and implementation details

Q1-Q76 are resolved in section 2.2. Earlier O01-O21 groups are resolved as behavior and/or provisional starting settings, except the specific engineering and validation details below. This register does not reopen approved rules or claim provisional values are final.

| Item | Remaining work | Needed for |
|---|---|---|
| V01 | Tune exact air-control coefficients, hit-volume widths/heights, Magnet pull-speed balance (F9 starts at 28 studs/s), Bounce input response, and physics application within approved behavior | Milestone 1 |
| V02 | Validate animation alignment, active trades, repeated-pressure protection, armored slam redirection, valid surfaces, and ability startup interruption | Milestones 1-2 |
| V03 | F3 spawn/failure policy is approved in section 2.3 and technically exercised on The Platform. Owner gameplay review and safe-spawn/hazard integration for later maps remain | Milestones 1-2 |
| V04 | Playtest timing, launch, arena dimensions, warnings, all nine loadouts, and both modes; assess compulsory Bounce selection | Milestones 1-4 |
| V05 | Choose camera distance/zoom bounds, clipping handling, effects/animations, final assets, menu background scene, lobby decoration, and results layout within DD01/DD10 | Milestones 1-2 |
| V06 | Choose local test-session allocation/capacity and full-capacity handling; production target remains one reserved server per match | Milestone 2 |
| V07 | Implement admission, server-owned roster validation, retry scheduling within bounded policy, destination configuration, and physics ownership/security approach | Milestones 1-3 |
| V08 | Choose reference desktop hardware and verify FPS, low-graphics readability, and latency targets | Before beta technical signoff |
| V09 | Assign milestone owners, schedule, and beta participants; assess voluntary repeat play and critical failures | Before beta acceptance |
| Deferred | Controller/mobile mappings, reconnect/backfill, direct rematches, individual statistics, sudden-death anti-stalling, and future rewards | Later review; not current beta gates |

Acceptance requires exercising approved rules, not merely recording agreement. No implementation or completed tests are asserted by this revision.

## 19. Deferred features and risks

### 19.1 Explicitly outside v0.1

- Inventory management and persistent equipment unlocks.
- Currency, progression, shops, monetization, and purchasable weapons.
- Party formation and manual 2v2 teammate selection.
- Ranked and cross-server matchmaking.
- Complex combo systems, universal blocking or parrying, and universal air recovery.
- Additional weapons and abilities or a large roster of special weapon–ability interactions.
- Continuous whole-arena rotation on The Ring.
- Mobile/controller support for the first desktop beta; reconnect/backfill, direct rematches, and individual performance statistics.
- Double jumps, sprinting, dodge rolls, ledge grabs, and accumulating damage/launch meters.

Detailed assist tracking is not required for initial scoring. A sudden-death anti-stalling system is a later exploration, not a current requirement. Do not create a progression system merely to implement future reward policy language. The Dev Special in section 19.2 is the specifically tracked P3 stretch exception; it remains outside v0.1 release scope.

### 19.2 P3 stretch feature: Dev Special

- Add a developer-only weapon called **Poop Hammer** and an associated ability called **Eat Poop**. This is a humorous development special, not part of the starter roster or general player loadout.
- On activation, Eat Poop smears poop on the nearest opponent. The affected opponent becomes slippery and has increased knockback susceptibility, doubling the knockout potential of the user's Poop Hammer.
- This is an intentionally paired, special weapon-ability interaction. It does not imply a general status-effect or combo system. Detailed values, eligibility, cooldown, and presentation remain to be specified before implementation.
- Priority: **P3 stretch**; excluded from v0.1 beta requirements and release gates.

### 19.3 Delivery risks

| Risk | Why it matters | Response within the approved scope |
|---|---|---|
| Knockback feels inconsistent | Players cannot judge spacing or understand losses | Prototype physics early; tune launch and recovery on The Platform |
| Paddle Pops removes counterplay | Fast attacks could produce indefinite control | Evaluate approved displacement protection |
| Bounce becomes mandatory or ineffective | Recovery can dominate loadout choice | Evaluate cooldown and launch against offensive opportunity cost |
| Hammer or Ground Slam is unreadable | Heavy attacks feel unavoidable | Evaluate windup, impact readability, radius, and recovery |
| Map geometry creates loadout bias | One weapon could dominate bridges or edges | Test every map in both modes with varied loadouts |
| Collapse warnings are unclear | Hazard eliminations feel arbitrary | Validate warning visibility and escape opportunity before final art |
| Sudden-death races produce arbitrary winners | Fairness depends on event timing | Exercise approved simultaneity and transition rules at boundary cases |
| Teleports split or strand groups | Players cannot finish the intended journey | Complete local flow first, then exercise partial-arrival and return recovery |
| Presentation hides combat | Players lose information during busy fights | Keep effects brief and camera response subtle; review 2v2 visibility |
| Scope grows before combat is fun | Infrastructure and content delay useful feedback | Keep milestone order; tune the confirmed roster before expanding it |

## 20. Source and maintenance notes

Section 2.2 is the latest approved decision record and supersedes conflicting earlier proposals. The supplied **Knockout Night v0.1 Confirmed Game Design Decisions** remains the original baseline. The referenced **Roblox Game Ideation** conversation and HUD whiteboard establish the minimal HUD layout, pre-fight selection approach, automatic teams, and fully 3D gameplay intent. Section 2.2 records the subsequently approved interview clarifications.

Engineering references consulted for platform constraints:

- [Roblox teleport guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/teleport.md): server-side teleportation, reserved destinations, and teleport failure handling.
- [Roblox client and server boundary guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/client-server-boundary.md): validate client requests before applying authoritative outcomes.
- [Roblox network ownership guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/network-ownership.md): client-controlled physics, movement validation, and legitimate movement tolerances.

When a provisional value is accepted or an open question is resolved, update its status, the relevant requirement, runtime configuration, and acceptance criteria together. Record material design changes below so later implementation does not confuse an old proposal with the current decision.

### Change log

| Date | Version | Change |
|---|---|---|
| October 20, 2026 | 0.1 | Consolidated confirmed game design into an implementation-oriented PRD; separated provisional tuning, open decisions, engineering recommendations, and deferred scope. |
| October 20, 2026 | 0.2 | Recorded approved Q1-Q76 in dedicated section 2.2; reconciled requirements, expanded provisional tuning, and replaced resolved open questions with validation/engineering work. Arrival timeout 20 seconds; respawn protection 3 seconds. Documentation only; no implementation or asset changes. |
| October 22, 2026 | 0.3 | Recorded approved F3 Q1–Q7 and implementation authorization: bounded safe-spawn fallback, distance/tie selection, fresh character lives, visible protection, spectator timing, and F3 HUD scope. Linked technical evidence and preserved owner gameplay acceptance as pending. |
| October 22, 2026 | 0.4 | Recorded product-owner F3 gameplay sign-off and updated the next-slice status to F4. |
