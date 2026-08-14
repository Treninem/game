# ImPuls — Source-only atmosphere staging — 2026-08-14

Status: **STAGING ONLY / NOT RUNTIME-INTEGRATED**.

Root: `assets/staging/atmosphere/`

## Physically staged and verified

### `oga_clouds_transparency_2k`
- Source: OpenGameArt — Clouds with Transparency, WickedInsignia.
- License: CC0.
- Source pack: 2K cloud textures; alpha PNG variants plus black-background JPEG variants.
- Physical repository contents include real `FX_CloudAlpha01.png/.jpg`, `FX_CloudAlpha02.png/.jpg`, `FX_CloudAlpha03.png/.jpg`, `FX_CloudAlpha04.png/.jpg`, `FX_CloudAlpha05.png/.jpg`, `FX_CloudAlpha06.png/.jpg` and further variants from the source ZIP, plus `SOURCE.md` and `LICENSE.txt`.
- Candidate uses: cloud cards/layers, distant storm banks, mist, fog banks, smoke-like atmospheric layers and sky composition.
- Main chat should normally prefer alpha PNG variants, remove redundant JPEG copies from promoted production assets, downscale/atlas as appropriate and choose near/far quality roles.

## Source-only chat boundary
This chat stores source files only. The main integration chat owns cloud shaders, sky systems, scenes, graphics settings and runtime use.
