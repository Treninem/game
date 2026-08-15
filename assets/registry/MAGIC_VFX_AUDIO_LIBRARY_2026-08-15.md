# Magic VFX + Audio Library Index — 2026-08-15

Purpose: shared discovery map for development chats/agents. This document describes **staged library assets only**. It does not authorize or perform automatic gameplay integration.

## Current expansion in this pass

This pass adds 520 staged asset-library files (excluding vendor workflow YAML):

- 383 files — expanded OpenGameArt CC0 magic tier 2.
- 20 files — cleaned ritual/barrier/summoning library.
- 88 files — elemental weapon effects + dark magic icons.
- 7 files — modern CC0 Godot 4 procedural portal/gravity/glow shader library.
- 22 files — CC0 spell audio library, including 12 actual audio files.

Every imported third-party folder preserves source/license metadata. Vendor jobs use safe fetch/rebase/normal-push retries and do not force-push concurrent work.

## Fast selection by gameplay concept

### Portal / teleport / warp
Prefer:
- `assets/vfx/third_party/oga_teleport_circle/`
- `assets/vfx/third_party/oga_teleporter_volumetric_blue/`
- `assets/vfx/third_party/oga_teleporter_volumetric_edited/`
- `assets/vfx/third_party/godotshaders_portal_cc0/portal_2d.gdshader`
- `assets/vfx/third_party/godotshaders_portal_cc0/pixelated_stencil_portal.gdshader`
- audio: `assets/audio/third_party/oga_magic_cc0/teleport/`

Use the sprites for authored portal animation, the shader code for procedural variants, and the audio only after the main integration flow chooses the final semantic event.

### Time / cosmic / stasis
Prefer:
- `assets/vfx/third_party/oga_cosmic_time_magic/`

Contains multiple clock/vortex/cosmic effects suitable for time stop, time travel, temporal charge, phase shift and cosmic teleport visuals.

### Gravity / void / black hole
Prefer:
- `assets/vfx/third_party/godotshaders_portal_cc0/black_hole_3d.gdshader`
- `assets/vfx/third_party/godotshaders_portal_cc0/black_hole_2d.gdshader`
- existing Binbun Dark Magic: `assets/vfx/third_party/binbun_godot4_combat_magic/DarkMagicFX/`

### Summoning / ritual / traps
Prefer:
- `assets/vfx/third_party/oga_summoning_circles_vector/` — four scalable circles with PNG/SVG/AI sources.
- `assets/vfx/third_party/oga_fire_trap_rune/`
- `assets/vfx/third_party/oga_fire_circle_fx/`
- `assets/vfx/third_party/oga_cc0_rune_icons/`
- `assets/vfx/third_party/oga_runes_2d/`

The summoning archive is sanitized: macOS metadata is excluded and source file modes are normalized.

### Barriers / shields / protection
Prefer:
- `assets/vfx/third_party/oga_magic_barrier_gfroad/`
- `assets/vfx/third_party/oga_angel_shield/`
- `assets/vfx/third_party/oga_energy_shield/`
- `assets/vfx/third_party/oga_magic_forcefield_color/`
- `assets/vfx/third_party/oga_magic_forcefield_grayscale/`
- Binbun Battle shield effects: `assets/vfx/third_party/binbun_godot4_combat_magic/BattleFX/`

### Fire / explosion / wrath
Prefer:
- `assets/vfx/third_party/oga_fire_wrath_magic/`
- `assets/vfx/third_party/oga_fire_circle_fx/`
- existing fireball families under `assets/vfx/third_party/oga_fireball_*`
- Binbun `FlameFX` and `ExplosionFX` under `assets/vfx/third_party/binbun_godot4_core/`
- audio: `assets/audio/third_party/oga_magic_cc0/fire/`

### Ice / frost / freeze
Prefer:
- existing basic spell/frost assets.
- elemental enchanted weapons: `assets/vfx/third_party/oga_elemental_weapons_magic/Ice/`
- audio: `assets/audio/third_party/oga_magic_cc0/freeze/`

### Lightning / electricity / plasma
Prefer:
- `assets/vfx/third_party/binbun_godot4_electric/ElectricFX/`
- `assets/vfx/third_party/oga_plasma_electric/`
- `assets/vfx/third_party/oga_radial_lightning/`
- `assets/vfx/third_party/oga_lightning_effect/`

### Nature / healing / life magic
Prefer:
- `assets/vfx/third_party/oga_nature_magic/`
- `assets/vfx/third_party/oga_angel_wings_magic/`
- `assets/vfx/third_party/oga_light_magic/`
- procedural glow: `assets/vfx/third_party/godotshaders_portal_cc0/magic_pulse_glow_2d.gdshader`
- audio: `assets/audio/third_party/oga_magic_cc0/healing/`

### Water magic
Prefer:
- `assets/vfx/third_party/oga_water_magic/`
- combine later with the separate water/splash library when the main game flow defines the actual spell behavior.

### Blood / dark / curse / poison-facing visuals
Prefer:
- `assets/vfx/third_party/oga_blood_magic/`
- `assets/vfx/third_party/oga_dark_magic_icons/`
- `assets/vfx/third_party/binbun_godot4_combat_magic/DarkMagicFX/`
- blood enchanted weapons: `assets/vfx/third_party/oga_elemental_weapons_magic/Blood/`

### Arcane / pure projectiles / beams
Prefer:
- `assets/vfx/third_party/oga_pure_projectile_magic/`
- `assets/vfx/third_party/binbun_godot4_beam/`
- `assets/vfx/third_party/binbun_godot4_core/ElementalMagicFX/`
- arcane enchanted weapons: `assets/vfx/third_party/oga_elemental_weapons_magic/Arcane/`

### Enchanted weapons
`assets/vfx/third_party/oga_elemental_weapons_magic/` contains 72 PNG weapon-effect variants organized across:
- Arcane
- Blood
- Fire
- Ice
- Light
- Nature

Use these as visual/reference/effect layers, not as a substitute for the weapon system itself.

### Music / bard / resonance magic
Prefer:
- `assets/vfx/third_party/oga_music_magic/`

This is one of the largest new sprite-effect folders and includes several effect families/color variants.

### Spell icons / UI support
Prefer:
- `assets/vfx/third_party/oga_dark_magic_icons/` — eight dark spell/ability icons.
- `assets/vfx/third_party/oga_magic_spell_icons/`
- `assets/vfx/third_party/oga_cc0_rune_icons/`

## Magic audio

Root: `assets/audio/third_party/oga_magic_cc0/`

Actual audio files: 12.

Folders:
- `general_cast/` — 7 general magical cast/activation sounds.
- `healing/` — magic words + health restore.
- `teleport/` — teleport spell.
- `freeze/` — freeze spell.
- `fire/` — synthesized fire effect.

Do not hard-wire these filenames into gameplay. The main game flow should bind them through semantic events such as `spell.cast`, `spell.teleport`, `spell.heal`, `spell.freeze`, `spell.fire` or equivalent project conventions.

## Procedural Godot 4 shader library

Root: `assets/vfx/third_party/godotshaders_portal_cc0/`

Code-only CC0 staging:
- `portal_2d.gdshader`
- `pixelated_stencil_portal.gdshader`
- `black_hole_3d.gdshader`
- `black_hole_2d.gdshader`
- `magic_pulse_glow_2d.gdshader`
- `SOURCE.md`
- `LICENSE.txt`

Page screenshots/videos are intentionally not copied because the GodotShaders pages license the shader code separately from page media.

## Integration policy for the main game-development flow

1. Choose a semantic event first: cast, charge, projectile, impact, aura, status, summon, teleport, barrier, beam, death, heal, etc.
2. Pick the best staged source from this index rather than duplicating assets.
3. Build a layered effect when appropriate: mesh/flipbook or shader + particles + light + decal + audio.
4. Pool/reuse expensive emitters.
5. Add distance/quality fallbacks for costly transparent effects.
6. Do not modify third-party originals in place when a reusable derived preset can live in project-owned runtime content.
7. Preserve `SOURCE.md` and `LICENSE.txt` when moving/copying assets into any derived production package.

## Status

All entries listed as staged above are physically present in `Treninem/game` at the time this index was created. This document is an asset discovery/index layer, not a gameplay implementation.
