# F10 - Recover using Bounce

Implemented and technically verified October 22, 2026. **David signed off F10 gameplay on October 23, 2026, with current Bounce tuning at 48 horizontal / 90 upward studs/s.** Scope: local 1v1 on The Platform, including the explicitly authorized temporary ability selector next to the weapon selector. F11 Ground Slam, private intermission selection, other maps, polish, asset exports, and publishing remain separately gated.

## Behavior

| Setting | Value |
| --- | --- |
| Cooldown | 10 seconds from accepted activation |
| Launch | Replacement velocity: 48 horizontal / 90 upward studs/s |
| Direction | Camera-relative held movement sampled on Q press; normalize diagonals; no movement launches straight up |
| Primary delay | 0.15 seconds; early attacks are rejected without buffering |
| Steering after launch | Existing ordinary airborne movement |
| Protection / armor | No new protection or armor; existing displacement protection remains; spawn protection ends |

Bounce works grounded, airborne, during ordinary knockback and its weapon-hit reaction, and to escape Magnet. It cannot cancel the user's existing weapon or ability action. Gust's 0.25-second stun rejects Bounce; the runtime distinguishes that stun deadline from ordinary weapon reaction. Escaping Magnet ends its pull, retains the ordinary minimum protection deadline, and prevents that pull resuming. Gravity and physical collisions remain active. The server checks life/bounds and match eligibility before acceptance; an eliminated player cannot recover. Bounce leaves enemy knockout attribution untouched.

`F10Bounce` defines tuning and normalized launch components. `F2Combat` validates finite horizontal input, maximum input magnitude, character generation, sequence, traffic, alive/equipped status, selected ability, action, stun, and cooldown. The server owns the launch through the next simulation update, then restores the motor and player ownership with the existing authoritative release snapshot. This uses ordinary airborne controls rather than the weak knockback steering path. Horizontal and vertical movement-validation allowances include the legitimate launch.

Player-owned cooldowns continue through death/respawn and equip cleanup. Fresh matches and sudden-death round resets clear the cooldown; retirement, departure, and shutdown clean launch state. Q is a fresh-press input, with no ability buffering or held-key auto-repeat.

## Temporary loadout selector

The centered weapon and ability panels sit side by side. Gust, Magnet, and Bounce are available; Bounce defaults when no ability was selected. The server validates the enum, staging/waiting state, connected player, and 0.15-second selection request limit. Countdown closes the existing staging gate and locks both choices through respawns and sudden death. Combat independently rejects requests for unequipped abilities.

This deliberately brings the owner-requested developer selector forward from the later loadout work. Selections are session-only replicated attributes, like the existing weapon picker. L4's timed private intermission flow remains unimplemented. Q and the single cooldown HUD now follow the selected ability; this supersedes F9's temporary fixed Magnet binding.

Feedback uses a brief expanding launch pad and bundled pitched ping, with selected-ability readiness/cooldown and rejection text. Temporary parts are noncolliding and expire or clear with their character. No assets were generated or exported.

## Technical verification

| Check | Result |
| --- | --- |
| `tests/run_f10_checks.ps1` | Passed: 579 deterministic checks, including 24 Bounce and 555 F2-F9 regressions |
| StyLua / Selene / Luau compilation | Passed; zero lint errors or warnings |
| Isolated R15 engine integration | 74 checks passed |
| Magnet runtime regression | 50 checks passed |
| Single live client probe | 17 checks passed |
| Studio source comparison | All 26 local runtime scripts match Studio; temporary fixtures removed; Studio returned to Edit |

Evidence: [F10Bounce.json](../evidence/F10Bounce.json). `tests/build_f9_harness.ps1` embeds current checked combat source with synthetic roster/remote/clock dependencies and forced server ownership. `tests/F10Runtime.spec.luau` covers grounded/falling/diagonal launch, invalid input, unequipped/stale rejection, expiry and respawn cooldown behavior, primary rejection without buffering, ordinary aerial attacks with all weapons, startup noncancellation, weapon-reaction recovery, Gust stun, Magnet escape, attribution/protection, gravity, wall/underside collisions, elimination eligibility, and death cleanup. F8/F9 fixtures now explicitly equip the abilities they exercise.

`tests/F10Live.server.luau` is explicitly gated and temporarily installed for the one-client probe. It exercises real selection validation, a closed staging gate, actual keyboard Q through the real controller/combat remote, ownership return, motor restoration, and launch cleanup. The measured straight-up rise was about 8.91 studs. Its temporary active-match gate supplies a single-player technical environment; it is not a completed two-player match. Client inspection verified adjacent visible selectors, all three options, default Bounce selection, Gust selection replication, and the selected-ability cooldown HUD.

The initial Studio comparison also found an existing double-KO feed punctuation difference in `F4Rules`; the checked local source was synced as required. No local rules behavior changed. An initial direct MCP-command selection probe used a separate module execution context and was rejected; the normal server Script probe and actual client remote subsequently passed. Final game checks showed no project runtime errors. The existing unrelated `rbxassetid://203785492` asset-type mismatch remains.

## Owner acceptance and remaining technical verification

David signed off the current F10 gameplay on October 23, 2026, including the 48 horizontal / 90 upward studs/s Bounce tuning. The sign-off covers gameplay acceptance for this slice; it does not close the technical verification gaps below or authorize F11, polish, or publishing.

Two-live-client networking, target latency, full match/countdown/sudden-death integration with the temporary selector, and adversarial ownership handoff under latency remain unverified. Existing shared match gates and reset paths are reused; the single-client probe does not establish those multiplayer results. These remain technical verification items, separate from the completed gameplay acceptance.

## Owner tuning follow-up

David requested tripling Bounce. Horizontal launch increases from 32 to **96 studs/s**, and upward launch from 60 to **180 studs/s**. Cooldown remains 10 seconds and primary delay remains 0.15 seconds. This triples velocity, not height: ignoring collisions, upward height scales with velocity squared (roughly nine times the original height). Direction, action rules, and lifecycle behavior are unchanged.

The 579 deterministic checks, formatting, lint, and compilation passed with the 96/180 tuning before Studio comparison/sync. The 74 engine and 17 live-client results above describe the original 32/60 tuning; neither set was rerun for this numerical adjustment. David later accepted the current gameplay on October 23, 2026; see the owner acceptance record below.


## Owner tuning follow-up — October 23, 2026

David requested halving both launch speeds: horizontal from 96 to **48 studs/s**, upward from 180 to **90 studs/s**. Cooldown remains 10 seconds and primary delay remains 0.15 seconds. Direction, action rules, and lifecycle behavior are unchanged. The focused offline suite passed all 24 Bounce checks, with formatting, lint, and Luau compilation passing. Studio synchronization completed on October 23, 2026. Engine and live-client checks were not rerun for this tuning. David signed off F10 gameplay on October 23, 2026; two-live-client verification and target-latency checks remain open.
