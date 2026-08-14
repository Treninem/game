# ImPuls Game — Shared Asset Pack Registry

This file is the canonical asset registry for all development chats working on this game.

## Rule for every development chat
Before generating a replacement asset, check this registry and the `assets/` tree. Reuse suitable existing assets first. New imported assets must have a compatible license and their source/license must be recorded here.

## Approved CC0 packs

### Nature
- Kenney Nature Kit — 330 3D files — CC0 1.0
  Source: https://kenney.nl/assets/nature-kit
  Target: `assets/nature/kenney_nature_kit/`
- Kenney Survival Kit — 80 3D files — CC0 1.0
  Source: https://kenney.nl/assets/survival-kit
  Target: `assets/nature/kenney_survival_kit/`
- Quaternius Ultimate Fantasy RTS — 128 models, includes nature/buildings — CC0
  Source: https://quaternius.com/packs/ultimatefantasyrts.html
  Target: `assets/environment/quaternius_fantasy_rts/`

### Buildings
- Quaternius Ultimate Buildings Pack — 76 modular textured buildings — CC0
  Source: https://quaternius.com/packs/ultimatetexturedbuildings.html
  Target: `assets/buildings/quaternius_ultimate_buildings/`
- Quaternius Buildings Pack — 9 buildings — CC0
  Source: https://quaternius.com/packs/buildings.html
  Target: `assets/buildings/quaternius_buildings/`
- Quaternius Farm Buildings Pack — 13 buildings — CC0
  Source: https://quaternius.com/packs/farmbuildings.html
  Target: `assets/buildings/quaternius_farm_buildings/`

### Animals
- OpenGameArt CC0 3D Animals collection
  Source: https://opengameart.org/content/3d-animals-under-cc0
  Target: `assets/animals/opengameart_cc0/`
- OpenGameArt CC0 3D Animals / Creatures collection
  Source: https://opengameart.org/content/cc0-3d-animals-creatures
  Target: `assets/animals/opengameart_cc0_creatures/`

### UI
- Kenney UI Pack — 430 UI assets — CC0 1.0
  Source: https://kenney.nl/assets/ui-pack
  Target: `assets/ui/kenney_ui_pack/`
- Kenney UI Pack Adventure — 130 UI assets — CC0 1.0
  Source: https://kenney.nl/assets/ui-pack-adventure
  Target: `assets/ui/kenney_ui_adventure/`
- Kenney UI Pack RPG Expansion — 85 UI assets — CC0 1.0
  Source: https://kenney.nl/assets/ui-pack-rpg-expansion
  Target: `assets/ui/kenney_ui_rpg/`

## License policy
Prefer CC0 assets. Do not import assets with unclear redistribution/commercial-use rights. Preserve original license/readme files when importing packs.

## Integration priority
1. Nature/environment
2. Buildings and settlements
3. Animals/creatures
4. Game HUD, inventory, map, settings and save/load UI

This registry is intentionally stored in the repository so any ChatGPT/Codex development session that opens `Treninem/game` can discover and use the same asset sources.