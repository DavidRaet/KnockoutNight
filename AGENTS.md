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

## Luau assertions

Always pass a descriptive failure message as the second argument to `assert`. Messages should explain the invariant that failed and help identify the affected system or data.

## Checks Before Studio

Run builds, tests, linter, and formatters before studio sees whatever code you sync

Before every Studio change, compare the relevant local scripts with Studio and sync any differences, even when the current change does not touch those scripts.

## Testing and Playtesting Responsibilities

For Knockout Night, separate technical verification from subjective gameplay playtesting.

**Your responsibilities (AI agent):**
- Implement the requested functionality according to the approved design.
- Run available automated tests and technical checks.
- Verify that scripts execute without errors and that core mechanics satisfy their specified requirements.
- Report any unverified behavior, limitations, or known issues.
- Provide concise instructions for manually testing the implemented feature in Roblox Studio.

**My responsibilities (developer/designer):**
- Personally playtest completed gameplay features.
- Evaluate combat feel, responsiveness, readability, balance, and player experience.
- Decide whether a feature is acceptable or requires refinement.
- Provide feedback that guides subsequent implementation.

**Workflow rule:** Do not treat automated testing or simulated gameplay as a substitute for my hands-on playtesting. After implementation and technical verification, hand the feature back to me for gameplay evaluation. Do not mark subjective gameplay acceptance as complete until I approve it.

**Sign-off progress rule:** When I explicitly sign off a feature, update its implementation/verification document and the engineering roadmap with the acceptance status and date. Correct stale status and next-step references, and keep deferred slices and release gates separate; sign-off alone does not authorize publishing or the next slice.

Do not automatically continue into polishing or unrelated features while awaiting gameplay acceptance. Lengthy playtest reports for every minor change. Save structured playtest reviews for major milestones, particularly when assessing networking, physics, and new combat systems.
