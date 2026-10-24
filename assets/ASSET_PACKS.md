# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import. Registry entry != physical import: mark an asset imported only when its files are actually present.

## Verified CC0 production sources

### Nature / terrain / vegetation
- Kenney Nature Kit / Survival Kit — CC0.
- Quaternius nature families — CC0 after pack-level verification.
- Poly Haven — CC0 PBR textures/models/HDRIs — https://polyhaven.com/ — primary realistic material/environment source.
- Binbun Stylized 3D Grass Shader — CC0 Godot 4 shader with noise-driven wind, atlas variation and billboard options — https://forum.godotengine.org/t/free-stylized-3d-grass-shader-cc0/134880 — target `assets/shaders/vegetation/binbun_grass/`.
Maintain terrain, soil, sand, stone, gravel, mud, snow, ice, cliffs, caves, trees, grass, crops, moss, reeds, flowers, bushes and biome variants.

### Reflection / glass / windows / mirrors — high priority
Folders: `assets/materials/reflective/`, `assets/materials/glass/`, `assets/shaders/glass/`, `assets/shaders/reflection/`.
- Godot Asset Store Frosted Glass FX — CC0, Godot 4.1+, refraction/blur/roughness/chromatic aberration — https://store.godotengine.org/asset/binbun3d/frosted-glass-fx/
- Godot Shaders Rain on Glass — shader code CC0 — https://godotshaders.com/shader/rain-on-glass-2/
Required: mirrors clean/aged/dirty/scratched/cracked; glass clear/tinted/frosted/dusty/wet/fogged/scratched/cracked/shattered/reinforced; vehicle/display/bottle/lens/screen glass. Windows react to weather and day/night.

### Water / rivers / waterfalls / underwater / wet surfaces — high priority
Folders: `assets/materials/water/`, `assets/shaders/water/`, `assets/vfx/water/`, `assets/vfx/waterfalls/`, `assets/vfx/underwater/`, `assets/decals/wet/`.
- Binbun Godot Water — CC0 shader with world-space caustics, refraction, depth, foam and smooth/toon shading — https://forum.godotengine.org/t/free-water-shader-with-caustics-cc0/134925
- TomAzod Godot Water Splash VFX — CC0 dynamic splash: ripples/foam/bubbles/pillar/scenes/scripts — https://tomazod.itch.io/godot-splash-vfx
- Godot Shaders water/waterfall CC0 family remains approved after individual verification.
Water coverage: ocean/lake/river/stream/pond/swamp/puddle/shallow/deep/clear/turbid/muddy/industrial/underwater. Waterfalls need flowing body, edge breakup, impact foam, spray, mist, droplets and downstream turbulence. Effects: waves/current/ripples/rain rings/splashes/wakes/bubbles/foam/shore spray/caustics/refraction/depth/Fresnel. Wet asphalt/stone/soil/wood/roofs/vehicles dynamically change darkening, roughness and reflection.
Underwater coverage: world-space caustic light patterns on terrain/rocks/objects, depth color absorption, fog/turbidity, suspended particles/plankton, bubbles, current-driven vegetation, surface view from below, distortion, shafts of light, muffled ambience and transition when camera crosses water surface. Use quality tiers and avoid expensive full-screen effects when not underwater.

### Ice / frost / snow material systems
Folders: `assets/materials/ice/`, `assets/shaders/ice/`, `assets/vfx/frost/`, `assets/decals/snow/`.
- Dragonforge Godot 3D Ice Material Shaders and VFX — pack marked CC0; free download includes an ice shader and uses CC0 material sources — https://dragonforge-development.itch.io/godot-3d-vfx-ice-shaders — verify each bundled dependency before physical import.
Required: clear/blue/cloudy/cracked/thin/thick ice, frozen puddles/lakes, icicles, frost on windows/metal/vegetation, slippery/wet thaw states, ice cracking cues, snow crust/powder/wet snow, footprint/tire depressions and melt-to-water transitions.

### Animated fire / smoke / steam / heat
Maintain candle, lighter, torch, campfire, fireplace, stove, forge, barrel/object/building/grass/forest fires. Layer flames + sparks + embers + ash + smoke + light flicker + heat distortion. Add steam for hot water, cooking, industrial pipes, vents, geysers and extinguishing fire. Smoke needs wispy, chimney, campfire, dense black fire, white steam-like, ground-hugging and distant-column variants. Approved discovery/source families remain OpenGameArt CC0 animated effects and Kenney Particle/Smoke packs.

### Magic / combat / explosions / collisions — physically integrated core
Folders: `assets/vfx/`, `assets/vfx/third_party/`, `assets/decals/impact/`.
- Project-owned procedural VFX Core Pack is physically integrated through `scripts/vfx_library.gd`; runtime catalog: `assets/vfx/README.md`; detailed registry: `assets/registry/VFX_MAGIC_COMBAT_EXPLOSIONS_2026-08-14.md`.
- Current magic presets: arcane, fire, frost, lightning, poison, heal, holy, dark, portal, shield.
- Combat presets: melee swing, slash hit, blunt hit, block/parry, critical hit, defeat burst.
- Explosion presets: small, medium, large with flash + hot particles + debris + smoke + shockwave.
- Collision presets: metal sparks, stone fragments/dust, wood fragments, dirt dust, glass shards, water splash/wave.
- Physically imported CC0 enhancement packs under `assets/vfx/third_party/`: Kenney Particle Pack, Kenney Smoke Particles, OpenGameArt 2D Spell Effects, Arcane Magic Effect, Earth Impact - Magic Effect and Weapon Slash - Effect. Each pack keeps `SOURCE.md` and `LICENSE.txt`.
- Expanded physical CC0 magic library adds 16 pack folders / 329 files: `oga_light_magic`, `oga_angel_shield`, `oga_plasma_electric`, `oga_basic_pixel_spells`, `oga_magic_forcefield_grayscale`, `oga_magic_forcefield_color`, `oga_radial_lightning`, `oga_fireball_godot`, `oga_assorted_fireballs`, `oga_fireball_umplix`, `oga_magic_spell_icons`, `oga_energy_shield`, `oga_resurrection_spell`, `oga_magic_mirror_portal`, `oga_m484_lightning_weapon`, `oga_lightning_effect`. Sources and licenses are preserved inside every folder. These are staged library assets only; importing them does not authorize automatic gameplay integration.
- High-quality Godot 4 CC0 VFX library is physically staged under `assets/vfx/third_party/binbun_godot4_core/`, `assets/vfx/third_party/binbun_godot4_combat_magic/` and `assets/vfx/third_party/binbun_godot4_electric/`. It contains the free Binbun/Binbun3D `ElementalMagicFX`, `FlameFX`, `ExplosionFX`, `DarkMagicFX`, `BattleFX`, `StylizedHitFX` and `ElectricFX` packs: 148 repository files, including 32 Godot scenes, 58 shaders and 25 GDScript files plus shared dependencies and license/source metadata. Paid/full showcase scenes and generated `.import`/`.uid` files are excluded. Internal `res://` paths are rewritten to the staged library paths. These assets remain library-only until the main game-development flow explicitly integrates them.
- Binbun `Beam VFX` free CC0 base is physically staged at `assets/vfx/third_party/binbun_godot4_beam/`: 10 files containing one customizable Godot beam scene, five shaders, one controller GDScript, a shared placeholder texture plus `SOURCE.md`/`LICENSE.txt`. It was sourced specifically from a public mirror path named `GodotBeamVFXFree`; paid preset files are not included. Internal `res://` paths are rewritten for the staged library, and the beam remains library-only until explicitly integrated.
- OpenGameArt CC0 Magic Tier 2 is physically staged as 14 folders / 383 files: `oga_cosmic_time_magic`, `oga_pure_projectile_magic`, `oga_fire_wrath_magic`, `oga_nature_magic`, `oga_water_magic`, `oga_angel_wings_magic`, `oga_music_magic`, `oga_blood_magic`, `oga_fire_circle_fx`, `oga_cc0_rune_icons`, `oga_runes_2d`, `oga_teleport_circle`, `oga_teleporter_volumetric_blue`, `oga_teleporter_volumetric_edited`. It expands time/cosmic, projectile, fire, nature/heal, water, holy/wing, bard/music, blood, ritual/rune and teleport coverage. Each folder keeps `SOURCE.md` + `LICENSE.txt`.
- Clean ritual/barrier/summoning expansion is physically staged as 20 files: `oga_fire_trap_rune`, `oga_magic_barrier_gfroad`, `oga_summoning_circles_vector`. The four summoning-circle designs retain PNG/SVG/AI source variants; macOS archive metadata is removed and file modes normalized.
- Elemental weapon + dark-magic UI expansion is physically staged as 88 files: `oga_elemental_weapons_magic` contains 72 PNG weapon-effect variants organized into Arcane/Blood/Fire/Ice/Light/Nature, while `oga_dark_magic_icons` contains eight 128x128 spell/ability icons plus preview/metadata.
- Modern procedural CC0 Godot 4 magic shaders are staged code-only under `assets/vfx/third_party/godotshaders_portal_cc0/`: `portal_2d.gdshader`, `pixelated_stencil_portal.gdshader`, `black_hole_3d.gdshader`, `black_hole_2d.gdshader`, `magic_pulse_glow_2d.gdshader`, plus source/license metadata. Only CC0 shader code is copied; page screenshots/videos are intentionally excluded.
- CC0 magic audio is physically staged under `assets/audio/third_party/oga_magic_cc0/`: 12 actual sound files in `general_cast`, `healing`, `teleport`, `freeze` and `fire`, plus source/license metadata (22 repository files total). These are staged sound-library resources only and are not bound to gameplay events in this asset-collection flow.
- Detailed cross-chat selection map: `assets/registry/MAGIC_VFX_AUDIO_LIBRARY_2026-08-15.md`. Use it to choose staged resources by concept (portal, time, gravity, summon, barrier, fire, ice, lightning, healing, water, blood/dark, projectile/beam, enchanted weapons, music/bard and spell UI) before importing or generating duplicates.
Future magic must reuse semantic VFX events instead of hard-coding a texture or audio filename into combat.

### Weather / atmosphere / sky — high priority
Folders: `assets/vfx/weather/`, `assets/vfx/atmosphere/`, `assets/shaders/weather/`, `assets/shaders/sky/`.
- OpenGameArt Fog Animation — CC0 tileable 40-frame fog/cloud animation — https://opengameart.org/content/fog-animation — target `assets/vfx/atmosphere/fog/oga_fog_animation/`.
- Godot Shaders Basic Cloud Shader — CC0 FogVolume/cloud shader code — https://godotshaders.com/shader/basic-cloud-shader/ — target `assets/shaders/sky/basic_clouds/`.
- Binbun Dynamic Sky — CC0 Godot shader with dynamic sun, day/sunset/night blending, clouds, stars and parallax — https://forum.godotengine.org/t/free-sky-shader-with-dynamic-sun-and-customizability-cc0/134798 — target `assets/shaders/sky/binbun_dynamic_sky/`.
- Godot Shaders Animated Wind/Cloud Shadow Patches — CC0 procedural moving wind/cloud-shadow code — https://godotshaders.com/shader/animated-grassy-wind-or-cloud-shadow-pixel-patches-overlay/.
- Godot Shaders CC0 archive — approved discovery source; verify each individual shader before physical import — https://godotshaders.com/shader-license/cc0/.
Required dynamic weather library: rain from drizzle to wind-driven downpour; local/distant lightning and delayed thunder; wind from breeze to storm; layered clouds and cloud shadows; ground/river/valley/storm fog; snow and blizzard; hail; dust/sandstorms; leaves/petals/pollen; insects/fireflies; heat haze; frost/breath vapor; volcanic ash/industrial soot/steam.

### Vegetation / cloth / flexible-object environmental motion
Do not keep the world static. Shared wind systems must support grass, crops, reeds, bushes, flowers, tree branches/crowns, hanging vines, flags, banners, curtains, laundry, tarps, tent cloth, ropes, cables, hanging signs and lightweight debris. Use per-material stiffness, gust response, damping and distance LOD. Add interaction bending near player/animals/vehicles where affordable. Rain adds weight/wetness; snow adds accumulation; storms increase sway; fire can transition vegetation/cloth to burning/scorched states. Prefer shared GPU noise/turbulence over per-object scripts.

### Additional animated world phenomena — proactive coverage
- Godot Shaders LAVA shader animated — CC0 animated lava/energy shader with noise, wave distortion and emission — https://godotshaders.com/shader/lava-shader-animated/ — target `assets/shaders/lava/animated_lava/`.
Also maintain systems/assets for cooling lava crust, bubbles/splashes, ice/frost/melting, snow tracks/drifts, aurora/stars/meteors, god rays/light shafts, tornado/whirlwind/dust devil, ocean storm/whitecaps, underwater particles/caustics/currents, distant bird flocks, insects/butterflies and fish schools.

### Ambient life / flocking / schooling
Maintain reusable animation/behavior-ready visuals for bird flocks, bats, insects, butterflies, fireflies, flies/gnats, fish schools and small background wildlife. Need near/far LOD: real animated meshes nearby, cheap impostors/particles at distance. Movement must respond to wind/current, time of day, biome and disturbances instead of looping in one fixed spot.

### Ground interaction VFX
Maintain reusable effects per surface: dirt dust, sand kick, gravel chips, grass/leaf disturbance, mud splash, shallow-water splash, snow puff, stone dust, wood splinters, metal sparks, glass shards. Trigger from footsteps, running, landing, tools, combat, falling objects and vehicles. Scale by force/speed and surface material.

### Reflective polished surfaces
Include chrome, polished steel/aluminum, wet metal, glossy ceramic/tile, varnished wood, polished marble/granite, ice, glossy plastic and painted vehicle surfaces. Use roughness/normal variation; Poly Haven HDRIs provide CC0 reflection environments.

### Physical surface detail / decals
Maintain fingerprints, dust, grime, scratches, cracks, condensation, droplets, streaks, frost, ice, foam, wet edges, puddles, mud splashes, moss, leaks, scorch, impact, broken glass, soot, ash and waterline marks. Prefer parameterized state transitions.

### World content coverage
Continue broad approved sources for buildings/infrastructure/interiors, humans/NPC animations, animals/ecology, food/farming, resources/crafting/tools, weapons/armor, vehicles/logistics, machines/production/technology, VFX/destruction, audio and complete UI. Shared material/VFX systems must be reused across world assets.

## Environmental VFX composition rule
A production effect is a system, not one texture. Combine as appropriate: shader + particles + mesh/flipbook + light + decal + audio + environment/material response. Storm = clouds + darkening + wind + rain + wetness + lightning + thunder + water response; waterfall = flowing water + foam + mist + spray + audio; fire = flame + embers + smoke + light + heat distortion + scorch; lava = animated material + emission + crust + bubbles + heat haze + smoke/steam + light; underwater = surface + refraction + caustics + depth fog + particles + current + audio.

## Material-state system requirement
Support dry↔wet, clean↔dirty, intact↔cracked/broken, warm↔frosted/condensed, calm↔storm water, still↔wind-blown vegetation/cloth, normal↔burning/scorched, snow↔melted/wet, water↔ice↔thaw, lava↔cooling crust, day↔night reflection. Prefer shader parameters/masks over duplicate meshes.

## Performance / quality tiers
- High/Ultra: nearby high-density particles, richer shaders, important true/planar reflections and interaction VFX.
- Medium: reduced particles, SSR/probes, simplified fog/cloud/water layers.
- Low/distant: billboard/flipbook/static approximations, aggressive culling and cheap shaders.
- Weather emitters follow camera/local cells rather than simulating particles across the whole map.
- Vegetation/cloth wind runs in shared GPU shaders; avoid per-object scripts.
- Pool/reuse impact/splash/fire emitters.
- Heavy cloud/fog/lava/water/underwater systems expose quality switches and avoid unnecessary transparent overdraw.

## Import policy
1. Prefer `.glb`/`.gltf` for models and optimized PNG/WebP masks/atlases for materials/VFX.
2. Import only verified free/redistributable content; preserve source/license metadata.
3. Do not dump huge archives blindly; import useful optimized production content.
4. Deduplicate meshes/materials/textures/animations/VFX atlases.
5. Normalize scale/orientation/pivots/collision/naming/LOD.
6. Every third-party pack folder gets `SOURCE.md` and/or `LICENSE.txt` before production use.
7. Track dependencies: mesh + PBR + shader + particles + probe/environment + VFX + audio + gameplay tag.
8. Registry entry is not a physical import until files exist in repository.

## Stable taxonomy
`nature`, `materials`, `lighting`, `world`, `buildings`, `interiors`, `characters`, `animations`, `animals`, `food`, `items`, `resources`, `tools`, `weapons`, `clothing`, `props`, `vehicles`, `machines`, `technology`, `shaders`, `vfx`, `decals`, `audio`, `music`, `ui`, `icons`, `prototype`.

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack. Goal: a coherent reusable production library, not a random pile of downloads.
## Integrated woodland and animated human selection — 2026-10-18

- PRODUCTION_READY: Quaternius RPG Ranger from existing source chat B36, normalized skinned GLB retained under `assets/production/characters/ranger/`; the live human selection below supersedes its body mesh. Its bow animation source is reused for retargeting.
- INTEGRATED: six selected Quaternius Stylized Nature MegaKit models from existing source chat B44: `assets/production/nature/woodland/`. Authored textured trees replace geometric crowns in near and far rendering; shared wind animates leaves.
- INTEGRATED: two CC0 photographic diffuse ground textures from the existing OpenGameArt Seamless Textures pack: `assets/production/materials/ground/`.
- Every production selection preserves source and license metadata. Detailed record: `assets/registry/VISUAL_WORLD_INTEGRATION_2026-10-18.md`.

- INTEGRATED: one existing CC0 Tree Leaves Pack 1 silhouette atlas by TrachinusDraco, runtime-capped to 256 px with mipmaps, for seasonal wind leaves under `assets/production/nature/woodland/`.
- INTEGRATED: axe, dagger visual proxy, wooden bow and arrow from the existing B36 Quaternius Low Poly RPG Pack, normalized under `assets/production/weapons/woodland/`; animated equipment and physical bow projectiles.

### Adult human and temperate tree selection — 2026-10-19

- INTEGRATED: existing CC0 byzmod3d B89 anatomical human geometry (`homen_base.obj`) under `assets/production/characters/citizen/`, normalized to 1.8 m and fitted to the existing Quaternius Animated Human rig. Ten clips, clothing and skin variants retained; Axe_Chop reuses the physically staged CC0 Universal Animation Library 2 Standard. Project materials replace the source OBJ's absent MTL. This is an anatomical mesh, not a photorealistic scan.
- INTEGRATED: existing CC0 Free Vegetation Asset Pack with LOD, physically present on `main` under B44, selected into `assets/production/nature/temperate/`. Reconstructed materials reuse original branch textures and existing Quaternius bark. Shared environment wind shader supplies required black-key cutout; seeded card layers enrich the canopy.
- INTEGRATED: existing production city-core wall, window, door, tile roof and gable modules now form ordinary capital house facades in batched geometry. Solid collision shells remain; this does not establish enterable capital homes.
- Details and limitations: `assets/registry/VISUAL_WORLD_INTEGRATION_2026-10-18.md`.

- INTEGRATED: `TemperateTree_Broad.glb`, the existing B44 Free Vegetation `tree_leaves_higher` mesh with original `branches_leaves.png`, grounded to 11 m and using shared foliage wind/cutout. Selected for the near-start forest.
- INTEGRATED: existing B47 Quaternius city-core `Prop_Chimney.gltf` and its buffer/textures, selected for ordinary capital roofs with wider eaves. Ordinary houses still have solid collision shells.

- INTEGRATED — 2026-10-19 contact refinement: three existing CC0 rubberduck wood-hit sounds from B04, preserving original filenames under `assets/audio/world/oga_100_cc0_sfx_2/`. Source/license metadata retained; no download. Axe_Chop retargeting now aligns the source and target shoulder axes before transferring motion.

- INTEGRATED — 2026-10-19 capital-square follow-up: Bench, Lantern_Wall, Workbench, Barrel and Barrel_Apples from the existing physically staged B46 CC0 Quaternius Fantasy Props MegaKit Standard, selected into `assets/production/medieval/capital_square/`. Original glTF buffers and OpenGL furniture/metal textures plus source licenses retained. Props are measured, grounded and given collision; no new download. Existing market-stall scene reused.
- INTEGRATED — existing CC0 OpenGameArt seamless photograph `100_1453_seamless.JPG` selected as `assets/production/materials/ground/stone_paving.jpg` for capital paving. Mipmapped, world-scaled diffuse only.

- INTEGRATED — 2026-10-19 household furniture: existing B46 CC0 Chest_Wood glTF, buffer and shared textures selected into `assets/production/medieval/capital_square/`; original open/close clips drive actual storage. Existing production Bench and Quaternius Bed/Table reused for household places. Physical source and both source licenses checked on main; no new download.

## Character family review — 2026-10-19
- INTEGRATED in the 0.10.7.2 review candidate: MakeHuman native male/female bodies, separate face/hair/garments and a playable creator. Source selections: `assets/staging/characters/makehuman_mpfb_core/` and `makehuman_system_selected/`; target: `assets/production/characters/realistic/`. Official core/system graphics are CC0; no tool code embedded. Main physical confirmation and final production readiness are pending. See `assets/registry/REALISTIC_HUMANS_2026-10-19.md`.

## Forest understory review — 2026-10-20
- INTEGRATED in the review: `assets/production/nature/woodland/Grass_Ground.glb`, a 155-triangle, 0.38 m derivative of the existing Quaternius CC0 `Grass_Wispy_Tall.glb`. Embedded texture retained; existing woodland license applies. No new source pack or download. Reproducer/checksums: `tools/prepare_ground_cover.py`, adjacent `Grass_Ground.source.json`. Existing temperate trees and shrub/fern assets supply the denser bounded forest. See `assets/registry/FOREST_UNDERSTORY_2026-10-20.md`.

## Eye color selection — 2026-10-20 review
- INTEGRATED in review: five existing MakeHuman CC0 eye atlases in `assets/production/characters/realistic/eyes/`; exact source hashes and license preserved there. Runtime choice and save compatibility verified on both bodies. No new download; STAGED_PHYSICAL on main is not claimed.

- INTEGRATED in review: Rehman Polanski Viking tunic/pants/boots, selected from official MakeHuman suits02 CC0 pack; local physical files and hashes under `assets/staging/characters/makehuman_viking_selected/`. Physical confirmation on main pending. Selected outfit is referenced by the review male/female GLBs with per-body normal/AO maps; overall art acceptance remains open. Builder: `tools/build_viking_humans.py`. See `assets/registry/VIKING_HUMAN_WARDROBE_2026-10-21.json`.

## Household concept kit — 2026-10-22 review
- INTEGRATED in review: 19 selected existing B46 CC0 Fantasy Props MegaKit Standard objects, normalized in Blender into `assets/production/interiors/architecture/HouseholdProps.glb`; editable `.blend`, source license and 512px cloth derivatives retained. Original source files were verified on main 0015b68c; no download. Shared photographed plank/stone and original metal/props maps reused. Project-authored Blender partitions, bedding, curtains, rugs and arched hearth are integrated alongside the selected objects. See `assets/registry/HOUSEHOLD_DRESSING_2026-10-21.json`. Overall concept acceptance remains open.

### Terrain path selection — 22 October 2026
Existing CC0 musdasch ground set: unmodified 512px dirt1/gravel1 selected as road_soil/road_gravel under assets/production/materials/ground/, with licenses, mipmaps and anisotropic filtering. Reuses photographic stone_paving.jpg. INTEGRATED in the review through shared terrain_paths.gd; no download. Exact scope/evidence: assets/registry/TERRAIN_PATHS_2026-10-22.json and docs/DEVELOPMENT_LOG_2026-10-22_TERRAIN_PATHS.json. This is not completed farms/animals/mountain content.

### Cottage exteriors and connected yards — 22 October 2026
INTEGRATED in review: project-authored Blender worked timber/stone, planter, flowers and open timber store with selected existing B47 CC0 WoodenFence_Single geometry. Editable source and reproducer retained; actual game references CottageYardKit.glb. Existing photo wood/stone, temperate bush, woodland grass and animated B46 chest reused. No download or full concept/farm/livestock acceptance. See assets/registry/COTTAGE_YARDS_2026-10-22.json.

## Fitted human outfit — 2026-10-22 review
- INTEGRATED in review: both existing native human costumes retain their covered-body mask and authored outer surfaces, while the redundant visible OutfitLining shell is removed. Independent comparison preserves outer triangles/normals/UVs/weights, nine morphs, ten source clips, bind frames and embedded image pixels. Portable Blender sources: `assets/source/characters/fitted_outfit/`; current producer: `tools/export_fitted_outfit.py`. Source licenses remain the selected MakeHuman/Rehman Polanski CC0 records; no new pack or bitmap. Seven skinned parts remain. Existing CC0 woodland arrows also display a supplied fletcher batch on the actual bench, driven by finite recipe state. The standing work pose is project-authored. Full wardrobe, layer contact, human/weapon art and concept acceptance remain open. See `assets/registry/FITTED_HUMAN_OUTFIT_2026-10-22.json` and `docs/DEVELOPMENT_LOG_2026-10-22_WORK_WARDROBE.json`. Main physical staging is not newly claimed.

## Refined human contours — 2026-10-23 review
- INTEGRATED in review: `realistic_contours/{male,female}.glb` adds Blender-refined near skin/eyes and retains the exact accepted original body as a complementary distance mesh. Five other parts, original clothing triangles, nine morphs, ten source clips and embedded image pixels are independently compared. Existing CC0 sources and wardrobe maps are reused; no new pack/download/bitmap. Editable sources: `assets/source/characters/refined_contours/`; builder: `tools/refine_human_contours.py`. Eight skinned parts, explicit 7/9 metre body selection and the near eight-weight layout require the runtime helper. The baseline remains for preservation checks and the already-open user review. Hair, full skin/wardrobe realism, weak-PC frame-rate and concept acceptance remain open. See `assets/registry/HUMAN_CONTOURS_2026-10-23.json`. No new physical-staging-on-main claim.

## Character strand and iris surfaces — 2026-10-23 review
- INTEGRATED in review: existing MakeHuman CC0 atlases are reused by `hair_strands.gdshader` and `human_iris.gdshader`; source pixels, native geometry, wardrobe, rig and save profile remain unchanged. Local strand contrast/cutout, measured brown-iris centers and independent material reuse are verified. Four experimental Blender skin maps were not selected, so no new runtime texture or source pack is added. Full art acceptance is false. See `assets/registry/HUMAN_SURFACES_2026-10-23.json` and the character-surfaces journal.

- INTEGRATED in review: one Blender-authored UV response map separates neutral ring highlights from the cloth of the existing Rehman Polanski CC0 tunic on both native bodies. Original source pixels/UVs/rig/morphs/clips remain unchanged. The creator uses a small static reflection sky with its existing plain backdrop and lights. No rejected groom candidate is selected. Full human art acceptance remains false. See `assets/registry/TUNIC_MATERIAL_RESPONSE_2026-10-23.json` and the wardrobe-response journal. No new pack download or main physical-staging claim.

## Review family-home roof, lime plaster and meadow — 2026-10-23

INTEGRATED on the review branch: project-authored Blender layered shingle roof/gables/chimney and 130-triangle meadow blades; selected existing CC0 B29 plaster/shingle, cedar and musdasch rock photographs. Source packs remain STAGED_PHYSICAL on main; no new pack download. Production families: `assets/production/exteriors/family_home/`, `assets/production/interiors/materials/lime_plaster/`, `assets/production/nature/meadow/`. Editable geometry: `assets/source/exteriors/family_home/` and `assets/source/nature/meadow/`. Exact provenance, native constraints and open art limits: `assets/registry/REGION_SURFACES_2026-10-23.json`. Full concept/world acceptance remains false.

## City concept review models — 2026-10-23

`INTEGRATED` on the review branch, not main: `assets/production/architecture/townhouse/` and `market_court/`. Original Blender townhouse shells and carved fountain, selected existing B29 CC0 balcony, shared existing CC0 photographs, and authored clay response maps. Editable relative-linked sources: `assets/source/architecture/`. Registry: `assets/registry/CITY_CONCEPT_MODELS_2026-10-23.json`. Two repeated exterior shells are not newly enterable homes; full visual acceptance remains false. No third-party download.

## Functional public market — 2026-10-24 review

`INTEGRATED` on the review branch, not main: `assets/production/architecture/market_arcade/MarketArcade.glb`, editable relative-linked source in `assets/source/architecture/market_arcade/`. Original Blender-authored open arcade reuses the existing authored townhouse roof family and existing shared CC0 photo materials. No new third-party download. Registry: `assets/registry/PUBLIC_MARKET_2026-10-24.json`. Two 9m bays, measured post/roof collision and lantern anchors; public benches, finite goods and local obstacle navigation are live game behavior. Full city/human art acceptance remains false.


## Connected capital canal neighbourhood — 2026-10-24 review
- INTEGRATED in review only: original five-part Blender CapitalCanalKit (43,348triangles), editable source and safe exporter. Four96x16m actual open-vault bridges,6m quays, a continuous carved600m canal, conforming dry paving, existing shared photographs/water/wind/nature, one two-adult working household, shop and finite fletcher production. No new third-party pack or concept pixels. See assets/registry/CAPITAL_CANALS_2026-10-24.json. Main integration, full city composition, human/household variety and overall art acceptance are not claimed.

### Human-scale city surface family - 2026-10-24

INTEGRATED in review: fifteen metre-scaled street materials using existing CC0 ground photographs, differentiated stone/brick bond and gravel/soil treatments; six-metre ordinary carriageways, two-point-two-metre household lanes and three-metre canal promenades. Existing Blender CityStreetKit stone troughs and CottageYardKit wind-driven flowers reused for bounded pocket gardens; no new third-party download or generated bitmap. Grand arterials and physical canal bridges are retained. Scope, sources, measured door/stature limits and evidence: assets/registry/HUMAN_STREET_SCALE_2026-10-24.json. Full city composition, house density and art acceptance remain open.
