# ImPuls VFX Core Pack

This folder contains the project-owned runtime VFX layer plus physically imported CC0 enhancement packs.

## Current physically integrated presets

### Magic
- `magic_arcane` — arcane burst, glow and shockwave.
- `magic_fire` — hot flash, fire particles and smoke.
- `magic_frost` — ice-colored burst, white shards and frost wave.
- `magic_lightning` — white flash and directional electric sparks.
- `magic_poison` — green particles, toxic smoke and pulse.
- `magic_heal` — ascending green/gold particles.
- `magic_holy` — gold/white flash, burst and shockwave.
- `magic_dark` — dark-violet particles and pulse.
- `magic_portal` — layered portal pulses and arcane particles.
- `magic_shield` — defensive blue pulse and sparks.

### Combat
- `melee_swing` — fast weapon-swing streak.
- `hit_slash` — cutting impact.
- `hit_blunt` — blunt impact.
- `hit_block` — block/parry sparks and pulse.
- `hit_critical` — stronger critical hit flash and burst.
- `death_burst` — lightweight defeat feedback.

### Explosions
- `explosion_small`
- `explosion_medium`
- `explosion_large`

Each explosion combines flash, hot particles, debris, smoke and a shockwave with strength-dependent density.

### Collision / surface impact
- `collision_metal` — bright sparks.
- `collision_stone` — fragments and dust.
- `collision_wood` — wood-colored fragments.
- `collision_dirt` — soil fragments and dust.
- `collision_glass` — bright shard-like particles.
- `collision_water` — splash particles and expanding wave.

## Runtime API

```gdscript
VFXLibrary.spawn("magic_fire", position, get_tree().current_scene)
VFXLibrary.spawn_magic("frost", position)
VFXLibrary.spawn_explosion(position, "large")
VFXLibrary.spawn_collision("metal", position, hit_normal)
```

All helpers accept a `strength` value so gameplay can scale visual intensity without duplicating assets.

## Physically imported CC0 packs

Stored in `assets/vfx/third_party/` with `SOURCE.md` and `LICENSE.txt` beside each pack:

1. `kenney_particle_pack` — general magic/fire/smoke/sparks/slash/scorch/trace particle sprites.
2. `kenney_smoke_particles` — smoke and explosion sprites.
3. `oga_2d_spell_effects` — fire/lightning/explosion/rain spell effects by Mikodrak.
4. `oga_earth_impact` — earth/stone magic impacts by Cethiel.
5. `oga_weapon_slash` — animated slash/hit variants by Cethiel.
6. `oga_arcane_magic` — arcane spell/projectile effects by Cethiel.

These imported textures are enhancement material for the shared semantic VFX system. The procedural core remains the fallback so gameplay never depends on one third-party texture layout.

## Performance rules

- Effects are short-lived and self-delete.
- Particle counts are deliberately bounded for the current GL Compatibility renderer.
- No expensive true reflections or persistent lights are created.
- Flash lights have shadows disabled.
- Keep routine combat effects below large-explosion density.
- Imported sprite/flipbook packs should decorate existing emitters, not create duplicate gameplay systems.

## License

The procedural VFX code and project-owned preset composition are part of the ImPuls project. Imported third-party packs are CC0 according to their source pages; each imported folder preserves source/license metadata.
