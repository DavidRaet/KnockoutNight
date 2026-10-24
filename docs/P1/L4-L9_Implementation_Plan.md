# L4–L9 implementation plan

David confirmed this design and authorized implementation on October 23, 2026. Delivery checkpoints are L4, L5, combined L6–L8, then L9. Each checkpoint returns to David for hands-on acceptance before the next checkpoint. This authorization does not authorize publishing, asset generation/export, or subjective gameplay acceptance.

**Subsequent instruction, October 23, 2026:** David requested continuing through L6 without stopping for L5 acceptance (his “F6” reference was interpreted as L6 in the local-flow context). This supersedes the intermediate pause through L6 only; it does not sign off L4 or authorize a claim of gameplay acceptance.

**Current status, October 23, 2026:** David subsequently signed off the completed L4–L6 gameplay and deferred L7–L9 to another session. Outstanding technical checks and milestone/release gates remain open. Resume later at David's request; no automatic continuation or publishing is authorized by sign-off.

## Agreed behavior

- One active local 1v1 session. Waiting entrants retain FIFO order and see “Match in progress.” Dispatch resumes only after participant return and cleanup.
- L4: three-second dispatch countdown; final membership check before one assignment. Leaving the pad, reset, or disconnect before assignment cancels/restarts the countdown while preserving remaining order. After assignment, stepping away does not withdraw a participant.
- Separate intermission blockout: movement/jumping enabled, combat disabled. L4 checkpoint offers Return to Lobby while awaiting map voting.
- L5: full ten-second map vote, editable until deadline. Show aggregate counts and highlight own vote without naming voters. Offer The Platform, Sky Bridges, Dungeon. Random among tied leaders; no votes random among all maps. Cleanly replace arena and move players to opposing frozen spawns. L5 checkpoint retains Return to Lobby.
- L6: fresh blank weapon/ability choices, private even in replicated data, with defaults explained. Fifteen-second selection; edits clear Ready. Ready accepts missing-choice defaults. Both Ready or deadline locks choices, independently defaults missing weapon/ability to Spring Fist/Gust, and explains assignments. Reveal equipment at the three-second opening countdown. Remain frozen through selection/countdown. GO enables movement/combat/timer together. Reject invalid, nonparticipant, stale-session, and late requests.
- Before GO, reset/unexpected death/disconnect cancels without an official result. Connected participants return outside the lobby queue, receive an explanation, and do not automatically requeue. After GO retain existing scoring, elimination, sudden-death, and forfeit rules.
- L7: current-session-only HUD; top-center authoritative clock, final-30/final-10 urgency, sudden-death label; top-right score/portraits; top-left feed. Latest successful displacement within five seconds qualifies for attribution; blocked/protected contacts do not. Feed lasts four seconds, maximum three entries. Bottom-right ability icon/Q/numeric cooldown and clockwise-clearing radial overlay. Preserve respawn/spectating and asset fallbacks.
- L8: results show winner, scores and regulation/sudden-death/forfeit outcome. Immediate Return to Lobby and eight-second automatic return. Cancellation explains no result. No direct rematch. Cleanup covers participants, timers, actions, effects, equipment, map geometry, callbacks, score/HUD and allocation before reuse.
- L9: distinguish existing weapons/abilities and preserve essential warnings at low graphics without color alone. Settings button and P work throughout the journey; opening releases cursor and suppresses movement/combat input while match continues. Closing clears held input and restores phase controls. Sensitivity starts at current value, shake defaults off, music/effects start at existing mix levels. Settings persist across matches in the current server visit only. No music track exists; music control remains silent until a separately added track. Use code-built icons/text and existing effects/sounds; final art/new music deferred.

## Implementation reach

Reuse L3Lobby/L3Queue and the existing F1 spawner/controller, F3 lives/HUD, F4 match/rules/results, F2 combat/effects, arena builders and configurations. Add explicit lobby/session ownership and dynamic arena lifecycle; keep the separate developer arena path. Private loadout state must not reuse the existing immediately public picker attributes. Restrict match HUD/requests to current participants. No new dependencies or persistence service are planned.

## Verification and acceptance

Run formatting, lint, compilation, deterministic rules and relevant lifecycle regressions before Studio changes. Compare local runtime sources with Studio before sync and read back changes. Technically exercise dispatch expiry races, FIFO preservation, duplicate/stale requests, private selection/defaults, departures in each phase, synchronized GO, terminal outcomes, all nine loadouts, all three maps, and repeated sessions. Distinguish isolated/synthetic assertions from real multiplayer replication and latency evidence. David evaluates gameplay, readability and controls at each checkpoint. Existing outstanding technical/milestone gates remain open unless separately verified.

## Progress

- L4: implementation and initial technical checks completed; David signed off gameplay October 23, 2026. See [checkpoint record](L4/L4_Implementation_and_Verification.md).
- L5–L6: implemented and technically checked within the limits in the [verification record](L6/L5-L6_Implementation_and_Verification.md); David signed off gameplay October 23, 2026.
- L7–L9: unfinished and explicitly deferred to another session. Existing minimal HUD/results reuse supports the accepted L6 endpoint without claiming these later slices or M2 complete.
