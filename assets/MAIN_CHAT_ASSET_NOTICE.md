# MAIN GAME CHAT — ASSET NOTICE

Updated: 2026-08-15

The asset-research flow has prepared a verified NPC/model/material selection for ImPuls.

## Mandatory action for the main game-development chat

Before creating replacement NPCs, generic citizens, fantasy humanoids, crowd characters, wooden/stone/cobblestone materials or duplicate placeholder art, read:

`assets/registry/NPC_MODELS_TEXTURES_LIBRARY_2026-08-15.md`

Use the verified library first where it fits the current art direction. Main chat remains responsible for actual Godot integration, retargeting, LOD/culling, collisions/navigation, material tuning and stability testing.

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
4. Kenney Blocky Characters as low-cost crowd/prototype/LOD fallback.
5. Poly Haven Medieval Wood, Medieval Wall 02 and Cobblestone Floor 001 for coherent settlement materials.

The main chat should reuse these before generating duplicate resources.
