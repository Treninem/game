# World / Physical VFX Registry — 2026-08-14

Status: **physically integrated runtime**, not only an asset shortlist.

## Active runtime

- `scripts/world_vfx.gd` — semantic material/surface effects.
- `scripts/weather_vfx.gd` — rain, snow, dust, bubbles, storm flashes.
- `scripts/weather_hail_vfx.gd` — hail layer.
- `scripts/ambient_vfx.gd` — motes, fireflies, volcanic ash.
- `scripts/nature_vfx.gd` — mist, leaves, sea spray, cold breath.
- `scripts/screen_vfx.gd` — hit/landing/explosion/lightning/underwater screen feedback.
- `scripts/environment_mark_pool.gd` — pooled footprints, tire tracks, mud, scorch and spill marks.
- `scripts/vfx_library.gd` — project-owned procedural physical particles.
- `scripts/third_party_vfx.gd` — imported CC0 sprite/flipbook enhancement layer.

## Active gameplay integration

### Movement
- walking footsteps;
- sprint footsteps;
- hard landing effects;
- snow/sand/wet-ground footprints;
- mud marks;
- surface-driven particle choice.

### Physical impacts
- metal sparks;
- stone chips/dust;
- wood debris;
- glass shards/glints;
- dirt/grass/sand disturbance;
- mud splash;
- water splash.

### Persistent aftermath
- scorch marks;
- spill marks;
- tire tracks;
- footprints;
- mud marks;
- explosion aftermath API.

### Weather and nature
- rain;
- rain splashes;
- snow;
- hail;
- dust;
- storm lightning flash;
- underwater bubbles;
- underwater tint transition;
- ground mist;
- wind-driven leaves;
- sea spray;
- cold breath;
- pollen/air motes;
- fireflies;
- volcanic ash.

### Screen / camera feedback
- melee impact shake;
- incoming damage flash and shake;
- heavy landing shake;
- distance-aware explosion feedback API;
- lightning flash;
- underwater transition.

## Reused verified CC0 assets

From `assets/vfx/third_party/kenney_particle_pack/PNG (Transparent)/`:
- `dirt_01.png`–`dirt_03.png`
- `spark_01.png`–`spark_04.png`
- selected `smoke_*.png`
- `flame_01.png`–`flame_04.png`

The source/license metadata stays inside the imported Kenney pack directory. Procedural fallback remains available through `VFXLibrary`.

## Semantic hooks for future content

Future systems should reuse these hooks instead of embedding effect implementations:

```gdscript
WorldVFX.spawn_footstep(position, strength, surface, forward)
WorldVFX.spawn_landing(position, fall_speed, surface, forward)
WorldVFX.spawn_impact(surface, position, normal, direction, strength)
WorldVFX.spawn_break(surface, position, normal, strength)
WorldVFX.spawn_tire_contact(position, forward, slip, surface)
WorldVFX.spawn_spill(position, color, size, lifetime)
WorldVFX.spawn_scorch(position, normal, size, lifetime)
WorldVFX.spawn_explosion_aftermath(position, normal, size, surface)
WorldVFX.spawn_environment_effect(kind, position, strength)
ScreenVFX.explosion_feedback(position, strength)
```

## Planned adjacent effects

Use this registry as the next-extension checklist, not as a claim that every item is already complete:
- waterfall mist and splash zones;
- river rapids/foam;
- stronger shoreline breakers/foam strips;
- dust devils and tornado debris;
- falling rocks / avalanche snow cloud;
- building collapse dust/debris;
- tree-fall leaf/wood burst;
- forge/welding/grinding sparks;
- exhaust smoke / engine dust;
- skid smoke for hard surfaces;
- electricity short-circuit sparks;
- steam leaks / pressure bursts;
- fire extinguisher cloud;
- glass-window crack/break stages;
- object drag/scrape dust and sparks;
- underwater caustics and suspended particles;
- heat haze near fire/lava/hot machinery;
- localized fog banks;
- insect swarms and bird-flock disturbance hooks;
- large storm/tornado/ocean-event VFX with distance LOD.

## Performance policy

- Nearby/local emitters only for continuous effects.
- Pooled/short-lived impact effects.
- Capped persistent marks.
- No continent-wide transparent particle layers.
- LOD/distance gating for large future phenomena.
