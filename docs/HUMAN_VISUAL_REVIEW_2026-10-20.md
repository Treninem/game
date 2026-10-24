# Human graphics and animation review — 2026-10-20

Overall human/world art acceptance remains open. This change fixes a reproducible cycle restart, not the requested complete realism upgrade.

## Direct observations

Both existing MakeHuman bodies rendered with the live player controller on a physical floor: 23.55 m via normal action input. Final full-world graphical pass: 24.30 m with no driver coordinate assignments. Walk/run, axe and bow images were inspected. Shoulders/armpits deform poorly, fingers look stiff/splayed, and the shared garment is insufficiently varied. These are remaining defects, not accepted quality.

The desktop capture API timed out; no claim of a manual playthrough. The successful source-game pass was automated input in a visible Godot window. First full-world startup timed out; the subsequent successful result does not erase that observation.

## Reference study — partial, not a completed requirement

| Reference | Material actually opened | Observation | Decision / outstanding work |
|---|---|---|---|
| [Enshrouded Steam](https://store.steampowered.com/app/1203620/Enshrouded/) | In-page live gameplay stream; two displayed frames, exterior ruined stone settlement and interior beds | Rear third-person camera, compact bottom action bar, layered stone surfaces; clothing silhouette visible from rear | Use as a composition reference; two frames are insufficient for gait timing or comprehensive comparison |
| [Skyrim SE gameplay trailer](https://elderscrolls.bethesda.net/en-EU/news/1dcGD5lk0Ss06Q4Eeaa2Mk/skyrim-special-edition-gameplay-trailer-2) | Search result found; video not visually inspected | No observation asserted | Character, motion, world and UI comparison pending |
| Kenshi | No gameplay imagery inspected this turn | No observation asserted | Required visual/video comparison pending |
| Mantella | Documentation search result only; no demo watched | No observation asserted | Required NPC response/memory/demo comparison pending |

No meshes, textures or new assets were selected from these references. Do not treat this table as completion of the full reference requirement.

## Reproduction

Run `tests/smoke_locomotion_facing.tscn` for the mandatory existing CI regression. Both bodies, both directions and three gait phases are checked. The original runtime failed both initial transition assertions. The corrected runtime retains normalized phase; repeated speed updates and Idle entry are checked separately.

For visible inspection, launch Godot with `--path <project> --script res://tests/visual_locomotion_walk_run.gd` under an isolated user profile. It saves eight `user://gait-*.png` frames and requires over 15 m of physical movement. The flat floor and observer camera are inspection tools, not new world content. The full-world QA result and remaining limitations are recorded in DEVELOPMENT_LOG_2026-10-20_HUMAN_GAIT.json.
