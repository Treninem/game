# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import.

## Approved CC0 sources and packs

### Nature / terrain / vegetation
- Kenney Nature Kit — 330 3D files — CC0 1.0 — https://kenney.nl/assets/nature-kit — `assets/nature/kenney_nature_kit/`
- Quaternius Ultimate Nature Pack — 150 models — CC0 — https://quaternius.com/packs/ultimatenature.html — `assets/nature/quaternius_ultimate_nature/`
- Quaternius Ultimate Stylized Nature Pack — 63+ models with textures/normal maps — CC0 — https://quaternius.com/packs/ultimatestylizednature.html — `assets/nature/quaternius_stylized_nature/`
- Quaternius Simple Nature Pack — trees, grass, rocks, bushes — CC0 — https://quaternius.com/packs/simplenature.html — `assets/nature/quaternius_simple_nature/`
- Poly Haven — CC0 high-resolution PBR textures/models/HDRIs — https://polyhaven.com/ — `assets/materials/polyhaven/`
- Poly Haven Aerial Grass Rock — 8K PBR grass/rock terrain — CC0 — https://polyhaven.com/a/aerial_grass_rock — `assets/materials/terrain/grass_rock/`
- Poly Haven Coast Sand 03 — up to 16K sand/pebbles PBR — CC0 — https://polyhaven.com/a/coast_sand_03 — `assets/materials/terrain/sand/`

Maintain: `trees/`, `grass/`, `plants/`, `flowers/`, `bushes/`, `rocks/`, `stone/`, `sand/`, `soil/`, `mud/`, `snow/`, `cliffs/`, `water/`, `roads/`, `caves/`.
For PBR materials preserve diffuse/albedo, normal GL, roughness, AO and displacement where useful; create lower-resolution game variants rather than shipping unnecessarily huge source textures.

### Buildings / settlements / interiors
- Quaternius Ultimate Buildings Pack — modular textured buildings — CC0 — https://quaternius.com/packs/ultimatetexturedbuildings.html — `assets/buildings/quaternius_ultimate_buildings/`
- Quaternius Buildings Pack — CC0 — https://quaternius.com/packs/buildings.html — `assets/buildings/quaternius_buildings/`
- Quaternius Farm Buildings Pack — CC0 — https://quaternius.com/packs/farmbuildings.html — `assets/buildings/quaternius_farm_buildings/`
Maintain residential, farm, industrial, commercial, civic, ruins, walls, roads, bridges, interiors, doors/windows and modular construction parts.

### Humans / characters / NPCs / animation
- Quaternius CC0 character ecosystem: animated humans, RPG characters and reusable animation libraries. Reference: https://opengameart.org/content/all-cc0-uploader-quaternius — `assets/characters/`
Maintain male/female variants, civilian, survivor, merchant, worker, farmer, hunter, guard, warrior, bandit and NPC archetypes plus reusable locomotion/combat/work animations in `assets/characters/animations/`.

### Animals / wildlife / creatures
- Quaternius CC0 animal ecosystem and OpenGameArt CC0 animal collections (individual licenses must be verified) — `assets/animals/`
Maintain farm animals, forest wildlife, birds, fish, insects, predators, aquatic creatures and hostile creatures with reusable animation sets.

### Items / props / tools / weapons
- Kenney Generic Items — 160 items/tools/household sprites — CC0 — https://www.kenney.nl/assets/generic-items — `assets/items/kenney_generic_items/`
- Quaternius CC0 props/weapons/survival libraries; verify pack-level CC0 before import — `assets/props/`
Maintain `items/`, `tools/`, `weapons/melee/`, `weapons/ranged/`, `weapons/ammo/`, `armor/`, `clothing/`, `food/`, `medicine/`, `containers/`, `furniture/`, `crafting/`, `resources/`, `electronics/`, `machines/`.

### Survival / sandbox support
- Kenney Voxel Pack — textures, items, characters, skybox, particles, sun/moon — CC0 — https://opengameart.org/content/voxel-pack — `assets/survival/kenney_voxel/`
Use selectively where visual style fits; do not mix incompatible styles without adaptation.

### VFX / elements / weather
- OpenGameArt Smoke Vapor Particles — four smoke/vapor/dust particle textures — CC0 — https://opengameart.org/content/smoke-vapor-particles — `assets/vfx/smoke/opengameart_vapor/`
- OpenGameArt Animated Particle Effects #1 — fire/flame/smoke/magic sprite sheets — CC0 — https://opengameart.org/content/animated-particle-effects-1 — `assets/vfx/particles/opengameart_particlefx1/`
Maintain `water/` (splashes, foam, rain, waterfalls, ripples), `fire/` (flames, embers, sparks), `wind/`, `dust/`, `smoke/`, `fog/`, `rain/`, `snow/`, `mud/`, `debris/`, `blood/`, `magic/`, `electricity/`, `weather/`.
Prefer Godot shaders and GPUParticles for dynamic wind, water, fire, dust and weather, using CC0/project-owned textures.

### UI / HUD
- Kenney UI Pack — 430 assets — CC0 — https://kenney.nl/assets/ui-pack — `assets/ui/kenney_ui_pack/`
- Kenney UI Pack Adventure — 130 assets — CC0 — https://kenney.nl/assets/ui-pack-adventure — `assets/ui/kenney_ui_adventure/`
- Kenney RPG Base — 230 assets — CC0 — https://www.kenney.nl/assets/rpg-base — `assets/ui/kenney_rpg_base/`
UI coverage: HUD, inventory, equipment, crafting, map/fog-of-war, quests, character, skills, technology, trading, construction, settings, controls, graphics, audio and 10-slot save/load/delete.

### Optional future genres / technology
- Quaternius Sci-Fi Essentials Kit — 60+ models including enemies, guns, props; Godot-compatible source examples — CC0 — https://quaternius.itch.io/sci-fi-essentials-kit — `assets/technology/scifi_essentials/`
- Quaternius Ultimate Space Kit — 92 models — CC0 — https://quaternius.com/packs/ultimatespacekit.html — `assets/technology/space/`
Use when game progression reaches advanced technology.

## License and repository policy
Prefer CC0. Never import unclear, NC, ND, ripped or otherwise incompatible assets. Preserve license/readme/source metadata. Free individual CC0 packs are preferred over paid bundles. Do not commit gigantic raw source packs blindly: import game-ready assets actually used, retain source manifests, and optimize textures/models for runtime and repository size.

## Integration priority
1. Terrain/PBR ground, water, trees, grass, rocks and biome vegetation
2. Buildings, interiors, roads, bridges and settlement props
3. Humans/NPCs plus common animation library
4. Wildlife, farm animals, fish and creatures
5. Items/resources/crafting/tools/weapons/clothing
6. Fire/water/wind/dust/smoke/weather VFX
7. Complete game UI
8. Advanced technology assets as progression requires

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack.