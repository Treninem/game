# ImPuls — physically staged KayKit source packs

Date: 2026-08-15
Mode: source-library only; main game chat owns integration.

The following upstream CC0 packs are now registered as Git submodules under `assets/source_packs/`. They are real source-pack references pinned to upstream commits, not just research links.

## 1. `kaykit_character_pack_adventures`
Upstream: `KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0`
Pinned commit: `672074b73ba276876a19e8816ecdc5241817ab47`
License: CC0 1.0 Universal.
Contents verified from upstream README:
- 4 free fully textured, rigged and animated dungeon/adventure characters;
- 75 animations;
- 25+ weapons/accessories;
- FBX + glTF;
- shared 1024×1024 gradient atlas texture.
Recommended use: adventurers, guards, bandits, quest NPCs, combat prototypes and animation source.

## 2. `kaykit_character_pack_skeletons`
Upstream: `KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0`
Pinned commit: `15b62b9bad122f72926c10fb14d622c73819fa54`
License: CC0 1.0 Universal.
Contents verified from upstream README:
- 4 free fully textured, rigged and animated skeleton characters;
- 90+ animations;
- 10+ weapons/accessories;
- FBX + glTF;
- shared 1024×1024 gradient atlas texture.
Recommended use: dungeon enemies, undead encounters, ruins, necromancy areas and combat testing.

## 3. `kaykit_dungeon_remastered`
Upstream: `KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0`
Pinned commit: `b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07`
License: CC0 1.0 Universal.
Contents verified from upstream README:
- 200+ stylized dungeon assets and props;
- walls, floors, stairs and doors;
- chests, barrels, chairs, tables, crates, traps, banners and more;
- modular low-poly layout;
- FBX + glTF + OBJ;
- 1024×1024 gradient atlas texture.
Recommended use: dungeons, cellars, ruins, mines, fort interiors and underground locations.

## 4. `kaykit_furniture_bits`
Upstream: `KayKit-Game-Assets/KayKit-Furniture-Bits-1.0`
Pinned commit: `96d5930a8dbdb363409bbc2d3341718b00e17c9c`
License: CC0 1.0 Universal.
Contents verified from upstream README:
- 50+ optimized low-poly furniture models;
- OBJ + FBX + glTF;
- 1024×1024 gradient atlas texture.
Recommended use: houses, taverns, shops, workshops, inns, NPC homes and general interior dressing.

## Main-chat rule

Do not wire these packs into runtime from the research chat. Main game-development chat should initialize/update the submodules, inspect the free-tier files, then selectively copy/import only the assets required for the current stable milestone.

Normalize scale, materials, collision and LOD before production placement. Reuse the shared animation/material families rather than duplicating assets per NPC or room.
