# Photographic ground textures

Status: INTEGRATED in scripts/world_streamer.gd.
Source: assets/staging/materials/oga_seamless_textures/seamlessTextures/
Source page: https://opengameart.org/content/seamless-textures
Creators recorded by staged source: arikel/CruzR. License: CC0 (LICENSE.txt).

Unmodified source images:
- 100_1382_seamless.JPG -> grass_meadow.jpg
- 100_1374_seamless.JPG -> lichen_rock.jpg
- 100_1453_seamless.JPG -> stone_paving.jpg: INTEGRATED on capital district, road and plaza surfaces with world-aligned scale and generated mipmaps. Existing CC0 source retained unmodified; diffuse photograph, not a full scanned PBR set.

Diffuse textures only; no unsupported claim of full scanned PBR channels.
World-aligned tiling keeps texture scale consistent across streamed chunks.

3D ground imports explicitly generate mipmaps. The meadow material uses
anisotropic filtering and a subdued albedo tint to avoid high-frequency shimmer
and overexposed straw under daylight; source diffuse photographs stay unmodified.
