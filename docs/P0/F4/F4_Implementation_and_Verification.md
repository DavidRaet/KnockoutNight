# F4 — Complete regulation and results

**October 22, 2026:** Implemented, technically verified, and signed off by the product owner. F5 subsequently implemented the sudden-death continuation; see [F5 verification](../F5/F5_Implementation_and_Verification.md). The F4 evidence below records the original slice.

## Implementation

- `F4Match` owns one local 1v1 session, its authoritative score, clock, immutable result, and returns. It starts the first session when both admitted players are ready. Subsequent sessions use the server-only `Match.begin()` operation.
- `F4Rules` isolates the ordering decisions for deterministic testing. Heartbeat resolves queued departures before GO or pending elimination scores. A countdown departure cancels without a competitive result; an active departure awards the remaining side a forfeit; both sides empty means no winner. Finalized results remain unchanged by later departures or shutdown.
- `F3Lives` commits a session/life token at server time before disabling that life. Score/feed delivery waits for the coordinator's update. A pre-deadline commitment counts even when delivery happens after the deadline; equality and later commitments fail. Same-update departure resolution discards pending fall points and feed. Death/character-removal callbacks capture their original session and life.
- `F2Combat` checks server receipt time for every request and gates simulation work on the active session. Client timestamps grant no deadline exception. The existing character generation rejects requests from previous lives/sessions. No combat tuning or ownership strategy changed.
- Waiting/countdown roots are anchored. GO releases movement and combat and establishes the regulation deadline in the same coordinator transition. Regulation expiry retires actions, buffers, displacement, and protection, then freezes characters. Pending falls/respawns cannot continue scoring or respawning after expiry.
- One versioned `F4State` StringValue carries the complete roster, scores, phase, deadline, and result as JSON. Clients display that snapshot rather than independently determining winners. The HUD adds countdown/GO, a top-center timer, result reason/final scores, and Return to Lobby. The feed moves below the timer row to avoid overlap.
- A tie preserves scores and enters `sudden-death-pending`, with combat/respawns frozen and SUDDEN DEATH displayed. F5 now owns the full reset, repeat countdown, and untimed round through this handoff. F4 invents no tie winner or draw.
- `F4Config` retains the provisional PRD defaults: opening 3 seconds, regulation 180 seconds, results 8 seconds. Existing F1–F3 tuning remains unchanged.

The return destination in this developer-controlled prototype is local staging: no new lobby, queue, teleport, rematch system, or backfill is introduced. Players can return immediately or automatically at the results deadline. Starting another session is an explicit developer operation. The original result remains immutable while participants return separately.

## Technical verification

Run from the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_f4_checks.ps1
```

| Check | Result |
| --- | --- |
| StyLua, Selene, standalone Luau compilation | Passed; zero lint errors/warnings |
| Existing F2/F3 deterministic suites | 28 + 17 passed |
| F4 deterministic suite | 143 passed |
| Two-client F4 regulation/reuse/tie | 49 passed, including two completed sessions and a third tied session |
| Two-client active forfeit / both-empty / pre-GO cancellation | 6 / 5 / 3 passed |
| Two-client F1 regression | Passed; 16 matching body parts, symmetric starts, no body blocking |
| Two-client F2 regression | 28 passed |
| Two-client F3 regression | 34 passed |
| HUD timer/score/feed bounds | No overlap at 1607×873 in the F4 fixture |
| Studio source readback/cleanup | All 19 runtime sources matched; defaults restored; temporary fixtures removed; Studio in Edit |

[Raw engine evidence](../evidence/F4Match.json) records each assertion and client snapshots. F4 engine fixtures used temporary **2/8/2-second** opening/regulation/results settings to exercise repeated expiry. Production sources retain **3/180/8**. F1/F2/F3 regressions ran with those normal defaults restored. Exact timestamp equality, delayed delivery of already committed eliminations, simultaneous departure/GO or pending-score ordering, shutdown interruption, and 19 fresh-session cycles are covered in the pure rules suite; this does not claim networked events were generated at an exact floating-point timestamp.

The F1/F2/F3 fixtures now wait for GO. F3 explicitly advances or waits for coordinator score publication; reading life status alone no longer implies the end-of-update score has been published. The old F3 disconnect check moved to the F4 forfeit scenarios so that its bounded spawn-failure scenario still runs during active regulation. Known Studio plugin-icon asset errors are excluded from the F4 fixture's game-script error list; other errors fail that check.

To reproduce the engine checks, temporarily insert `tests/F4Match.server.luau` as a Script named `F4MatchFixture` in ServerScriptService and `tests/F4Match.client.luau` as a LocalScript with the same name in StarterPlayerScripts. Do not overwrite the `F4Match` runtime ModuleScript. With short test timing configured, invoke `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="F4Match"})` from Edit; repeat with `scenario="forfeit"`, `"empty"`, or `"cancel"`. Remove fixtures and restore default timing afterward. Follow AGENTS.md checks and source comparisons before each Studio change.

## Owner Studio playtest

1. Start two local clients. Try walking, jumping, and attacking during the opening countdown. Confirm both unlock at GO and show the same timer/score.
2. Produce a ring-out and an avatar reset. Check one opposing point each. Finish with unequal scores; compare winner, final scores, and regulation wording on both clients. Try a fall/attack near expiry and confirm nothing scores afterward.
3. Use Return to Lobby on one client; let the other wait eight seconds. Both should reach local staging. In the server Command Bar run `require(game.ServerScriptService.F4Match).begin()` to start another session; confirm fresh scores, characters, countdown, and no old effects.
4. In separate runs, disconnect before GO, disconnect during active play, and close both clients together. Expect cancellation, remaining-player forfeit, and no winner respectively. Check no disconnect point appears.
5. Let regulation finish tied. Expect SUDDEN DEATH, a fresh three-second countdown, and untimed play with tied scores preserved. Continue with the F5 manual checks.

The product owner signed off the current F4 feature on October 22, 2026, including the developer controls and F4 console toggle used to release the mouse during a match. Automated checks remain technical evidence; owner sign-off records gameplay acceptance for this slice.

## Limits

- F4 is local 1v1 on The Platform. 2v2/team departures, queues/full lobby flow, reserved servers, and ability integration remain in their roadmap slices.
- The original F4 slice stopped at a frozen tie handoff. F5 now resolves it; its evidence and pending owner acceptance are recorded separately.
- No 100–150 ms RTT run, reference-hardware/FPS evaluation, broad viewport coverage, or full standalone Roblox type analysis is claimed.
- The automated return checks exercise the server return operation. Clicking the actual button and evaluating its usability remain in the manual steps.
- No publishing, asset generation/export, new dependency, or unrelated feature work occurred.
