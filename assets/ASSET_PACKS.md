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
Future magic must reuse semantic VFX events instead of hard-coding a texture into combat.

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