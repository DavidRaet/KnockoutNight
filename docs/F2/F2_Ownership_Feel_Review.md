# F2 Ownership Feel Review

## Follow-up manual review — October 21, 2026

The product owner reports that backward launches now look smooth for both players in **both ownership modes**, including the comparison requested after the initial review below. Walking resumes immediately after landing without needing a jump first.

Holding A or D produces a small sideways influence during displacement. The product owner accepts this as consistent with the intended limited mobility during knockback; greater directional control is not requested. Preserve the current steering behavior for the next review rather than increasing it.

The product owner then repeated the comparison on both sides with the delayed profile active and reported **no noticeably worse behavior**, accepting the current feel. The profile was verified at **114.85–132.97 ms RTT** across five ping/pong probes per client, with 40 ms added inbound and outbound delay on each client and zero configured jitter/loss. See the [network setup evidence](evidence/F2Physics_manual_latency_setup.json).

The product owner additionally confirms that launch distance feels consistent and recovery timing is correct: normal control resumes when the character lands or settles. The brief transition from fling to recovery is intentional and acceptable, rather than an outstanding feel defect. This accepts the current behavior; it does not request a new one-second pause or a timer change.

The ordinary and delayed hands-on feel review is complete for backward launch, visible smoothness, perceived distance consistency, recovery, immediate walking, and limited steering. **Order 2 is closed for the current prototype evaluation.** This does not establish wall/edge coverage or certify the proposed numeric tolerances. The automated measurements and failed experimental checks remain recorded in [Order 2 investigation](F2_Order2_Investigation.md); they have not been converted to passing results.

After comparing the ownership options, the product owner explicitly approved **client ownership for ordinary movement, server ownership during knockback, then return to the client after recovery**. The [Order 3 decision](F2_Next_Steps.md#order-3-decision-approved-physics-approach) records this selection and its known limits.

## Initial review (retained for comparison)

Conditions: ordinary 
Player acting as subject: Player 2 
Player acting as observer: Player 1 

| Check | Client-owned | Temporarily server-owned |
|---|---|---|
| Launch readability to subject | flinging is smooth | flinging is smooth |
| Launch readability to observer | Flinging is not smooth; it looks like as if they're teleporting | Flinging is not smooth from Player 2's perspective; Player 1's flinging movement lags for a moment and then flings a little after |

## Acceptable behavior
- Player should be flung backwward when getting hit (i.e, when i press L, the player should be flung backward) 

## Unacceptable behavior
- Player 1's lag 
- Player's being flung forward (i'm not sure if this is our desired behavior since player's that are flinging each other, should be flung backwward)

## Repro steps for any issue
- Mode / condition: Walk around with Player 1 and try L to experience the lag 
- What I did: Played as Player 1 and press L
- What I expected: Player 1/2 should be flung backward when pressing L (unless if i misunderstood anything, we're testing how far the player gets flung backward)
- What happened: both player's flung forward instead of backward; Player 1's flinging movement lags and Player 2 views Player 1's lag as if they're teleporting
