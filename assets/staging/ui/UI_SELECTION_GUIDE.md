# UI Selection Guide — source-only staging

This file is guidance for the main integration chat. It does **not** mean the assets are integrated into gameplay.

## Recommended production direction

For the main open-world RPG interface, prefer a restrained adventure/fantasy style rather than mixing every staged pack.

### Main menus and settings
- Primary structure: `kenney_ui_pack_adventure/`.
- Neutral/system controls when needed: `kenney_ui_pack/`.
- Input hints: `kenney_input_prompts/`.
- Mouse pointers: `kenney_cursor_pack/`.

Keep the number of button styles on one screen low. Use one family for normal/hover/pressed/disabled states.

### World map and minimap
- Base/background candidates: `parchment_map_texture/` or `fantasy_map_scroll/`.
- Compass/navigation: `compass_rose/`.
- Point markers: `map_marker_normal/`, `map_marker_active/`.
- City/faction/map symbol reserve: `fantasy_units_skills_icons/`.
- Compact utility glyphs: `map_editor_ui_icons/`.
- Alternate minimap frame reference: `tiny_rpg_dragon_regalia_gui/`.

Do not bake gameplay geography into these source images; they are presentation assets only.

### HUD
- Health/mana/energy candidate: `health_mana_ui/`.
- Health/breath variants for swimming/underwater states: `health_breath_bars/`.
- Experience/progression: `experience_bar/`.
- Quest/new-objective marker: `quest_exclamation_icon/`.

HUD should remain visually lighter than inventory/map screens so it does not cover the 3D world.

### Inventory, equipment and crafting
- Layout reference/frames: `rpg_inventory/`.
- High-resolution fantasy item icons: `fantasy_rpg_icons_handpainted/` and `fantasy_rpg_icons_handpainted_2/`.
- Additional equipment/crafting icons: `rpg_inventory_icons/`.
- Large fallback icon library: `rpg_496_icons/`.
- Status/magic/system icons: `rpg_ui_icons/`.

Prefer the hand-painted 128x128 family when visual quality matters. Use pixel libraries only if the selected production style supports them or as temporary/fallback coverage.

### Journal, quests, codex and lore
- Open-book background: `epic_book_ui/`.
- Scroll/panel background: `scroll_ui_container/`.
- Document/map/calendar icons: `document_icons_scalable/`.
- Parchment buttons/panels/labels/slots: `parchment_gui/`.

### Skills, factions, settlements and strategic screens
- `fantasy_units_skills_icons/` contains faction, city, unit and skill icon coverage.
- `rpg_ui_icons/` provides compact status/magic/equipment symbols.
- `rpg_496_icons/` is a broad reserve for missing categories.

## Style groups

### Group A — preferred adventure / hand-painted
Use together where possible:
- `kenney_ui_pack_adventure/`
- `fantasy_rpg_icons_handpainted/`
- `fantasy_rpg_icons_handpainted_2/`
- `scroll_ui_container/`
- `epic_book_ui/`
- `fantasy_map_scroll/`
- `compass_rose/`

### Group B — neutral utility
Good for settings, prompts and generic controls:
- `kenney_ui_pack/`
- `kenney_game_icons/`
- `kenney_board_game_icons/`
- `kenney_input_prompts/`
- `kenney_cursor_pack/`
- `map_marker_normal/`
- `map_marker_active/`

### Group C — pixel / fallback / reference
Keep as fallback or use only if the chosen production UI becomes pixel-styled:
- `tiny_rpg_dragon_regalia_gui/`
- `parchment_gui/`
- `rpg_496_icons/`
- `fantasy_units_skills_icons/`
- `map_editor_ui_icons/`

## Integration rule

The main integration chat should copy/select only the assets needed by a screen. Never load or wire the whole `assets/staging/ui/` tree directly into gameplay. Normalize naming, margins, scale, nine-patch slicing and icon sizing during production integration, not in this source-only staging chat.
