# ImPuls — Source-only nature staging — 2026-08-14

Status: **STAGING ONLY / NOT RUNTIME-INTEGRATED**.

Root: `assets/staging/nature/`

## Physically staged and verified

### `kenney_foliage_sprites`
- Source: Kenney Foliage Sprites via OpenGameArt.
- License: CC0.
- Physical contents: original license, `PNG/`, `Vector/`, `Preview.png`, `Sample.png`, `SOURCE.md`.
- Source pack description: 50 flat foliage sprites + 50 shaded foliage sprites, with vector source files included.
- Candidate uses for main chat: foliage cards, bushes, small plants, distant vegetation, tree-building source, leaf/plant variation and low-cost LOD.

### `oga_tree_leaves_pack_1`
- Source: OpenGameArt — Tree Leaves Pack 1, TrachinusDraco.
- License: CC0.
- Physical contents: `tree_leaves_001.png`, `tree_leaves_002.png`, `tree_leaves_003.png`, `tree_leaves_004.png`, `SOURCE.md`, `LICENSE.txt`.
- The four source PNGs are large (~4.2 MB each), so the main chat should generate optimized runtime atlases/LODs rather than blindly use originals at full resolution.
- Candidate uses: tree/branch foliage cards, loose/falling leaves, wind-driven leaf particles and species/color variations.

## Main integration chat notes
1. Do not load all source-resolution leaf textures everywhere; produce optimized production variants.
2. Keep originals in staging as source material and preserve license/source files.
3. Prefer shared foliage atlases and material instances for open-world rendering.
4. Main chat owns Godot import settings, shaders, scenes and runtime integration.

## Source-only chat boundary
This chat may source, verify, download and catalog assets here. It must not connect them to scenes, scripts, autoloads or `project.godot`.
