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
- `scripts/vfx_library.gd` — semantic visual effects shared by combat and magic.
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
Gameplay emits semantic calls through `VFXLibrary`. Imported CC0 packs under `assets/vfx/third_party/` may improve visuals without changing spell logic.

Physically imported enhancement packs include Kenney Particle Pack, Kenney Smoke Particles and OpenGameArt spell/impact/slash packs. Keep source/license files beside third-party assets.

## Validation
`.github/workflows/validate-magic.yml` runs Godot 4.7.1 headlessly for changes affecting the magic runtime. It is isolated from the release workflow so unrelated parallel commits cannot cancel the magic validation run.

## Next production pass
- Use selected imported CC0 flipbooks/sprites inside the semantic VFX presets.
- Add cast animation hooks for hands/staves/weapons.
- Add spell audio and spatial impact audio.
- Add surface-specific elemental decals: scorch, frost, poison residue, arcane rune.
- Add unlock/progression rules instead of exposing every spell permanently.
- Add resistances, elemental interactions and friendly/hostile magic ownership.
- Add boss-scale channels, summons and large weather-linked magic after the base combat loop is stable.
