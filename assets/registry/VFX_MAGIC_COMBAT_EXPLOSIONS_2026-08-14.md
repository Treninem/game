# VFX expansion — magic, combat, explosions and collisions

Date: 2026-08-14
Repository: `Treninem/game`

## Physically integrated runtime core

Project-owned procedural Godot VFX Core Pack:
- implementation: `scripts/vfx_library.gd`;
- runtime documentation: `assets/vfx/README.md`;
- autoload: `VFXLibrary` in `project.godot`;
- player melee swing + hit impact integrated in `scripts/player_controller.gd`;
- enemy attack + defeat feedback integrated in `scripts/enemy.gd`.

### Runtime coverage

Magic: arcane, fire, frost, lightning, poison, heal, holy, dark, portal, shield.

Combat: melee swing, slash hit, blunt hit, block/parry, critical hit, defeat burst.

Explosions: small, medium, large; each composed from flash + hot particles + debris + smoke + shockwave.

Collisions/surface impacts: metal, stone, wood, dirt, glass, water.

## Physically imported third-party CC0 VFX packs

All packs below are now physically present under `assets/vfx/third_party/`. Each imported pack contains generated `SOURCE.md` and `LICENSE.txt` metadata. The vendor workflow copies only image files and human-readable metadata and excludes executables/scripts.

### Kenney Particle Pack
- Status: imported.
- License: CC0.
- Path: `assets/vfx/third_party/kenney_particle_pack/`.
- Coverage: generic particles; magic, fire/flame, light, smoke, sparks, slash, scorch, traces and related sprites.
- Source: https://www.kenney.nl/assets/particle-pack

### Kenney Smoke Particles
- Status: imported.
- License: CC0.
- Path: `assets/vfx/third_party/kenney_smoke_particles/`.
- Coverage: smoke and explosion sprites.
- Source: https://www.kenney.nl/assets/smoke-particles

### OpenGameArt — 2D Spell Effects by Mikodrak
- Status: imported.
- License: CC0.
- Path: `assets/vfx/third_party/oga_2d_spell_effects/`.
- Coverage: spell effects including fire, lightning, explosion and rain.
- Source: https://opengameart.org/content/2d-spell-effects

### OpenGameArt — Earth Impact - Magic Effect by Cethiel
- Status: imported.
- License: CC0.
- Path: `assets/vfx/third_party/oga_earth_impact/`.
- Coverage: multiple earth-impact magic effects.
- Source: https://opengameart.org/content/earth-impact-magic-effect

### OpenGameArt — Weapon Slash - Effect by Cethiel
- Status: imported.
- License: CC0.
- Path: `assets/vfx/third_party/oga_weapon_slash/`.
- Coverage: animated weapon movement, slash and hit effects with multiple variants.
- Source: https://opengameart.org/content/weapon-slash-effect

### OpenGameArt — Arcane Magic Effect by Cethiel
- Status: imported.
- License: CC0.
- Path: `assets/vfx/third_party/oga_arcane_magic/`.
- Coverage: arcane projectile/spell effects.
- Source: https://opengameart.org/content/arcane-magic-effect

## Required next VFX coverage

When magic gameplay is implemented, extend the same library rather than creating disconnected systems:
- projectiles: magic missile, fireball, ice shard, poison glob, holy bolt, dark orb;
- beams/channels: lightning chain, fire beam, frost ray, life drain, heal beam;
- area effects: fire ground, ice field, poison cloud, holy zone, curse zone, gravity well;
- status loops: burning, frozen, shocked, poisoned, bleeding optional, stunned, shielded, invisible, slowed, haste;
- casting: hand charge, staff charge, rune circle, cast release, interrupted cast;
- summoning: spawn circle, creature materialization, banish/despawn;
- teleport: departure, transit streak, arrival;
- environment/destruction: falling rubble, wall hit, wood splinter, glass shatter, rock fracture, dust cloud;
- projectile collisions: body, armor, shield, stone, wood, soil, water, metal, glass;
- large events: magical storm, boss aura, boss phase transition, portal storm, building explosion.

## Production rules

1. Gameplay emits semantic VFX events (`hit_slash`, `magic_fire`, `collision_metal`) rather than hard-coding a specific third-party texture.
2. Imported CC0 flipbooks/sprites decorate existing presets without changing combat logic.
3. VFX quality must scale through settings/LOD: particle amount, light flashes, smoke density and decal persistence.
4. Short combat VFX must self-delete and avoid persistent lights.
5. Large effects need distance culling and reduced far-LOD variants.
6. Every third-party pack keeps `SOURCE.md`/`LICENSE.txt` beside its files.
