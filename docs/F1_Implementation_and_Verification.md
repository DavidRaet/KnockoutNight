# F1 — Move and aim on The Platform

**Status:** Implemented; Studio checks passed; product-owner feel review pending.

**Date:** October 20, 2026.

**Scope:** [Approved engineering roadmap](Knockout_Night_v0.1_Engineering_Roadmap.md), F1; [PRD](Knockout_Night_v0.1_PRD.md), DD01 and section 17.

## Implementation

| File | Owns |
|---|---|
| `ReplicatedStorage/F1Config.luau` | Configurable movement, platform, and prototype camera settings |
| `ReplicatedStorage/F1Movement.luau` | Normalized camera-relative movement and fresh-press jump eligibility |
| `ServerScriptService/F1Prototype.server.luau` | Runtime greybox, symmetric spawn slots, standardized R15 appearance/dimensions, noncolliding characters, ordinary character replacement |
| `StarterPlayerScripts/F1Controller.local.luau` | Desktop input, ordinary air steering, horizontal facing, third-person camera, zoom, obstruction handling, cursor/focus lifecycle |

The greybox is generated at runtime from versioned code: a 70-stud circular platform centered at `(0, 40, 0)`, four studs thick, with starts offset 18 studs either side. The existing baseplate is hidden and noncollidable during play only. Stopping play restores the edit-time scene. No Blender source or exported assets were changed.

Both player appearances and the neutral fallback use the same R15 body dimensions. Compatible clothing, colors, face, and accessories are retained; body packages, scales, and custom animation selections are normalized. Accessories do not add collision or mass. Appearance lookup/load failures fall back to the neutral rig with a warning.

The client explicitly disables the current default PlayerModule's exported controls. F1 owns WASD and Space through action bindings, while retaining the Humanoid character motor. Movement follows camera yaw, with normalized diagonal input. A fresh grounded Space press produces one jump; holding or pressing again in flight does not produce another jump.

Ordinary airborne movement uses native movement input scaled to `0.6`. This is prototype tuning, not a combat knockback controller. Horizontal facing remains independent of camera pitch and movement direction. F2 must evaluate ownership and movement validation and add the approved restrictions during attacks/knockback.

Camera starts 16 studs away at -22 degrees of pitch, with 8–24 stud zoom and -65 to +20 degree pitch bounds. Sensitivity starts at 0.16 degrees per mouse-delta unit, alongside Roblox's user sensitivity behavior. Spherecasting brings the camera in before solid geometry. These values remain subject to prototype review.

For a future game menu, the client observes the local player's `F1ControlsEnabled` attribute: `false` disables gameplay input and releases the cursor; clearing it or setting `true` permits control when window/menu/text focus also allows it. This is a client presentation/input hook, not server authorization.

## Verification evidence

Studio place inspected/tested: **MY PLACE**, place ID **2336816683**. Testing used the live Client/Server contexts and actual two-client sessions launched through StudioTestService. Viewport inspection included a 1096 × 675 client view; this is not broad desktop coverage or performance signoff.

| Check | Result / observation |
|---|---|
| File sync and source syntax | Four implementation scripts synced to their intended locations and compiled in Studio; client controller is a LocalScript |
| Movement/jump self-check | Nine assertions passed: idle, normalized diagonals, yaw-relative direction, horizontal movement, fresh grounded press, held press, airborne press, release, and rearmed press |
| Two-player rig/spawn/collision | Final automated session returned `passed = true`, two players, 16 matching body parts, symmetric starts, and no body blocking; normalized rig scales asserted |
| Strafe and held jump | Both clients strafed with unchanged aim and produced one jump while Space remained held across landing |
| Retreat | Approximately 6.4 studs of backward movement while retaining forward aim |
| Diagonal speed | Measured peak horizontal speed: 16 studs/second |
| Ordinary air steering | Approximately 2.22 studs of airborne adjustment; second airborne Space press did not jump; peak root Y approximately 52.32 from a standing Y of 45 |
| Horizontal facing and mouse yaw | Mouse delta changed camera yaw; character facing remained horizontal under pitch changes |
| Camera limits | Observed zoom endpoints 8 and 24 studs, with camera look-Y matching -65 and +20 degree pitch bounds |
| Camera obstruction | Temporary wall reduced a 24-stud camera offset to approximately 10.75 studs; removing it restored 24 studs; fixture removed |
| Menu lifecycle | Escape opened the Roblox menu and released the cursor; Escape closed it and restored center capture. Gameplay movement was blocked while the menu was open |
| Text input | Focused test TextBox released the cursor and produced zero character movement during typing; release restored capture; fixture removed |
| Character replacement | Both clients received fresh normalized R15 characters at their assigned starts; cameras reattached and held Space still produced one jump afterward |
| Repeat sessions / cleanup | Multiple sessions started and ended; temporary synced verification script removed; retained tests live outside Script Sync folders |

Live tests exposed and corrected a default-control conflict, differing neutral-template scales, and insufficient steering caused by combining manual velocity changes with the Humanoid motor. The results above describe the corrected behavior.

## Repeatable checks

- `tests/F1Movement.spec.luau`: run its contents in Studio's Edit context after the movement module syncs.
- `tests/F1Multiplayer.server.luau`: temporarily sync a copy into ServerScriptService, then launch `game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { test = "F1" })` from the Edit/plugin context. The test returns structured results, ends itself, and has a timeout. Remove the synced copy afterward.
- For hands-on input review, start a two-client Studio test and exercise WASD, tap/held Space, airborne input, mouse yaw/pitch, scroll zoom, menus, text focus, and reset. The platform is constructed when the server starts.

Roblox documents the multiplayer launcher and its separate server/client contexts in [StudioTestService](https://create.roblox.com/docs/reference/engine/classes/StudioTestService).

## Remaining review and limits

- Product owner should review rig appearance, camera distance/zoom/pitch/sensitivity, ordinary air steering, and overall control feel. Values are not final balance.
- Manual OS window focus loss/regain, broad desktop/low-graphics coverage, 60 FPS reference-hardware performance, and 100–150 ms simulated round-trip latency are not signed off.
- No standalone Luau type analyzer/linter was run. Syntax compilation and live engine behavior were checked.
- F1 deliberately has two spawn slots. Larger rosters and safe combat respawning belong to later slices.
- Physics ownership and movement validation remain an explicit pre-F2 decision. F1 client-controlled movement is not an anti-exploit implementation.
- Scored elimination, lower-plane commitment, safe combat respawns, protection, weapons, abilities, HUD, queues, and teleports are not implemented by F1.
- Nothing was published and no asset was exported. The existing starter print script remains unchanged.

**Next step:** Product-owner hands-on review of F1. Announce the proposed work before making tuning changes or beginning F2.
