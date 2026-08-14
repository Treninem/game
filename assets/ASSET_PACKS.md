# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import.

## Verified CC0 production packs

### Nature / terrain / vegetation
- Kenney Nature Kit — 330 3D assets — CC0 — https://kenney.nl/assets/nature-kit — `assets/nature/kenney_nature_kit/`
- Quaternius Stylized Nature MegaKit — 116 models: 40 trees, 35 plants/flowers, 27 rocks, grass/bushes; glTF and Godot support — CC0 — https://quaternius.com/packs/stylizednaturemegakit.html — `assets/nature/quaternius_stylized_megakit/`
- Quaternius Simple Nature Pack — 13 essentials: trees/grass/rocks/bushes — CC0 — https://quaternius.com/packs/simplenature.html — `assets/nature/quaternius_simple_nature/`
- Poly Haven — CC0 PBR textures/models/HDRIs — https://polyhaven.com/ — `assets/materials/polyhaven/`, `assets/lighting/hdri/polyhaven/`
Maintain biome-ready trees, grass, plants, flowers, bushes, crops, rocks, stone, sand, soil, mud, snow, cliffs, water, caves, coast, river, swamp, desert, tundra, temperate, tropical and mountain assets.

### Buildings / settlements / roads / dungeons
- Kenney Building Kit — 80+ walls/floors/doors/windows, OBJ/FBX/glTF, Godot compatible — CC0 — https://kenney-assets.itch.io/building-kit — `assets/buildings/kenney_building_kit/`
- Kenney Modular Buildings — 100 modular 3D assets — CC0 — https://kenney.nl/assets/modular-buildings — `assets/buildings/kenney_modular_buildings/`
- Kenney Fantasy Town Kit — 160 medieval/town/wall/building assets — CC0 — https://kenney.nl/assets/fantasy-town-kit — `assets/buildings/kenney_fantasy_town/`
- Kenney Castle Kit — 75 castle/medieval assets — CC0 — https://kenney.nl/assets/castle-kit — `assets/buildings/kenney_castle/`
- Kenney Retro Urban Kit — 120 urban/building/city assets — CC0 — https://kenney.nl/assets/retro-urban-kit — `assets/buildings/kenney_retro_urban/`
- Quaternius Medieval Village MegaKit — 300+ modular pieces, glTF, free Standard tier CC0 — https://quaternius.com/packs/medievalvillagemegakit.html — `assets/buildings/quaternius_medieval_village_megakit/`
- Quaternius Downtown City MegaKit — 300+ modular city pieces, glTF, free Standard tier CC0 — https://quaternius.com/packs/downtowncitymegakit.html — `assets/buildings/quaternius_downtown_city/`
Maintain residential, farm, industrial, commercial, civic, castles, fortifications, ruins, dungeons, roads, paths, bridges, interiors, doors/windows and modular construction.

### Humans / NPCs / animation
Quaternius CC0 collection is an approved discovery source for Animated Characters, Animated Human Low Poly, LowPoly RPG Characters and related packs: https://opengameart.org/content/all-cc0-uploader-quaternius
Maintain civilians, survivors, merchants, workers, farmers, hunters, guards, warriors, bandits and NPC archetypes; idle/walk/run/sprint/crouch/crawl/jump/climb/swim/combat/tools/gathering/crafting/farming/fishing/building/carrying/sitting/sleeping/injury/death/interactions.

### Animals / wildlife / creatures
Quaternius CC0 collection includes animated animals, farm animals, fish and monsters; verify each selected pack before physical import: https://opengameart.org/content/all-cc0-uploader-quaternius
Maintain farm animals, forest wildlife, birds, fish, insects, predators, aquatic creatures and hostile creatures.

### Items / props / tools / weapons
- Kenney Generic Items and other verified Kenney CC0 item sets remain approved.
- Quaternius Fantasy Props MegaKit Standard — 200+ furniture/tools/weapons/books/potions/breakables/props; optimized shared textures; glTF; free Standard tier CC0 — https://quaternius.com/packs/fantasypropsmegakit.html — `assets/props/quaternius_fantasy_props_standard/`
- Quaternius CC0 collection is approved for individually verified food, furniture, survival, medieval weapons and animated-gun packs.
Maintain tools, melee/ranged weapons, ammo, armor, clothing, food, medicine, containers, furniture, crafting stations, raw resources, electronics and machines.

### Vehicles / transportation
Maintain cars, trucks, carts, wagons, boats, ships and progression-era transport. Import only verified CC0 packs with coherent art direction.

### VFX / weather / physical environment
Maintain `water`, `fire`, `wind`, `dust`, `smoke`, `fog`, `rain`, `snow`, `mud`, `debris`, `blood`, `magic`, `electricity`, `weather`. Prefer Godot shaders/GPUParticles with CC0/project-owned textures. Water covers ocean/lake/river/shallow water, foam, splash, ripple and waterfalls; vegetation supports wind response.

### Audio / ambience / Foley
Maintain biome ambience, weather, fire/water, footsteps per surface, wildlife, human Foley, crafting/tools, combat, construction, machines, vehicles, UI and world interactions. Only verified redistribution-compatible/CC0 audio is production-approved.

### UI / HUD / input
- Kenney UI Pack Adventure — 130 UI assets — CC0 — https://www.kenney.nl/assets/ui-pack-adventure — `assets/ui/kenney_ui_adventure/`
Maintain HUD, inventory, equipment, crafting, map/fog-of-war, quests, character, skills, technology, trading, construction, settings, controls, graphics, audio, accessibility and 10-slot save/load/delete.

### Advanced technology / sci-fi
- Quaternius Modular Sci-Fi MegaKit Standard — 270+ modular environment pieces in full family; free Standard version available, CC0, Godot Asset Store distribution — https://store.godotengine.org/asset/quaternius/modular-sci-fi-megakit/ — `assets/technology/quaternius_scifi_megakit_standard/`
- Quaternius Modular Sci-Fi Pack Godot conversion — CC0, StaticBody/collisions and demo scene — https://godotengine.org/asset-library/asset/1671 — `assets/technology/quaternius_scifi_godot/`
Activate only when progression reaches advanced technology.

## Import policy
1. Prefer glTF/GLB for Godot when available; retain source/license metadata.
2. Import only the files actually distributed in the verified free tier. A pack being CC0 does not make paid-only files free to download.
3. Do not dump huge source archives into Git blindly. Import useful game-ready content and optimized runtime variants.
4. Deduplicate meshes/materials/textures/animations shared across packs.
5. Normalize scale, orientation, collision, material naming and LOD conventions before production use.
6. Keep art direction coherent: recolor/rematerial compatible CC0 assets where necessary rather than mixing visibly incompatible styles.
7. Third-party pack folders get `SOURCE.md` and/or `LICENSE.txt` metadata before assets are production-ready.
8. For large packs, use a manifest plus selected production assets; avoid repository bloat and GitHub file-size problems.

## Godot production profile
- Preferred interchange: `.glb` / `.gltf`; fallback `.fbx`/`.obj` only when necessary.
- Target one coherent unit scale and Y-up orientation.
- Static world pieces need simplified collision; tiny decorative meshes normally do not.
- Repeated foliage/rocks/props should be MultiMesh-friendly.
- Terrain/vegetation need distance culling and LOD strategy.
- PBR runtime textures should normally use sensible game resolutions rather than raw 8K/16K sources.
- Reusable humanoid animations belong in a shared animation library instead of duplicated per NPC.

## World asset taxonomy
Stable top-level categories: `nature`, `materials`, `lighting`, `world`, `buildings`, `characters`, `animals`, `items`, `props`, `vehicles`, `vfx`, `audio`, `ui`, `technology`.

## Integration priority
1. Terrain/biomes/water/vegetation
2. Settlements/buildings/interiors/roads/dungeons/ruins
3. Humans/NPCs and universal animations
4. Wildlife/farm animals/aquatic life
5. Items/resources/tools/weapons/clothing
6. Vehicles
7. VFX/weather
8. Audio/Foley/ambience
9. Complete UI
10. Advanced technology

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack.