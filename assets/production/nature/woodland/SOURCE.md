# Woodland production selection

Status: INTEGRATED in start_region_streamer.gd and production_nature.gd.
Source: assets/staging/sourcechat_b44/models/quaternius_stylized_nature_megakit_standard/glTF/
Creator: Quaternius. License: CC0 (LICENSE.txt).
Source page: https://opengameart.org/content/stylized-nature-megakit

Selected CommonTree_1, CommonTree_3, Pine_1, Bush_Common, Fern_1 and
Grass_Wispy_Tall. GLBs preserve authored geometry, bark/leaf textures and alpha
cutouts. Models are grounded at zero and normalized to metre-scale heights:
10/12/12 m trees, 1.2 m bush, 0.7 m fern, 0.65 m grass.
Near trees retain physical trunks. Far trees use authored meshes in MultiMeshes,
replacing cone crowns. Leaves reuse the shared environment wind shader.
No source pack was downloaded again. Regenerate with tools/prepare_production_visuals.py.

Far rendering uses CommonTree_1_LOD.glb, a 15% geometric reduction of the same
normalized authored tree. Distant batches start at 110 m and omit far shadows;
near detailed trees remain visible to 150 m with physical trunks and shadows.
Tiny ground vegetation stops at 85 m. These limits avoid rendering full-density
foliage and shadows where their detail is subpixel on the integrated GPU.

Near models are also rendered in per-cell MultiMeshes, grouped by source model.
This preserves their authored geometry, material surfaces and root positions.
Physical tree bodies remain separate from visual batching. Prepared render meshes
are shared between cells instead of duplicating geometry for every tree.

Foliage extends the shared environment wind family with foliage_wind.gdshader.
Cloth and leaves share wind_motion.gdshaderinc and EnvironmentState parameters.
Leaf/grass cutouts use opaque depth writes with an alpha discard, avoiding the
transparent sorting/overdraw path. Detailed tree range is 150 m; distant batches begin at 110 m.

Wind-blown leaf masks reuse `tree_leaves_001.png` from the already staged
`assets/staging/nature/oga_tree_leaves_pack_1/` (TrachinusDraco, CC0).
Source: https://opengameart.org/content/tree-leaves-pack-1
The production mask has a 256 px import size cap and mipmaps; the shader samples
one silhouette from the existing atlas. The separate leaf license is preserved.
Leaves appear in autumn or strong gusts, rather than permanent summer confetti.

## Low ground-cover derivative — 2026-10-20

INTEGRATED in the review: `Grass_Ground.glb` derives only from the existing CC0 `Grass_Wispy_Tall.glb`. `tools/prepare_ground_cover.py` bakes the source transforms, applies a 0.25 decimation ratio and grounds the result at 0.38 m height with a wider footprint. Original embedded Grass texture and the existing LICENSE.txt apply. The final mesh has 233 vertices and 155 triangles; exact source/output checksums are in `Grass_Ground.source.json`. No new bitmap or downloaded source pack.
