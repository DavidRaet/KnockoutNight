# Asset organization

Save project assets under `assets/`, using paths relative to the project root:

| Asset | Directory |
| --- | --- |
| Blender weapon source files (`.blend`) | `assets/blender/weapons/` |
| Blender arena source files (`.blend`) | `assets/blender/arenas/` |
| Blender prop source files (`.blend`) | `assets/blender/props/` |
| Exported weapons | `assets/exports/weapons/` |
| Exported arenas | `assets/exports/arenas/` |
| UI icons | `assets/ui/icons/` |
| UI HUD assets | `assets/ui/hud/` |

Save future Blender files directly in the appropriate source directory. The hammer source is `assets/blender/weapons/WreckingHammer.blend`.

Only export or regenerate assets when requested. When organizing existing assets, preserve file contents and leave Roblox Script Sync directories untouched (`ReplicatedStorage/`, `ServerScriptService/`, and `StarterPlayerScripts/`).
