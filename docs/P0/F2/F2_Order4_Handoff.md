# F2 Order 4: conversation handoff

Saved October 21, 2026, at the product owner's request before chat compaction.

## Resume here

Orders 1–3 are complete for the prototype decision. **Order 4 has only been introduced and unpacked; its implementation outline is not finalized.** The user wants to discuss the remaining design choices in manageable pieces before implementation. Resume with **Spring Fist hit-volume width, height, and placement**, explaining gameplay tradeoffs in plain language. Five-stud forward reach is already approved; exact dimensions are not.

The last explanation grouped Order 4 into:

1. What counts as a hit: volume/placement, walls, and vertical overlap.
2. How the punch feels online: authoritative timing, client presentation, and latency treatment.
3. Actions colliding: startup interruption, active trades, hit reaction, and protection ordering.
4. Reliable input/lifecycle: action/request contracts, the one late buffer, and cleanup.

Do not treat that explanation as approval of a particular hitbox, lag compensation, request schema, or event ordering. No attacks or hit detector have been implemented. The user requested context preservation, not advancement into implementation.

## Approved direction

The user explicitly selected **option 2**: client-owned walking/jumping, server-owned physics throughout knockback, then client ownership after recovery. The reason is to prevent a modified client from refusing the launch that should push it off the platform. Client-owned knockback failed the initial resistance probes; temporary server ownership preserved those initial launches. This is classic network ownership, not Roblox's separate Server Authority system. Server Authority support remains unverified and no migration is approved.

The full recorded decision, including launch application, transitions, motor restoration, validation/correction policy, cleanup, and limits, is in [F2 Next Steps, Order 3](F2_Next_Steps.md#order-3-decision-approved-physics-approach). Use that section as the authoritative architecture decision.

Retain these approved Spring Fist rules:

- Startup/active/recovery: **0.08 / 0.10 / 0.32 seconds**. Total uninterrupted cycle: 0.50 seconds.
- **5-stud forward reach** and replacement launch of **50 horizontal / 12 upward studs/s**. Exact hitbox width/height/placement remains open.
- Commit horizontal facing; permit 70% base movement; disable jumping during the action. Ordinary airborne attacks add no lift/hover.
- One click requests one attack; holding does not repeat. At most one next attack may buffer in the final **0.12 seconds of recovery**.
- Suitable vertical overlap and unobstructed hit path. An activation can hit multiple eligible enemies, once each.
- Weapon hits interrupt startup; already-active attacks retain their hit opportunity so trades remain possible.
- Separate **0.15-second hit reaction**, **0.35-second post-hit displacement protection**, and physics/control recovery. Blocked contacts do not extend protection.
- Temporary readable combat presentation is planned. Asset generation/export requires its own request. Respawn protection/scoring remains F3.

Shared study values remain prototype starting values: steering acceleration 3 studs/s², minimum flight 0.12 s, landing or horizontal speed ≤18 with absolute vertical speed ≤8 for recovery, 0.2 s replication burst, and 3 studs position slack. The user accepted current feel; this does not certify numeric fairness/security bounds.

## Product-owner acceptance and measurement limits

The owner manually tested both players and both ownership modes under ordinary conditions and a delayed profile verified at **114.85–132.97 ms RTT**. They accepted:

- backward fling direction and visible smoothness;
- immediate walking after landing without jumping to restart it;
- small sideways influence while holding A/D as appropriate limited mobility;
- perceived distance consistency and current landing/settling recovery timing;
- the brief fling-to-recovery pause as intentional behavior, with no noticeable worsening under the delayed profile.

Do not reopen those subjective questions without new evidence. “Pause for a second” was descriptive speech, not a request for a new one-second timer. The manual self-launch goes opposite the victim's facing; future combat direction must derive from authoritative hit geometry.

Keep objective evidence intact:

- 216 recorded automated trials include failed experimental groups, plus four successful manual-path launch checks. Recorder success and behavior success are separate flags.
- A longer 0.30-second flight floor reduced the travel gap but increased server-owned subject pauses; it was not adopted.
- A Physics-state motor-suspension alternative retained pauses and caused a legitimate correction; it was reverted. Exact experimental sources are evidence only.
- Reset stabilization lets an anchored reset replicate before ownership changes. A separate corrected airborne probe asserts actual airborne execution; older “airborne” trials had landed before launch.
- The 44-trial regression passed its behavior checks: no legitimate corrections, all eight teleport/excess-speed probes detected, six invalid requests rejected. Two RTT outliers were followed by an eight-trial speed/replacement repeat at 110–118 ms RTT; corrected airborne cases also passed at 110–118 ms.
- The latest default-setting idle sample had about **14.7 studs client-owned versus 6.9 studs server-owned travel**, with only two idle trials per mode. These are observations, not targets; choose one knockback mode consistently.
- Original proposed 1-stud/10% variation and no-0.10-second-pause gates were not all met. Their explicit disposition accepts current prototype feel, preserves failed diagnostics, and leaves the numeric variation bound unproven. The user's interpretation is not proof of the precise rendering/engine cause.
- Validation corrects/logs invalid movement without automatic kicks/bans. Client ownership after recovery remains untrusted. Vertical flight prevention, wall traversal prevention, higher player counts/server load, reference-hardware FPS, and actual combat latency are not established by the fixtures.

## Files to consult

| Context | Source |
| --- | --- |
| Current orders, approved physics decision, next action | [F2_Next_Steps.md](F2_Next_Steps.md) |
| Approved mechanics/design authority | [PRD](Knockout_Night_v0.1_PRD.md), DD01/DD02 and section 17 |
| Slice boundaries | [Engineering roadmap](Knockout_Night_v0.1_Engineering_Roadmap.md) |
| Repeated experiments, rejected mitigations, numeric disposition | [F2_Order2_Investigation.md](F2_Order2_Investigation.md) |
| Initial concerns and subsequent owner acceptance | [F2_Ownership_Feel_Review.md](F2_Ownership_Feel_Review.md) |
| Original evaluation/setup and evidence limits | [F2_Physics_Evaluation.md](F2_Physics_Evaluation.md) |
| Recorded measurements | `docs/evidence/F2Physics_order2_*.json`; aggregate `F2Physics_order2_summary.json`; accepted manual profile `F2Physics_manual_latency_setup.json` |
| Existing implementation seams | `StarterPlayerScripts/F1Controller.local.luau`, `ServerScriptService/F1Prototype.server.luau`, `ReplicatedStorage/F1Config.luau`, `ReplicatedStorage/F1Movement.luau`, `ReplicatedStorage/F2PhysicsStudy.luau` |
| Reusable fixtures/checks | `tests/F2PhysicsStudy.server.luau`, `tests/F2PhysicsStudy.client.luau`, `tests/F2PhysicsStudy.spec.luau`, `tests/analyze_f2_physics.py`, existing F1 tests |

## Workspace and Studio state

- Workspace: `C:\Users\david\KnockoutNight`, PowerShell. Read current `AGENTS.md` before further work. Respect its pre-Studio checks and descriptive Luau assert messages.
- The repository was already dirty; many F2 files are untracked, and F1 controller/docs/roadmap changes predate this handoff. The user changed `AGENTS.md` during the session. Preserve all existing work; no commit or reset was requested.
- The owner authorized using **MY PLACE, place ID 2336816683**, for temporary fixtures and two-client testing. Do not request that same permission again. Re-discover current Studio IDs rather than reuse transient client IDs.
- The latest parent Studio ID was `77254e11-527d-4208-a48e-2fce8b49fc24`. The parent was in Edit mode; temporary F2 fixture scripts were removed and the manual workspace gate cleared. Client delay was restored from 40/40 ms to 0/0 and read back; all seven parent network settings were verified zero.
- The tool's stop command reported success but the separate manual session still appeared live. The user was instructed to click **End Session**; this was not subsequently verified. Inspect before starting another session or claiming every window is closed.
- Standalone Selene 0.32.0 and StyLua 2.6.0 were downloaded with approval to `%TEMP%\KnockoutNight-F2Checks`. Both changed fixtures passed lint (zero warnings) and format checks, with AST verification during formatting. Studio compilation, helper checks, and nine F1 movement assertions passed. No full Roblox-type standalone analysis is claimed.
- Bundled Python is `C:\Users\david\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`; `python` is not on PATH. No new runtime dependencies were added.

## Collaboration on resuming

Use the Roblox collaboration skill first, then relevant architecture/physics/networking/security/gameplay skills. Use Context7 for current API/library documentation as required by project instructions. Explain gameplay-affecting choices and their tradeoffs to the owner before treating them as approved. Resolve routine implementation details within the accepted scope. The owner prefers progress without repeated permission prompts.

Ponytail full remains active: the smallest complete solution, focused changes, and proportionate verification. Do not spawn agents unless the user or an applicable instruction explicitly requests delegation. Continue with the Order 4 discussion rather than immediately writing combat code.
