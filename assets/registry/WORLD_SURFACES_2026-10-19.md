# World surface integration follow-up

INTEGRATED in the source review: project-owned `terrain_ground.gdshader` reuses the existing production ground grass/lichen textures. It blends two UV scales with world-space macro color variation and slope/altitude masks. No new source pack. The shared `ice_surface.gdshader` retains freeze/crack/frost/thaw controls and now uses world-space directional wave normals instead of a multiplied sine grid. No screen-space reflection or geometry displacement/terrain redesign is claimed. Runtime evidence and limits: `docs/DEVELOPMENT_LOG_2026-10-19_WORLD_SURFACES.json`.

## Coast and planting — 2026-10-20

INTEGRATED in the review source: 4 m shared physical/rendered terrain grid with halo normals; existing woodland Pine_1 replaces duplicate near-tree alias, grass remains bounded in MultiMesh cells. Shared foliage wind adds `vegetation_tint` and optional `height_anchor` for grass; defaults preserve other foliage. No new source pack or photorealistic claim. Evidence: `docs/DEVELOPMENT_LOG_2026-10-20_COAST_NATURE.json`.

## Original bark restoration — 2026-10-20

INTEGRATED in the review: same CC0 Free Vegetation packs original `bark.JPG`, copied unmodified to `production/nature/temperate/bark_albedo.jpg`, explicit mipmaps, shared idempotent bark overrides and anisotropic foliage filtering. Shared wind now has a stable per-instance phase. Existing meshes and cutout branch cards remain; no new tree sculpt or scanned PBR claim. Evidence: `docs/DEVELOPMENT_LOG_2026-10-20_NATURE_MATERIALS.json`.

## Near-forest composition correction — 2026-10-20

INTEGRATED: original CC0 `bush_higher` with `leaf_small.png`, normalized as `TemperateBush.glb`; same family license/source retained. The near palette now uses two temperate models and excludes the visually incompatible pine; taiga pine remains. Near roots have 5.5 m minimum separation; ground texture scale and linear black-key cutoff corrected. Native and frozen evidence: `docs/DEVELOPMENT_LOG_2026-10-20_FOREST_CORRECTION.json`.
