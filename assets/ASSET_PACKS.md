# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import.

## Approved CC0 sources and packs

### Nature / terrain / vegetation / lighting
- Kenney Nature Kit — 330 3D files — CC0 1.0 — https://kenney.nl/assets/nature-kit — `assets/nature/kenney_nature_kit/`
- Quaternius Ultimate Nature Pack — 150 models — CC0 — https://quaternius.com/packs/ultimatenature.html — `assets/nature/quaternius_ultimate_nature/`
- Quaternius Ultimate Stylized Nature Pack — CC0 — https://quaternius.com/packs/ultimatestylizednature.html — `assets/nature/quaternius_stylized_nature/`
- Quaternius Simple Nature Pack — CC0 — https://quaternius.com/packs/simplenature.html — `assets/nature/quaternius_simple_nature/`
- Poly Haven — CC0 PBR textures, 3D models and HDRIs — https://polyhaven.com/ — `assets/materials/polyhaven/` and `assets/lighting/hdri/polyhaven/`
Maintain trees, grass, plants, flowers, bushes, rocks, stone, sand, soil, mud, snow, cliffs, water, caves and biome-specific vegetation. For PBR preserve albedo, normal GL, roughness, AO and displacement where useful; ship optimized game resolutions.

### Buildings / settlements / interiors / roads
- Quaternius Ultimate Buildings Pack — CC0 — https://quaternius.com/packs/ultimatetexturedbuildings.html — `assets/buildings/quaternius_ultimate_buildings/`
- Quaternius Buildings Pack — CC0 — https://quaternius.com/packs/buildings.html — `assets/buildings/quaternius_buildings/`
- Quaternius Farm Buildings Pack — CC0 — https://quaternius.com/packs/farmbuildings.html — `assets/buildings/quaternius_farm_buildings/`
- Kenney City Kit Roads — 70 road/city 3D files — CC0 — https://kenney.nl/assets/city-kit-roads — `assets/world/roads/kenney_city_roads/`
- Kenney City Kit Commercial — 50 commercial/city building files — CC0 — https://www.kenney.nl/assets/city-kit-commercial — `assets/buildings/kenney_city_commercial/`
Maintain residential, farm, industrial, commercial, civic, ruins, walls, roads, paths, bridges, interiors, doors/windows, street furniture and modular construction pieces.

### Humans / characters / NPCs / animation
- Quaternius CC0 character ecosystem: animated humans, RPG characters and reusable animation libraries. Reference: https://opengameart.org/content/all-cc0-uploader-quaternius — `assets/characters/`
Maintain body variants, civilians, survivors, merchants, workers, farmers, hunters, guards, warriors, bandits and NPC archetypes; locomotion, swimming, climbing, combat, gathering, crafting, farming, building, sleeping and interaction animations go in `assets/characters/animations/`.

### Animals / wildlife / creatures
- Quaternius CC0 animal ecosystem and individually verified OpenGameArt CC0 animal packs — `assets/animals/`
Maintain farm animals, forest wildlife, birds, fish, insects, predators, aquatic creatures and hostile creatures, with reusable animation sets.

### Items / props / tools / weapons
- Kenney Generic Items — 160 assets — CC0 — https://www.kenney.nl/assets/generic-items — `assets/items/kenney_generic_items/`
- Quaternius CC0 props/weapons/survival libraries; verify pack-level CC0 before import — `assets/props/`
Maintain items, tools, melee/ranged weapons, ammo, armor, clothing, food, medicine, containers, furniture, crafting stations, raw resources, electronics and machines.

### Vehicles / transportation
- Kenney Car Kit — 45 3D vehicle/transport files — CC0 — https://www.kenney.nl/assets/car-kit — `assets/vehicles/kenney_car_kit/`
Maintain cars, trucks, carts, boats and later advanced transport as gameplay requires. Separate vehicle meshes, interiors, wheels, damage/debris and audio.

### Survival / sandbox support
- Kenney Voxel Pack — textures, items, characters, skybox, particles, sun/moon — CC0 — https://opengameart.org/content/voxel-pack — `assets/survival/kenney_voxel/`
Use selectively where style fits; adapt materials when necessary to avoid incoherent art direction.

### VFX / elements / weather
- OpenGameArt Smoke Vapor Particles — smoke/vapor/dust textures — CC0 — https://opengameart.org/content/smoke-vapor-particles — `assets/vfx/smoke/opengameart_vapor/`
- OpenGameArt Animated Particle Effects #1 — fire/flame/smoke/magic — CC0 — https://opengameart.org/content/animated-particle-effects-1 — `assets/vfx/particles/opengameart_particlefx1/`
Maintain water splashes/foam/rain/waterfalls/ripples, fire/flames/embers/sparks, wind, dust, smoke, fog, rain, snow, mud, debris, blood, magic, electricity and weather. Prefer Godot shaders/GPUParticles with CC0 or project-owned textures for dynamic effects.

### Audio / ambience / Foley
- OwlishMedia Sound Effects Pack — CC0; ambience, cloth, footsteps, human sounds, impacts, paper, UI, sci-fi/technology and water — https://opengameart.org/content/sound-effects-pack — `assets/audio/sfx/owlishmedia_cc0/`
- Fantozzi Footsteps Grass/Sand/Stone — CC0 — https://opengameart.org/content/fantozzis-footsteps-grasssand-stone — `assets/audio/footsteps/fantozzi_cc0/`
Maintain ambience/forest/city/cave/weather/water/fire, footsteps by surface, wildlife, human Foley, crafting/tools, combat, building, machines, vehicles, UI and world interaction sounds. Normalize and convert runtime copies to appropriate OGG/WAV without destroying masters unnecessarily.

### UI / HUD
- Kenney UI Pack — CC0 — https://kenney.nl/assets/ui-pack — `assets/ui/kenney_ui_pack/`
- Kenney UI Pack Adventure — CC0 — https://kenney.nl/assets/ui-pack-adventure — `assets/ui/kenney_ui_adventure/`
- Kenney RPG Base — CC0 — https://www.kenney.nl/assets/rpg-base — `assets/ui/kenney_rpg_base/`
Cover HUD, inventory, equipment, crafting, map/fog-of-war, quests, character, skills, technology, trading, construction, settings, controls, graphics, audio and 10-slot save/load/delete.

### Advanced technology / sci-fi progression
- Quaternius Ultimate Modular Sci-Fi Pack — 46 modular interior/prop models — CC0 — https://quaternius.com/packs/ultimatemodularscifi.html — `assets/technology/scifi_modular/`
- Quaternius Modular Sci-Fi Megakit — 277 modular environment pieces — CC0 — https://quaternius.com/packs/modularscifimegakit.html — `assets/technology/scifi_megakit/`
- Quaternius Ultimate Space Kit — CC0 — https://quaternius.com/packs/ultimatespacekit.html — `assets/technology/space/`
Use only as civilization/technology progression reaches those eras.

## World asset taxonomy
Keep stable top-level categories so every chat can find assets: `nature`, `materials`, `lighting`, `world`, `buildings`, `characters`, `animals`, `items`, `props`, `vehicles`, `vfx`, `audio`, `ui`, `technology`. Add a `LICENSE.txt` or source manifest inside imported third-party pack directories.

## License and repository policy
Prefer CC0. Never import unclear, NC, ND, ripped or otherwise incompatible assets. Preserve license/readme/source metadata. Free individual CC0 packs are preferred over paid bundles. Do not commit gigantic raw source packs blindly: import game-ready assets actually used, retain source manifests, optimize textures/models/audio for runtime and repository size.

## Integration priority
1. Terrain/PBR ground, lighting/HDRI, water, trees, grass, rocks and biome vegetation
2. Buildings, interiors, roads, bridges and settlement props
3. Humans/NPCs plus common animation library
4. Wildlife, farm animals, fish and creatures
5. Items/resources/crafting/tools/weapons/clothing
6. Vehicles and transport
7. Fire/water/wind/dust/smoke/weather VFX
8. Footsteps, ambience, interaction and world audio
9. Complete game UI
10. Advanced technology assets as progression requires

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack.