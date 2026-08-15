# Nature / Weather / Ambience SFX — 2026-08-15

Asset-research staging only. Nothing in this file is wired into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## Newly pinned source pack: AmbientSounds
- Status: `PINNED_VENDOR_MIXED_FREE_LICENSES`
- Path: `assets/audio/source_packs/ambient_sounds_muges/`
- Upstream: `Muges/ambientsounds`
- Pinned commit: `7ef9aefeeed93c37bca3cdb246a982dd1afce2f0`
- Repository purpose: audio-only ambient loops.
- Important: license is per-file, not one blanket license for the entire pack.

### CC0 files in the pinned pack
- `fireplace.ogg` — fireplace / campfire / hearth ambience.
- `wind.ogg` — wind ambience.

### CC BY files in the pinned pack
These are free for commercial use when the original attribution/license requirements are preserved:
- `heavy-rain.ogg` — heavy rain.
- `forest-rain.ogg` — forest rain.
- `stream.ogg` — stream / flowing water.
- `thunderstorm.ogg` — thunderstorm ambience.

Do not copy a CC BY file into a production-selected folder without carrying its attribution metadata forward.

## Verified CC0 sources for later selective import
These are deliberately not copied into core Git history yet, either because they are large or because a selective production import is preferable.

### OpenGameArt — Park ambiences
- License: CC0.
- Three real field recordings: birds near trees before rain; small river with birds/frogs/wildlife; open field with stronger wind.
- 48 kHz WAV recordings; individual files are roughly 74–99 MB, so keep as source-only until a production edit is selected.
- Suggested semantic targets: `FOREST_BIRDS_BED`, `RIVER_WILDLIFE_BED`, `FIELD_WIND_BED`.

### OpenGameArt — Forest bird sounds
- License: CC0.
- Ten bird recordings intended for forest ambience.
- Suggested semantic targets: `BIRD_FOREST_NEAR`, `BIRD_FOREST_FAR`, `FOREST_DAY_SCATTER`.

### OpenGameArt — Loopable Dungeon Ambience
- License: CC0.
- Loopable dungeon/cave ambience with low-frequency wind and water drips.
- Suggested semantic targets: `CAVE_ROOM_TONE`, `DUNGEON_WIND`, `CAVE_DRIPS`.

### OpenGameArt — Dark Cavern Ambient
- License: CC0.
- Two cavern/dungeon ambience variants, including a continuous loop.
- Suggested semantic targets: `CAVERN_DARK_LOOP`, `UNDERGROUND_DREAD`.

### Freesound — Forest birds seamless loop
- License: CC0.
- Field recording of birds in a Polish forest, edited as a seamless stereo loop.
- Suggested semantic target: `FOREST_BIRDS_LOOP`.

## Open-world ambience matrix to fill
The sound library should ultimately provide several variants per cell instead of one universal loop.

### Forest
- day birds, distant birds, insects, leaf rustle, branch movement, calm wind, strong wind, rain canopy, post-rain drips, night insects, owl/night calls.

### Fields / plains
- light wind, strong wind, grass movement, insects, sparse birds, distant storm, rain, night ambience.

### Swamp / wetlands
- frogs, insects, water movement, mud, reeds, bubbles, distant birds, night variants.

### Rivers / lakes / coast
- small stream, large river, lake edge, waterfall, shore waves, storm water, dripping rock, underwater muffled beds.

### Mountains / snow
- high wind, gusts, blizzard, snow movement, ice cracks, distant avalanche/rumble, sparse wildlife.

### Underground
- cave room tone, mine room tone, water drips, distant rock movement, tunnel wind, wooden mine supports, chains/mechanisms, large cavern reverb beds.

### Settlements
- quiet village, market crowd, tavern interior, blacksmith/forge, workshop, stable/farm, bells, distant carts/animals, night settlement.

## Rules for main integration flow
- Prefer CC0 variants when quality is comparable.
- CC BY is allowed only with attribution preserved in shipped notices/credits.
- Do not bind gameplay to source filenames; map selected assets to semantic events.
- Avoid a single looping ambience for an entire biome: combine bed + randomized one-shots + weather layers.
- Keep long ambience loops streamed/compressed appropriately; do not preload all biome beds at once.
- Main development owns loudness normalization, 3D placement, occlusion/reverb, crossfades and runtime routing.
