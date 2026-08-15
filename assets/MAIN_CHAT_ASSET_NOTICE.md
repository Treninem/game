# MAIN GAME CHAT — ASSET NOTICE

Updated: 2026-08-15

The asset-research flow has prepared a verified NPC/model/material selection for ImPuls and physically staged several CC0 source packs as Git submodules.

## Mandatory action for the main game-development chat

Before creating replacement NPCs, generic citizens, fantasy humanoids, crowd characters, dungeon props, furniture, wooden/stone/cobblestone materials or duplicate placeholder art, read:

- `assets/registry/NPC_MODELS_TEXTURES_LIBRARY_2026-08-15.md`
- `assets/registry/KAYKIT_STAGED_SOURCE_PACKS_2026-08-15.md`

Use the verified library first where it fits the current art direction. Main chat remains responsible for actual Godot integration, retargeting, LOD/culling, collisions/navigation, material tuning and stability testing.

## Already staged as source submodules

- `assets/source_packs/kaykit_character_pack_adventures`
- `assets/source_packs/kaykit_character_pack_skeletons`
- `assets/source_packs/kaykit_dungeon_remastered`
- `assets/source_packs/kaykit_furniture_bits`

These are source-library assets only. Initialize/update the repository submodules when needed, inspect the free/CC0 files, and selectively integrate only what matches the current stable milestone.

## Important ownership boundary

This asset-research chat DOES NOT edit or wire:
- `project.godot`
- `scripts/`
- `scenes/`
- autoload/runtime configuration
- quests/gameplay/world assembly

Do not treat staged/researched assets as automatically integrated. Integrate them deliberately from the main game-development flow and keep each stable milestone working.

## Current priority

1. Quaternius Modular Men + Modular Women for reusable town/village NPC variation.
2. Quaternius Ultimate Animated Character Pack for broader civilian/background population.
3. Quaternius RPG characters for guards/adventurers/bandits/fantasy roles.
4. KayKit Adventurers for animated combat/quest NPCs and KayKit Skeletons for undead enemies.
5. KayKit Dungeon Remastered + Furniture Bits for underground locations and interiors.
6. Kenney Blocky Characters as low-cost crowd/prototype/LOD fallback.
7. Poly Haven Medieval Wood, Medieval Wall 02 and Cobblestone Floor 001 for coherent settlement materials.

The main chat should reuse these before generating duplicate resources.
