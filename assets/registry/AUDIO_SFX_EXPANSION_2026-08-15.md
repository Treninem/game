# Audio SFX expansion — 2026-08-15

Asset-library update only. Nothing in this document or the linked packs is wired into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## Newly pinned pack: Kenney RPG Audio
- Status: `PINNED_VENDOR`
- Path: `assets/audio/third_party/kenney_rpg_audio/`
- Upstream: `Boyquotes/kenney-rpg-audio-for-godot`
- Pinned commit: `22eb79bb843bbcadcaa6ed119353a33265ffad11`
- License: CC0 1.0 Universal (`LICENSE` in upstream root).
- Real OGG coverage includes belt/equipment handling, books, chopping, cloth and cloth+belt Foley, creaks, doors opening/closing, knife draws, leather drops, footsteps and other RPG/world interactions.

## Confirmed material packs in the already pinned bulk CC0 library
Source path: `assets/audio/source_packs/cc0_public_domain_sounds/` pinned at `f2b6264f9ab89fabc266914c3654685d68c5a39b`.

Audited this pass:
- `25-CC0-bang-sfx/` — 25 real OGG bang/explosion-style one-shots.
- `25-CC0-mud-sfx/` — 25 real OGG wet/mud interaction sounds.
- `40-cc0-water-splash-slime-sfx/` — real OGG bubbles, rain/water loops, splashes and liquid/slime interactions.

These remain inside the pinned source-library submodule to avoid duplicating hundreds of binary files in the core game Git history. The main game-development flow may later select only production-ready variants.

## Recommended semantic groups for later integration
- `FOLEY_CLOTH_LIGHT`, `FOLEY_GEAR`, `FOLEY_BOOK`, `FOLEY_LEATHER`
- `DOOR_WOOD_OPEN`, `DOOR_WOOD_CLOSE`, `WOOD_CREAK`
- `WEAPON_KNIFE_DRAW`, `TOOL_CHOP`
- `FOOTSTEP_GENERIC`, `FOOTSTEP_MUD`
- `EXPLOSION_SMALL`, `EXPLOSION_MEDIUM`, `DISTANT_BANG`
- `WATER_BUBBLE`, `WATER_SPLASH`, `WATER_FLOW_LOOP`, `RAIN_LOOP`

Do not bind gameplay to source filenames. Select/normalize variants in the main integration flow after listening tests.
