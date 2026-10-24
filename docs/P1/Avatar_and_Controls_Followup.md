# Avatar appearance and laptop camera controls

Implemented October 23, 2026 following David's beta feedback. Owner gameplay acceptance is pending. This is the requested follow-up to the accepted L4–L6 flow; the remaining L7–L9 work stays deferred. No publishing is authorized.

## Changes

- Normal lobby players now load their own compatible Roblox appearance. The existing appearance loader previously ran only after the developer-arena admission check, so normal lobby spawns always cloned the blank test character. The shared spawner now fetches/caches appearance for both paths and reuses it through lobby resets, arena entry and combat respawns.
- Preserve clothing, body colors, face and compatible accessories while retaining the approved standardized R15 body proportions, collision group and animation restrictions. This does not enable arbitrary body packages or player-sized combat hitboxes. Failed lookups/model creation retain a usable fallback; departure during lookup cannot create a late avatar. Lobby spawning also rechecks ownership after the now-yielding appearance load.
- Custom shift lock defaults on during lobby, intermission and active combat, allowing camera rotation without holding right-click. Left/Right Shift and the on-screen button toggle it. Off releases the cursor; optional right-drag still works. The preference lasts across respawns/matches for the current server visit.
- Menus, selection, countdown, results, focus loss and developer console release the cursor. Explicit selection/menu state blocks capture even if an earlier active-combat snapshot is still visible. Closing a menu restores the chosen preference. Built-in mouse lock remains disabled to avoid two camera owners; the custom camera/controller owns the toggle.

## Verification

- `tests/run_player_controls_checks.ps1 -AppearanceOnly` first reproduced the exact normal-lobby failure: “normal lobby must use the player's appearance, not the blank test template.” The fixture drives the current bootstrap/shared spawner with controlled platform services. After the fix, seven appearance assertions pass, including standardized dimensions/retained clothing, cache reuse, lobby-to-arena reuse, fallback and departure.
- `tests/run_player_controls_checks.ps1`: formatting, Selene and Luau compilation pass; seven appearance, nine mouse-lock and 886 existing deterministic assertions pass (**902 total**).
- Real Studio player: twelve appearance checks pass for clothing, face/body colors, accessory asset IDs and standardized R15 dimensions. All four expected accessories appear in the character. A real lobby death/respawn retains clothing. Roblox normalized one hair accessory from layered description metadata to rigid accessory metadata; verification compares accessory IDs rather than that storage classification.
- Real input: Shift turns capture off; clicking the on-screen button turns it on. Escape releases capture for the Roblox menu and restores the preference once the menu-close animation finishes. Opt-out survives a real lobby respawn.
- Controlled client combat snapshots verify opt-out persists when entering combat and Shift reenables it. A seven-assertion live-controller phase fixture covers lobby, intermission, combat, selection/menu with stale combat state, countdown and results; all pass after fixing the phase gate. These snapshots do not establish a two-client match.
- Existing isolated lobby lifecycle fixture: 23 assertions pass after adding the post-load ownership check. Console shows the existing `rbxassetid://203785492` type warnings and the expected deliberate fixture spawn-failure warning; no unexpected runtime error observed.
- Compared all 37 runtime sources with Studio; the five changed runtime sources were synced and read back. Temporary fixture modules removed and play stopped after verification. Screenshot inspection confirms the avatar and shift-lock button render at the current desktop viewport.

## Owner check and limits

Join with a personal account and confirm clothing/accessories in lobby and arena, then reset. On a laptop, move the touchpad without holding right-click; press Shift to release and recapture the cursor. Confirm loadout screens and Escape menus remain clickable and the chosen mode survives a match/reset. Evaluate camera feel in a two-player match before acceptance.

Physical laptop/touchpad behavior, different avatar inventories/body packages, real two-client combat/match transitions, target latency, smaller viewports, low graphics and reference-hardware performance remain unverified. Standardized bodies and unsupported/inaccessible asset fallbacks still apply. Full L7 HUD, L8 lifecycle acceptance and L9 sensitivity/shake/audio settings remain separate.

## Left/right arrow camera follow-up — October 23, 2026

David requested camera rotation with Left/Right after investigation reproduced zero movement/camera response from the unbound arrows, while W moved normally. The custom controller disables the default Roblox movement controller and uses a Scriptable camera; only WASD had been registered. The diagnosis identified missing custom camera bindings rather than UI interception or a touchpad hardware failure.

Implemented horizontal keyboard camera rotation: hold Left to look left, Right to look right, release to stop, both to cancel. Starting rate is 120 degrees/second in `F1Config.CameraKeyboardTurnSpeed`; rotation uses render delta time. Works with shift lock on or off. WASD remains movement/Bounce direction; arrows do not add translation. Existing phase, focus and menu gates clear held keys, and existing attack-facing commitment remains in effect. Lobby hint now advertises the arrows. Owner acceptance is pending.

Five new deterministic assertions cover direction, yaw wrapping, release/opposing arrows and frame-rate independence. `tests/run_player_controls_checks.ps1` passes formatting, Selene, compilation and **907 total deterministic assertions** (seven appearance, fourteen mouse-lock/keyboard-camera, 886 existing regressions). In a real single Studio client, arrow bindings are registered; Left and Right rotate correctly, no character translation occurs, release stops rotation, both arrows cancel, opt-out still permits keyboard rotation, and menu open/close clears held arrows without resuming a stuck turn. A controlled committed-action attribute fixture verifies the camera can turn while character/attack facing stays fixed; this is not a multiplayer combat playtest. Console contains only the existing asset-type warnings. Temporary diagnostic attributes were cleared and all 37 runtime sources match Studio; Studio is left in Edit mode.

Owner check: on a laptop, hold Left/Right in the lobby and combat with shift lock both on and off; combine with WASD; open/close Escape while holding an arrow; assess the 120-degree/second turning speed and attack readability. Physical laptop feel, actual multiplayer attack/aim behavior and remaining milestone gates stay unverified. No publishing or remaining L7–L9 work is included.
