# ImPuls — Combat Magic System

Playable Stage 10 foundation for combat magic. This is a gameplay system, not only an asset/VFX catalog.

## Controls
- Left mouse: physical attack.
- Right mouse: cast selected spell.
- Q: cycle to the next spell.
- Bindings live in `SettingsManager.DEFAULT_BINDINGS` and can use the existing rebinding system.

## Runtime architecture
- `scripts/magic_system.gd` — spell catalog, mana/cooldowns, targeting, cast routing, AoE damage and blink.
- `scripts/magic_projectile.gd` — reusable raycast-safe projectile runtime.
- `scripts/magic_zone.gd` — reusable persistent area spell runtime.
- `scripts/magic_hud.gd` — selected spell, mana, shield and cooldown HUD.
- `scripts/vfx_library.gd` — procedural semantic VFX foundation shared by combat and magic.
- `scripts/third_party_vfx.gd` — runtime bridge from semantic events to physically imported CC0 sprites/flipbooks.
- `scripts/vfx_flipbook_3d.gd` — lightweight 3D billboard flipbook player.
- `scripts/game_state.gd` — persistent mana and magic shield state.
- `scripts/enemy.gd` — burning, poisoned, frozen and shocked status processing.

## Playable spell set
1. Fireball — projectile, splash damage, burning.
2. Ice Shard — fast projectile, direct damage, freeze/slow.
3. Lightning — instant ray spell, high damage, shock.
4. Poison Orb — slow projectile, splash, long poison damage-over-time.
5. Heal — restores player health.
6. Magic Shield — adds an absorb shield before health damage.
7. Fire Zone — persistent AoE damage plus burning.
8. Frost Zone — persistent AoE damage plus heavy slowing.
9. Arcane Blast — targeted radial burst.
10. Blink — short portal movement that stops before blocking geometry and returns to terrain height.

## Resources and persistence
- Mana: 100 base/max, regenerates during survival simulation.
- Magic shield: capped absorb pool; incoming damage consumes shield before HP.
- Mana and shield are included in save snapshots and load safely from older saves where those keys do not exist.

## Enemy statuses
- `burning`: periodic fire damage.
- `poisoned`: periodic poison damage.
- `frozen`: severe movement slowdown.
- `shocked`: movement slowdown and longer attack interval.

Status durations refresh instead of creating duplicate independent timers.

## VFX integration
Gameplay emits semantic calls through `VFXLibrary`; imported assets are layered through `ThirdPartyVFX` without coupling combat rules to individual PNG files.

Physically integrated visual layers now include:
- Kenney fire sprites on fireball projectiles and flame flipbooks on fire casts/impacts;
- Kenney star/frost-style sprites on ice projectiles and frost events;
- Kenney spark sequences on lightning events;
- Kenney magic/twirl sequences on poison, dark and portal events;
- Kenney light/star sequences on healing and holy effects;
- Kenney circle sequence on shield casts;
- Kenney slash sequence on physical weapon swings and hit feedback;
- OpenGameArt Arcane Magic `Arcane_Effect_1..7` as the arcane flipbook sequence;
- Kenney scorch texture as a short-lived lightweight ground mark for fireball/fire-zone impacts.

The procedural particle layer remains active underneath these sprites. This keeps the effect volumetric and readable in 3D while adding authored CC0 detail. All imported packs retain their own `SOURCE.md` and `LICENSE.txt` under `assets/vfx/third_party/`.

## Performance rules
- Imported effects use unshaded billboard quads rather than extra 3D geometry.
- Flipbooks self-delete after their configured frame sequence.
- Projectile sprite layers are attached to the projectile and disappear with it.
- Fire scorch marks currently expire after 10 seconds.
- Persistent AoE zones use sparse CC0 sprite pulses while the cheaper procedural particles provide the continuous layer.

## Validation
`.github/workflows/validate-magic.yml` runs Godot 4.7.1 headlessly for changes affecting the magic runtime, HUD, imported-VFX bridge and flipbook player. It is isolated from the release workflow so unrelated parallel commits cannot cancel the magic validation run.

## Next production pass
- Add cast animation hooks for hands/staves/weapons.
- Add spell audio and spatial impact audio.
- Add frost, poison and arcane surface marks alongside scorch.
- Add unlock/progression rules instead of exposing every spell permanently.
- Add resistances, elemental interactions and friendly/hostile magic ownership.
- Add boss-scale channels, summons and large weather-linked magic after the base combat loop is stable.
