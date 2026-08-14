# ImPuls — World, Weather and Physical VFX

This document describes the non-magic visual feedback runtime used by the Stage 10 world foundation.

## Goals

- Make movement and combat react to the real surface instead of playing one generic effect.
- Keep weather and biome ambience local to the active player so the 64x64 km world remains streamable.
- Reuse the verified CC0 VFX library already stored under `assets/vfx/third_party/`.
- Keep persistent ground marks pooled and distance-limited.
- Expose semantic calls that future NPCs, animals, tools, vehicles and destructibles can share.

## Runtime layers

### `WorldVFX`

`scripts/world_vfx.gd` resolves surfaces and emits physical feedback.

Supported surfaces:
- dirt
- grass
- sand
- mud
- snow
- stone
- wood
- metal
- glass
- water

Surface resolution order:
1. explicit `surface_type` metadata on a collider;
2. `surface_<type>` or `<type>` groups;
3. useful collider-name keywords;
4. world biome / temperature / snow / water state fallback.

Public hooks include:
- `spawn_footstep(...)`
- `spawn_landing(...)`
- `spawn_impact(...)`
- `spawn_break(...)`
- `spawn_tire_contact(...)`
- `spawn_spill(...)`
- `spawn_scorch(...)`
- `spawn_explosion_aftermath(...)`
- `spawn_environment_effect(...)`

### `EnvironmentMarks`

`scripts/environment_mark_pool.gd` owns temporary world marks. It is shared rather than duplicated by VFX systems.

Current marks:
- footprints;
- tire tracks;
- mud marks;
- scorch marks;
- liquid spills.

The pool caps the mark count, fades old marks and limits visibility distance.

### `WeatherVFX`

`scripts/weather_vfx.gd` follows the local player and renders:
- rain;
- rain surface splashes;
- snow;
- dry dust;
- underwater bubbles;
- storm lightning screen flashes.

Particle amount and direction react to `EnvironmentState` rain, snow, dust, wind, storm and underwater values.

### `WeatherHailVFX`

A separate hail runtime is kept as an independent autoload so hail can evolve without bloating the normal rain/snow emitter.

### `AmbientVFX`

`scripts/ambient_vfx.gd` adds local biome atmosphere:
- pollen / floating motes in forest, plains, taiga and marsh;
- fireflies at night in warm forest and marsh regions;
- volcanic ash near Ashen Peak.

All emitters exist only around the active player.

### `NatureVFX`

`scripts/nature_vfx.gd` adds:
- low ground mist in wet/foggy forest, taiga and marsh;
- leaves carried by strong wind in forest and taiga;
- sea spray around ocean-level coastal/water regions;
- visible breath in freezing air.

### `ScreenVFX`

`scripts/screen_vfx.gd` provides lightweight screen/camera feedback without expensive post-processing:
- damage flash;
- camera shake for impacts;
- heavy landing feedback;
- distance-attenuated explosion feedback API;
- storm lightning flash;
- underwater screen tint and enter/exit transition.

## Player integration

`scripts/player_controller.gd` currently emits:
- biome-aware footsteps while walking/running;
- stronger sprint footsteps;
- landing particles/marks based on fall speed;
- oriented footprints/marks;
- material-aware melee impacts instead of generic stone impacts;
- light camera feedback on successful melee and hard surface contact.

## Physical surface behavior

- **Metal:** sparks and metal collision particles.
- **Glass:** bright shards/spark-like glints.
- **Wood:** chips/splinters-style brown debris.
- **Stone:** chips and grey dust.
- **Dirt:** soil dust.
- **Grass:** small soil/green disturbance.
- **Sand:** larger tan dust kick.
- **Mud:** dirt plus wet splash and mud marks.
- **Snow:** cold white puff and footprints.
- **Water:** splash particles.

## Destruction and vehicles

Future destructibles should call `WorldVFX.spawn_break(surface, position, normal, strength)` rather than constructing particles directly.

Future vehicles should call `WorldVFX.spawn_tire_contact(position, forward, slip_strength, surface)` for tracks, skid dust and wet/mud response.

Fluid systems can call `WorldVFX.spawn_spill(...)`. Fires/explosions can call `spawn_scorch(...)` or `spawn_explosion_aftermath(...)`.

## Imported CC0 integration

The world layer currently reuses real Kenney Particle Pack frames for:
- dirt/dust;
- sparks;
- smoke;
- flame.

Procedural `VFXLibrary` particles remain underneath these sprites so effects still work if optional art is changed later.

## Performance rules

- Weather, nature and ambient emitters follow the local player.
- Particles use bounded visibility AABBs.
- Ground marks use a capped pool and visibility distance.
- Do not create continent-wide rain/snow/fog particle systems.
- Prefer semantic VFX events over scene-specific particle duplication.
- Use low-cost GL Compatibility materials; heavy full-screen post-processing is not required for basic feedback.

## Validation

`.github/workflows/validate-world-vfx.yml` loads the project headlessly with Godot 4.7.1 and verifies the runtime/autoload wiring whenever world/weather/VFX files change.
