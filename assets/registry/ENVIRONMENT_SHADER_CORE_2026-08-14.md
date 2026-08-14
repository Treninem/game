# Environment Shader Core — 2026-08-14

Status: PHYSICALLY INTEGRATED in `Treninem/game`.

Project-owned reusable Godot 4.7 / GL Compatibility shaders:
- `assets/shaders/environment/underwater_screen.gdshader`
- `assets/shaders/environment/snow_cover.gdshader`
- `assets/shaders/environment/wind_cloth.gdshader`
- `assets/shaders/environment/seasonal_surface.gdshader`
- usage/integration: `assets/shaders/environment/README.md`

## Purpose
These form the first shared environmental material/VFX layer for underwater visuals, snow accumulation/melting, cloth/flag wind response and seasonal wet/dry/dust/frost changes. Other chats should extend these shared systems instead of creating incompatible one-off shaders.

## Approved CC0 reference sources for further work
- Godot Shaders — Water with Caustics: https://godotshaders.com/shader/water-with-caustics/
- Godot Shaders — Underwater Camera Effect: https://godotshaders.com/shader/underwater-camera-effect/
- Godot Shaders — Multilayer Snowfall Shader: https://godotshaders.com/shader/multilayer-snowfall-shader/
- Godot Shaders — Snow-Covered Surface: https://godotshaders.com/shader/snow-covered-surface/
- Godot Shaders — 3D Flags: https://godotshaders.com/shader/3d-flags/
- Godot Shaders — Parallax Ice: https://godotshaders.com/shader/parallax-ice-for-fake-depth-to-plane-meshes/

Reference pages are not physical imports. Their example images/textures are not automatically covered by the shader-code license; verify every bundled asset separately before importing.

## Next extensions
1. underwater caustic projector/material and bubble/suspended-particle scenes;
2. snow/rain weather particle scenes and accumulation controller;
3. pooled footprint/tire-track/mud/scorch Decal manager;
4. ice/frost/crack material state and thaw transitions;
5. wind controller shared by vegetation, cloth, particles and weather audio;
6. seasonal world-state controller feeding material parameters globally.
