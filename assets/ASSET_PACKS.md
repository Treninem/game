# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import.

## Approved CC0 sources and packs

### Nature / terrain / vegetation / lighting
- Kenney Nature Kit — 330 3D files — CC0 — https://kenney.nl/assets/nature-kit — `assets/nature/kenney_nature_kit/`
- Quaternius Ultimate Nature Pack — CC0 — https://quaternius.com/packs/ultimatenature.html — `assets/nature/quaternius_ultimate_nature/`
- Poly Haven — CC0 PBR textures, models and HDRIs — https://polyhaven.com/ — `assets/materials/polyhaven/`, `assets/lighting/hdri/polyhaven/`
Maintain trees, grass, plants, flowers, bushes, crops, rocks, stone, sand, soil, mud, snow, cliffs, water, caves and biome vegetation.

### Buildings / villages / ruins / dungeons
- Quaternius Medieval Village MegaKit — 300+ modular pieces, free portion 60–70%, CC0, glTF/Godot compatible — https://quaternius.com/packs/medievalvillagemegakit.html — `assets/buildings/quaternius_medieval_village_megakit/`
- Quaternius Medieval Village Pack — 44 buildings/props — CC0 — https://quaternius.com/packs/medievalvillage.html — `assets/buildings/quaternius_medieval_village/`
- Quaternius Modular Medieval Building Pack — 30 pieces — CC0 — https://quaternius.com/packs/modularmedievalbuildings.html — `assets/buildings/quaternius_modular_medieval/`
- Quaternius Modular Dungeon Pack — 41 dungeon/prop pieces — CC0 — https://quaternius.com/packs/medievaldungeon.html — `assets/buildings/dungeons/quaternius_medieval_dungeon/`
- Quaternius Ultimate Modular Ruins Pack — 90 pieces plus character/props — CC0 — https://quaternius.com/packs/ultimatemodularruins.html — `assets/buildings/ruins/quaternius_modular_ruins/`
- Quaternius Farm Buildings Pack — 13 buildings — CC0 — https://quaternius.com/packs/farmbuildings.html — `assets/buildings/farm/quaternius_farm_buildings/`
- Kenney City Kit Roads — CC0 — https://kenney.nl/assets/city-kit-roads — `assets/world/roads/kenney_city_roads/`
Maintain residential, farm, industrial, commercial, civic, ruins, castles, walls, roads, paths, bridges, interiors, doors/windows and modular construction.

### Humans / NPCs / animation
- Quaternius Universal Animation Library — 120+ humanoid animations, FBX/GLB, tested with Godot — CC0 — https://quaternius.com/packs/universalanimationlibrary.html — `assets/characters/animations/quaternius_universal_1/`
- Quaternius Universal Animation Library 2 — 130+ animations including melee, armed combos, parkour, farming, fishing and zombie locomotion; Godot-compatible — CC0 — https://quaternius.com/packs/universalanimationlibrary2.html — `assets/characters/animations/quaternius_universal_2/`
- Quaternius Toon Shooter Game Kit — 74 models, animated characters/enemies/environment — CC0 — https://quaternius.com/packs/toonshootergamekit.html — `assets/characters/quaternius_toon_shooter/`
Maintain civilians, survivors, merchants, workers, farmers, hunters, guards, warriors, bandits and NPC archetypes. Animation coverage: idle/walk/run/sprint/crouch/crawl/jump/climb/swim, combat, tools, gathering, crafting, farming, fishing, building, carrying, sitting, sleeping, injury/death and interaction.

### Animals / wildlife / creatures
- Quaternius Farm Animal Pack — 7 animated farm animals — CC0 — https://quaternius.com/packs/farmanimal.html — `assets/animals/farm/quaternius_farm_animals/`
- Additional Quaternius/OpenGameArt animal packs only after individual CC0 verification.
Maintain farm animals, forest wildlife, birds, fish, insects, predators, aquatic creatures and hostile creatures.

### Items / props / tools / weapons
- Kenney Generic Items — 160 assets — CC0 — https://www.kenney.nl/assets/generic-items — `assets/items/kenney_generic_items/`
- Quaternius RPG Essentials Pack — 13 RPG essentials — CC0 — https://quaternius.com/packs/rpg.html — `assets/items/quaternius_rpg_essentials/`
Maintain items, tools, melee/ranged weapons, ammo, armor, clothing, food, medicine, containers, furniture, crafting stations, raw resources, electronics and machines.

### Vehicles / transportation
- Kenney Car Kit — CC0 — https://www.kenney.nl/assets/car-kit — `assets/vehicles/kenney_car_kit/`
- Quaternius Cars Pack — 8 cars — CC0 — https://quaternius.com/packs/cars.html — `assets/vehicles/quaternius_cars/`
Maintain cars, trucks, carts, boats and advanced transport as progression requires.

### VFX / elements / weather
Maintain `water`, `fire`, `wind`, `dust`, `smoke`, `fog`, `rain`, `snow`, `mud`, `debris`, `blood`, `magic`, `electricity`, `weather`. Prefer Godot shaders/GPUParticles with CC0/project-owned textures.

### Audio / ambience / Foley
- OwlishMedia Sound Effects Pack — ambience, cloth, footsteps, humans, impacts, UI, technology, water — CC0 — https://opengameart.org/content/sound-effects-pack — `assets/audio/sfx/owlishmedia_cc0/`
- OpenGameArt Footsteps — CC0 — https://opengameart.org/content/footsteps-0 — `assets/audio/footsteps/opengameart_footsteps/`
- OpenGameArt 100 CC0 SFX #2 — air, doors, footsteps, glass, machines, construction, highway/street, flowing water, metal, stone, thunder, wood — CC0 — https://opengameart.org/content/100-cc0-sfx-2 — `assets/audio/sfx/oga_100_cc0_2/`
- OpenGameArt Various Sound Effects — stone break, doors, weapons, birds, footsteps, swimming, metal and interactions — CC0 — https://opengameart.org/content/various-sound-effects-0 — `assets/audio/sfx/oga_various_cc0/`
Maintain biome ambience, weather, fire/water, footsteps per surface, wildlife, human Foley, crafting/tools, combat, building, machines, vehicles, UI and world interactions.

### UI / HUD
- Kenney UI Pack — CC0 — https://kenney.nl/assets/ui-pack — `assets/ui/kenney_ui_pack/`
- Kenney UI Audio — 50 button/switch/click sounds — CC0 — https://www.kenney.nl/assets/ui-audio — `assets/audio/ui/kenney_ui_audio/`
Cover HUD, inventory, equipment, crafting, map/fog-of-war, quests, character, skills, technology, trading, construction, settings, controls, graphics, audio and 10-slot save/load/delete.

### Advanced technology
Keep CC0 sci-fi/space packs under `assets/technology/` and activate them only when progression reaches those eras.

## World asset taxonomy
Stable top-level categories: `nature`, `materials`, `lighting`, `world`, `buildings`, `characters`, `animals`, `items`, `props`, `vehicles`, `vfx`, `audio`, `ui`, `technology`. Every imported third-party pack gets source/license metadata.

## License/repository policy
Prefer CC0. Never import unclear, NC, ND, ripped or incompatible assets. Preserve licenses. Do not blindly commit huge source archives: import game-ready files actually used and optimize runtime copies. For packs with free and paid/source tiers, import only files actually distributed under the verified free CC0 tier unless separately licensed.

## Integration priority
1. Terrain/biomes/water/vegetation
2. Settlements/buildings/interiors/roads/dungeons/ruins
3. Humans/NPCs and universal animation libraries
4. Wildlife and farm animals
5. Items/resources/tools/weapons/clothing
6. Vehicles
7. VFX/weather
8. Audio/Foley/ambience
9. Complete UI
10. Advanced technology

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack.