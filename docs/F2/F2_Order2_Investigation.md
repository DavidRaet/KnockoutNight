# F2 Order 2: travel and presentation investigation

**Updated:** October 21, 2026.  
**Status:** Order 2 complete for the current prototype evaluation. Repeated measurements, timing/motor experiments, regression checks, and ordinary/delayed hands-on review are recorded. The product owner accepts current distance consistency, recovery timing, limited steering, and the brief fling-to-recovery pause. Failed experimental/proposed numeric checks remain failed; their disposition is documented below. The subsequent [Order 3 decision](F2_Next_Steps.md#order-3-decision-approved-physics-approach) explicitly approves temporary server ownership during knockback.

**Latest hands-on update:** The product owner accepts both ownership modes, immediate walking after landing, the small sideways influence from holding A/D, perceived distance consistency, and current recovery timing. The delayed comparison at verified 114.85–132.97 ms RTT produced no noticeable worsening. The owner identifies the brief pause as the intended fling/recovery transition. See the [follow-up feel review](F2_Ownership_Feel_Review.md). No physics coefficient was changed; subjective acceptance does not make the proposed numeric checks pass.

The product owner reports Order 1 complete. The initial [Ownership Feel Review](F2_Ownership_Feel_Review.md) reported delayed/teleport-like observer motion and forward launch direction. The follow-up accepts backward launches and current feel under ordinary and verified target-latency conditions. The original [physics evaluation](F2_Physics_Evaluation.md) retains the previous measurements and limitations.

## Reproduced from saved evidence

Replaying both original JSON captures reproduces a pause followed by a catch-up step on server-owned subjects. A 20 Hz trace measures position changes, not rendered frames; it can expose a discontinuity but cannot certify visual smoothness. The observer complaint and the subject handoff discontinuity must be assessed separately.

| Profile | Mode | Idle trials | Server horizontal travel | Recovery after trial start | Subject excess step | Observer excess step |
| --- | --- | --- | --- | --- | --- | --- |
| Ordinary | Client | 2 | 14.43–14.81 studs | 0.285–0.299 s | 0.00–0.05 studs | 0.12–0.59 studs |
| Ordinary | Server | 2 | 6.87–7.87 studs | 0.132–0.134 s | 2.52–4.24 studs | 0.31–0.70 studs |
| Delayed | Client | 2 | 13.90–14.18 studs | 0.267–0.300 s | 0.01–0.08 studs | 0.18–0.48 studs |
| Delayed | Server | 2 | 7.08–8.16 studs | approximately 0.133 s | 1.93–3.95 studs | 0 studs |

Horizontal travel here is the maximum XZ distance from launch origin (the first server sample in old evidence). It differs slightly from the original X-only metric. An excess step is `max(0, horizontal distance between adjacent samples - maximum endpoint horizontal speed * sample interval)`. This is a diagnostic for catch-up, not proof of cheating or a complete continuity test. Acceleration, collision, and a missed speed peak can affect it. The subject's largest raw step was 5.23–7.29 studs in the server idle cases, after repeated stationary samples despite reported 50-stud/s velocity.

The original 20 Hz client clocks begin on receipt and cannot be aligned with server elapsed time. Do not subtract these old clocks to estimate one-way latency. Repetition, synchronized diagnostic timestamps, and landing details are needed before attributing the entire distance difference to a specific cause.

## Hypotheses and distinguishing experiments

1. **Premature recovery:** the ray uses standing Humanoid height while the disabled motor leaves different physical contacts; the server can also see a delayed client-owned position. Record ground distance, ray length, velocity, motor state, and recovery time. Repeat with only the minimum-flight floor changed from 0.12 to 0.30 seconds. If early recovery causes the gap, travel should converge when recovery cannot occur at 0.13 seconds. The 0.30-second setting is an experiment, not proposed final tuning.
2. **Ownership handoff discontinuity:** the short server-owned phase returns ownership while the subject is displaying an older position. Compare subject pauses and excess steps around the synchronized recovery timestamp. A later handoff may relocate the discontinuity without removing it; that would fail this mitigation.
3. **Disable/launch ordering:** replicated attributes and the launch remote arrive at different times. Compare the subject's motor/mode columns at launch and recovery with the server's event times. An enabled subject motor during the launch would distinguish this from a pure handoff problem.
4. **Simulation variation:** if travel remains different after timing/ownership artifacts are isolated, compare repeated trajectories from identical positions and inputs before changing velocity, friction, steering, or recovery coefficients.

`tests/F2PhysicsStudy.server.luau` now records launch origin, synchronized start/recovery times, the recovery ground query, and minimum movement-budget credit. Automated arguments may set `minimumFlight`; omission preserves 0.12 seconds. Client sample rows append `[estimatedServerTime, motorEnabledAs0Or1, modeAs0Or1Or2]` after the existing seven columns; mode values are none/client/server. All ten fields must be finite and the report remains capped at 40 samples. These remain untrusted diagnostics.

The manual L trigger now launches opposite the subject's horizontal facing. This is a self-launch convenience for review. Future combat must compute direction from the attacker/hit geometry; the victim's facing alone does not determine the direction of a hit.

## Repeated-trial procedure

Use the existing two-client installation and cleanup procedure. Keep normal F1/controller code and the launch velocity unchanged while testing the timing hypothesis.

1. Run the helper spec and compile the changed fixtures. These checks passed on October 21 in Studio 0.743.0.7431133; the original nine F1 movement assertions and the Python analyzer self-check also passed.
2. For ordinary conditions, run `{test = "F2Physics", probes = {"idle"}, repeats = 5}`. Both subjects run both ownership modes: 20 trials per capture. For delayed runs add `awaitNetwork = true`; the fixture waits at `F2StudyWaitingNetwork` before trials start.
3. Repeat the same profile/inputs with `minimumFlight = 0.30`, changing only that argument. Save separate captures so original evidence is preserved.
4. Use zero added delay for ordinary conditions. For delayed conditions identify the two spawned **client** Studio processes and set each client's NetworkSettings to 50 ms inbound/outbound and zero jitter/loss; leave the test server at zero. Use the fixture's ping/pong command to verify both clients measure 100–150 ms RTT, then set `workspace:SetAttribute("F2StudyNetworkReady", true)` in the test server. Adjust client delay if needed. The parent Studio setting alone does not configure these processes. Complete setup within the 45-second barrier timeout; added delay is not measured RTT. Restore each client's prior values after final reports, before the test exits.
5. If the timing comparison supports a fix, rerun reverse steering, airborne launch, obstruction, walk-before-jump, replacement/death, and movement-abuse probes with that fix. Repeat the manual backward trigger and inspect subject and observer rendering. Restore all seven inspected network properties and remove temporary scripts/captures.

Analyze saved captures with `python tests/analyze_f2_physics.py --self-test docs/evidence/F2Physics_baseline.json docs/evidence/F2Physics_latency.json`, substituting new evidence paths as available. The workspace's bundled Python can be used when `python` is not on PATH. The analyzer supports both original seven-column and new ten-column client samples.

## October 21 measured experiments

The four primary captures each contain five idle trials per player per mode, or ten per mode. They use the same launch velocity and input, before the later reset stabilization. The longer-floor experiment changes only `minimumFlight` from 0.12 to 0.30 seconds. It is not a retained tuning change. The current fixture includes the subsequent reset and airborne corrections; use the separate stabilized capture to assess that setup.

The [machine-readable summary](evidence/F2Physics_order2_summary.json) covers **216 recorded automated trials**, including failed experimental groups, plus four successful manual-path launches recorded separately. It contains min/median/max metrics and preserves the distinction between recorder success and behavior-check success.

| Profile / minimum flight | Mode | Measured RTT | Server travel, min / median / max (studs) | Subject excess step, min / median / max (studs) | Subject high-speed pause (s) |
| --- | --- | --- | --- | --- | --- |
| [Ordinary / 0.12](evidence/F2Physics_order2_baseline.json) | Client | 12.7–19.6 ms | 8.40 / 12.21 / 15.75 | 0.00 / 0.15 / 0.41 | 0 |
| Ordinary / 0.12 | Server | 11.7–21.5 ms | 6.04 / 6.46 / 7.61 | 1.20 / 2.17 / 4.39 | 0.110–0.113 |
| [Ordinary / 0.30](evidence/F2Physics_order2_baseline_hold.json) | Client | 12.0–20.6 ms | 15.33 / 16.13 / 16.43 | 0.12 / 0.21 / 0.30 | 0 |
| Ordinary / 0.30 | Server | 12.5–21.7 ms | 14.60 / 14.85 / 15.58 | 3.56 / 3.93 / 4.64 | 0.166–0.224 |
| [Delayed / 0.12](evidence/F2Physics_order2_latency.json) | Client | 109.6–144.0 ms | 0.00 / 14.13 / 17.25 | 0.11 / 0.18 / 0.64 | 0 locally |
| Delayed / 0.12 | Server | 110.9–118.3 ms | 6.25 / 6.46 / 7.08 | 2.02 / 2.90 / 3.44 | 0.110–0.112 |
| [Delayed / 0.30](evidence/F2Physics_order2_latency_hold.json) | Client | 110.2–118.5 ms | 17.09 / 17.63 / 18.32 | 0.13 / 0.20 / 0.37 | 0 |
| Delayed / 0.30 | Server | 111.1–123.9 ms | 13.95 / 15.22 / 15.97 | 3.47 / 4.93 / 6.62 | 0.165–0.209 |

The delayed 0.12 client group **failed behavior checks**: Player 2's trials 12 and 14 moved locally but remained at their origin on the server and observer for the entire recorded trial. Those zeros are replication failures, not zero-distance launches or accepted balance observations. The other three captures passed their fixture behavior checks; passing those checks does not mean they meet the presentation/consistency proposals.

Two additional [ordinary controls](evidence/F2Physics_order2_baseline_repeat.json) and [ordinary longer-floor controls](evidence/F2Physics_order2_baseline_hold_repeat.json) were initially intended as delayed runs. They measured only 11.5–21.7 ms RTT and are retained as ordinary evidence, never as delayed evidence. Configuring the parent Studio or test server's NetworkSettings did not delay these separate test clients. Actual delayed captures used 50 ms inbound/outbound **on both test client processes**, with the server at zero, and a verified round-trip probe before releasing the test barrier.

### What the experiments establish

- **Recovery materially changes travel.** Server-mode recovery at the 0.12 floor occurred while descending at roughly 12–13 studs/s, with 2.72–2.83 studs between the root and ground inside the 3.3-stud standing-height ray. Increasing only the floor raised ordinary server median travel by about 8.4 studs and substantially narrowed the ownership gap. This establishes a timing contribution; it does not validate the standing-height ray as actual physical landing with the motor disabled.
- **The recovery clocks are asymmetric.** The server-owned timer starts when the server assigns the launch; the client-owned timer starts when its application acknowledgement returns to the server. At target RTT, a 0.30-second floor therefore released the client candidate around 0.416–0.424 seconds after trial start versus 0.304–0.321 for the server candidate, before the release must travel back to the subject. These are not matched physical control durations. Do not compensate by secretly changing launch velocity or declare ownership modes interchangeable.
- **A longer floor does not fix presentation.** It increased server-owned subject pauses and excess steps. The first pause occurs during the server-owned phase, before release; handoff can add another discontinuity. The evidence does not support attributing the entire pause to handoff alone. Delayed observers also have measurable onset delay and occasional excess steps even when the subject looks smooth.
- **Changing motor suspension did not fix it.** A temporary [`Physics`-state experiment](evidence/F2Physics_order2_physics_motor.json), with the 0.30 floor and 109.8–124.2 ms RTT, retained 0.165–0.222-second server-subject pauses and 3.95–6.39-stud excess steps. It also produced a legitimate client correction and failed behavior checks. It was reverted completely. The [exact three experimental sources](evidence/F2Physics_order2_physics_motor_sources.json) are retained only as evidence; they are not installed or synced. Roblox documents that [Physics requires explicit entry/exit](https://create.roblox.com/docs/reference/engine/enums/HumanoidStateType) and that [server ownership can cause client jitter](https://create.roblox.com/docs/physics/network-ownership); the particular causes and magnitudes above come from this experiment.
- **Reset ordering affected the experiment.** The fixture previously anchored, teleported, unanchored, and reassigned ownership in one frame. It now holds the reset anchored for 0.20 seconds, then allows 0.50 seconds after ownership return before launching. A [20-trial stabilized delayed repeat](evidence/F2Physics_order2_latency_stabilized.json) at 110.5–119.1 ms RTT had no missing-motion failures or corrections, but server-subject pauses remained 0.166–0.222 seconds. This removes the observed failure in that repeat; it does not prove reset ordering was its only possible cause. Delayed client median travel was 17.92 studs versus 15.03 for the server candidate. Subject motion was first sampled at 0.113–0.124 seconds for client ownership versus 0.282–0.344 for server ownership; sampling and estimated-clock uncertainty apply.

### Regression and fixture corrections

The [44-trial stabilized regression](evidence/F2Physics_order2_regression.json), using the original 0.12 floor, passed all existing behavior assertions: zero legitimate corrections, all eight teleport/excess-speed probes corrected, and six invalid requests rejected. Both client-owned resisted-launch probes were flagged, while both server-owned probes preserved the initial launch. Minimum legitimate movement-budget credit was 4.61 studs; these samples do not justify tightening the 0.2-second burst or 3-stud slack.

RTT was 110.4–200.5 ms: 42 trials were within 100–150 ms; the Player 1/client speed and replacement trials measured 159.1 and 200.5 ms. A separate [eight-trial targeted repeat](evidence/F2Physics_order2_targeted_regression.json) reran speed and death/replacement in both roles/modes at 110.2–118.5 ms RTT and passed. The full run is not described as entirely inside target latency.

Inspection also caught a false-positive airborne scenario: all four subject traces started around Y=45 because the character landed during reset settling. The fixture now resets the airborne case higher and explicitly checks the subject's first sample against standing height. The [corrected four-trial airborne capture](evidence/F2Physics_order2_airborne.json) passed both roles/modes at 110.3–118.1 ms RTT, with first subject samples at Y=58.60–60.36, above the Y=45 standing position. The old matrix's airborne launch assertion alone does not establish airborne coverage. Server and client positions still differ during replication; this focused check proves airborne execution, not cross-view consistency or approved balance.

The [four centered manual launches](evidence/F2Physics_order2_manual.json) verified both players and ownership modes through the manual request handler: assigned velocity dotted with facing was exactly **−50 studs/s**, upward velocity was **12 studs/s**, and the motor returned to `Running` with the study mode cleared. K/L-generated requests for both modes were observed separately. An initial watcher sampled before the handler ran and was discarded; the valid velocity check runs after handler execution. This verifies the manual path and direction, not renewed product-owner feel acceptance.

Selene 0.32.0 reports zero errors, warnings, or parse errors on the two changed fixtures. StyLua 2.6.0 check mode passes on those fixtures, with AST verification during formatting. The Python analyzer self-check and Studio compilation/helper/F1 movement checks also passed. Unchanged module/spec formatting is outside this change; no full Roblox-type standalone analysis or reference-hardware performance result is claimed.

Cleanup was read back and verified: both temporary fixture scripts and the Edit-time capture folder were removed, the manual study attribute was cleared, and all seven inspected parent NetworkSettings properties were restored to zero. Delayed test clients had restoration callbacks for their final reports and all test processes exited. The original F1 controller source matches its pre-experiment contents; no failed motor prototype remains installed. Final helper checks and the nine F1 movement assertions passed after cleanup. No place was published and no assets were generated/exported.

### Engineering recommendation

**Close Order 2 and proceed to the Order 3 decision.** Retain current limited steering and the original experimental coefficients. Do not adopt the longer floor or failed motor variant. The owner accepts the current prototype behavior after ordinary and target-latency review, including distance consistency, landing/settling recovery, and the brief pause. This provides the product-owner disposition of the feel concerns; it does not select ownership or approve production validation.

Disposition of the original numeric proposals:

- The blanket prohibition on any ≥0.10-second high-speed stationary interval is **not adopted as a prototype feel gate**. It does not distinguish an intended control/recovery transition from objectionable displayed motion, and the owner accepts the tested transition. Recorded pauses/excess steps remain measurements; their precise engine/rendering cause is not established by the owner's interpretation. No assertion is changed to make them pass.
- The `max(1 stud, 10%)` travel bound remains **unproven**, rather than approved or silently widened. The owner accepts perceived consistency of the tested behavior. The two ownership candidates still produce different distances and must not be interchanged during gameplay; Order 3 must choose one and record this limit.
- Existing launch, steering, recovery, and movement-budget values remain experimental starting values. The passing legitimate/abuse regressions support retaining them for the next decision, not claiming a complete anti-cheat or final balance result.
- Additional presentation work is deferred unless the chosen architecture or actual combat reveals an unacceptable artifact. Retain these captures as regression references, with visual motion and phase boundaries measured separately when investigating any recurrence.

Client ownership retains its demonstrated launch-resistance weakness. Following this recommendation, the product owner explicitly selected temporary server ownership during knockback; the [Order 3 decision](F2_Next_Steps.md#order-3-decision-approved-physics-approach) records transitions, launch application, motor restoration, correction policy, and the limits above. Server Authority support remains unestablished, so no migration/prototype was attempted.

## Proposed review thresholds

These are the original engineering proposals, retained with their measurements. The disposition above closes the prototype review without certifying every proposed bound. They must not become automatic punishment thresholds or be presented as passed production gates.

| Concern | Proposed gate | Basis and limit |
| --- | --- | --- |
| Repeated launch distance | For each ownership/profile/identical-input group, every origin-based travel result within `max(1 stud, 10% of median)` of its group median; profile medians within the same bound | Original client idle spans are below 0.4 studs. Start with headroom for sampling/replication; at least five repetitions per subject/mode/profile are needed. This does not select a desired absolute travel distance. |
| Handoff continuity | Subject and observer excess step at most 1 stud; no moving launch with two consecutive stationary sample intervals (at least 0.10 s) absent a verified obstruction | Old subject server-mode steps fail this gate. Old observer idle steps pass the numeric step gate despite the written complaint, so hands-on review remains required. |
| Steering | Retain 3 studs/s² initially. Opposing input must not reverse an unobstructed launch before recovery; matched reverse/idle trials should differ by no more than 1 stud over a 0.5-second displacement | The acceleration alone changes velocity by at most 1.5 studs/s and position by about 0.375 studs over 0.5 s. Collisions and different recovery timing can dominate; compare matched repetitions. No upward steering force. |
| Recovery | Keep recovery separate from reaction/protection; release on a verified landing or speed ≤18 horizontal and ≤8 vertical after the minimum-flight interval. Propose control return within 0.10 s locally after release reaches the owner | Ground detection and release timing need the experiment above. The fixture's 1.5-second manual timeout is a safety cleanup, never a successful natural-recovery result. No approved minimum-flight change yet. |
| Validation | Zero legitimate corrections and detection of every existing teleport/excess-speed probe in both roles/profiles; retain 0.2-second burst and 3-stud slack during investigation | Original runs meet the probe gate, but cannot justify tightening thresholds. Use recorded minimum credit to assess headroom in repeats. This budget does not prevent resisted launches, vertical flight, or wall traversal. |
| Response and input transit | Report measured launch onset and control return separately for subject and observer; treat 0.10 s of stationary high-speed motion as a failure to investigate | A remote ping is not input-to-display latency. New synchronized times are estimates; 20 Hz sampling introduces uncertainty. Manual steering currently sends at 10 Hz, which alone can add nearly 0.10 s before network transit. |

Both candidates' manual feel is now accepted for the prototype; the original numeric proposals were not all adopted as acceptance gates. Server Authority remains a separate viability investigation; its support has not been established. Order 3 must explicitly decide ownership transitions, launch application, motor restoration, correction policy, known limits, and accepted tuning before combat implementation.

Applying the proposed within-group travel bound separately to each player/mode: three of four ordinary 0.12 groups fail, while all four ordinary 0.30 groups and all four delayed 0.30 groups pass. The stabilized delayed 0.30 repeat still fails for Player 2/server (1.60-stud deviation versus a 1.52-stud bound). Player 2/client's ordinary-to-delayed 0.30 median shift also exceeds 10% of the ordinary median. All server-owned idle groups fail the proposed subject continuity gate. Several delayed observer steps exceed 1 stud as well. These measurements remain failed diagnostic proposals despite the later architecture approval; the decision does not silently widen the bounds or certify them as passed.
