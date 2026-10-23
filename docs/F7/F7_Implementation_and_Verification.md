# F7 — Apply Paddle Pops pressure

**Implemented and technically verified:** October 22, 2026. **Owner gameplay acceptance:** signed off by David on October 22, 2026.

## Approved design and implementation

The owner approved interview Q1–Q7 and the complete design summary, then explicitly authorized F7 implementation. This authorizes the local 1v1 Platform slice, including the existing centered weapon picker. It supersedes the roadmap's earlier instruction to wait before proceeding into F7; it does not record F6 gameplay sign-off, authorize abilities or polishing, or authorize publishing.

Paddle Pops uses the existing server-authoritative combat lifecycle and shared launch, protection, interruption, cleanup, and input validation. It adds no combo chain or faster base locomotion.

| Setting | Implemented prototype value |
| --- | --- |
| Startup / active / recovery | 0.10 / 0.08 / 0.16 seconds |
| Total action / late buffer begins | 0.34 / 0.22 seconds; one buffered attack |
| Attack movement | 85% of normal; jumping disabled until recovery ends |
| Horizontal / upward launch | 30 / 8 studs per second; velocity replacement, not a guaranteed travel distance |
| Hit volume | 3 studs wide × 4 tall × 4 deep; centered at root height, extending 0.5–4.5 studs forward |
| Hand offset | 0.5 studs toward the attacking hand; left/right geometry is mirrored |
| Shared reaction / displacement protection | 0.15 / 0.35 seconds |

The server starts with the right hand and advances once per accepted activation. Misses, protected contacts, and interrupted startups consume the hand. Rejected requests and queued inputs do not advance it; a buffered attack advances when it actually starts. Pausing preserves alternation. Fresh matches, respawns, sudden-death resets, and weapon changes reset to right through existing character/equip cleanup. `F7NextHand` exposes the server's next hand; accepted attack messages carry the actual hand. Client prediction never controls hit geometry or alternation.

Each active slap checks a compact mirrored volume, sampled along attacker movement. An overlapping opponent body part can count even when its center is outside the volume. Shared exposure checks enforce solid obstruction and vertical overlap. An activation consumes each contacted target once, including protected contacts. Ordinary airborne attacks use the same geometry and add no self-lift.

Protected Paddle contacts emit a brief cyan sphere cue at contact, without normal hit impact, launch, reaction, interruption, or protection extension. Two simple foam paddle/handle proxies show pullback, active slap, and return. The debug volume remains opt-in through `workspace.F2DebugVolumes`. The existing centered staging picker now offers all three implemented weapons and retains server validation, rate limiting, and countdown locking. Successful Paddle knockouts use the Paddle Pops feed label.

**Owner tuning follow-up, October 22, 2026:** Increased forward reach from 3.5 to **4.5 studs** and horizontal launch from 25 to **30 studs/s**; upward launch remains **8 studs/s**. The near edge stays at 0.5 studs: the box is now 3 wide × 4 tall × 4 deep, centered 2.5 studs forward. Paddle proxy extension follows the longer reach. The current table above reflects this revision. All 500 deterministic checks, formatting, lint, compilation, 79 geometry checks, and 55 Paddle integration assertions passed again, including exact 30/8 replacement launch and a defender response during protection. [Tuning evidence](../evidence/F7Tuning.json). Earlier evidence below retains the original 25/8 run. All 23 runtime sources match Studio and temporary fixtures are removed. David accepted the current prototype tuning on October 22, 2026.

## Verification

Run `./tests/run_f7_checks.ps1` from the project root. It runs the existing F2–F6 checks and checks the F7 files with StyLua, Selene, standalone Luau compilation, and deterministic tests.

| Check | Result |
| --- | --- |
| Formatting, lint, compilation for affected runtime and fixtures | Passed; zero lint errors/warnings |
| F2 / F3 / F4 / F5 / F6 deterministic regressions | 28 / 17 / 143 / 254 / 29 passed |
| Paddle deterministic rules | 29 passed; 500 total including regressions |
| Paddle / Hammer / Fist geometry | 32 / 27 / 20 passed |
| Paddle two-client Platform integration | 55 assertions passed |
| Hammer / Fist two-client regressions | 48 / 28 assertions passed |
| Repeated sudden death with Paddles on both players | 110 assertions passed; right-hand reset checked on all six fresh round characters |
| Final comparison and cleanup | All 23 runtime scripts match Studio; fixtures removed; 3/180/8 timing restored; Studio in Edit |

[Paddle evidence](../evidence/F7PaddlePops.json), [Hammer regression](../evidence/F7HammerRegression.json), [Fist regression](../evidence/F7FistRegression.json), and [sudden-death evidence](../evidence/F7SuddenDeath.json) retain the results.

Checks cover hand sequencing, rejected requests, late buffering, weapon changes, stale generations, mirrored hit boundaries, obstruction, height, attacker movement, exact server-owned 25/8 replacement launch, mixed-weapon startup interruption, shield contact rendering on both clients, feed attribution, elimination cleanup, and respawn preservation/reset. The defender successfully started a response after low-launch recovery while displacement protection was still active. Pure checks also exercise active trades, once-per-victim consumption, protection-expiry boundaries, protected-contact non-extension, and multiple eligible targets.

To reproduce engine verification after local checks and source comparison, temporarily install `F7Contact.spec.luau`, `F6Contact.spec.luau`, and `F2Contact.spec.luau` as the matching `F7ContactSpec`, `F6ContactSpec`, and `F2ContactSpec` ModuleScripts under ServerScriptService. Install the F7Combat server/client fixture pair under ServerScriptService and StarterPlayerScripts, then run `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="F7Combat"})` from Edit. For the existing F5 fixture, use the checked temporary 3/2/8 match configuration and `{test="F5Match", weapon="PaddlePops"}`. Remove fixtures, restore production timing, and compare runtime sources afterward.

## Owner acceptance and remaining verification

**October 22, 2026:** David confirmed that Paddle Pops looks good for now and explicitly signed off F7. Acceptance covers the current local 1v1 Platform prototype at 4.5-stud forward reach and 30/8 studs-per-second launch. Final art, later balance work, and the remaining technical and milestone gates are separate from this sign-off.

### Remaining limits

Both F7 clients and the Hammer/sudden-death regressions reported the previously known Roblox-generated `PlayerScripts.ChatScript` CoreGuiChatConnections initialization error. Project client/server error checks passed; this is not a claim of an entirely clean engine session. No F7 target-latency run, full Roblox type analysis, reference-hardware performance sign-off, or final art is claimed. The Fist regression measured ordinary RTT around 32 ms, not the 100–150 ms target. Contact uses current server poses and the inherited quarter-stud exposure sampling; there is no target rewind. Numerical tuning remains provisional.

### Future manual regression checklist

1. Start **Server & Clients with 2 clients**. Choose **Paddle Pops** in the centered picker and Fist or Hammer on the other client. Start the match using the existing Developer Console.
2. Click individual attacks at close range. Check right/left alternation, short reach, low launch, and recovery. Holding click should not repeat; one late click should queue one next slap. Compare movement while attacking versus moving normally.
3. Against Paddles, try retreating, spacing with Fist, and retaliating after a hit. Judge whether repeated clicks leave practical response opportunities and whether protection cues explain blocked slaps. Try Paddles versus Paddles too.
4. Check airborne slaps, walls, respawn hand reset, and a tied sudden-death reset. Recheck feel, readability, and pressure balance after future combat changes.

F7 is accepted for the current prototype. F8 design/implementation, polishing, asset export, publishing, and beta release remain separate work requiring their own authorization. Target-latency verification and the other limits above remain outstanding.
