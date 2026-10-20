# Knockout Night v0.1 Product Requirements Document

**Platform:** Roblox  
**Product:** Competitive multiplayer 3D arena fighter  
**Document version:** 0.1  
**Updated:** October 20, 2026  
**Product owner:** To be assigned  
**Release:** Friends-and-family beta  
**Design authority:** The supplied Knockout Night v0.1 Confirmed Game Design Decisions, supplemented by the referenced Roblox Game Ideation discussion and HUD whiteboard.

## Contents

1. [Product brief](#1-product-brief)
2. [Release scope and fixed decisions](#2-release-scope-and-fixed-decisions)
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
18. [Open decision register](#18-open-decision-register)
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
| D09 | Every ring-out awards one point to the opposing side, regardless of cause. |
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

## 3. Player journey

**Confirmed flow:** Main Menu → Lobby → Queue → Intermission → Map Vote / Loadout Selection → Arena → Results → Lobby.

### 3.1 Main menu and lobby

**Purpose:** Give players one clear starting action and a shared space from which to find a match.

**Requirements**

- PF01: Show the Knockout Night title or logo over a blurred 3D background.
- PF02: Provide one prominent **Play** button. Do not add inventory or progression menus in v0.1.
- PF03: Play takes the user into the shared 3D lobby experience. Whether the menu background uses the same physical lobby scene is open.
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

**Provisional:** A short dispatch countdown may precede transition. Its length is open.

**Engineering recommendation:** Maintain one authoritative queue membership and dispatch record per player. Use a group identifier to prevent duplicate dispatch when zone contacts or join requests repeat.

**Acceptance criteria**

- A queue with fewer than its required players remains available and does not launch an incomplete match.
- Filling a queue creates one locked group and one dispatch attempt for that group.
- Leaving while waiting immediately releases membership and updates the visible count.
- Different groups cannot claim the same player.
- 2v2 starts with two server-assigned teams of two; clients cannot choose teammates.

**Open edge cases:** Queue priority when zones overlap, the behavior of extra entrants during dispatch, and whether a locked group refills or cancels if someone leaves before intermission must be decided. The intermission cancellation rule applies once that phase begins.

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
| Map vote window | 8 seconds | Provisional |
| Loadout window | 12 seconds | Provisional |
| Default loadout | Spring Fist plus Gust | Provisional |
| Vote tie or no-vote behavior | Not selected | Open |
| Whether voting and selection share a screen or overlap | Not selected | Open |

**Technical constraints:** The server determines phase deadlines and accepted selections. Client display state cannot override a locked loadout. Loadout privacy must include replicated data, not just hiding portraits in the interface.

**Acceptance criteria**

- All three maps, weapons, and abilities are available in their respective choices.
- Every player enters combat with exactly one valid weapon and one valid ability.
- Missing selections resolve to the approved default rather than blocking the match.
- Late selection requests cannot change combat equipment.
- Opponent selections remain private during intermission.
- An intermission departure cancels the match and provides a return path for every remaining participant.

**Open edge cases:** Choose vote tie resolution, empty-vote behavior, selection deadlines, and whether confirmation prevents further edits before the deadline. These decisions must precede final acceptance of the voting flow.

## 5. Movement and camera

**Purpose:** Support spacing, juking, positioning, and recovery in a fully 3D arena.

- MV01: Use a third-person view with movement across both horizontal axes: forward, backward, left, and right.
- MV02: Support jumping. Vertical movement also comes from applicable abilities and combat knockback.
- MV03: Keep initial character movement speed consistent across weapons. Paddle Pops' speed identity comes from attacks, not faster locomotion.
- MV04: Use committed knockback as the initial combat approach: a hit sends the target along a knockback trajectory.
- MV05: Bounce can be activated during ordinary knockback if available. There is no universal air-recovery input or specialized universal recovery system.

**Open:** Standard movement speed, jump parameters, ordinary air steering, camera distance, camera rotation behavior, facing and aiming rules, and camera behavior near geometry. Third-person does not imply a finalized lock-on, shoulder camera, or camera-relative control model.

**Technical constraints:** Controls must support all approved actions without obscuring the HUD. Server validation must account for legitimate jumping, knockback, Bounce, and network delay; ordinary client-controlled character physics cannot be assumed trustworthy.

**Acceptance criteria**

- Players can approach and circle each other from any horizontal direction; movement is not restricted to a side-scrolling plane.
- All weapons use the same approved base movement settings.
- Jumping and valid Bounce activations work in the applicable character states.
- A normal hit produces a readable directional launch, while an available Bounce can attempt recovery.
- Once aiming and facing rules are chosen, visual attack direction and server hit direction agree.

**Open edge cases:** Define movement permissions during attack startup, active frames, recovery, and Ground Slam preparation. Define boundaries for Bounce activation during special states beyond ordinary knockback.

## 6. Combat foundation

**Purpose:** Make attacks readable, punishable, and mechanically consistent across the roster.

- CB01: Left mouse click initiates the equipped weapon's primary attack.
- CB02: Each attack has startup, active hitbox, and recovery phases.
- CB03: Hits apply directional knockback determined by configurable attack parameters. Do not introduce a conventional health or damage system.
- CB04: Missed attacks leave recovery that opponents can punish.
- CB05: Eliminate a player when they fall outside the arena. Exact bounds and the commitment point of a ring-out are open.
- CB06: Prevent indefinite stun-locking from repeated fast attacks. The mechanism is open and must preserve meaningful counterplay.
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

**Open edge cases:** Attack buffering, held-input behavior, simultaneous trades, weapon use in the air, hit interruption, and hit immunity or diminishing control rules remain undecided. Do not add combo chains, blocking, or parrying to resolve these questions.

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

### 7.4 Provisional weapon configuration

These are illustrative starting parameters, not approved final balance. Launch targets describe conceptual velocity changes; they are not literal Roblox force units.

| Parameter | Spring Fist | Wrecking Hammer | Paddle Pops | Status |
|---|---:|---:|---:|---|
| Startup | 0.08 s | 0.48 s | 0.10 s | Provisional |
| Recovery | 0.32 s | 0.65 s | 0.16 s | Provisional |
| Reach | 5 studs | 7 studs | 3.5 studs | Provisional |
| Horizontal launch target | 50 | 75 | 25 | Provisional |
| Vertical launch target | 12 | 16 | 8 | Provisional |
| Active duration and hitbox size | TBD | TBD | TBD | Open |

Do not derive a finalized attack frequency from startup plus recovery alone; active duration and input behavior remain open. The supplied Paddle Pops startup example also does not establish that every speed-weapon timing parameter must be lower than Spring Fist's.

## 8. Starter abilities and synergy

**Purpose:** Add positional choices and loadout variety without equipment superiority.

- AB01: Each player equips one active ability and activates it with Q on keyboard.
- AB02: The server enforces availability and cooldowns; clients display their state.
- AB03: Controller mappings are open. Mobile controls and release device coverage are open.

### 8.1 Gust

**Confirmed:** A short frontal cone of wind creates a brief directional push. Visually, wind begins behind the user and travels through and ahead of the character. Its principal role is positioning rather than large knockout force.

Use it to disrupt approaches, create distance, or move opponents toward an edge. It must not automatically cancel every opposing attack.

**Provisional cooldown:** 8 seconds. **Open:** Cone angle, range, duration, push strength, and interactions with individual attack states.

**Acceptance:** Visual wind origin and frontal gameplay hitbox communicate the same direction. Enemies inside the approved cone receive the intended push; allies do not. Gust does not become a universal attack cancel.

### 8.2 Magnet

**Confirmed:** A short-range pull brings a nearby opponent in the intended direction toward the user. The target can still attack or respond; a skilled opponent may use the pull to create their own opportunity.

Use it to punish misses, close distance, or set up a weapon attack.

**Provisional cooldown:** 12 seconds. **Open:** Range, direction tolerance, pull strength and duration, obstruction rules, and target selection in 2v2.

**Acceptance:** The pull moves an eligible enemy toward the user without inherently disabling all responses. A 2v2 target-selection rule must be agreed and reproducible before final acceptance; the server cannot accept an arbitrary client-nominated victim.

### 8.3 Bounce

**Confirmed:** Launches the user upward with directional movement. It works grounded, airborne, and during ordinary knockback when available. It has one activation per cooldown and enables escape, edge recovery, repositioning, and aerial initiation.

Bounce must not create unlimited flight or multiple air dashes. Offensive use consumes the same opportunity that could otherwise save the player from a later ring-out.

**Provisional cooldown:** 10 seconds. **Open:** Launch strength, directional input, steering, and cooldown reset behavior at respawn and sudden-death restart.

**Acceptance:** One valid activation is possible per cooldown. A player can attempt recovery during ordinary knockback, but cannot reactivate repeatedly while unavailable. Using Bounce offensively leaves it unavailable for recovery until the cooldown permits it.

### 8.4 Aerial Ground Slam

**Confirmed sequence:** Equip Wrecking Hammer and Bounce → activate Bounce with Q → use primary attack while airborne → prepare a downward hammer strike → land and create a short radial shockwave that pushes nearby enemies outward.

Its landing area and windup should be predictable enough for opponents to move away. Bounce is consumed, leaving the user without that escape option during cooldown. Wide coverage is confirmed; lower launch per target than a standard Hammer hit is a provisional trade-off.

**Open:** Slam radius, launch strength, landing detection, activation window after Bounce, interaction with ordinary airborne Hammer attacks, recovery, and treatment of direct-hit plus shockwave overlap.

**Acceptance:** The input sequence reliably produces one valid landing shockwave; enemies in the approved radius are pushed outward and allies are unaffected. Falling into the void must not generate an unintended arena-wide impact. Exact cancel and interrupted-landing behavior requires a decision.

### 8.5 Natural loadout synergy

| Weapon | Gust | Magnet | Bounce |
|---|---|---|---|
| Spring Fist | Edge control and follow-up punches | Pull into punch range | Repositioning and aerial approaches |
| Wrecking Hammer | Force movement before a heavy swing | Pull into Hammer range | Aerial Ground Slam |
| Paddle Pops | Pressure toward exposed edges | Bring enemies into close range | Hit-and-run repositioning |

These describe intended opportunities, not guaranteed combos. Do not implement nine separate special attacks for v0.1.

## 9. Arena requirements

**Purpose:** Offer three distinct combat environments without changing the core ring-out objective. Every map supports both 1v1 and 2v2.

Exact dimensions, spawn coordinates, fall bounds, and safe-spawn protection are open. Greybox and evaluate these before final environment art. Safe spawning and respawning are confirmed requirements; the precise protection mechanism is not yet selected.

### 9.1 The Platform

| Attribute | Confirmed specification |
|---|---|
| Purpose | Fundamental combat testing and balanced competition |
| Theme | Calm, minimal, neutral; Japanese inspiration is provisional |
| Layout | One medium-sized circular or octagonal platform; final shape open |
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
| Footprint | Medium-large; exact dimensions open |
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

**Open:** Section geometry and selection, safe duration, warning duration, collapse duration, restoration timing, visual warning treatment, and hazard behavior during sudden death. No shrinking-arena rule is established.

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

**Open:** Exact ring-out boundary, when recovery stops being possible, avatar reset handling, unexpected character death, and failure to spawn. Do not silently treat a disconnect as a ring-out; departures have their own confirmed rules.

### 10.3 Scoring and attribution are separate

The team score does not depend on determining who last hit the eliminated player. Individual knockout statistics may be tracked separately, but detailed assists and attribution are not required for initial scoring.

A lightweight recent-hit system may support the knockout feed. Its attribution window, qualifying attacks, and icon rules are open. If no recent valid attacker is identified, show an environmental fall message.

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

**Open decisions required for implementation**

- Define the simultaneity window and event ordering used to compare eliminations.
- Define the transition when regulation ends while players are eliminated or awaiting respawn. All participants' eligibility must be explicit before a fair sudden-death start can be accepted.
- Define restart spawn positions, ability cooldowns, character motion reset, and hazard reset behavior.
- Define score presentation during sudden death without altering the confirmed elimination-based win rule.
- Define the ordering of a ring-out and the regulation deadline when both occur at the boundary.

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

**Open edge cases:** Both teams leaving together, server shutdown, reconnection eligibility, and departure timing during dispatch or a terminal result. These require explicit handling without inventing progression penalties.

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

**Open:** Effect libraries and assets, exact shake settings, feed lifetime and stacking limits, and the icon convention for ability-caused knockouts. Do not imply that an effect library has already been selected.

### 12.2 Results

Results must reflect the authoritative winner or forfeit and lead players back to the lobby. Exact layout, display duration, detail level, and whether there is a direct rematch action are open. The confirmed repeat-play route is returning to the lobby and queueing again.

**Technical constraints:** The server determines ability readiness and deadlines. The client interpolates visuals and countdowns from authoritative state. Avatar thumbnails, sounds, and effects must not block scoring or phase transitions if an asset fails to load.

**Acceptance criteria**

- Timer, score, feed, and ability status appear in the specified locations in both modes.
- The radial overlay clears clockwise and numeric cooldown agrees with server readiness.
- Final-30-second and final-10-second urgency occurs correctly; sudden death replaces the timer.
- Environmental falls remain understandable without false attacker credit.
- Regulation elimination shows a respawn countdown; sudden death does not promise a respawn.
- Results match the server's winner and provide the return flow.

**Engineering recommendation:** Check readability at supported screen sizes, avoid relying only on color for ready and hazard states, and keep effects readable at lower graphics settings. Device coverage and specific accessibility options remain open.

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

**Engineering recommendation:** Use a bounded retry policy, explicit arrival tracking, and a visible recovery state. Choose retry limits, timeout durations, and recovery wording before finalizing this phase. If the expected roster cannot be assembled, cancel before combat rather than silently start an unintended incomplete match. This is a recommended failure policy; partial-arrival rules remain open until approved.

Returning players need a route to any valid public lobby; returning to the exact original lobby instance is not a confirmed requirement. Public late joining and backfilling an active reserved match are not established features.

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
| AC07 | Knockback, Bounce, and miss punishment are exercised | Direction is readable; valid Bounce can recover; missed attacks expose recovery |
| AC08 | Repeated Paddle Pops pressure | Target retains a meaningful opportunity to respond; no indefinite stun-lock |
| AC09 | Ally is inside an attack, cone, pull, or shockwave | No harmful friendly-fire outcome |
| AC10 | Combat, accidental, intentional, and hazard falls | Opposing side receives +1 per regulation elimination |
| AC11 | One elimination has duplicate callbacks | One point, one elimination event, at most one regulation respawn |
| AC12 | Tied regulation and 2v2 sudden death | Untimed; no respawns; first lost player decides the losing team |
| AC13 | Mutual sudden-death elimination | Restarts using the approved simultaneity and reset rules |
| AC14 | Departures in every phase | Queue removal, intermission cancellation, 1v1 forfeit, 1v2 continuation, or team forfeit as specified |
| AC15 | Every map runs in both modes | Topology, safe spawns, fall bounds, and hazard behavior meet map requirements |
| AC16 | The Ring hazard cycles | Clear warning; only selected sections collapse; reliable center; collision restores |
| AC17 | HUD across combat phases | Correct mode-specific score, urgency, overtime label, feed, and authoritative cooldown |
| AC18 | Parallel or successive sessions | No leaked roster, score, cooldown, hazard, timer, or presentation state |
| AC19 | Reserved dispatch and lobby return fail | Approved retry or recovery paths prevent stranded players and duplicate starts |
| AC20 | Friends complete repeated matches | Feedback records fairness, clarity, controls, combat enjoyment, and voluntary repeat play |

Open policies referenced in this matrix must be decided before their corresponding gate can pass. A provisional number may be used during testing, but must remain labeled and configurable.

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

**Open performance targets:** Supported devices, reference hardware, frame rate, network latency tolerance, lobby capacity, and maximum concurrent local sessions. Agree measurable targets before final technical signoff rather than asserting unapproved numbers.

## 16. Implementation phases

### Milestone 1 Core combat prototype

**Scope:** Third-person 3D movement; two players; The Platform; shared weapon and ability configurations; all three weapons; all three abilities; Hammer plus Bounce Ground Slam; directional knockback; elimination; scoring; regulation respawns; timed match and results.

**Exit criteria:** Two players complete a match and understand its outcome. Combat acceptance criteria for attacks, cooldowns, friendly-fire preparation, duplicate elimination prevention, and recovery are exercised as applicable. Players find fighting enjoyable enough to continue. Final art and teleport infrastructure are not prerequisites for this milestone.

**Dependencies:** Choose prototype movement, hitbox, launch, fall-boundary, and spawn settings as explicitly provisional configuration. Resolve action-state rules needed to make the prototype coherent.

### Milestone 2 Complete local player flow

**Scope:** Main menu; shared lobby; physical 1v1 and 2v2 queues; random teams; intermission; map voting; private loadout selection; all three maps; complete HUD and combat feedback; sudden death; departure rules; results and return flow.

**Exit criteria:** AC01–AC18 pass for the relevant local implementation after open gameplay policies are resolved. Each map works in both modes. A departure or cancellation does not strand the remaining players. Local session reuse is clean.

**Dependencies:** Vote resolution, sudden-death boundary and restart rules, safe spawning, anti-stun-lock behavior, and necessary 2v2 target-selection decisions.

### Milestone 3 Reserved match servers

**Scope:** Separate lobby and match places; reservation and group teleportation; destination initialization; intermission in the match server; failure and departure handling; lobby return.

**Exit criteria:** AC19 passes alongside the end-to-end flow in the published multiplayer environment. Full and partial arrival, dispatch failure, destination departure, and return failure have approved behavior and exercised recovery. Session isolation remains intact.

**Dependencies:** A complete local flow; agreed arrival and retry policies; configuration of the lobby and match destinations. Avoid making cross-server matchmaking a prerequisite.

### Milestone 4 Friends and family beta

**Scope:** Play with friends; evaluate balance, map fairness, knockback, recovery, controls, visibility, and voluntary repeat play. Tune provisional values based on observation.

**Exit criteria:** The complete acceptance matrix is reviewed, critical gameplay and flow failures are resolved, and the product owner accepts the current tuning for the beta. No numerical retention or win-rate threshold has been fixed.

**Planning note:** Dates, staffing, effort estimates, and milestone owners remain open. Preserve this sequence so infrastructure follows evidence that the combat works.

## 17. Provisional tuning register

This register is the single review list for supplied starting values. Changing a number here should update the corresponding runtime configuration and any dependent acceptance scenarios.

| Area | Proposed starting value | Review focus |
|---|---|---|
| Regulation duration | 3 minutes | Pace, comeback opportunity, queue-to-match satisfaction |
| Respawn delay | 3 seconds | Downtime, pressure, safe re-entry |
| Map voting window | 8 seconds | Enough time to recognize and choose maps |
| Loadout window | 12 seconds | New-player comprehension and repeat-player downtime |
| Default loadout | Spring Fist plus Gust | Approachability and valid automatic selection |
| Gust cooldown | 8 seconds | Positional value and counterplay |
| Magnet cooldown | 12 seconds | Pull frequency and punish opportunities |
| Bounce cooldown | 10 seconds | Recovery availability versus offensive opportunity cost |
| Spring Fist | Startup 0.08 s; recovery 0.32 s; reach 5 studs; horizontal/vertical launch 50/12 | Balanced responsiveness and reach |
| Wrecking Hammer | Startup 0.48 s; recovery 0.65 s; reach 7 studs; horizontal/vertical launch 75/16 | Readability, heavy launch, punishable misses |
| Paddle Pops | Startup 0.10 s; recovery 0.16 s; reach 3.5 studs; horizontal/vertical launch 25/8 | Close pressure without indefinite stun-lock |
| Dispatch countdown | Short countdown proposed; no duration chosen | Group clarity and departure behavior |
| Ground Slam trade-off | Possibly less launch per target than a direct Hammer hit | Area coverage versus direct-hit reward |

Launch values are conceptual velocity-change targets. Exact application in Roblox physics requires prototype evaluation. No additional numerical defaults are established by this PRD.

## 18. Open decision register

Resolve each question before accepting the dependent system. Owners are not assigned; the suggested timing identifies the milestone that needs the answer.

| ID | Decision still needed | Needed for |
|---|---|---|
| O01 | Movement speed, jump settings, default air steering, and committed-knockback behavior | Milestone 1 |
| O02 | Camera behavior, aim and facing direction, and attack-state movement permissions | Milestone 1 |
| O03 | Weapon active frames, hitbox shapes and sizes, repeat-hit rules, input buffering, held attack behavior, and trades | Milestone 1 |
| O04 | Mechanism preventing indefinite stun-lock without erasing weapon identity | Milestone 1 |
| O05 | Gust range, cone, push, duration, and interruption interactions | Milestone 1 |
| O06 | Magnet range, pull behavior, obstruction, and directional target selection; 2v2 selection must be tested | Milestones 1–2 |
| O07 | Bounce strength, direction, steering, and special-state eligibility | Milestone 1 |
| O08 | Ground Slam radius, launch, preparation and recovery, landing trigger, and direct-hit overlap | Milestone 1 |
| O09 | Arena dimensions, bridge widths, final Platform shape, spawn coordinates, safe-spawn policy, and ring-out commitment boundary | Milestones 1–2 |
| O10 | Exact regulation duration and respawn delay after playtesting | Milestones 1–4 |
| O11 | Vote ties, no votes, intermission sequencing, and confirmation edit policy | Milestone 2 |
| O12 | Queue overlap, extra entrants, dispatch departure handling, allocation capacity, and full-capacity behavior | Milestone 2 |
| O13 | Sudden-death transition roster, simultaneity window, deadline ordering, restart state, and score display | Milestone 2 |
| O14 | Ring section selection, warning, collapse, restoration, and sudden-death hazard behavior | Milestone 2 |
| O15 | Recent-hit attribution, attribution window, ability icons, feed duration, and stack limits | Milestone 2 |
| O16 | Avatar reset, unexpected character death, reconnects, simultaneous team departures, and shutdown policy | Milestones 2–3 |
| O17 | Controller and mobile mappings, supported device scope, camera settings, and accessibility options | Before device acceptance |
| O18 | Hit-effect and sound assets or libraries; effect intensity and fallback presentation | Milestone 2 |
| O19 | Results layout, display duration, and any direct rematch action | Milestone 2 |
| O20 | Match handoff admission, arrival timeout, partial-arrival cancellation, retries, and failed lobby-return recovery | Milestone 3 |
| O21 | Lobby maximum players, performance targets, physics ownership approach, and latency tolerance | Milestones 1–3 |
| O22 | Sudden-death anti-stalling, if explored later | Future design review; not a beta gate |
| O23 | Future reward treatment for innocent remaining players | With progression design; not a beta gate |

## 19. Deferred features and risks

### 19.1 Explicitly outside v0.1

- Inventory management and persistent equipment unlocks.
- Currency, progression, shops, monetization, and purchasable weapons.
- Party formation and manual 2v2 teammate selection.
- Ranked and cross-server matchmaking.
- Complex combo systems, universal blocking or parrying, and universal air recovery.
- Additional weapons and abilities or a large roster of special weapon–ability interactions.
- Continuous whole-arena rotation on The Ring.

Detailed assist tracking is not required for initial scoring. A sudden-death anti-stalling system is a later exploration, not a current requirement. Do not create a progression system merely to implement future reward policy language.

### 19.2 Delivery risks

| Risk | Why it matters | Response within the approved scope |
|---|---|---|
| Knockback feels inconsistent | Players cannot judge spacing or understand losses | Prototype physics early; tune launch and recovery on The Platform |
| Paddle Pops removes counterplay | Fast attacks could produce indefinite control | Choose and evaluate an explicit anti-stun-lock rule |
| Bounce becomes mandatory or ineffective | Recovery can dominate loadout choice | Evaluate cooldown and launch against offensive opportunity cost |
| Hammer or Ground Slam is unreadable | Heavy attacks feel unavoidable | Evaluate windup, impact readability, radius, and recovery |
| Map geometry creates loadout bias | One weapon could dominate bridges or edges | Test every map in both modes with varied loadouts |
| Collapse warnings are unclear | Hazard eliminations feel arbitrary | Validate warning visibility and escape opportunity before final art |
| Sudden-death races produce arbitrary winners | Fairness depends on event timing | Agree simultaneity and transition rules; evaluate boundary cases |
| Teleports split or strand groups | Players cannot finish the intended journey | Complete local flow first, then exercise partial-arrival and return recovery |
| Presentation hides combat | Players lose information during busy fights | Keep effects brief and camera response subtle; review 2v2 visibility |
| Scope grows before combat is fun | Infrastructure and content delay useful feedback | Keep milestone order; tune the confirmed roster before expanding it |

## 20. Source and maintenance notes

The supplied **Knockout Night v0.1 Confirmed Game Design Decisions** is the product source of truth. The referenced **Roblox Game Ideation** conversation and HUD whiteboard establish the minimal HUD layout, pre-fight selection approach, automatic teams, and fully 3D gameplay intent. The supplied source-of-truth clarification controls where it provides greater detail.

Engineering references consulted for platform constraints:

- [Roblox teleport guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/teleport.md): server-side teleportation, reserved destinations, and teleport failure handling.
- [Roblox client and server boundary guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/client-server-boundary.md): validate client requests before applying authoritative outcomes.
- [Roblox network ownership guidance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/network-ownership.md): client-controlled physics, movement validation, and legitimate movement tolerances.

When a provisional value is accepted or an open question is resolved, update its status, the relevant requirement, runtime configuration, and acceptance criteria together. Record material design changes below so later implementation does not confuse an old proposal with the current decision.

### Change log

| Date | Version | Change |
|---|---|---|
| October 20, 2026 | 0.1 | Consolidated confirmed game design into an implementation-oriented PRD; separated provisional tuning, open decisions, engineering recommendations, and deferred scope. |
