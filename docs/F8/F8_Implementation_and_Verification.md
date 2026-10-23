# F8 - Use Gust for positioning

**Implemented and technically verified: October 22, 2026. Owner gameplay acceptance: pending.** Local 1v1 on The Platform only. Nothing was published.

## Implementation

Q activates the default Gust ability for both players, independently of the existing weapon picker. There is no ability selection. `ReplicatedStorage/F8Gust.luau` follows the existing shared profile pattern and holds the provisional settings:

| Setting | Value |
| --- | --- |
| Cooldown | 15 seconds, beginning at accepted activation |
| Horizontal range / full cone angle | 12 studs / 60 degrees |
| Startup / instantaneous effect / recovery | 0.12 / 0 / 0.20 seconds |
| Replacement launch | 35 horizontal / 6 upward studs per second, along committed aim |
| Vertical overlap band | 5 studs tall, centered at the user's root |
| User movement | Normal movement speed; no jumping during the brief action, no lift or hover |
| Gust stun / displacement protection | 0.25 / 0.35 seconds; ordinary weapon reaction remains 0.15 seconds |

`F2Combat` owns activation, cooldown, aim commitment, contact resolution, and launch. Requests share existing generation, sequence, finite-vector validation, rate limiting, match/alive/equipped gates, and action cleanup. Gust cannot overlap a weapon or another Gust. Neither Gust nor weapon presses queue during Gust. A rejected request spends no cooldown; a miss or interrupted startup keeps its original deadline. Gust can activate during ordinary airborne movement and after brief hit reaction while displacement continues; activation does not release displacement or restore movement control early.

The horizontal cone checks opponent root position, with inclusive range/angle boundaries. Actual R15 body parts must overlap the vertical band; accessories do not count. Each target receives its own solid-obstruction check against body surfaces, excluding characters and the shared probe. An obstructed target does not stop other contacts. The server checks current poses once after startup, rather than sweeping a persistent wind field. Each target can be consumed only once. The resolver supports multiple targets even though the current match roster is 1v1.

Contacts enter the existing ordered shared resolver. A successful Gust interrupts target startup and blocks new weapon/ability actions for 0.25 seconds. Actions already in their active phase retain the shared trade rules. Movement/jump restrictions use the existing hit-reaction path; physics recovery may outlast the minimum stun. Incoming weapon hits can cancel Gust startup, including contacts collected later in the same slow server update. The burst is emitted only after resolving interruption. An already applied effect remains applied. Protected contacts produce no launch, reaction, cancellation, attribution, or protection extension. Successful launches retain existing server ownership, motor management, air steering, reaction/protection, recovery, and bounded cleanup. The knockout feed attributes successful Gust hits to Gust.

Cooldown storage belongs to the player rather than the character: death, respawn, and equip cleanup cannot refund it. The existing fresh-match retirement path resets it for new matches and sudden-death rounds. Departure and combat shutdown clear cooldown records and attributes.

`F2Client` adds an accepted cue and five thin moving wind streaks spanning the cone, plus a short instance of Roblox's bundled `action_falling.ogg` sound. The burst begins behind the user and travels forward. Existing hit feedback makes successful displacement visible. Effects are noncolliding, tweened, and removed after 0.22 seconds or character cleanup. A small temporary bottom-center HUD shows Q, the authoritative cooldown, and ordinary busy/recovery/cooldown rejection reasons. Invalid/stale/rate-exhausted traffic retains the existing silent early-return behavior.

## Tuning follow-up, October 22, 2026

David said the initial Gust looked good and requested more range plus a brief stun to prevent immediate counters. Range increased from 9 to 12 studs (+33%). Gust's action lock increased from the inherited 0.15 seconds to a dedicated 0.25 seconds and now interrupts startup. Active attacks still trade. Cone, launch, and user startup/recovery remain 60 degrees, 35/6 studs/s, and 0.12/0.20 seconds. The initial cooldown was eight seconds; the subsequent owner request increases it to fifteen seconds.

The user finishes recovery 0.20 seconds after the effect; the target's stun ends 0.25 seconds after it, giving a nominal 0.05-second initiative window. Protection still lasts 0.35 seconds, so an immediate follow-up does not guarantee another launch. Balancing this revision still requires David's playtest; the favorable initial feedback is not acceptance of the revised tuning.

**Cooldown follow-up, October 22, 2026:** Increased Gust cooldown from 8 to 15 seconds at David's request. Updated deterministic expectation and multiplayer fixture deadlines. All 525 deterministic checks, formatting, lint, and compilation pass again. Earlier two-client evidence above retains the eight-second run; this scalar cooldown follow-up is verified in the Edit module rather than claimed as another multiplayer run.

## Design reconciliation

The approved F8 request supersedes the roadmap's previous instruction to await F8 authorization. David's October 22 tuning request supersedes the initial nine-stud, no-startup-interruption design: Gust now reaches 12 studs and applies a 0.25-second stun with startup interruption. The PRD and roadmap reflect this revision. Its existing rule that cooldowns persist through death and reset for fresh matches/sudden-death rounds is now implemented for Gust. Magnet, Bounce, Ground Slam, ability selection, later maps, art/export, polishing, and publishing remain deferred. Existing F6 acceptance and milestone/release gates are unchanged.

## Technical verification

Run `./tests/run_f8_checks.ps1` from the project root. The runner includes F2-F7 regressions, StyLua, Selene, standalone Luau compilation, and the focused Gust rules spec.

| Check | Result |
| --- | --- |
| Formatting, lint, and compilation | Passed; zero lint errors/warnings |
| F2 / F3 / F4 / F5 / F6 / F7 deterministic checks | 28 / 17 / 143 / 254 / 29 / 29 passed |
| F8 deterministic rules | 25 passed; 525 including regressions |
| F8 two-client Platform fixture | 74 checks passed, including ten engine geometry checks; current 12-stud/stun revision |
| Existing Paddle/mixed-weapon combat regression | 55 assertions passed |
| Existing Paddle / Hammer / Fist geometry regression | 32 / 27 / 20 passed |
| Source comparison | Initial 23 runtime sources matched; final 24 sources match, including Gust |

[Current tuning evidence](../evidence/F8GustTuning.json) records accepted/rejected requests, invalid/stale inputs, weapon overlap, immediate cooldown, miss, cooldown expiry, interrupted startup without refund or burst, committed aim despite changed aim input, exact server-owned 35/6 replacement launch, target Hammer startup interruption from eleven studs, exact 0.25-second stun under unchanged 0.35-second protection, rejection after the old 0.15-second reaction window and a successful counter after the new stun expires, shared protection, vertical overlap, range/cone boundaries, independent obstruction, nonsolid scenery, cooldown persistence through equip/death/respawn, fresh-round reset, and airborne activation without lift/hover. Both clients observed accepted cues, bursts, and the HUD, with no project client or server errors. Simultaneous multiple-target and protected-contact resolver behavior is also covered by deterministic tests.

The [initial Gust evidence](../evidence/F8Gust.json) preserves the previous nine-stud/no-startup-interruption run. The mixed-weapon Studio regression below was run before this tuning; all deterministic weapon regressions passed again after it.

[Weapon regression evidence](../evidence/F8WeaponsRegression.json) records geometry for all three weapons and the existing two-client Paddle/mixed-weapon suite, including buffering, alternation, interruption, protection, response opportunities, attribution, and respawn cleanup.

To reproduce after running local checks and comparing/syncing runtime sources, temporarily install the F8Combat server/client fixtures as `F8CombatTestServer` under ServerScriptService and `F8CombatTestClient` under StarterPlayerScripts. Run `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="F8Combat"})` from Edit. The fixture invokes the existing round-reset hook to verify cooldown reset; it does not claim a new full sudden-death match-flow run. For the weapon regression, install the existing F7 fixture pair and F2/F6/F7 contact specs as in the F7 verification document. Remove fixtures and compare all runtime sources afterward. No production match timings were changed.

## Remaining limits and owner playtest

Studio plugin-icon download errors occurred on both F8 clients and are preserved separately as `engineErrors` in the evidence. No project errors were recorded. The weapon regression recorded no engine errors. No new 100-150 ms target-latency run, full Roblox type analysis, hardware performance sign-off, or four-player/multi-opponent network run is claimed. Cone targeting uses root position horizontally and current server poses without rewind. Obstruction samples one closest surface per eligible body part; very small exposed slivers may be excluded. Temporary visual streaks do not clip to walls. Sound presence uses an installed bundled asset; subjective audibility and all gameplay readability/feel remain unaccepted.

1. Start **Server & Clients with two clients**, choose any implemented weapons, and begin a match through the existing developer console. Press **Q** within about twelve studs while facing the opponent; check the burst, push, and fifteen-second cooldown. Try a miss and immediate repeat.
2. Turn the camera during Gust startup/recovery, jump before activation, and test height differences and a temporary solid wall. Check committed direction, no self-lift, and readable feedback without hiding players.
3. Try Gust against Hammer startup, then have a weapon hit interrupt Gust startup. Check that Hammer windup is canceled and an immediate counter is blocked for 0.25 seconds in the first case, interrupted Gust produces no burst in the second, and cooldown remains spent. Try protected contacts and a death/respawn; cooldown should persist through death and reset in a fresh match/sudden-death round.

**Await David's hands-on F8 evaluation.** Do not mark gameplay acceptance complete or continue into polishing/F9 without separate authorization.
