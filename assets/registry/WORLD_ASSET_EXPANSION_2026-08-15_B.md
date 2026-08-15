# ImPuls — World Asset Expansion B

Updated: 2026-08-15

Asset-research only. This file does not integrate anything into gameplay and does not authorize edits to `project.godot`, `scripts/` or `scenes/` from the asset-research chat.

## Physically staged CC0 source packs

The following packs are present in the repository as Git submodules under `assets/source_packs/` and are available for the main game-development flow to inspect/import deliberately.

### KayKit Medieval Hexagon Pack
Path: `assets/source_packs/kaykit_medieval_hexagon`
Source: https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0
License: CC0 1.0
Coverage: 200+ stylized medieval models including roads, rivers, lakes/coasts, blacksmith, lumbermill, church, tavern, market, windmill, watermill, mine, well, houses, barracks, archery range, trees, rocks, hills, mountains and clouds.
Recommended use: settlement planning/reference, distant settlement LOD, map/strategic representation, reusable medieval props where art direction fits.

### KayKit Restaurant Bits
Path: `assets/source_packs/kaykit_restaurant_bits`
Source: https://github.com/KayKit-Game-Assets/KayKit-Restaurant-Bits-1.0
License: CC0 1.0
Coverage: 140+ optimized 3D cooking, kitchen and food models, including ingredient/state variations.
Recommended use: taverns, inns, homes, kitchens, markets, food stalls, crafting/cooking props.

### KayKit City Builder Bits
Path: `assets/source_packs/kaykit_city_builder_bits`
Source: https://github.com/KayKit-Game-Assets/KayKit-City-Builder-Bits-1.0
License: CC0 1.0
Coverage: 32+ optimized city-building models in OBJ/FBX/GLTF.
Recommended use: generic infrastructure/settlement props only where visual style matches. Do not force modern-looking pieces into medieval areas.

### KayKit Halloween Bits
Path: `assets/source_packs/kaykit_halloween_bits`
Source: https://github.com/KayKit-Game-Assets/KayKit-Halloween-Bits-1.0
License: CC0 1.0
Coverage: 60+ low-poly models for graveyards/crypt/spooky areas; GLTF/FBX/OBJ.
Recommended use: cemeteries, ruins, cursed zones, crypt exteriors, dead vegetation and atmospheric props.

## Verified priority sources — not yet physically staged

These are verified against their primary creator pages. Main chat may use them once their free distribution files are staged with source/license metadata.

### Quaternius Medieval Village MegaKit
Source: https://quaternius.com/packs/medievalvillagemegakit.html
License: CC0
Coverage: 304 models; free tier contains roughly 60–70% of the pack. Modular roofs, walls, floors, stairs, doors, windows, vines and related village pieces. FBX/OBJ/glTF. Creator states Godot 4.3+ compatibility for the source implementation.
Priority: VERY HIGH for towns/villages.

### Quaternius Stylized Nature MegaKit
Source: https://quaternius.com/packs/stylizednaturemegakit.html
License: CC0
Coverage: 116 models: about 40 trees, 35 plants/flowers, 27 rocks plus grass/bushes and variants. FBX/OBJ/glTF; creator provides a Godot implementation in the source tier.
Priority: VERY HIGH for forests, fields, roadsides and settlement vegetation.

### Quaternius Ultimate Nature Pack
Source: https://quaternius.com/packs/ultimatenature.html
License: CC0
Coverage: 150 nature models.
Priority: HIGH for broad biome variety and distant/secondary vegetation.

### Kenney Nature Kit
Source: https://kenney.nl/assets/nature-kit
License: CC0
Coverage: 330 3D files for trees, rocks and foliage.
Priority: VERY HIGH for performant low-poly nature and LOD fallback.

### Kenney Survival Kit
Source: https://kenney.nl/assets/survival-kit
License: CC0
Coverage: 80 3D files; animated content included.
Priority: HIGH for camps, wilderness props and survival areas.

## Animals and ecology

### Quaternius Ultimate Animated Animal Pack
Source: https://quaternius.com/packs/ultimateanimatedanimals.html
License: CC0
Coverage: 12 animals, each with 12+ animations such as walk, gallop, jump, attack, kick and death. FBX/OBJ/glTF/Blend.
Priority: VERY HIGH for horses, cattle, deer/wildlife and ambient ecology.

### Quaternius Farm Animal Pack
Source: https://quaternius.com/packs/farmanimal.html
License: CC0
Coverage: 7 animated farm animals.
Priority: VERY HIGH for villages, farms and markets.

### Kenney Cube Pets
Source: https://kenney.nl/assets/cube-pets
License: CC0
Coverage: 24 files, animated cats/dogs/pets.
Priority: MEDIUM as a stylized/LOD fallback if art direction permits.

## NPCs and animation

### Quaternius Universal Base Characters
Source: https://quaternius.com/packs/universalbasecharacters.html
License: CC0
Coverage: 6 game-ready base humans in male/female teen/regular/superhero proportions, 20 hairstyles, humanoid rig, average around 13k triangles, FBX/glTF.
Priority: VERY HIGH for scalable civilian population.

### Quaternius Modular Character Outfits — Fantasy
Source: https://quaternius.com/packs/modularcharacteroutfitsfantasy.html
License: CC0
Coverage: 12 outfits built from 62 modular parts, 3 texture variants per outfit, humanoid rig and compatibility with Universal Base Characters/Animation Library.
Priority: VERY HIGH for guards, peasants, merchants, adventurers and role variation.

### Quaternius Universal Animation Library 2
Source: https://quaternius.com/packs/universalanimationlibrary2.html
License: CC0
Coverage: 130+ humanoid animations for melee/armed combos, parkour, farming, fishing, zombie locomotion and more; explicitly intended for retargeting in Godot/Unity/Unreal.
Priority: VERY HIGH.

### Quaternius Ultimate Animated Character Pack
Source: https://quaternius.com/packs/ultimatedanimatedcharacter.html
License: CC0
Coverage: 50+ animated characters.
Priority: HIGH for crowd/background population after style and skeleton compatibility checks.

### Quaternius RPG Character Pack
Source: https://quaternius.com/packs/rpgcharacters.html
License: CC0
Coverage: 6 rigged, animated, textured fantasy characters.
Priority: HIGH for guards/adventurers/enemies/NPC role prototypes.

## Materials physically prepared for later repository import

Verified Poly Haven CC0 sources matching locally prepared 1K texture sets:
- Cobblestone Floor 001 — https://polyhaven.com/a/cobblestone_floor_001
- Medieval Wall 02 — https://polyhaven.com/a/medieval_wall_02
- Medieval Wood — https://polyhaven.com/a/medieval_wood

Prepared maps include diffuse, OpenGL normal and roughness at 1K. These should be imported under a dedicated materials folder with source/license metadata when binary upload is performed. Do not regenerate duplicates first.

## Main-chat selection order

1. Use staged KayKit packs immediately where they match the art direction.
2. For villages/buildings, prioritize Quaternius Medieval Village MegaKit before procedural placeholder buildings.
3. For forests/fields, prioritize Quaternius Stylized Nature MegaKit + Kenney Nature Kit, then add LOD tiers.
4. For farms/wildlife, prioritize Quaternius animated animal packs.
5. For large civilian populations, combine Universal Base Characters + Fantasy Outfits + Universal Animation Library 2.
6. Preserve source/license metadata for every physical import.
7. Main game-development flow owns integration, retargeting, collisions, navigation, LOD/culling, shader/material tuning and final stability tests.
