# MAIN GAME CHAT — ASSET NOTICE

Updated: 2026-08-15

The asset-research flow has prepared a verified NPC/model/material/world selection for ImPuls and physically staged multiple CC0 source packs as Git submodules.

## Mandatory action for the main game-development chat

Before creating replacement NPCs, generic citizens, fantasy humanoids, crowd characters, animals, farm content, village buildings, dungeon/ruin props, furniture, nature props or duplicate placeholder art, read:

- `assets/registry/NPC_MODELS_TEXTURES_LIBRARY_2026-08-15.md`
- `assets/registry/KAYKIT_STAGED_SOURCE_PACKS_2026-08-15.md`
- `assets/registry/WORLD_ASSET_EXPANSION_2026-08-15_B.md`
- `assets/registry/CC0_WORLD_CREATURES_EXPANSION_2026-08-15_C.md`

Use the verified/staged library first where it fits the current art direction. Main chat remains responsible for actual Godot integration, retargeting, LOD/culling, collisions/navigation, material tuning and stability testing.

## Staged source submodules

KayKit:
- `assets/source_packs/kaykit_character_pack_adventures`
- `assets/source_packs/kaykit_character_pack_skeletons`
- `assets/source_packs/kaykit_dungeon_remastered`
- `assets/source_packs/kaykit_furniture_bits`
- `assets/source_packs/kaykit_medieval_hexagon`
- `assets/source_packs/kaykit_restaurant_bits`
- `assets/source_packs/kaykit_city_builder_bits`
- `assets/source_packs/kaykit_halloween_bits`
- `assets/source_packs/kaykit_prototype_bits`

Additional CC0 source libraries:
- `assets/source_packs/quaternius_cc0_stage` — broad OpenUSD mirror/index of Quaternius CC0 packs; includes animated animals, farm animals, fish, monsters, villages, farm buildings, crops, nature, ruins, dungeons, fantasy props, characters and animation libraries. Prefer original Quaternius FBX/glTF for final import when available.
- `assets/source_packs/cc0tree` — expanding lightweight CC0 FBX props/environment library.

These are source-library assets only. Initialize/update repository submodules when needed, inspect licenses/source notes, and selectively integrate only what matches the current stable milestone.

## Important ownership boundary

This asset-research chat DOES NOT edit or wire:
- `project.godot`
- `scripts/`
- `scenes/`
- autoload/runtime configuration
- quests/gameplay/world assembly

Do not treat staged/researched assets as automatically integrated. Integrate them deliberately from the main game-development flow and keep each stable milestone working.

## Current priority

1. Populate land wildlife and farm animals from Quaternius sources; start with horse/deer/wolf/fox and common farm animals.
2. Build settlements from KayKit Medieval Hexagon plus Quaternius Medieval Village/MegaKit and modular medieval buildings before generating generic replacement houses.
3. Establish coherent biome nature sets from Quaternius Stylized Nature/Ultimate Nature and Kenney Nature Kit; do not mix every pack randomly.
4. Use farm buildings + crops + farm animals + food/market props for believable villages and countryside.
5. Use modular ruins/dungeons selectively for exploration locations.
6. Use Quaternius modular/base characters and animation libraries plus KayKit Adventurers/Skeletons for NPC/enemy variety.
7. Keep Poly Haven medieval PBR materials as the preferred realistic material source where stylized atlas materials are not appropriate.
8. Treat prototype packs only as placeholders/LOD/blockout sources, not automatic final art.

Reuse verified/staged resources before generating duplicates.
