# Roblox project tool setup

Use this checklist when starting a Roblox game so Luau checks work before syncing scripts to Studio.

## Tools

- Install StyLua with its **Luau** feature enabled, Selene, and the Luau CLI/compiler.
- Keep project-local executables under `.tools/RobloxChecks/`:
  - `stylua/stylua.exe`
  - `selene/selene.exe`
  - `luau/luau.exe` and `luau/luau-compile.exe`
- Verify StyLua supports Luau with `stylua --check <Luau files>`.

## Selene

Add this to `selene.toml`:

```toml
std = "roblox"
```

Selene needs the Roblox API dump on its first run. Run `selene <Luau files>` while online; it will cache the Roblox standard library. For an offline or pinned setup, set `roblox-std-source = "pinned"`, run `selene generate-roblox-std` once, and keep the generated `roblox.yml` with the project.

## Before Studio sync

Run formatting, Selene lint, Luau compilation, and the project's tests. Keep these checks in a project script or CI job so they are easy to repeat before syncing.
