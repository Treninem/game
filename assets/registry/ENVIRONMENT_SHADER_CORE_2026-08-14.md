# Environment Shader Core — 2026-08-14

Status: PHYSICALLY INTEGRATED in `Treninem/game`.

## Project-owned Godot 4.7 / GL Compatibility shaders
- `assets/shaders/environment/underwater_screen.gdshader`
- `assets/shaders/environment/underwater_caustics.gdshader`
- `assets/shaders/environment/snow_cover.gdshader`
- `assets/shaders/environment/wind_cloth.gdshader`
- `assets/shaders/environment/seasonal_surface.gdshader`
- `assets/shaders/environment/track_mark.gdshader`
- usage/integration: `assets/shaders/environment/README.md`

## Runtime systems physically integrated
- `scripts/environment_state.gd` — global season/weather/wetness/frost/wind/underwater state, autoload `EnvironmentState`.
- `scripts/environment_mark_pool.gd` — pooled mesh-based footprints, tire tracks, mud, scorch and spill marks, autoload `EnvironmentMarks`.
- `scripts/underwater_bubble_field.gd` — lightweight configurable bubble field for underwater cells; turbulence is off by default for performance.

## Compatibility rule
The project currently uses Godot 4.7 `gl_compatibility`. Native Godot `Decal` rendering is not available in the Compatibility renderer, so ground traces use pooled `PlaneMesh` marks with `track_mark.gdshader` rather than `Decal` nodes. Keep this architecture until the project renderer is intentionally changed and revalidated.

## Purpose
These shared systems provide the first reusable environmental layer for underwater visuals, moving caustics, bubbles, snow accumulation/melting, cloth/flag wind response, seasonal wet/dry/dust/frost changes, and persistent-but-budgeted surface traces. Other chats should extend these shared systems instead of creating incompatible one-off replacements.

## Approved CC0 reference sources for further work
- Godot Shaders — Water with Caustics: https://godotshaders.com/shader/water-with-caustics/
- Godot Shaders — Underwater Camera Effect: https://godotshaders.com/shader/underwater-camera-effect/
- Godot Shaders — Multilayer Snowfall Shader: https://godotshaders.com/shader/multilayer-snowfall-shader/
- Godot Shaders — Snow-Covered Surface: https://godotshaders.com/shader/snow-covered-surface/
- Godot Shaders — 3D Flags: https://godotshaders.com/shader/3d-flags/
- Godot Shaders — Parallax Ice: https://godotshaders.com/shader/parallax-ice-for-fake-depth-to-plane-meshes/

Reference pages are not physical imports. Their example images/textures are not automatically covered by the shader-code license; verify every bundled asset separately before importing.

## Next extensions
1. rain/snow/hail particle field around the camera plus roof/ground/water reactions;
2. ice/frost/crack material state and thaw transitions;
3. footprint/tire mark emitters wired to player/animals/vehicles and surface type;
4. underwater suspended-particle/plankton field and water-current controller;
5. wind controller shared by vegetation, cloth, particles and weather audio;
6. seasonal world-state controller feeding terrain/vegetation/material transitions;
7. cheap far-distance storm/fog/cloud representations and quality tiers.
