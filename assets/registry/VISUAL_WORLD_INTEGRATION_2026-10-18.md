# Visual world integration — 2026-10-18

Selected existing CC0 sources, without new downloads:

| Source | Production selection | Runtime | Status |
| --- | --- | --- | --- |
| Quaternius RPG Characters, source chat B36 | Ranger body retained; bow clips retargeted to current adult human | prepare_citizen_visual.py | PRODUCTION_READY |
| Quaternius Stylized Nature MegaKit, source chat B44 | 3 trees, bush, fern, grass | start_region_streamer.gd; production_nature.gd | INTEGRATED |
| OpenGameArt Seamless Textures, arikel/CruzR | photographic meadow grass and lichen rock | world_streamer.gd | INTEGRATED |

Production folders retain LICENSE.txt and SOURCE.md, including exact source paths.
The Blender conversion is reproducible through tools/prepare_production_visuals.py.
GLBs embed texture dependencies, normalize height and place roots/feet at zero.
Near tree trunks retain collision; far trees use authored meshes in MultiMeshes.
Leaf motion extends the existing shared environment wind shader architecture.

The human remains stylized, rather than a photorealistic scanned person. Do not
represent these sources or this integration as AAA/photorealistic production art.

Related physical corrections: retire the temporary flat spawn collider after real
terrain becomes available; increase mesh sampling to 8 m; carve banks to meet the
water edge; use continuous curved river strips and suppress duplicate water tiles.
Regression: tests/smoke_visual_grounding.tscn.

The woodland particle selection also reuses the existing CC0 Tree Leaves Pack 1
mask by TrachinusDraco. Its import is capped at 256 px with mipmaps; the leaf
shader samples one silhouette, and emission follows autumn/strong wind instead
of permanent square confetti. Photographic ground imports explicitly generate
mipmaps to prevent minification shimmer in the GL Compatibility renderer.

## Gameplay follow-up — 2026-10-19

- INTEGRATED: four existing CC0 Quaternius RPG items from B36, normalized under
  `assets/production/weapons/woodland/`. Equipment follows the animated forearm;
  the holder compensates skeleton scale without overwriting the asset transform.
  Axe/knife/bow equip and unequip visually; arrows have swept collision, gravity,
  ammo consumption and cooldown. The early knife uses a dagger visual proxy.
- INTEGRATED: existing production plaster textures, authored windows and doors
  in the live `city_streamer_fast.gd`, with denser residential blocks and doors
  facing streets. The capital keeps its 4 km extent and 32 gates; this does not
  establish that every detailed district requirement is complete.
- Capital residents now stream near the player, walk and converse. They wait for
  actual ground collision before becoming visible and moving.
- Four persisted graphics presets control 3D scale, MSAA, shadows and vegetation
  distance. Windows-compatible mouse confinement/recentering avoids unavailable
  raw motion; camera tests cover both modes and three UI scales.
- Lighting follows the game clock and shared fog state. Spell projectiles and
  cast effects originate near the human instead of behind it at the camera.

Regression scenes: `smoke_gameplay_actions`, `smoke_capital_gameplay`,
`smoke_camera_input`, alongside the terrain, grounding, movement and world checks.
The human and nature art remain stylized. This is not Witcher-3-level realism.

### Capital civic landmarks follow-up, 2026-10-19

- INTEGRATED: the existing modular civic building system now runs inside the
  live fast city streamer. All six protected anchors use capital-to-world
  coordinates and terrain elevation: town hall, treasury, guild hall, gate hall,
  guard headquarters and royal estate. Ordinary lots reserve 58 m around anchors.
- Existing production city-core walls, doors, windows and roofs are reused;
  plaster attic gables close the roof pack's open ends. No new source pack.
- Repeated authored wall/window/roof meshes are grouped into static MultiMeshes
  per landmark; their world transforms and existing collision proxies are retained.
- The capital gameplay check covers all six positions, grounding, roof ends
  and distance-based unloading, in addition to gates, walking and residents.
- Native inspection confirmed the town hall facade and a grounded street walk.
  This remains a partial capital implementation, not completion of every district.

### Living world follow-up, 2026-10-19

- INTEGRATED: CC0 Quaternius Animated Human from existing physically staged source,
  smoothed once, normalized to 1.8 m, open face and adult proportions. Tunic,
  trousers and boots are assigned on the authored skinned mesh; original light
  and dark skin palettes remain. Ten clips include two retargeted B36 bow clips
  and Axe_Chop from the physically staged CC0 Universal Animation Library 2
  Standard TreeChopping_Loop, with translation/root motion excluded.
  `tools/prepare_citizen_visual.py` reproduces the production selection.
- INTEGRATED: B44 Free Vegetation Asset Pack temperate tree and authored LOD,
  normalized to 12 m. Original photographic branch cards, seeded nearby layers,
  existing Quaternius bark; `tools/prepare_temperate_tree.py`. The shared
  foliage wind shader's black-key cutout is required by this source texture.
- Ordinary capital houses use batched authored facade and pitched roof modules;
  their collision shells remain solid. Full dwelling interiors are not integrated.
- Streamed citizens use work, meal, social, home-porch and travel destinations.
  Traders have paid finite stock persisted by citizen ID. These are deterministic
  routines, not external language-model AI or a full population simulation.
- Local maps render real terrain and discovered building/tree footprints, plus
  current nearby hostile, allied, civilian and resource markers. Fog is retained.
- Outside the start region, trees now stay visible nearby and have trunk collision;
  ground cover and authored gatherable models replace primitive resource bodies.
- Physics fixes correct bridge approach pitch, road cuts below the continental
  sea floor, and unsupported upward wall nudges. New tests cover actual traversal,
  572 road samples, supported stairs, persistent trade, map features and encounters.
- Long input-driven traversal reached the western capital gate after 14 km and
  exposed a real collision regression: child AnimatableBody synchronization kept
  the doors closed despite rotating hinge parents. Disabled that conflicting
  synchronization, moved the solid guardroom off the passage axis, and reserved
  house-free gate approaches. Regression checks all 32 open and closed gates plus
  actual player entry to the western street. Continuing the route uses the real
  unchanged autosave made at the failed gate, not an invented city position.
- The continuation reached the central square on foot: 2,840 m after the real
  autosave reload, following 14,293 m from the forest before gate repair. This
  verifies the route in two runs; it is not a fresh uninterrupted traversal of
  the final build. No manual full visual journey is claimed. Final package
  checks also verify open gate collision, actual street entry and merchant
  dialogue purchases independently of source resources.
- Native UI automation failed during this follow-up. Full manual visual traversal
  to the capital is not verified; offline input-driven traversal is separate QA.
  The art remains stylized and does not reach Witcher 3 realism.

### Anatomical human and living-world follow-up — 2026-10-19

- INTEGRATED: existing CC0 B89 byzmod3d `homen_base.obj` replaces the citizen's former stylized geometry. The existing Quaternius rig, ten clips and NPC palettes remain. Anatomical mesh is 1.8 m / 10066 vertices, with connected-arm weight transfer and smooth joint weights. Missing source MTL replaced by project materials; exact finger grip and photographic skin are unfinished. Source and both licenses are preserved under `assets/production/characters/citizen/`.
- INTEGRATED: existing B44 `tree_leaves_higher` / `branches_leaves.png` selected as `TemperateTree_Broad.glb`, using the shared wind/cutout shader in the near-start forest. Distant taiga pines retain their prior assets.
- INTEGRATED: existing B47 authored chimney and wider roof eaves on batched capital houses. Ordinary homes remain solid collision shells, not enterable interiors.
- Civilian legacy patrols now enter the existing work/meal/social/home schedule; watchmen retain patrols. Chest-height obstacle steering prevents a tested wall from blocking access to work. These remain deterministic routines, not a full social/economic simulation or external AI.
- Map footprints now include actual batched rocks and persistent felled stumps alongside existing terrain, water, roads, buildings, trees and live markers.
- A fresh continuous input-driven route reached the capital square after 16,911.59 m, all 16 waypoints, normal speed/stamina/gravity and time scale 1. The driver never assigns player position; ten berries and ten water flasks are explicit test supplies. Arrival slot retained. Subsequent visual-only bow/gait fixes do not change the movement controller or collision. This supersedes the older split-run route evidence above, not the incomplete city-art assessment.
- Native official-game inspection loaded that real arrival save: human mesh, roofs, moving citizens, local map, inventory, Escape return and mouse camera rotation were inspected. Empty oversized square, repetitive houses, plain ground and dark evening silhouettes remain visible problems; full manual journey and all city interiors are not claimed.

### Contact refinement — 2026-10-19

- INTEGRATED: `sfx100v2_wood_hit_01/02/03.ogg` from the existing physically staged B04 CC0 rubberduck pack, promoted to the existing world-audio production folder. A successful delayed axe contact emits spatial sound at the bark surface; cancelled swings remain silent.
- Axe_Chop retargeting aligns anatomical shoulder axes between FBX human and glTF mannequin before transferring rotations. Original mesh, palettes and all ten clips are retained; no new character pack was generated.
- Local-map canopy footprints consult persistent felling state, including unloaded cells and old saved map-feature dictionaries. Buildings and unexplored terrain are retained independently.

### Working capital square — 2026-10-19

- INTEGRATED: existing B46 CC0 Fantasy Props Bench, Lantern_Wall, Workbench, Barrel and Barrel_Apples, with original furniture/metal glTF dependencies and source licenses under `assets/production/medieval/capital_square/`. Shared existing market stalls reused. Measured normalization sets grounded mesh bounds and matching collision; the main crossing stays clear.
- INTEGRATED: existing CC0 arikel/CruzR `100_1453_seamless.JPG` as `stone_paving.jpg`, with mipmaps and world-space scale. City paving meets terrain. Native review exposed world dirt patches painting over it; WorldRoads now defers visual paving inside capital bounds to city streaming. Bridge and roadbed physics are preserved.
- Night ambient fill now uses a bounded cool color instead of multiplying a nearly black procedural sky; warm stall lanterns switch on in the evening. This is not a full lighting/performance certification.
- Two named square citizens use actual work, home, meal and social destinations. The artisan consumes the existing arrow recipe from the trader's finite wood/stone stock over eight seconds and adds five arrows; players can sell both inputs. Stock/progress live in existing persistent world state. Work stops when inputs are missing. This concrete local loop is not a complete capital economy or external AI.
- Actual street furniture footprints are recorded on the local map beneath living markers. Ordinary homes still have closed collision shells; interiors, architectural repetition, oversized urban spaces and realistic character/forest materials remain unfinished.

### First live square home — 2026-10-19

- INTEGRATED: the existing EnterableBuilding physical room, authored building-shell door/roof and existing Quaternius bed/table decorator now replace the left sealed square house. Existing city plaster is reused. No new third-party pack was downloaded or duplicated.
- Marta and Marek physically enter this one home after 21:00 and leave for work in the morning. A shared doorway queue and threshold occupancy prevent the observed deadlock and automatic closure into a passing resident/player. Door target state is stored in world state.
- This is one accessible home, with indoor idle rest rather than a complete sleep/household animation. Most capital homes remain sealed, furniture storage interactions are unfinished and streamed residents still resume from authored spawn positions.
- Local dialogue uses actual finite shop money/stock, supply history, equipped weapon and nearby visible successful spell events. This is deterministic local game behavior, not an external AI service or a complete social simulation.
