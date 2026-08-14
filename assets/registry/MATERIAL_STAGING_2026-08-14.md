# ImPuls — Source-only material staging — 2026-08-14

Status: **STAGING ONLY / NOT RUNTIME-INTEGRATED**.

Root: `assets/staging/materials/`

## Physically staged and verified

### `oga_seamless_ice_512`
- Source: OpenGameArt — Texture pack seamless / ice, Heathal.
- License: CC0.
- Physical contents: real `ice.png`, `SOURCE.md`, `LICENSE.txt`.
- Source dimensions: 512x512 seamless texture.
- Candidate uses: frozen puddles/lakes, frosted surfaces and source material for ice variants. Main chat should derive/author the PBR channels it needs rather than treating a single diffuse texture as a full material.

### `oga_desert_sand_2048`
- Source: OpenGameArt — 2048 Digitally Painted Tileable Desert Sand Texture, txturs.
- License: CC0.
- Physical contents: real `sand.jpg`, `SOURCE.md`, `LICENSE.txt`.
- Source dimensions: 2048x2048 tileable texture.
- Candidate uses: desert, dunes, beaches, drylands and color/detail source for dust/sand variants.

## Source-only chat boundary
This chat stores material source files only. Main chat owns PBR processing, texture resolution choices, Godot import settings, terrain blending and runtime use.
