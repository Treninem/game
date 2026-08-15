# World infrastructure / creatures / cave / water expansion — 2026-08-16 D

Purpose: source-only asset research for ImPuls. This chat must not modify runtime code, scenes, `project.godot`, quests or world wiring.

## Newly staged broad source registry

### `assets/source_packs/open_source_3d_registry`
Source: `ToxSam/open-source-3D-assets`
Pinned commit when staged: `c0496c867dfa232ee5dc7ee631133d2753cf6285`.

This repository is a CC0 metadata registry of open 3D collections and includes direct model links, preview metadata, file formats and per-collection license data. The registry itself is CC0. Individual assets must still be checked through `projects.json` before integration.

High-value CC0 collections described by the registry include Polygonal Mind Medieval Fair, towers, ruins/environment sets and creature collections. Use this source as a discovery/index layer, not as automatic approval for every linked asset.

## Direct CC0 packs verified for ImPuls

### Caves / mines

- Kenney Modular Cave Kit — 40 modular 3D cave files, CC0. Source: `https://kenney.nl/assets/modular-cave-kit`
- OpenGameArt `mines and cave set` by loafbrr_1 — 178 objects; modular cave/mine system; 1K textures; Blend + GLB + FBX; Godot setup included; CC0. Source: `https://opengameart.org/content/mines-and-cave-set`
- OpenGameArt `Low poly cave assets` — stalactites, stalagmites, pillars, cave stones and texture; OBJ; CC0. Source: `https://opengameart.org/content/low-poly-cave-assets`
- OpenGameArt `free mine assets pack` — 35+ wooden support pieces plus stones, stalactites/stalagmites, rail system, lamps, treasure chest, minecart and coins; CC0. Source: `https://opengameart.org/node/27105`
- OpenGameArt `LowPoly Cave Entrance` — dedicated low-poly cave entrance pack; CC0. Source: `https://opengameart.org/content/lowpoly-cave-entrance`

Preferred main-chat order: use the 178-object loafbrr modular set for actual mine/cave locations, Kenney Modular Cave for clean modular fallback/LOD, then smaller OGA packs for variation.

### Castles / walls / medieval towns

- Kenney Castle Kit — 75 castle/medieval 3D files including siege assets; CC0. Source: `https://kenney.nl/assets/castle-kit`
- Kenney Tower Defense Kit — 160 medieval/castle files; CC0. Source: `https://kenney.nl/assets/tower-defense-kit`
- Kenney Fantasy Town Kit — 160 medieval wall/town/building files; CC0. Source: `https://kenney.nl/assets/fantasy-town-kit`
- Kenney Retro Fantasy Kit — 100 medieval/castle/building/town files; CC0. Source: `https://kenney.nl/assets/retro-fantasy-kit`
- Quaternius Medieval Village Pack — 44 medieval buildings/props; FBX/OBJ/Blend; CC0. Source: `https://quaternius.com/packs/medievalvillage.html`
- Quaternius Medieval Village MegaKit and Modular Medieval Buildings are already available through `quaternius_cc0_stage` as source/index candidates.
- LoFi3D Castle by Philip_Erd — castle construction pieces plus example castle; GLB/FBX/Blend; CC0. Source: `https://philip-erd.itch.io/lofi3d-castle`

Do not mix all visual styles inside one settlement. Pick one family per city/village/castle and use the others for distant settlements, ruins, dungeons or LOD/background architecture.

### Boats / docks / coast

- Kenney Watercraft Kit — 45 boat/ship/watercraft 3D files; CC0. Source: `https://kenney.nl/assets/watercraft-kit`
- Kenney Pirate Kit — 70 3D files, animated, includes pirate/boat/island/fortress content; CC0. Source: `https://kenney.nl/assets/pirate-kit`
- Quaternius Ships Pack — 6 simple ships, FBX/OBJ/Blend, CC0. Source: `https://quaternius.com/packs/ships.html`
- `quaternius_cc0_stage/models/PirateKit` and `/Ships` are already staged source candidates.

Use rowboats/small craft first for rivers/lakes, then fishing/sailing vessels for coast and harbors. Keep large ship scenes streamed separately.

### Camps / roads / travel props

- Kenney Survival Kit — 80 3D survival/nature assets, animated; CC0. Source: `https://kenney.nl/assets/survival-kit`
- Quaternius Survival Pack — 53 survival assets, FBX/OBJ/Blend, CC0. Source: `https://quaternius.com/packs/survival.html`
- KayKit Medieval Hexagon is already staged and includes roads, water/river pieces, bridge/building/settlement assets.
- Quaternius Medieval Village/MegaKit should be preferred for carts/wagons/fences/market props where the required model exists.
- OpenGameArt `Low Poly Cart` — simple low-poly cart in Blend format; CC0. Source: `https://opengameart.org/content/low-poly-cart`
- OpenGameArt `Handwagon` — wagon in DAE + OBJ with AO textures; CC0. Source: `https://opengameart.org/content/handwagon`

### Dungeons / graveyards / dark locations

- Kenney Modular Dungeon Kit — 40 modular dungeon files, animated + variants; CC0. Source: `https://kenney.nl/assets/modular-dungeon-kit`
- Kenney Mini Dungeon — 25 3D RPG/dungeon/medieval files with animations/variants; CC0. Source: `https://kenney.nl/assets/mini-dungeon`
- Kenney Graveyard Kit — 90 spooky/graveyard 3D files with animation; CC0. Source: `https://kenney.nl/assets/graveyard-kit`
- Quaternius Ultimate Modular Ruins — 90 modular ruins/dungeon assets; already verified and represented in staged Quaternius source.
- KayKit Dungeon Remastered and Halloween Bits are already staged as direct source submodules.

### Animals / birds / ambient life

Primary coherent source remains Quaternius `UltimateAnimatedAnimals` + `FarmAnimal`, already staged in the broad Quaternius source tree.

Additional verified CC0 fallback sources:

- Mordrag `Low Poly Animals` — low-poly animal bundle including elephant, rabbit, sheep and wolf; Blend; CC0. Source: `https://mordrag.itch.io/low-poly-animals`
- Vertexcat `Farm animals set` — duck, chicken, cow, pig and sheep, each below ~900 tris; CC0. Source: `https://vertexcat.itch.io/farm-animals-set`
- Plewr `3D Goose` — free CC0 goose, static + rigged Blend. Source: `https://plewr.itch.io/goose`
- Plewr `3D Call Duck` — free CC0 low-poly duck pack. Source: `https://plewr.itch.io/call-duck`
- OpenGameArt `CC0 - 3D Animals / Creatures` collection — rabbit, deer, raven, butterfly, rooster, chicken, wolf, fish and many more CC0 candidates. Source: `https://opengameart.org/content/cc0-3d-animals-creatures`
- OpenGameArt `Boar` — ~1K tris, rigged + textured, walk and attack animations; CC0. Source: `https://opengameart.org/content/boar`
- OpenGameArt `Low poly 3D Pigeon` — rigged + animated pigeon; CC0. Source: `https://opengameart.org/content/low-poly-3d-pigeon-model-rigged-animated-untextured`
- OpenGameArt `Frog low poly animated 3d model` — 600 triangles, rigged + animated; CC0. Source: `https://opengameart.org/content/frog-low-poly-animated-3d-model`
- OpenGameArt `Butterfly (animated)` — low-poly, rigged, animated and textured butterfly; CC0. Source: `https://opengameart.org/content/butterfly-animated`
- OpenGameArt `Ant 3D Model + Rigging + Animated` — animated low-poly ant; CC0. Source: `https://opengameart.org/content/ant-3d-model-rigging-animated-low-poly-ish`

Use these only when the main Quaternius animal style does not contain a required species or when low-cost ambient variants are needed.

## Main-chat implementation priority

1. Build one stable mine/cave prototype using loafbrr 178-object cave/mine set or Kenney Modular Cave Kit.
2. Establish castle/town architecture from one coherent family instead of placeholder primitives.
3. Add small boats and docks before large ships.
4. Add road/travel props: carts/wagons, signs, campfires, fences and bridges.
5. Fill graveyards/ruins/dungeons from staged modular packs.
6. Add missing ambient species only after primary animal AI/LOD is stable: boar -> pigeon/raven -> frog -> butterfly/insects.
7. Never bulk-import entire libraries into active Godot scenes. Select only needed files and preserve source/license metadata.

## License and safety rule

Only integrate assets with explicit CC0 or another license intentionally approved for the project. A registry entry is not enough by itself: verify the individual collection/model license before copying it into runtime assets. Preserve original README/LICENSE/source information.

## Ownership boundary

This research chat only searches, verifies, stages and catalogues asset sources. Main game-development chat owns Godot imports, material conversion, animations, collisions, navigation, LODs, occlusion/culling, world placement and testing.
