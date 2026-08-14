# ImPuls Environment Shader Core

Project-owned reusable Godot 4.7 / GL Compatibility environment shaders.

## Files
- `underwater_screen.gdshader` — screen-space underwater distortion/tint/darkening. Apply to a full-screen ColorRect/TextureRect shown only while the camera is submerged.
- `snow_cover.gdshader` — upward-facing snow coverage with runtime `snow_amount` and `melt` controls.
- `wind_cloth.gdshader` — reusable wind deformation for subdivided flags, cloth banners and light flexible meshes. UV.x=0 should be the anchored side.
- `seasonal_surface.gdshader` — shared dry/wet/dust/autumn/winter/frost material-state shader.

## Runtime integration rules
1. Weather code should drive shared parameters rather than swap entire meshes.
2. Rain increases `wetness`; prolonged cold increases `frost`/`winter`; warming increases `melt`.
3. Wind direction/strength should come from one world weather state and feed vegetation/cloth/VFX together.
4. Do not apply high-cost transparent effects to the whole map. Use camera/local cells and distance quality tiers.
5. Footprints, tire tracks, mud, scorch and cracks should use pooled Decal nodes and reusable masks; persist only gameplay-important traces.
6. Underwater visuals should be combined with fog, caustics, particles/bubbles and filtered audio instead of relying on the screen shader alone.

## License
These shader files are project-owned and may be used as part of ImPuls. External reference shaders listed in `assets/ASSET_PACKS.md` remain subject to their recorded source/license and are not physically imported unless their files exist in the repository.
