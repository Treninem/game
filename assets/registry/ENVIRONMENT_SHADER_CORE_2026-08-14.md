# Environment Shader Core — 2026-08-14

Status: PHYSICALLY INTEGRATED in `Treninem/game`.

## Project-owned Godot 4.7 / GL Compatibility shaders
- `assets/shaders/environment/underwater_screen.gdshader`
- `assets/shaders/environment/underwater_caustics.gdshader`
- `assets/shaders/environment/snow_cover.gdshader`
- `assets/shaders/environment/ice_surface.gdshader`
- `assets/shaders/environment/wind_cloth.gdshader`
- `assets/shaders/environment/seasonal_surface.gdshader`
- `assets/shaders/environment/track_mark.gdshader` — human footprint, tire, mud, scorch, spill, paw and hoof procedural masks.
- usage/integration: `assets/shaders/environment/README.md`

## Runtime systems physically integrated
- `scripts/environment_state.gd` — global season/weather/wetness/frost/wind/underwater state, persistent snow cover, persistent surface freeze/thaw and shared water-current direction/strength; autoload `EnvironmentState`.
- `scripts/environment_exposure.gd` — periodic upward physics ray from the player to detect roof/shelter and publish local precipitation exposure; autoload `EnvironmentExposure`.
- `scripts/environment_mark_pool.gd` — pooled mesh-based human footprints, paw prints, hoof prints, tire tracks, mud, scorch and spill marks; autoload `EnvironmentMarks`.
- `scripts/surface_track_emitter.gd` — reusable child component for future animals/vehicles with HUMAN/PAW/HOOF/TIRE modes and deformable-surface filtering.
- `scripts/weather_vfx.gd` — camera/player-local rain, snow, dust, underwater bubbles and rain splash reactions; fixed particle budgets + `amount_ratio`; respects roof/shelter exposure; autoload `WeatherVFX`.
- `scripts/weather_hail_vfx.gd` — hail layer with fixed budget + `amount_ratio`, temperature/storm checks and shelter exposure; autoload `WeatherHailVFX`.
- `scripts/ambient_vfx.gd` — biome motes/fireflies/ash plus underwater suspended-particle field driven by shared water current; autoload `AmbientVFX`.
- `scripts/underwater_bubble_field.gd` — optional localized bubble source for vents, springs, wrecks and underwater cells; turbulence is off by default for performance.
- `scripts/player_controller.gd` already emits real player footstep/landing events into `WorldVFX`.
- `scripts/city_npc.gd` and `scripts/enemy.gd` now emit distance-budgeted surface footsteps while moving.

## Compatibility rule
The project currently uses Godot 4.7 `gl_compatibility`. Native Godot `Decal` rendering is not available in the Compatibility renderer, so ground traces use pooled `PlaneMesh` marks with `track_mark.gdshader` rather than `Decal` nodes. Keep this architecture until the project renderer is intentionally changed and revalidated.

Compatibility also lacks particle trails and does not support `GPUParticles3D.emit_particle()`, so rain/snow/hail and ambient particle systems use ordinary persistent emitters with fixed budgets and `amount_ratio` instead of per-drop manual GPU emission.

## Purpose
These shared systems provide a reusable environmental layer for underwater visuals, moving caustics, bubbles/suspended particles, water current, rain/snow/hail, shelter-aware precipitation, persistent snow accumulation/melting, persistent freezing/thawing, cloth/flag wind response, seasonal wet/dry/dust/frost changes, and persistent-but-budgeted human/animal/vehicle surface traces. Other chats should extend these shared systems instead of creating incompatible one-off replacements.

## Approved CC0 reference sources for further work
- Godot Shaders — Water with Caustics: https://godotshaders.com/shader/water-with-caustics/
- Godot Shaders — Underwater Camera Effect: https://godotshaders.com/shader/underwater-camera-effect/
- Godot Shaders — Multilayer Snowfall Shader: https://godotshaders.com/shader/multilayer-snowfall-shader/
- Godot Shaders — Snow-Covered Surface: https://godotshaders.com/shader/snow-covered-surface/
- Godot Shaders — 3D Flags: https://godotshaders.com/shader/3d-flags/
- Godot Shaders — Parallax Ice: https://godotshaders.com/shader/parallax-ice-for-fake-depth-to-plane-meshes/

Reference pages are not physical imports. Their example images/textures are not automatically covered by the shader-code license; verify every bundled asset separately before importing.

## Completed from previous extension queue
1. roof/shelter detection — DONE;
2. ice/frost/thaw material state — BASE SYSTEM DONE;
3. player/NPC/hostile footprints plus reusable paw/hoof/tire emitter — DONE;
4. underwater suspended-particle field + shared water-current state — DONE;
5. rain/snow/dust fixed budgets + `amount_ratio` optimization — DONE;
6. persistent snow-cover accumulation/melt — DONE.

## Next extensions
1. gameplay ice cracking/breaking: stress threshold, crack growth, break-through and refreeze;
2. local snow accumulation cells so sheltered roofs/interiors and warm areas differ instead of one global snow value;
3. roof-edge runoff, gutter/drip effects and rain-on-roof impact/audio intensity;
4. biome/river/ocean-specific water currents and current zones for fish/boats/floating debris;
5. attach `surface_track_emitter.gd` to imported animal/vehicle prefabs as they enter production;
6. wind controller shared by vegetation, cloth, particles and weather audio;
7. seasonal terrain/vegetation transitions by streamed world cell;
8. cheap far-distance storm/fog/cloud representations and graphics-quality tiers;
9. weather audio occlusion/attenuation under roofs and inside buildings;
10. puddle growth, slush and meltwater state after rain/snow/thaw.
