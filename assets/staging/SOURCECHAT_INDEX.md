# ImPuls source-chat staging index

This is the handoff index for the **source-only asset chat**. Every batch marked `READY / PHYSICAL` below has been downloaded as real files and committed under `assets/staging/`. These assets are **not wired into gameplay here**. The main integration chat should inspect each pack's `SOURCE.md` and `LICENSE.txt`, deduplicate, choose production subsets, optimize if needed, then promote selected files into final asset paths.

## Core non-magic VFX staging

Path: `assets/staging/vfx_nonmagic/`

Real staged families already include animated particles, fire/smoke, bubbles, rendered explosion/ring/shockwave effects, explosion audio, splat/decal sources, smoke/vapor textures, multiple explosion atlases, water caustics, lightning, rain particles, water drops and splashes. See `vfx_nonmagic/INTEGRATION_QUEUE.md` and each pack's source metadata.

## B03 — destruction / materials / water / electricity

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b03/`

Visual VFX:
- `vfx/oga_70_animated_effects/`
- `vfx/oga_plasma_electric_animations/`

Audio:
- `audio/oga_100_metal_wood_sfx/`
- `audio/oga_25_mud_sfx/`
- `audio/oga_40_water_splash_slime_sfx/`
- `audio/oga_75_breaking_falling_hit_sfx/`
- `audio/oga_electricity_sfx/`
- `audio/oga_glass_break_sfx/`
- `audio/oga_ice_shatters_sfx/`
- `audio/oga_rain_thunder_ambience/`
- `audio/oga_wind_sfx/`

Recommended use: destruction, material-specific impacts, wet/mud interactions, shattered glass/ice, electrical faults, storms and broad physical VFX source selection.

## B04 — environment audio / snow / fire

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b04/audio/`

- `oga_100_cc0_sfx_2/`
- `oga_35_wood_destruction_sfx/`
- `oga_41_snow_shoe_steps/`
- `oga_42_snow_gravel_footsteps/`
- `oga_4_dry_snow_steps/`
- `oga_9_wet_snow_steps/`
- `oga_fire_crackling/`
- `oga_fireplace_loop/`

Recommended use: snow variants, gravel, wood destruction, fireplaces/campfires/forges, and broad environment/mechanism/thunder/water loop source coverage.

## B05 — decals / damage masks / smoke / material overlays

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b05/`

Decals:
- `decals/oga_100_grunge_splatter_masks/`
- `decals/oga_cracking_overlay/`
- `decals/oga_liquid_splatter/`

Materials:
- `materials/oga_64x_texture_overlays/`
- `materials/oga_y2k_ice_texture/`
- `materials/oga_cc0_glass_alpha/`
- `materials/oga_window_texture/`

VFX:
- `vfx/oga_smoke_spritesheet_2024/`
- `vfx/oga_bubble_glass_burst/`

Recommended use: dirt/soot/grime/oil/liquid residues, progressive cracking, cheap LOD masks, ice/glass/window source material, smoke and burst candidates.

## B06 — biome ambience

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b06/audio/`

- `oga_ambient_birds/`
- `oga_swamp_environment/`
- `oga_night_crickets/`
- `oga_beach_ocean_waves/`

Recommended use: forest/field birds, swamp/marsh layers, night insects and coast/ocean ambience.

## B07 — workshop / machines / vehicles

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b07/audio/`

- `oga_68_workshop_sounds/`
- `oga_steam_release_hisses/`
- `oga_engine_sounds_2/`
- `oga_racing_engine_loops/`

Recommended use: blacksmith/workshop tool noise, machinery, steam pipes/boilers, engines and future vehicle RPM layers.

## B08 — animals / fauna / creature source audio

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b08/audio/`

- `oga_80_creature_sfx/`
- `oga_dog_sounds_pauliuw/`
- `oga_animal_beast_sounds/`
- `oga_horse_trotting/`
- `oga_sheep_baa/`
- `oga_quail_sound/`

Recommended use: dogs, horse movement, sheep, birds and wild/creature vocal source selection. The broad creature pack contains stylized/synthetic variants; main chat should reject unsuitable takes rather than use all files automatically.

## B09 — interaction Foley / vegetation / mechanisms

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b09/audio/`

- `oga_87_clickety_clips/`
- `oga_27_various_foley/`
- `oga_20_dry_leaf_rustles/`
- `oga_chain_winch/`

Recommended use: switches, buttons, levers, latches, locks, drawers, door/wood creaks, vegetation contact/rustle and chain/winch machinery.

## B10 — surface footsteps

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b10/audio/`

- `oga_different_steps_surfaces/`
- `oga_fantozzi_footsteps/`
- `oga_steps_wood_floor/`

Recommended use: wood, stone/hard surface, leaves, gravel, mud/dirt, grass/sand and wooden-floor walking. Combine with B04 snow and B03 mud/water material audio rather than creating a separate incompatible footstep system.

## B11 — water / cooking / utility audio

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b11/audio/`

- `oga_dripping_water_loop/`
- `oga_6_short_water_splashes/`
- `oga_boiling_water_loops/`
- `oga_stove_switch/`
- `oga_adding_salt/`
- `oga_water_waves/`

Recommended use: caves/cellars/sewers/wells/pipe leaks, small water impacts, cooking pots, tavern/home/camp kitchens, stove/furnace controls and river/shore/water-body layering.

## B12 — metal / clockwork / mechanical audio

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b12/audio/`

- `oga_31_metal_pings_scrapes/`
- `oga_33_cast_iron_clangs/`
- `oga_metal_clang_pitches/`
- `oga_door_spring_sounds/`
- `oga_steam_boiler_loop/`
- `oga_clockwork_ticking/`

Recommended use: metal filing/scrapes, heavy resonant impacts, object-size clang variation, door/trap springs, steam/industrial generators, clocks/timers and clockwork machinery. Deduplicate against B03/B07 by selecting the best sound for each object mass and mechanism.

## B13 — physical world interactions

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b13/audio/`

- `oga_shovel_dirt/`
- `oga_object_into_water/`
- `oga_stone_rock_wood_move/`
- `oga_moving_boulder/`
- `oga_qubodup_impact_palette/`
- `oga_cannon_wall_crash/`

Recommended use: digging and soil work, heavy objects entering water, dragging/moving stone or timber, boulder drops/scrapes, multi-material hard/soft/wet impacts, and large structural/cliff crash source layers. CC-BY-only rock-breaking/falling-rock candidates were deliberately excluded from this CC0 source batch.

## Integration rules for the main chat

1. A `READY / PHYSICAL` status means real files exist in `main`, not just source links.
2. Read `SOURCE.md` and `LICENSE.txt` before promoting any pack.
3. Prefer CC0 assets already staged here instead of downloading duplicates.
4. Do not move whole source libraries into production blindly; choose coherent subsets.
5. Normalize audio loudness/sample formats and texture atlas dimensions only during integration.
6. Keep surface/material semantics consistent across footsteps, impacts, destruction and weather.
7. Preserve source/license metadata after promotion.
8. Source-only chats do not modify gameplay scripts, scenes, `project.godot`, autoloads or build/export configuration.
