# ImPuls — Source-only non-magic VFX staging — 2026-08-14

Status: **STAGING ONLY / NOT RUNTIME-INTEGRATED**.

This registry is for the asset-sourcing chat. Nothing listed here is connected to gameplay by this chat. The main integration chat owns production selection, deduplication, optimization, placement into production asset folders and runtime wiring.

Root: `assets/staging/vfx_nonmagic/`

## Physically staged and verified in repository

All entries below have real files present in the repository, not registry-only placeholders. Each staged family keeps `SOURCE.md` and `LICENSE.txt`.

### Fire / smoke / fog / steam

- `oga_burning_fire_40f` — OpenGameArt, Mikodrak, CC0. Real looping burning-fire assets including GIF previews and a directory of individual transparent PNG frames. Recommended: campfire, fireplace, furnace, torch and burning-object source material.
- `oga_fire_smoke_animations` — OpenGameArt, Reactorcore, CC0. Real fire/flame/smoke sprite families including preview sheets and separate animation-frame directories such as FireBlast, FireBurst, FirePlume, OilyFireball and SmokeGas. Recommended: main chat selects suitable subsets by art direction.
- `oga_animated_steam` — OpenGameArt, hatmix, CC0. Real `steam_wall_sheet.png` animated steam/smoke spritesheet. Recommended: pipes, vents, cooking, hot water, machinery, geysers and industrial steam.
- `oga_smoke_vapor` — OpenGameArt, Fupi, CC0. Four soft smoke/vapor textures. Recommended: smoke, steam, dust, cloud wisps, fog wisps, gas and industrial emissions.
- `oga_fog_animation` — OpenGameArt, AntumDeluge, CC0. Real tileable `fog.png` texture for moving/layered fog and cloud banks.
- `oga_thick_fog` — OpenGameArt, LFA, CC0. Real horizontally tileable `fog01.png` texture for thick fog, haze and distant smoke banks.
- `oga_blender_volumetric_effects` — OpenGameArt, rubberduck, CC0. Rendered flame, explosion, ring, shockwave and smoke families; rendered visual files only are staged.

### Weather / water

- `oga_lightning_animation` — OpenGameArt, Calinou, CC0. Real lightning animation files staged for storms/electrical faults/distant lightning.
- `oga_rain_particle` — OpenGameArt, donte, CC0. Real five-frame rain animation (`rain_drop_0.png` through `rain_drop_4.png`) for low-cost rain/far LOD.
- `oga_water_caustics` — OpenGameArt, leeor_net, CC0. Real caustic atlas files plus individual frame directory; useful for underwater light movement/fallback caustics.
- `oga_water_drop` — OpenGameArt, davididev, CC0. Real `water_ball.png` additive water-droplet candidate for spray, leaks, fountains and wet machinery.
- `oga_splash` — OpenGameArt, jcpmcdonald, CC0. Real `splash.png` low-cost splash animation candidate.
- `oga_para_particlefx_2` — OpenGameArt, para, CC0. Animated air bubbles plus fire/flame and physical hit-style sheets.

### Explosions / impacts / residues

- `oga_explosion_animations_1` — OpenGameArt, Sinestesia, CC0. Transparent frame-by-frame explosion atlas family.
- `oga_explosion_animations_2` — OpenGameArt, Sinestesia, CC0. Second transparent explosion-atlas family.
- `oga_explosion_atlas` — OpenGameArt, TheJosh + Kenney-derived source, CC0. Compact 3x3 explosion atlas.
- `oga_para_particlefx_1` — OpenGameArt, para, CC0. 14 animated particle-effect variations in regular frame grids; candidates for smoke/fire/general effects.
- `kenney_splat_pack` — Kenney, CC0. Splat/VFX textures suitable for mud, paint, oil, water, grime, dirt, stains and impact residue.
- `oga_cc0_bang_sfx` — OpenGameArt, rubberduck, CC0. Explosion/firework/cannon/short bang recordings for later audio selection and normalization.

## Main integration chat checklist

Before promoting any staged pack into production:
1. inspect actual frames/audio and remove duplicates or weak variants;
2. compare with existing `assets/vfx/third_party/` production assets;
3. choose near/medium/far LOD roles;
4. optimize atlases and audio formats where useful;
5. preserve source/license metadata with promoted files;
6. integrate through shared semantic VFX/material/audio systems rather than one-off scene hacks;
7. test GL Compatibility performance before broad deployment.

## Source-only chat boundary

This staging chat must not edit gameplay scripts, scenes, `project.godot`, autoloads, export/build settings or live integration to consume these assets. It may only source, sanitize, catalog, license and place files under staging/registry paths for the main chat to consume.
