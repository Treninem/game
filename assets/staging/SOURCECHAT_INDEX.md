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

## B14 — species / fauna audio

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b14/audio/`

- `oga_donkey_bray/`
- `oga_bear_growls/`
- `oga_bat_screeches/`
- `oga_crow_caw/`
- `oga_crows_singing/`
- `oga_penguin_sounds/`
- `oga_rabbit_eating/`
- `oga_large_wings_flap/`

Recommended use: farm/pack animals, bears, cave/night bats, crow calls/ambience, cold-region birds, close rabbit feeding behavior and large flying-animal wing movement. Non-CC0 goat/chicken/gull/horse-gallop candidates were intentionally excluded from this batch.

## B15 — weather / cavern ambience

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b15/audio/`

- `oga_loopable_rain/`
- `oga_rain_gutter_loop/`
- `oga_short_wind/`
- `oga_wind_whoosh_loop/`
- `oga_wind1_family/`
- `oga_dark_cavern_ambient/`

Recommended use: multiple rain intensities/loops, rain heard from roofs/gutters, short gusts, high-frequency wind, five long wind layers, and underground/cavern atmosphere. Layer by shelter, region, storm intensity and underground state rather than playing everything together.

## B16 — destructible 3D source models

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b16/models/`

- `oga_destructible_cartoon_box/`
- `oga_breakable_crates_barrels/`
- `oga_destroyed_city_assets/`
- `oga_realistic_rocks_boulders/`

Recommended use: source meshes/chunks for destructible props, breakable containers, damaged roads/buildings/rubble and rock/boulder debris. Main chat should inspect topology/scale/materials/collisions, generate optimized GLB production copies where appropriate, and only integrate subsets matching the final art direction/performance target.

## B17 — forest ambience

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b17/audio/`

- `oga_forest_ambience_tinyworlds/`
- `oga_forest_birds_pauliuw/`

Recommended use: calm forest/woods ambient layer plus individual forest-bird source takes. Combine selectively with B06 biome ambience and B15 wind/rain; clean the noisier raw bird recordings before production promotion.

## B18 — Godot-ready breakable boxes / barrels / jars

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b18/models/oga_breakable_boxes_godot_ready/`

- extracted Godot-ready `.tscn`/`.tres`/GLTF/material/texture content;
- source FBX/GLTF/Blend/1K texture files;
- crate/barrel/jar intact and broken pieces plus collision-source meshes.

Recommended use: breakable settlement/interior/world props. Third-party executable scripts were excluded; main chat should connect these assets to ImPuls' own destruction logic rather than importing foreign runtime code.

## B19 — Godot-ready breakable doors and windows

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b19/models/oga_breakable_doors_windows/`

- Godot-ready resource/scene/model/material sources;
- FBX/GLTF/Blend/1K texture source files;
- intact and broken door/window variants plus collider meshes.

Recommended use: buildings, interiors, destructible windows/doors and damage states. Third-party executable scripts were excluded; main chat should inspect pivots, collisions and break-piece scale before production promotion.

## B20 — Containers Pack

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b20/models/oga_containers_pack/`

Real Godot-ready and source content for 34 container combinations: propane tanks, oxygen tanks, gas cans, water drums, water jugs and water tanks, with 1K textures and Godot collision setup from the source pack.

Recommended use: settlements, workshops, mines, farms, industry, storage and logistics. Main chat should select only context-appropriate variants and keep dangerous/fuel container gameplay semantics separate from visuals.

## B21 — Mine Object collection

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b21/models/oga_mine_object_collection/`

Real Godot-ready and FBX/GLTF/Blend/texture sources for mine tracks, mine carts, pickaxes, jars, pipes, posts and mining contraptions; source page lists roughly 12.7k total tris and 1K textures.

Recommended use: authored mines/caves, underground industry, minecart routes, mining tools and pipes. Main chat should assemble modular track/pipe sections, verify pivots/collisions/scale, and promote only the pieces needed by each location.

## B22 — roads / factory / furniture / medieval props

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b22/models/`

- `kenney_city_kit_roads/` — modular optimized road and barrier source assets.
- `kenney_factory_kit/` — large factory/warehouse/conveyor source kit.
- `oga_3td_furniture_pack/` — household/workshop furniture sources.
- `oga_medieval_props_pack/` — chest, bench, brazier, campfire, cart, basket, bed, hay, trough, logs, barrel and other settlement props.

Recommended use: roads and city approaches, warehouses/factories, interiors, workshops, farms, taverns and settlement clutter. Main chat should normalize scale/materials and promote coherent subsets rather than whole libraries.

## B23 — cave environment source pack

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b23/models/oga_3td_cave_pack_pro/`

Real extracted cave chambers, junctions, rock/cliff/boulder/stalagmite/stalactite pieces, cave plants and textures.

Recommended use: authored caves, mines and underground regions. Main chat should build modular collision/LOD rules and combine selectively with B21 mine props.

## B24 — PBR industrial source pack

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b24/models/oga_pbr_industrial_a52/`

Real editable industrial sources covering tanks, pipes, stairs, control panels, containers, chimneys, vents, ladders, garages and related PBR assets.

Recommended use: factories, utility areas, mines, workshops, industrial districts and infrastructure. Export optimized production GLB copies after material/scale review.

## B25 — harbour / fantasy ruins

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b25/models/`

- `oga_3td_harbour_pack/` — dock, lighthouse/splitrock, wharf, stand, industrial shack and textures.
- `oga_3td_fantasy_ruins_pack/` — ruined cathedral, foundations, walls, arches, columns, temple pieces, speaking stones and textures.

Recommended use: coast/port locations, abandoned settlements, ruins, dungeons and landmark dressing. Main chat should verify scale/collisions and only promote art-direction-compatible variants.

## B26 — animated farm animals / food kit

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b26/models/`

- `quaternius_farm_animals/` — real animated low-poly pig, cow, horse, llama, pug/dog and sheep source assets.
- `kenney_food_kit/` — large optimized food/kitchen object library for homes, markets, taverns and camps.

Recommended use: farms/pastures/stables and settlement life, plus food/kitchen/market clutter. Main chat should test Godot animation import and normalize animal skeleton/scale before production promotion.

## B27 — traffic / road furniture / fences

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b27/models/`

- `oga_traffic_road_assets/` — cones, barriers, manholes, roadblocks, streetlights and hydrants.
- `oga_modular_fence_pack/` — two modular fence families including Godot meshlib/gridmap source content.
- `oga_basic_wooden_fence/` — farm-style wooden fence Blender source.

Recommended use: city streets, work zones, farms, property boundaries and settlement dressing after scale/material/collision review.

## B28 — large CC0 nature libraries

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b28/models/`

- `kenney_nature_kit/` — large nature library with trees, rocks, stones, terrain elements, waterfalls, camping equipment and plants.
- `quaternius_ultimate_nature_pack/` — broad trees/rocks/pines/forest/flowers source library in common 3D formats.

Recommended use: regional vegetation/terrain dressing. Main chat should deduplicate overlaps, select consistent biome families, normalize scale/materials, create LOD/Multimesh-friendly production versions and avoid loading whole source packs at runtime.

## B29 — modular medieval building system

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b29/models/`

- `oga_modular_medieval_building_pack/` — modular house bases, windows, doors, balconies, chimneys, stairs, roofs/extensions/signs.
- `oga_medieval_tavern/` — standalone tavern building source.
- `oga_medieval_blacksmith/` — standalone blacksmith building source.
- `oga_medieval_tavern_interior/` — explorable tavern interior source.

Recommended use: varied capital/village architecture and authored interiors. Main chat should compose optimized production buildings rather than instancing heavy Blend source files directly.

## B30 — Kenney world architecture kits

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b30/models/`

- `kenney_castle_kit/` — castle walls, towers, gates and related fortification pieces.
- `kenney_modular_dungeon_kit/` — modular dungeon segments.
- `kenney_building_kit/` — general building walls, windows, animated doors and roofs.
- `kenney_fantasy_town_kit/` — broad modular fantasy/medieval town source set.
- `kenney_city_kit_commercial/` — commercial city buildings and compatible street details.

Recommended use: fortifications, dungeons, capital/village expansion and commercial districts. Main chat should choose one coherent regional style per district, normalize scale/materials/collisions and promote optimized production subsets only.

## B31 — prototype/animation fallback and pirate/coast assets

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b31/models/`

- `kenney_prototype_kit/` — broad prototyping source library with characters/animations, animals/animations, vehicles, structures and interactive objects.
- `kenney_pirate_kit/` — ships, treasure, island/nature and pirate-themed props.

Recommended use: Prototype Kit primarily as animation/prototyping/fallback source; Pirate Kit for ports, islands and coastal locations where the art direction fits. Avoid blindly promoting placeholder-style assets into final runtime content.

## B32 — survival / graveyard / furniture

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b32/models/`

Real Kenney Survival, Graveyard and Furniture source kits. Recommended use: camps/crafting, cemeteries/crypt approaches and authored interiors. Promote only coherent optimized subsets.

## B33 — land vehicles / racing / watercraft

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b33/models/`

Real Kenney Car, Racing and Watercraft source kits. Recommended use: future vehicles, roads/tracks and boats after wheel/pivot/scale/collision conventions are standardized by the main chat.

## B34 — people / humanoid animation libraries

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b34/`

- `models/quaternius_animated_characters/` — animated character source family.
- `animations/quaternius_universal_animation_library/` — free Standard humanoid animation source archive.
- `animations/quaternius_universal_animation_library_2/` — extended compatible Standard humanoid animation source archive.

Recommended use: establish one canonical Godot humanoid skeleton/retarget profile, test root motion/import and promote curated character/motion subsets only.

## B35 — animated wild / water fauna

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b35/models/`

Real animated animal/fish source packs including wolf/eagle/dog/cat/piranha families plus additional animals and fish. Main chat should standardize species scale/orientation and build AI/animation state machines separately.

## B36 — RPG characters / monsters / items

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b36/models/`

- `quaternius_rpg_characters/` — rigged/animated fantasy character archetypes.
- `quaternius_animated_monsters/` — animated monster/enemy sources.
- `quaternius_ultimate_rpg_items/` — broad RPG equipment/item source library.

Recommended use: curated NPC/enemy/equipment production assets after skeleton, collision, LOD and item-category normalization.

## B37 — crops / growth stages

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b37/models/quaternius_crops_pack/`

Real 3D crop source library with multiple growth stages. Recommended use: fields/farms/farming system after scale/pivot normalization and production optimization.

## B38 — weapons / item UI / construction source

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b38/`

- `models/kenney_weapon_pack/` — low-poly weapon source models and related renders.
- `ui/kenney_generic_items/` — generic tools/medical/tech/travel/transport inventory UI source set.
- `models/oga_construction_site_kit/` — building-site source props retained for staging/reference; inspect material provenance/visual quality before production promotion.

## B39 — fox / rabbit / duck / boar 3D species

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b39/models/`

Species-specific real CC0 source assets: animated fox, rigged/animated rabbit, rigged duck and rigged/animated boar. Main chat should normalize scale/orientation and verify Godot animation import before production use.

## B40 — pigeon / chicken / rooster 3D birds

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b40/models/`

Real CC0 bird sources: rigged/animated pigeon, chicken and rooster. Recommended use: city flocks and farm birds after materials, scale, animation import and AI behavior are standardized.

## B41 — deer / tiger / crocodile / bear 3D wildlife

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b41/models/`

Real CC0 wildlife sources: rigged/animated female deer, rigged tiger, animated crocodile and textured low-poly white bear. Bear source is not rigged; main chat should only rig/animate it if selected for production.

## Integration rules for the main chat

1. A `READY / PHYSICAL` status means real files exist in `main`, not just source links.
2. Read `SOURCE.md` and `LICENSE.txt` before promoting any pack.
3. Prefer CC0 assets already staged here instead of downloading duplicates.
4. Do not move whole source libraries into production blindly; choose coherent subsets.
5. Normalize audio loudness/sample formats and texture atlas dimensions only during integration.
6. Keep surface/material semantics consistent across footsteps, impacts, destruction and weather.
7. Preserve source/license metadata after promotion.
8. Source-only chats do not modify gameplay scripts, scenes, `project.godot`, autoloads or build/export configuration.

## B42 — small wildlife models

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b42/models/`

- `oga_frog_lowpoly_animated/` — animated frog source.
- `oga_snake_lowpoly_animated/` — animated snake source.
- `oga_rat_godot/` — Godot-ready animated rat source.
- `oga_ant_rigged_animated/` — rigged/animated ant.
- `oga_flying_squirrel_rigged/` — rigged flying squirrel.
- `oga_goat_lowrez/` — goat source mesh.

Recommended use: small wildlife, farm edges, caves/swamps/forests and ambient fauna after scale/animation/collision review.

## B43 — wetland / coast / insect fauna

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b43/models/`

- `oga_penguin_rigged_animated/`
- `oga_crab_lowpoly_animated/`
- `oga_turtle_rigged/`
- `oga_butterfly_animated/`
- `oga_bee_rigged/`
- `oga_swamp_limule_rigged_animated/`

Recommended use: coasts, ponds, wetlands, cold-region fauna and ambient insects. Verify imported materials and animation clips before promotion.

## B44 — vegetation / explicit LOD nature sources

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b44/models/`

- `quaternius_stylized_nature_megakit_standard/`
- `oga_free_plant_pack/`
- `oga_free_vegetation_lod_pack/`

Recommended use: trees, rocks, grasses, ferns, flowers and performance-oriented vegetation LOD candidates. Deduplicate visually against B28 before production promotion.

## B45 — 50+ monster source library

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b45/models/oga_50plus_monsters_pack_3d/`

Real CC0 library of 56 static low-poly monster source models. These are not assumed rigged/animated; shortlist only useful creatures for later production work.

## B46 — Fantasy Props MegaKit Standard

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b46/models/quaternius_fantasy_props_megakit_standard/`

Real CC0 standard pack with 94 source models spanning weapons, tools, vegetables, potions, market stalls, chests, furniture and related fantasy/medieval props.

Recommended use: markets, homes, workshops, taverns, inventory/world props and settlement dressing after deduplication against older prop libraries.

## B47 — Medieval Village MegaKit Standard

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b47/models/quaternius_medieval_village_megakit_standard/`

Real CC0 standard pack with 176 modular village-building models including walls, roofs, stairs, doors, windows, vines and related architecture pieces.

Recommended use: main settlement construction source. Compare against older medieval kits and keep the strongest coherent building family rather than integrating duplicates.

## B48 — pond / docks / well / windmill

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b48/models/`

- `oga_free_lowpoly_pond_kit/`
- `oga_modular_wooden_docks/` — source page lists 176 modular dock objects.
- `oga_basic_well_4k/`
- `oga_stylized_windmill/`

Recommended use: ponds, lakes, swamps, shores, docks, farms and villages. Normalize scale/materials/collisions and deduplicate against harbour/nature/medieval sources before promotion.

## B49 — tents / crafting stations / survival props

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b49/models/`

- `oga_medieval_tents/`
- `oga_medieval_crafting_stations/`
- `oga_medieval_survival_props/`

Recommended use: camps, crafting areas and temporary/rural settlements after material, pivot, collision and scale review.

## B50 — church / blacksmith interiors / candles / signs

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b50/models/`

- `oga_medieval_church_interior/`
- `oga_medieval_blacksmith_interior/`
- `oga_medieval_candles/`
- `oga_medieval_signs/`

Recommended use: authored enterable church/temple and blacksmith interiors plus selective interior/street detail props. Compare building shells with B47/B52 before promotion.

## B51 — medieval detail props

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b51/models/`

- `oga_medieval_benches/`
- `oga_medieval_cage/`
- `oga_medieval_boat/`
- `oga_cemetery_gravestones/`
- `oga_open_books/`

Recommended use: squares/churches, quest/prison dressing, shore props, cemetery locations and libraries/interiors after scale/material/collision review.

## B52 — modular explorable house interiors

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b52/models/`

- `oga_medieval_doors_interiors/`
- `oga_medieval_windows_interiors/`
- `oga_medieval_small_house_interior/`
- `oga_medieval_medium_house_interior/`
- `oga_medieval_shack/`

Recommended use: genuinely enterable homes and reusable double-sided doors/windows. Establish one production building grid/scale with B47 rather than mixing incompatible modules blindly.

## B53 — inventory / mine / magic staff sources

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b53/models/`

- `oga_inventory_items_60plus/` — broad food/tool/weapon/crafting/quest/resource inventory source library.
- `oga_crystal_mine/` — authored crystal-mine source.
- `oga_magic_staff_set/` — elemental staff source family.

Recommended use: classify and deduplicate inventory meshes against B36/B38/B46; promote only the strongest production candidates. Treat mine/staff assets as separate location/equipment sources.

## B54 — crystals / target / key collection

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b54/models/`

- `oga_lowpoly_crystals_28/` — 28 low-poly crystal source models.
- `oga_target_3d_2023/` — target/range prop source with multiple formats/color sets.
- `oga_key_collection/` — modern/old keys and keyring source.

Recommended use: resource/decor crystals, training/range dressing and quest/lock key props after scale/material/collision review.

## B55 — mammoth / lemur / rhinoceros / snail

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b55/models/`

- `oga_mammoth_lowpoly/`
- `oga_lemur_animated/`
- `oga_white_rhinoceros/`
- `oga_snail_photogrammetry/`

Recommended use: biome-specific fauna sources. Validate animation/material readiness individually; optimize the photogrammetry snail before any runtime promotion.

## B56 — hippo / oryx / aurochs / whale

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b56/models/`

- `oga_hippo_rigged/`
- `oga_beisa_oryx_rigged/`
- `oga_auroch_male_female/`
- `oga_whale_rigged_animated/`

Recommended use: large land fauna and lightweight aquatic fauna after skeleton/material/scale review. Whale includes a simple swim-animation source.

## B57 — gorilla / cobra / shark / camel

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b57/models/`

- `oga_gorilla_male/` — low-poly source; final texture not included by source.
- `oga_cobra_rigged/` — rigged/posed source, but no animations/final texture.
- `oga_shark_rigged_textured/` — rigged/textured aquatic source.
- `oga_camel_basemesh/` — basemesh source explicitly requiring production work.

Recommended use: mixed-readiness fauna source pool. Main integration chat should not treat all four as equally production-ready.

## B58 — animated male deer / elephant / Anklyosaurus

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b58/models/`

- `oga_old_deer_male_animated/` — rigged/animated male deer source with packed material maps.
- `oga_elephant_lowpoly_animated/` — rigged elephant source with multiple authored animations.
- `oga_anklyosaurus_static/` — static dinosaur source; not rigged/animated.

Recommended use: production-candidate deer/elephant after Godot import tests; Anklyosaurus only as a source mesh requiring rigging/animation if selected.

## B59 — prehistoric static fauna sources

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b59/models/`

- `oga_pentaceratops_static/`
- `oga_albertosaurus_static/`
- `oga_trex_static/`

Recommended use: optional authored prehistoric-region source pool. These are static source meshes and must not be treated as finished animated creatures.

## B60 — bridges / fortified gate

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b60/models/`

- `oga_big_stone_bridge/`
- `oga_wooden_bridge/`
- `oga_medieval_gatehouse/`

Recommended use: traversal landmarks, settlement entrances and fortifications after scale/collision/LOD work. Optimize the large stone bridge heavily before production promotion.

## B61 — water-powered sawmill / horse-drawn carriage

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b61/models/`

- `oga_medieval_waterpowered_sawmill/`
- `oga_horse_drawn_carriage/`

Recommended use: authored river/lumber/industry location and carriage/world-prop source. Carriage materials require repair/replacement before production use.

## B62 — authored NPC archetypes

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b62/models/`

- `oga_bartender_rigged/`
- `oga_old_lady_rigged/`
- `oga_monk_rigged_idle/`
- `oga_goblin_rigged_animated/`

Recommended use: authored settlement/enemy NPC candidates after skeleton/animation/material import checks. Use as distinct archetypes rather than mass-spawning identical models.

## B63 — rigged skeleton / Forest Monster / gibs

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b63/models/`

- `oga_skeleton_with_rig/` — simple rigged skeleton source.
- `oga_forest_monster_rigged_animated/` — rigged/animated creature with diffuse, normal and AO maps.
- `oga_forest_monster_gibs/` — matching separated body/gib source pieces.

Recommended use: authored enemy candidates after Godot skeleton/animation/material checks. Use gibs only if the final corpse/destruction direction needs them.

## B64 — Mudeater / Undead Squirrel / Daemon Statue

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b64/models/`

- `oga_mudeater_rigged_animated/` — rigged/animated humanoid creature with packed texture maps.
- `oga_undead_squirrel_animated/` — rigged/animated undead wildlife source.
- `oga_daemon_statue_rigged_animated/` — rigged statue/daemon with attack, die, spell and idle source animations.

Recommended use: distinct authored enemy archetypes only where they match final art direction; validate import, scale, materials and collisions before production promotion.

## B65 — Vampire Bat / Lava Golem

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b65/models/`

- `oga_vampire_bat_animated/` — textured, rigged and animated vampire-bat source.
- `oga_lava_golem_rigged_animated/` — rigged golem with idle/walk/attack source animation data; production materials require audit/rebuild.

## B66 — spider / boar / wolf / werewolf

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b66/models/`

- `oga_spider_animated/` — compact textured spider with idle/walk/attack.
- `oga_boar_rigged_animated/` — rigged/textured boar with walk/attack.
- `oga_wolf_rigged/` — rigged wolf source; animation readiness must be checked.
- `oga_werewolf_animated/` — textured animated werewolf with locomotion/combat/death clips.

## B67 — Universal Animation Library Standard

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b67/animations/`

- `quaternius_universal_animation_library_standard/` — free CC0 Standard edition with 45 humanoid animations for retargeting.

Important: this is the free Standard edition only, not the separate 120+ Source edition.

## B68 — humanoid bases / medieval soldier

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b68/models/`

- `oga_stylized_humanoid_base_yw/` — stylized textured rigged humanoid base.
- `oga_medieval_soldier_rigged_animated/` — low-poly medieval soldier/guard source with animations.
- `oga_simple_rigged_character_animated/` — simple textured rigged humanoid with idle/walk/jump.

## B69 — additional CC0 character sources

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b69/models/`

- `oga_cat_pilot_rigged_animated/` — rigged/animated character with multiple source actions and eye blendshapes.
- `kenney_animated_characters_3/` — Kenney CC0 rigged character package with four skins and basic animations.
- `oga_rigged_animated_humanoid/` — very low-poly humanoid source for prototyping/retargeting; rig hookup may need cleanup.

## B70 — Zantar / Bombalach / Hydrach / Fat Demon

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b70/models/`

- `oga_zantar_rigged_animated/` — gelatinous-cube enemy source described as rigged/animated.
- `oga_bombalach_rigged_animated/` — mud/stone creature source with low/high-poly data and animation set.
- `oga_hydrach_creature/` — original CC0 model/texture RAR archives preserved physically; hosted 7z extraction was unsafe. Animation status remains uncertain and must be inspected locally.
- `oga_fat_demon_static/` — static low-poly demon with texture; requires rigging for active NPC use.

## B71 — farm animals / duck / rooster / chicken / pigeon

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b71/models/`

- `quaternius_lowpoly_animated_farm_animals/` — animated low-poly farm-animal source pack including pig/cow/horse/llama/dog/sheep variants.
- `oga_rigged_duck/` — rigged duck with source waddle/peck actions.
- `oga_rooster_animated/` — rigged/animated rooster with diffuse/normal maps.
- `oga_chicken_animated/` — rigged/animated chicken with diffuse/normal maps.
- `oga_pigeon_rigged_animated_untextured/` — rigged/animated pigeon; explicitly untextured.

## B72 — forest fauna

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b72/models/`

- `oga_fox_animated/` — compact fox with diffuse/normal maps and idle/walk/run/bite/digging/death clips.
- `oga_deer_female_rigged_animated/` — rigged/animated doe with packed diffuse texture.
- `oga_rabbit_rigged_animated/` — rigged/animated rabbit with packed diffuse/normal maps.
- `oga_white_bear_static/` — textured low-poly white bear; explicitly static/unrigged.

Integration rule: these are source candidates. Main game chat should selectively retarget, normalize scale/materials/collisions/LOD and promote only chosen production assets. Do not wire whole source libraries directly into runtime.

## B73 — animated fish

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b73/models/`

- `oga_fish_rigged_animated/` — rigged/animated general fish source.
- `oga_esox_animated/` — detailed fish with idle/slow/fast swim and PBR-ish maps.
- `quaternius_animated_fish_pack/` — low-poly animated fish library for biome variety.

## B74 — cat / dog / horse / tiger

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b74/models/`

- `oga_simple_cat_animated/` — extremely low-poly cat with simple shape-key walk and author's CC0 texture.
- `oga_dog_jack_russell_rigged/` — low-poly rigged Jack Russell.
- `oga_rigged_horse/` — rigged horse source ready for animation work.
- `oga_tiger_rigged/` — low-poly rigged/unwrapped tiger source.

## B75 — crocodile / birds / wasp

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b75/models/`

- `oga_crocodile_animated/` — textured crocodile with idle/walk/attack/death source clips.
- `oga_yellow_billed_shrike_rigged/` — IK-rigged background bird with high-resolution maps.
- `oga_modified_wasp_animated/` — polygonal wasp with simple idle animation.
- `oga_bird_rigged_animated/` — generic textured rigged/animated small-bird candidate.

## B76 — dungeon kits / Genie

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b76/models/`

- `kenney_mini_dungeon_2/` — compact Kenney dungeon source kit.
- `kenney_modular_dungeon_kit_2/` — modular Kenney dungeon-building kit.
- `oga_medieval_dungeon_interior_2026/` — 2026 modular medieval dungeon interior with animated doors.
- `oga_genie_rigged_animated/` — higher-poly rigged Genie with floating animation; optimize before use.

## B77 — furniture / home / industrial

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b77/models/`

- `kenney_furniture_kit_120/` — broad optimized furniture/building-material source library.
- `oga_home_interior_assets_2025/` — compact modern home-interior prop collection.
- `oga_modular_industrial_157/` — 157-mesh low-poly industrial construction library.
- `oga_pbr_industrial_a52_2025/` — modern Blender/PBR factory/industrial source assets.

## B78 — Kenney nature / castle / retro medieval

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b78/models/`

- `kenney_nature_kit_2_1/` — very broad 330+ object nature source library.
- `kenney_castle_kit/` — modular fortification/castle source kit.
- `kenney_retro_medieval_kit/` — deliberately retro/PSX-style medieval source family.

## B79 — pirate / graveyard / fantasy town / watercraft

Status: **READY / PHYSICAL**
Path: `assets/staging/sourcechat_b79/models/`

- `kenney_pirate_kit_2_1/` — island/port/pirate/ship source library.
- `kenney_graveyard_kit_5/` — graveyard/coffin/fence/prop source library.
- `kenney_fantasy_town_2/` — large modular fantasy/medieval town kit.
- `kenney_watercraft_kit/` — broad boat/ship/watercraft source kit.

Integration rule: these remain source libraries. Main game chat should choose a consistent visual family per biome/location, normalize scale/materials/collisions/LOD and promote only selected production assets rather than wiring whole staging directories into runtime.
