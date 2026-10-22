# F5 — Resolve tied matches

**October 22, 2026:** Implemented and technically verified for the local 1v1 Platform prototype. **Signed off by the product owner on October 22, 2026, after hands-on testing.** The owner published the updated place and confirmed sudden death works before explicitly signing off F5. This acceptance does not authorize F6, further publishing, or asset generation/export.

## Owner acceptance

David accepted F5 on October 22, 2026. The initial frozen sudden-death report came from testing the older published build in the Roblox app; after publishing the updated place, the owner confirmed the feature works and signed off. No additional runtime fix was made for that report. This sign-off accepts the current slice; it does not claim that every manual edge case below was individually exercised. Future-map hazards, abilities/cooldowns, 2v2, target-latency verification, and wider release gates remain separate work.

## Implementation

- `F4Rules` extends the existing match rules with `sudden-death-pending → sudden-death-countdown → sudden-death`. The pending state is the reset handoff; the coordinator completes the reset before publishing the countdown. Regulation scores remain unchanged throughout overtime and in immutable final results.
- The first server elimination commitment records `closesAt = at + 0.2`. Only an opposing commitment at or before that value is mutual. The comparison uses commitment timestamps, never task delivery time. A late event is rejected even if Heartbeat has not delivered results yet. The next coordinator update finalizes the elapsed window; scheduling delay cannot grant additional eligibility.
- Departures drain before pending outcomes. A departure during either sudden-death countdown or decision window awards the remaining connected player a forfeit, including an already eliminated player. Both players departing means no winner. Finalized results remain immutable.
- `F3Lives.resetRound` resets both connected participants through the existing fresh-character path at each player's original regulation starting frame. Each replacement advances both the life identity and combat generation. Old callbacks, requests, action buffers, displacement state, motion, protection, effects, and respawn timers cannot follow it. Attribution clears; neither fresh sudden-death life has spawn protection. No ordinary sudden-death respawn is scheduled or selected.
- GO releases both players in the same coordinator transition, using the existing opening countdown. Production sudden-death countdown is three seconds even when the developer console configures a different initial match countdown. Actions are gated on both server and client. Fresh combat registrations survive the frozen countdown; freezing must not retire the new registrations a second time.
- Elimination retires combat immediately and marks the character dead. The final launch application also rechecks the attacker, so an already committed eliminated attacker cannot apply a queued active hit. Existing valid active trades remain supported.
- The HUD shows SUDDEN DEATH with countdown/GO, keeps the tied score, hides ordinary respawn promises, and reuses results. Mutual losses hold their individual feed events and emit exactly one neutral system entry; a decisive loss releases the ordinary attributed event without scoring.

## Integration seams and scope limits

The match coordinator contains no Platform coordinates or hazard rules. `Lives.add(player, initialFrame)` supplies the starting frame reused by regulation and every sudden-death reset. Future arena setup supplies its own mirrored frames. `Lives.start(createCharacter, world, points, emergency, resetHazards)` accepts an optional synchronous arena-owned safe-phase callback. `resetRound` calls it before placing either player or starting the countdown. Platform uses the no-op default. Future Ring integration must cancel old hazard callbacks, restore safe surfaces, and restart its safe phase there; Sky Bridges supplies its own starting frames. Their geometry, hazards, spawn safety, and elimination bounds are not implemented by F5. Existing F3 Platform bounds still need map-specific integration in those slices.

Spring Fist is the only implemented/equipped weapon. Abilities, ability cooldown state, and loadout selection do not exist in this runtime. F5 preserves the current Spring Fist loadout and resets its transient state; it does not fabricate or claim verification of future abilities. When those slices arrive, retain chosen loadouts in player/session-owned data across `Lives.reset`, initialize each new character from that choice, and reset ability cooldowns/effects in the same fresh-round path. Regulation respawns must continue to preserve cooldowns as specified in DD05.

The approved task overrides the old F4 frozen tie endpoint and roadmap's unimplemented/unauthorized F5 status. PRD D09's broad every-ring-out wording now explicitly applies to regulation; section 11 records the inclusive approved window, departures, identities, and presentation. F4's historical acceptance is preserved; its obsolete handoff instructions now point here. F6 and later gates remain separate.

## Verification

Run from the project root:

```powershell
./tests/run_f5_checks.ps1
```

| Check | Result |
| --- | --- |
| StyLua, Selene, standalone Luau compilation for affected runtime/tests and existing F2–F4 runners | Passed; zero lint errors/warnings |
| F2 / F3 / F4 deterministic regressions | 28 / 17 / 143 passed |
| F5 deterministic rules | 254 passed |
| F5 two-client Platform repeated rounds and decisive result | 98 assertions passed |
| F5 countdown departure using real Kick | 26 assertions passed |
| F5 decision-window server removal | 33 assertions passed; already eliminated connected player wins by forfeit |
| F4 two-client consecutive-match/result/tie regression | 50 assertions passed |
| F3 two-client life/respawn regression | 35 assertions passed |
| F2 two-client combat regression | 28 assertions passed |
| Runtime source comparison / cleanup | All 20 sources match; production 3/180/8 timing restored; temporary fixtures removed; Studio in Edit |

[Raw engine evidence](../evidence/F5Match.json) records assertions and both clients' replicated snapshots. Pure rules tests use supplied timestamps, including both event orders, equality, 0.200001-second rejection after delayed resolution, duplicates, stale sessions/lives, reset decision cleanup, twelve consecutive mutual rounds, untimed play, countdown/window departures, pending mutual/departure priority, both-empty, and immutable results. Engine tests additionally exercise pending regulation respawns at expiry, fresh identities, mirrored starts, zero motion, action/effect/protection cleanup, countdown lock, combat readiness at GO, feed cardinality, tied-score results, and client agreement. Exact floating-point boundary timing is proven by deterministic rules, not claimed from live network events.

The F5 engine fixture temporarily uses **3/2/8-second** opening/regulation/results timing so both regulation respawns are pending at expiry. F4 regression uses **2/8/2**. F2/F3 run with production **3/180/8**. Temporary values are never written into project runtime sources.

Two original F2 runs failed an instrumentation assumption: a separately connected PreSimulation listener sometimes sampled after the physics step, observing approximately (32.35, 8.73, 0) rather than the pre-physics (50, 12, 0). The fixture now wraps the actual `Combat.step` call and samples immediately after it, independent of connection registration order. The exact launch assertion is unchanged and passes. No combat tuning was changed to satisfy it.

Initial F5 fixture work also corrected a comparison of a falling post-GO position against an anchored spawn: the expected starting frame is now captured during regulation's opening countdown. Some test attempts reported a Roblox-generated `PlayerScripts.ChatScript` CoreGuiChatConnections initialization error; passing final runs contain no client errors and the error collector still reports it. A `Kick()` during the 0.2-second window can be delivered after the window has closed, legitimately resulting in a sudden-death loss. The bounded-window fixture therefore uses synchronous server-side Player removal; pure tests cover timestamp/priority semantics, and the countdown scenario retains an actual Kick. Real voluntary disconnect observed within that narrow window remains a manual/network scenario.

To reproduce engine checks, temporarily insert the matching `.server.luau` Script and `.client.luau` LocalScript as `F5MatchFixture` in ServerScriptService and StarterPlayerScripts. Configure the temporary timing above, then execute `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="F5Match"})` from Edit. Repeat with `scenario="countdown-departure"` and `scenario="window-departure"`. Remove fixtures and restore production timing. Compare runtime sources before Studio changes and run the local checks first.

No full standalone Roblox type analysis, target-latency run, reference-hardware performance evaluation, broad viewport review, future-map hazard test, or ability cooldown test is claimed. HUD bounds were checked at 1607×873; owner gameplay acceptance for the current F5 slice is complete. Remaining technical and release checks are not implied by sign-off.

## Manual Studio regression steps

1. Start **Server & Clients with 2 clients**. Reach regulation, keep scores tied, and use the existing developer console's **End Regulation Now**. Confirm both return to their mirrored starts, the score stays tied, SUDDEN DEATH counts down three seconds, neither can move/jump/attack early, and both unlock at GO.
2. Before ending another tied regulation, arrange for one or both players to be waiting on a respawn. Confirm the old timer is discarded, both reset fully, and neither receives a spawn shield. Attack immediately after GO to check readiness and old-effect cleanup.
3. Produce a single sudden-death ring-out or avatar reset. Confirm no ordinary respawn/countdown, one ordinary feed entry, an opponent sudden-death win after the short decision window, and the original tied final score on both clients.
4. In the **server Command Bar**, during sudden death, run the snippet below to commit both current lives in one server turn. Confirm one DOUBLE KO feed entry, a full reset/countdown, and unchanged scores. Repeat; there is no round cap.

```lua
local lives = require(game.ServerScriptService.F3Lives)
for _, player in lives.roster() do
    lives.eliminate(player, player:GetAttribute("F3Life"), "manual-mutual-check")
end
```

5. In separate runs, close a client during the sudden-death reset countdown and attempt a departure during the decision window. Confirm a server-observed departure before finalization awards whoever remains connected a forfeit, even if already eliminated. A disconnect reaching the server after the result is finalized cannot rewrite it.
6. Review banner/feed separation, transition clarity, character/camera behavior, and combat feel yourself. Current F5 gameplay acceptance is complete; use these steps for future regression reviews. Staging returns remain F4's existing local flow.
