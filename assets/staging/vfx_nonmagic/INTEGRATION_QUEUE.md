# Main-chat integration queue — non-magic VFX

This file is a handoff from the source-only staging chat. **Nothing here is automatically connected to gameplay.**

## Ready for main-chat review — physically staged

- `kenney_splat_pack/` — splat/decal candidates: mud, oil, grime, liquid residue, paint-like marks.
- `oga_blender_volumetric_effects/` — rendered flame, smoke, explosion, ring and shockwave candidates.
- `oga_cc0_bang_sfx/` — explosion/firework/cannon/bang audio candidates.
- `oga_explosion_atlas/` — compact low-cost explosion atlas.
- `oga_para_particlefx_1/` — animated general particle/fire/smoke sheets.
- `oga_para_particlefx_2/` — bubbles, fire and physical-hit-style animated sheets.
- `oga_smoke_vapor/` — soft smoke/vapor textures for steam, dust, mist, gas and smoke.

## Download queue — verify folder presence before use

The source-only workflows have been configured to stage these, but the main chat must confirm their folders actually exist before using them:

### Explosions / impacts
- `oga_explosion_animations_1/`
- `oga_explosion_animations_2/`

### Water / weather
- `oga_water_caustics/`
- `oga_water_drop/`
- `oga_splash/`
- `oga_rain_particle/`
- `oga_lightning_animation/`

### Fire / smoke / atmosphere
- `oga_fire_smoke_animations/`
- `oga_burning_fire_40f/`
- `oga_animated_steam/`
- `oga_spark_effect/`
- `oga_fog_animation/`
- `oga_thick_fog/`
- `oga_snowflake_particle/`

## Recommended main-chat selection order

1. Water/caustics/splash assets — useful across rivers, rain, fountains, waterfalls and underwater scenes.
2. Smoke/steam/fire — useful across settlements, camps, forge, industry, fires and weather interactions.
3. Surface splats/decals — useful for persistent environmental feedback.
4. Sparks and lightning — useful for metal impacts, machines, electrical failures and storms.
5. Explosion families — pick a small visually coherent subset; staging intentionally contains multiple choices so the main chat can reject duplicates.
6. Fog/snow low-cost particles — use as LOD/fallback layers rather than forcing them everywhere.

## Rules for integration

- Main chat should inspect `SOURCE.md`/`LICENSE.txt` in every selected pack.
- Do not move the whole staging library into production blindly.
- Deduplicate against `assets/vfx/third_party/` and other production assets.
- Keep near/medium/far LOD variants where they materially help performance.
- Promote only selected production files into the appropriate final folders.
- Source-only chats must not perform runtime integration.
