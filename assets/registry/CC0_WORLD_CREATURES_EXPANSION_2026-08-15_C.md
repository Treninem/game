# CC0 world / creatures / environment expansion — 2026-08-15 C

Purpose: source-only asset expansion for the ImPuls main development chat. This research chat must not wire these packs into Godot runtime, scenes or gameplay.

## Physically staged source repositories

### `assets/source_packs/quaternius_cc0_stage`
Source: `weftspun/quaternius-stage`
License: CC0 1.0. The repository describes itself as an OpenUSD (`.usda`) copy of Quaternius CC0 low-poly packs and carries a CC0 license.
Pinned commit when staged: `fe0129d2c93caaebd128d01c1f9cc70ebfd270c0`.

This is especially valuable because the repository contains a very broad Quaternius library in one source tree. High-priority ImPuls folders observed in the source include:

- `models/UltimateAnimatedAnimals` — animated wild/farm creature pool.
- `models/FarmAnimal` — farm animals.
- `models/CubeWorldKit` — additional animal/enemy/world pool including chicken/chick, dog, wolf, cat, raccoon, horse, sheep and pig candidates.
- `models/AnimatedFish` and `models/CuteFish` — aquatic population candidates.
- `models/UltimateMonsters`, `models/CuteMonsters`, `models/AnimatedMonster`, `models/AnimatedZombie`, `models/EasyEnemy` — enemies/creatures.
- `models/MedievalVillageMegaKit`, `models/MedievalVillage`, `models/ModularMedievalBuildings` — settlements and modular buildings.
- `models/FarmBuildings` — farm structures.
- `models/UltimateCrops` — crop/farming world dressing.
- `models/UltimateNature`, `models/StylizedNatureMegaKit`, `models/UltimateStylizedNature`, `models/SimpleNature`, `models/TexturedFantasyNature` — vegetation, rocks and nature dressing.
- `models/UltimateModularRuins`, `models/MedievalDungeon`, `models/ModularDungeon` — ruins/dungeons.
- `models/FantasyPropsMegaKit`, `models/UltimateFurniture`, `models/UltimateHomeInterior`, `models/UltimateFood` — props/interiors/food.
- `models/MedievalWeapons`, `models/KnightCharacter`, `models/RPGCharacters`, `models/UltimateModularCharacters`, `models/UltimateModularWomen`, `models/ModularCharacterOutfitsFantasy` — NPC/combat character building blocks.
- `models/UniversalAnimationLibrary`, `models/UniversalAnimationLibrary2`, `models/UniversalBaseCharacters` — character/animation source pool.
- `models/PirateKit` and `models/Ships` — docks/coastal/ship candidates when those regions are built.

Important format note: this mirror is OpenUSD-oriented. Main chat should prefer original Quaternius FBX/glTF downloads for final Godot integration when a direct original-format pack is available, and use this staged mirror as a broad CC0 source/index/backup rather than blindly importing every `.usda` file.

### `assets/source_packs/cc0tree`
Source: `SkywolfGameStudios/CC0Tree`
License: CC0 1.0 / public domain per repository README and LICENSE.
Pinned commit when staged: `15ebec49b7ef89f76396976dedc044db4a959fdb`.

The repository is an expanding low-poly FBX library. It currently includes lightweight props/environment pieces such as trees, tools and weapons and is explicitly intended for game-development use. Treat it as a supplemental pool, not as the primary art direction.

### `assets/source_packs/kaykit_prototype_bits`
Source: `KayKit-Game-Assets/KayKit-Prototype-Bits-1.0`
License: CC0 1.0.
Pinned commit when staged: `bb159596f4f5106b663741d002c8eb45c80c0f41`.

Contains 64+ optimized low-poly 3D models in OBJ/FBX/glTF. Use only for prototypes, distant LODs, temporary blockers or generic props where a better final asset is not already staged.

## Verified creature/animal sources

- Quaternius Ultimate Animated Animal Pack — 12 animated animals with 12+ animations each. Official tags identify bull, fox, horse, donkey, wolf, cow, deer/stag, llama/alpaca, husky and shiba-inu/dog candidates. FBX/OBJ/glTF/Blend, CC0.
- Quaternius Farm Animal Pack — 7 animated farm animals. Official tags identify pig, cow, horse, sheep, llama and pug/dog among the pack. FBX/OBJ/Blend, CC0.
- Quaternius Cube World Kit — 108 models; official tags include chick/chicken, dog, wolf, cat, raccoon, horse, sheep and pig, plus enemies/environment. FBX/OBJ/glTF/Blend, CC0.
- Quaternius Animated Fish Pack — 7 animated aquatic species; official tags include shark, whale, dolphin, clownfish and manta. FBX/OBJ/Blend, CC0.
- Quaternius Animated Cute Fish Pack — 52 models, with 50+ animated fish plus rods/lures; useful for rivers, lakes, sea and fishing systems. FBX/OBJ/Blend, CC0.

Not yet covered strongly enough by these verified packs: bear, wild boar, rabbit/hare, goose, duck, pigeon and some local forest birds. Continue searching before the main chat invents placeholders for those species.

## Verified farms / settlements / world props

- Quaternius Ultimate Crops Pack — 102 crop models with different crops represented across 5 growth stages; official tags include apple, lettuce, pumpkin, cactus, corn, watermelon, hay, mushroom and wheat. FBX/OBJ/Blend, CC0.
- Quaternius Farm Buildings Pack — 13 farm buildings/structures; official tags include windmill, well, stable and fence. FBX/OBJ/Blend, CC0.
- Quaternius Medieval Village Pack — 44 medieval buildings/props; official tags include blacksmith, tower, well, market and houses. FBX/OBJ/Blend, CC0.
- Quaternius Modular Medieval Building Pack — 30 modular medieval building pieces, CC0.
- Quaternius Ultimate RPG Pack — 106 RPG props/equipment useful for settlements, loot, shops and dungeons, CC0.
- Quaternius Ultimate Food Pack — 103 food/consumable models, useful for homes, taverns, kitchens and markets, CC0.

## Verified monsters / ruins / coastal sources

- Quaternius Ultimate Monsters — 50 fully animated monsters, FBX/OBJ/glTF/Blend, CC0.
- Quaternius Cute Animated Monsters — 21 animated/textured monsters, FBX/OBJ/glTF/Blend, CC0.
- Quaternius Ultimate Modular Ruins — 90 modular ruin/dungeon assets plus an animated character and props, CC0.
- Quaternius Pirate Kit — 71 models with animated pirate characters plus environmental assets; official tags include ships, skeletons, shark, cannon and dock. FBX/OBJ/glTF/Blend, CC0.
- Quaternius Ships Pack — 6 simple ships/boats; official tags include Viking-style boat, raft, sailboat and cruise ship candidates. FBX/OBJ/Blend, CC0.

## Additional verified CC0 sources to prefer for direct final-quality integration

- Kenney Castle Kit — 75 3D castle/medieval assets, CC0.
- Kenney Nature Kit — 330 3D nature files, CC0.
- Kenney Tower Defense Kit — 160 3D medieval/castle assets, CC0.
- Quaternius Ultimate Nature Pack — 150 nature models, CC0.
- Quaternius Stylized Nature MegaKit — 116 unique nature models including 40 trees, 35 plants/flowers and 27 rocks; FBX/OBJ/glTF; CC0.
- Quaternius Universal Animation Library 2 — 130+ humanoid animations covering combat, parkour, farming, fishing and more; Godot-ready retargeting versions are advertised by the creator; CC0.

## Main-chat integration order

1. Animals: horse/deer/wolf/fox/dogs/cats/farm animals first; add fish and ambient wildlife after land populations are stable.
2. Settlement architecture: staged KayKit medieval + Quaternius Medieval Village/MegaKit; avoid generating generic placeholder houses when a usable staged model exists.
3. Nature: establish one coherent tree/rock/grass family per biome instead of mixing every pack indiscriminately.
4. Farms: farm buildings + growth-stage crops + farm animals + food/market props.
5. Ruins/dungeons: use modular ruin/dungeon packs selectively; maintain collision/navmesh budgets.
6. NPC/enemy variety: modular humanoid/outfit sources + animation libraries + staged monster sources; share skeletons/animation sets where practical.
7. Coasts/water: use fish, Pirate Kit and ships when coastal/river regions are ready rather than loading them into early land-only milestones.
8. Performance: do not import whole mega-packs into active scenes. Copy/select only required assets, generate LODs where needed, use instancing/culling and keep source packs outside runtime wiring.

## License / provenance rule

Keep original LICENSE/README/source URL with any asset copied out of a source pack. Never relabel a source-only mirror or third-party conversion as original project art. If an asset's license/provenance is unclear, do not integrate it until verified.

## Ownership boundary

This research chat only stages/searches/catalogues assets. The main game-development chat owns Godot import settings, material conversion, retargeting, collisions, navigation, LODs, world placement and stability testing.
