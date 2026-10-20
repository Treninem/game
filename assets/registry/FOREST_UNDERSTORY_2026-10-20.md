# Forest understory review — 2026-10-20

Status: INTEGRATED in the source review; main merge and release readiness remain separate.

Existing Quaternius CC0 Grass_Wispy_Tall is the sole source of Grass_Ground.glb: 0.38 m grounded height, 233 vertices, 155 triangles, preserved embedded texture. Existing woodland LICENSE.txt applies. Reproduction and SHA256 metadata are checked in next to the asset/tool. No new pack, duplicate source format or generated bitmap.

The near start forest appends an independent seeded cohort, preserving the old tree RNG/IDs. Added bushes/ferns and patchy low grass remain in the same 25-cell streaming window. Test ceilings: at most 1850 detail objects per cell, 40x40 ground candidates, at most 180 triangles in the low grass mesh; production declares 1820 total objects. Sample population: 24,154 ground clumps and 353 additional trees.

Shared foliage wind gains optional rounded crown normals/interior shading and pigment controls. Cover batches split at 32 m and distant forest batches at 64 m. Choppable near trees stay unsplit. Far forest respects cached settlement/ford clearings.

Actual graphical inspection rejected yellow uniform grass, then accepted the muted patchy variant. Frozen package, camera and graphical chopping checks and limits: docs/DEVELOPMENT_LOG_2026-10-20_UNDERSTORY.json. Existing branch-card silhouettes remain coarse; no scanned-tree or finished-world claim.
