# ImPuls — Source-only non-magic VFX staging — 2026-08-14

Status: **STAGING ONLY / NOT RUNTIME-INTEGRATED**.

This registry is for the asset-sourcing chat. Nothing listed here is connected to gameplay by this chat. The main integration chat owns production selection, deduplication, optimization, placement into production asset folders and runtime wiring.

Root: `assets/staging/vfx_nonmagic/`

## Physically staged and verified in repository

### `kenney_splat_pack`
- Source: Kenney Splat Pack.
- License: CC0.
- Contents: splat/VFX textures suitable as candidates for mud, paint, oil, water, grime, dirt, stains and impact residue.
- Recommended production use: decals/material-state overlays after visual review.

### `oga_blender_volumetric_effects`
- Source: OpenGameArt — 25 special effects rendered with Blender, rubberduck.
- License: CC0.
- Contents: rendered flame, explosion, ring, shockwave and smoke families.
- Staging policy: rendered visual files only; Blender/source project files are intentionally excluded.
- Recommended production use: flipbooks/impostors for fire, explosions, smoke and shockwaves.

### `oga_cc0_bang_sfx`
- Source: OpenGameArt — 25 CC0 bang / firework SFX, rubberduck.
- License: CC0.
- Contents: explosion, firework, cannon and short bang recordings.
- Recommended production use: explosion/destruction/industrial impact audio after loudness normalization and duplicate review.

### `oga_explosion_atlas`
- Source: OpenGameArt — Explosion particles sprite atlas, TheJosh + Kenney-derived source.
- License: CC0.
- Contents: compact 3x3 explosion atlas.
- Recommended production use: low-cost/distant explosion LOD or UI/preview effects.

### `oga_para_particlefx_1`
- Source: OpenGameArt — Animated particle effects #1, para.
- License: CC0.
- Contents: 14 animated particle-effect variations; large sprite sheets with regular frame grids.
- Recommended production use: smoke/fire/general particle flipbooks after atlas inspection.

### `oga_para_particlefx_2`
- Source: OpenGameArt — Animated particle effects #2, para.
- License: CC0.
- Contents: air bubbles, flame/fire and physical hit-style animated sheets among the pack contents.
- Recommended production use: water bubbles, fire, impact feedback and low-cost environmental effects.

### `oga_smoke_vapor`
- Source: OpenGameArt — Smoke Vapor Particles, Fupi.
- License: CC0.
- Contents: four soft smoke/vapor textures.
- Recommended production use: smoke, steam, dust, cloud wisps, fog wisps, gas and industrial emissions.

## Extended staging batch requested by workflow

The following families are configured in `.github/workflows/vendor-vfx-staging.yml`. Treat them as **pending physical staging until their folders are confirmed in the repository after the workflow completes**:

- `oga_explosion_animations_1` — transparent frame-by-frame explosion atlases.
- `oga_explosion_animations_2` — second transparent explosion-atlas family.
- `oga_water_caustics` — pre-rendered water caustic frames/atlases.
- `oga_lightning_animation` — lightning animation candidate for storms/electrical faults.
- `oga_rain_particle` — tiny animated rain particle for low/far LOD.
- `oga_water_drop` — additive looping water-droplet candidate for spray/leaks/fountains.
- `oga_splash` — small low-cost water splash animation.

Do not call these physically staged until directory presence is verified after the workflow run.

## Additional verified source candidates for later staging

These are verified CC0 source candidates but are not physically staged by this registry entry:

- OpenGameArt Fog Animation — tileable 640x480 fog/cloud animation, 40-frame preview sequence; candidate for moving fog/cloud layers.
- OpenGameArt Thick Fog — 1024x512 horizontally tileable fog texture; candidate for rolling fog, smoke banks and distant haze.

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
