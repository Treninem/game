# ImPuls VFX Core Pack

This folder documents the physically integrated project-owned VFX layer implemented by `scripts/vfx_library.gd`.

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

## Performance rules

- Effects are short-lived and self-delete.
- Particle counts are deliberately bounded for the current GL Compatibility renderer.
- No expensive true reflections or persistent lights are created.
- Flash lights have shadows disabled.
- Keep routine combat effects below large-explosion density.
- Future sprite/flipbook packs should replace or decorate these emitters, not create duplicate gameplay systems.

## External CC0 enhancement packs

The following are approved enhancement sources, but must not be called physically imported until their binary files are actually committed under `assets/vfx/third_party/` with license/source metadata:

1. Kenney Particle Pack — CC0, general particle sprites including magic, fire, smoke, sparks, slashes, scorch marks and traces.
   Source: https://www.kenney.nl/assets/particle-pack
2. Kenney Smoke Particles — CC0, smoke/explosion VFX sprites.
   Source: https://www.kenney.nl/assets/smoke-particles
3. OpenGameArt 2D Spell Effects by Mikodrak — CC0; spell effects including fire/lightning/explosion/rain.
   Source: https://opengameart.org/content/2d-spell-effects
4. OpenGameArt Earth Impact - Magic Effect by Cethiel — CC0; earth impact variations.
   Source: https://opengameart.org/content/earth-impact-magic-effect

## License

The procedural VFX code and project-owned preset composition in this repository are part of the ImPuls project. Third-party assets retain their own source licenses and require their original license/source files beside imported content.
