# F6 — Fight with Wrecking Hammer

**October 22, 2026:** Implemented and technically verified for the local 1v1 prototype on The Platform. **Owner gameplay acceptance is pending.** Nothing was published. F7, abilities, other maps, final animation, and asset export remain outside this slice.

## Implementation

`F2Weapons` supplies the two implemented attack profiles. `F2Combat` snapshots the selected profile into each action, uses it for timing, buffering, movement restrictions, and replacement launch, and keeps the existing authoritative contact resolver, displacement ownership/protection, hit reaction, generation checks, and cleanup. Mixed-weapon startup interruption uses the victim's outgoing action profile; active attacks retain their trade opportunity. Ordinary Hammer has no armor.

| Hammer setting | Prototype value |
| --- | --- |
| Startup / active / recovery | 0.48 / 0.18 / 0.65 seconds |
| Total duration / buffer begins | 1.31 / 1.19 seconds |
| Reach / centerline sweep | 7 studs / 100 degrees |
| Radial blade width / height | 2.4 / 5 studs |
| Replacement launch | 118 horizontal / 16 upward studs/s, along committed aim; tuned toward 20 studs of grounded idle travel |
| Attack movement | 40% of base; jumping disabled throughout |
| Shared reaction / protection | 0.15 / 0.35 seconds |

`F6Hammer.frame` supplies the same rotating radial pose to server contact sampling and the client proxy. The blade covers the shaft through its seven-stud tip, rotates from +50 to -50 degrees during the active window, and follows sampled attacker movement. Eligible R15 body parts must overlap it and expose an unobstructed path from the strike origin. Accessories do not count. Physical body/volume widths provide overlap tolerance beyond the nominal centerline angles; targeting does not reduce a character to a center point. Contacts remain once per target per activation, including opportunities consumed by protection.

The temporary head-and-handle proxy winds outward/upward during startup, sweeps during the active window, and returns to guard through recovery. Shape and motion distinguish the phases in addition to the existing colors. This is procedural weapon motion, not a polished character animation. The invisible combat volume is deliberately taller than the visible head. Walls block covered contacts; the visual proxy itself has no collision and can pass through scenery.

The **server-owned Player attribute `F2Weapon`** selects `WreckingHammer` or `SpringFist`. The default remains Spring Fist. The choice survives fresh characters, regulation respawns, and sudden-death resets. A server-side change invalidates the current action/buffer and input generation through the existing equip cleanup. The owner subsequently authorized a temporary centered pre-match picker: both staged players can select either weapon through `F6WeaponChoice`. The server accepts only these two choices while the player is waiting and the match is in staging, rate-limits selections, and locks changes from countdown onward. The picker confirms the authoritative selection and hides outside staging. The knockout feed records the weapon at the successful hit rather than always naming Spring Fist.

The Blender source was inspected read-only: a substantial transverse head, short handle, charcoal caps, deep-teal head, and orange handle. No Blender source or exported asset was changed. The separate image mentioned in the task was not exposed as an attachment to this execution; the simple proxy uses the available Blender reference and is not a final visual reproduction.

## Design conflicts resolved

- PRD 7.2 says Hammer has greater reach than Spring Fist. The approved F6 request explicitly specifies seven studs, while the current accepted Fist runtime has ten-stud center reach. Those values are preserved; Hammer's distinction here is its wider coverage, heavier launch, and greater commitment.
- Some PRD tables still list an older eleven-stud provisional Fist reach. F6 does not retune Fist. Its existing box extends one stud beyond its ten-stud center reach; target limbs can partially overlap that boundary.
- The roadmap's earlier statement that F6 was unauthorized is superseded by this implementation request. F7 and later slices remain separate.

## Technical verification

Run from the project root:

```powershell
./tests/run_f6_checks.ps1
```

| Check | Result |
| --- | --- |
| StyLua, Selene, standalone Luau compilation | Passed; zero lint errors/warnings |
| F2 / F3 / F4 / F5 deterministic regressions | 28 / 17 / 143 / 254 passed |
| Hammer deterministic checks | 29 passed |
| Hammer engine geometry checks | 27 passed |
| Fist engine geometry regression | 20 passed |
| Hammer two-client Platform flow | 41 assertions passed |
| Follow-up centered picker and Hammer flow | 48 assertions passed; both clients see the centered picker, real client selection is confirmed, invalid choices/countdown changes are rejected, and the picker hides during combat |
| Fist two-client combat regression | 28 assertions passed |
| F5 repeated sudden death with both players choosing Hammer | 104 assertions passed |
| Final source comparison / cleanup | All 22 runtime sources match; fixtures removed; production 3/180/8 timing restored; Studio in Edit |

[Raw engine evidence](../evidence/F6Hammer.json) includes launch samples, both clients' phase observations and feed events, repeated-round snapshots, and earlier failed attempts.

[Picker follow-up evidence](../evidence/F6WeaponPicker.json) records the separately authorized UI addition. Local formatting, lint, compilation, and all 471 deterministic checks passed again. Its two-client run reported zero project/server errors and the known Roblox ChatScript initialization error on Player1. The initial 41-assertion Hammer run below was clean; the follow-up retains the separate engine-error report.

**Owner-requested horizontal knockback tuning, October 22:** The owner requested 20 studs of horizontal travel. Increased Hammer's horizontal launch speed from 75 to 118 studs/s; upward launch remains 16 and shared physics/recovery rules remain unchanged. A dedicated two-client, grounded, no-input measurement fixture recorded approximately 9.7–10.7 studs at the original setting. The final three trials at 118 measured **18.85, 20.19, and 19.18 studs** without server script errors. Twenty studs is an approximate tuning target, not a guaranteed distance: an earlier repeated hit at this same setting measured 14.73 studs. Collision, steering, airborne height, and physics/ownership timing can alter travel. [Calibration evidence](../evidence/F6Hammer20Studs.json) retains every attempt. All 471 deterministic checks, formatting, lint, and compilation passed with the updated setting; the combat fixture's expected launch is updated to 118/16. Earlier combat evidence below remains a historical record of the initial 75/16 setting. `tests/F6Knockback.server.luau` reproduces travel sampling using `{test="F6Knockback"}`; optional `expected`/`tolerance` arguments assert a chosen distance band. The fixture was removed after verification, and all 22 runtime sources match Studio. For manual evaluation, hit an idle opponent near the Platform center, then compare moving and airborne opponents. Owner feel acceptance remains pending.

Pure checks cover timing boundaries, slow-update active windows, the full sweep, movement/launch settings, the single late buffer, mixed startup interruption, active trades, protection, spawn shields, and hit-once behavior. Engine geometry checks cover both sides of the sweep, out-of-arc and out-of-reach misses, vertical overlap, early versus middle swing contact, obstruction/exposure, attacker movement, and consumed targets.

The multiplayer fixture verifies the actual client attack remote, pre-physics replacement launch at 75/16 under server ownership, recovery/ownership handoff, startup interruption, a windup dodge followed by a recovery punish, buffering, stale-generation rejection, elimination cleanup, weapon preservation, and Hammer feed attribution on both clients. The dodge scenario uses server-controlled repositioning to establish timing and targeting; it does not establish human dodge responsiveness or acceptable combat feel. Both clients rendered all three phases; the final Hammer run recorded no server, project-client, or Roblox ChatScript errors.

The F5 fixture's optional `weapon="WreckingHammer"` argument verifies the selected weapon on all six fresh sudden-death characters across three rounds, alongside existing identity, motion, protection, countdown, feed, and result checks. It uses temporary 3/2/8 match timing; production files retain 3/180/8. The Fist regression runs with production timing.

The old Fist geometry test incorrectly expected a one-stud test limb centered just beyond the volume's far edge to miss. The unchanged pre-F6 contact module reproduced the failure. The test now distinguishes centers at 11.49 and 11.51 studs, accounting for the limb's half-width; no Fist geometry or tuning changed.

Earlier multiplayer attempts encountered plugin-icon noise and an intermittent Roblox-generated `PlayerScripts.ChatScript` CoreGuiChatConnections initialization error already seen during F5 work. F5/F6 fixtures omit plugin-icon noise and record ChatScript errors separately in `engineErrors`; all other script errors still fail their checks. The final F5 Hammer run passed its project checks but recorded that ChatScript error on Player1. This is an outstanding Studio environment issue, not a claim of a completely clean engine session.

No target-latency Hammer run, full Roblox type analysis, reference-hardware performance signoff, final asset integration, or subjective gameplay acceptance is claimed. Geometry uses current server target poses without rewind and quarter-stud spatial sampling, retaining the existing exposure-sampling limitation for tiny slivers.

To reproduce engine checks, compare/sync runtime sources after the local checks, temporarily insert each matching server/client fixture pair into ServerScriptService and StarterPlayerScripts, then run `StudioTestService:ExecuteMultiplayerTestAsync(2, {test="F6Combat"})` or `{test="F2Combat"}` from Edit. For the F5 pair, use the temporary timing above and `{test="F5Match", weapon="WreckingHammer"}`. Geometry specs are callable ModuleScripts. Remove fixtures, restore timing, and compare all runtime sources afterward.

## Owner Studio playtest

1. Start **Server & Clients with 2 clients**. Use the centered **Choose your weapon** picker in each client. Select Wrecking Hammer in one and Spring Fist in the other; confirm the selected labels update.

2. Use the existing **Developer Console → Start Match**, then close the console. If needed, the server Command Bar can call `require(game.ServerScriptService.F4Match).begin()` once both players are staged. The selected weapons survive the opening character reset.
3. Click once with Hammer. Judge whether the windup is readable, aim stays committed, movement feels appropriately restricted, and the broad swing matches its contact timing. Holding click should not repeat. Test near the center before approaching edges.
4. As the defender, leave the front during windup, then approach and punish the missed swing during recovery. Land a Fist hit during Hammer startup and confirm it cancels the swing. Judge the responsiveness yourself.
5. Check both flanks, excessive height separation, walls, and edge launches. Optionally enable `workspace:SetAttribute("F2DebugVolumes", true)` in the server Command Bar to see active volumes; disable it afterward.
6. Before another match, select Wrecking Hammer on both clients for Hammer-versus-Hammer trades. Check the feed, respawns, and an **End Regulation Now** tied reset: weapons should persist, old effects should disappear, and neither player may attack before GO. Confirm the picker hides at countdown and returns when the players are back in staging.

Report feel, readability, dodge/punish opportunities, and any failure you encounter. Implementation and technical verification are complete for this slice; gameplay acceptance awaits David's explicit sign-off. This does not authorize publishing or F7.
