# ImPuls — Source-only weather staging — 2026-08-14

Status: **STAGING ONLY / NOT RUNTIME-INTEGRATED**.

Root: `assets/staging/weather/`

## Snow — physically staged and verified

### `snow/oga_snowflake_128`
- Source: OpenGameArt — Snow flake, mkwong98.
- License: CC0.
- Physical contents: real `snowflake.png` (128x128), `SOURCE.md`, `LICENSE.txt`.
- Candidate use: snowfall particle sprite, close snowflake detail and winter VFX masks.

### `snow/oga_seamless_snow_1024`
- Source: OpenGameArt — Seamless Snow Texture, GGBotNet.
- License: CC0.
- Physical contents: real `snow01.png` 1024x1024 plus source/license metadata.
- Candidate use: snow terrain/material source; main chat should create normal/roughness or blend maps as needed rather than treating diffuse alone as a complete PBR material.

### `snow/oga_snow_texture_verts`
- Source: OpenGameArt — Snow Texture, created by Verts and uploaded with permission by snowman.
- License: CC0 on the source page.
- Physical contents: real `snow.png` plus source/license metadata.
- Candidate use: alternate snow material/biome variant. Main chat should visually compare with `oga_seamless_snow_1024` and keep both only if they serve distinct looks.

## Existing physically staged weather VFX elsewhere
See `assets/registry/VFX_STAGING_NONMAGIC_2026-08-14.md` for real lightning, rain frames, fog, thick fog, water caustics, splashes, droplets, smoke and steam.

## Source-only chat boundary
This chat only places source assets and metadata in staging. Main chat owns optimization, Godot import settings, materials, scenes, weather logic and runtime integration.
