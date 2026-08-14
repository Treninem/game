# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import. Registry entry != physical import: mark an asset imported only when its files are actually present.

## Verified CC0 production sources

### Nature / terrain / vegetation
- Kenney Nature Kit / Survival Kit — CC0.
- Quaternius nature families — CC0 after pack-level verification.
- Poly Haven — CC0 PBR textures/models/HDRIs — https://polyhaven.com/ — primary realistic material/environment source.
Maintain terrain, soil, sand, stone, gravel, mud, snow, ice, cliffs, caves, trees, grass, crops, moss, reeds, flowers, bushes and biome variants.

### Reflection / glass / windows / mirrors — high priority
Folders: `assets/materials/reflective/`, `assets/materials/glass/`, `assets/shaders/glass/`, `assets/shaders/reflection/`.
- Godot Asset Store Frosted Glass FX — CC0, Godot 4.1+, refraction/blur/roughness/chromatic aberration — https://store.godotengine.org/asset/binbun3d/frosted-glass-fx/
- Godot Shaders Rain on Glass — shader code CC0 — https://godotshaders.com/shader/rain-on-glass-2/
Required: mirrors clean/aged/dirty/scratched/cracked; glass clear/tinted/frosted/dusty/wet/fogged/scratched/cracked/shattered/reinforced; vehicle/display/bottle/lens/screen glass. Windows react to weather and day/night.

### Water / rivers / waterfalls / wet surfaces — high priority
Folders: `assets/materials/water/`, `assets/shaders/water/`, `assets/vfx/water/`, `assets/vfx/waterfalls/`, `assets/decals/wet/`.
- Binbun Godot Water — CC0 shader with caustics/refraction/depth/foam — https://forum.godotengine.org/t/free-water-shader-with-caustics-cc0/134925
- TomAzod Godot Water Splash VFX — CC0 dynamic splash: ripples/foam/bubbles/pillar/scenes/scripts — https://tomazod.itch.io/godot-splash-vfx
- Godot Shaders Water Shader Easy Setup — CC0 dynamic movement, dual normal layers, refraction/distortion — https://godotshaders.com/shader/water-shader-easy-setup/
- Godot Shaders Water Shader — CC0 depth/refraction/animated normal detail — https://godotshaders.com/shader/water-shader-2/
- Godot Shaders 2D Waterfall — CC0 shader code — https://godotshaders.com/shader/2d-waterfall/
- Godot Shaders Low Poly Waterfalls — CC0 shader code — https://godotshaders.com/shader/low-poly-waterfalls/
- Godot Shaders Waterfall Trail Shader — CC0 shader code — https://godotshaders.com/shader/waterfall-trail-shader/
Water coverage: ocean/lake/river/stream/pond/swamp/puddle/shallow/deep/clear/turbid/muddy/industrial/underwater. Waterfalls need flowing body, edge breakup, impact foam, spray, mist, droplets and downstream turbulence. Effects: waves/current/ripples/rain rings/splashes/wakes/bubbles/foam/shore spray/caustics/refraction/depth/Fresnel.
Wet asphalt/stone/soil/wood/roofs/vehicles dynamically change darkening, roughness and reflection.

### Animated fire / smoke / steam / heat
Maintain candle, lighter, torch, campfire, fireplace, stove, forge, barrel/object/building/grass/forest fires. Layer flames + sparks + embers + ash + smoke + light flicker + heat distortion. Add steam for hot water, cooking, industrial pipes, vents, geysers and extinguishing fire. Smoke needs wispy, chimney, campfire, dense black fire, white steam-like, ground-hugging and distant-column variants. Approved discovery/source families remain OpenGameArt CC0 animated effects and Kenney Particle/Smoke packs.

### Weather / atmosphere / sky — high priority
Folders: `assets/vfx/weather/`, `assets/vfx/atmosphere/`, `assets/shaders/weather/`, `assets/shaders/sky/`.
- Kenney Particle Pack — 80 CC0 VFX sprites — https://www.kenney.nl/assets/particle-pack
- Kenney Smoke Particles — 70 CC0 smoke/explosion VFX files — https://www.kenney.nl/assets/smoke-particles
- Godot Shaders CC0 archive — includes water ripples, foggy glass, animated lava and other reusable procedural effects — https://godotshaders.com/shader-license/cc0/
- Godot Shaders Pixelated Animated Water/Clouds — CC0 code, useful procedural motion reference — https://godotshaders.com/shader/pixelated-animated-water/
- OpenGameArt 16x16 Animated Tiles — CC0 animated water/waterfall tiles; reference/fallback for animation timing — https://opengameart.org/content/16x16-animated-tiles

Required dynamic weather library:
- rain: drizzle, light, normal, heavy, downpour, wind-driven sheets; near streaks + distant volume + roof/ground/water/window splashes;
- lightning: cloud flash, distant sheet lightning, single bolt, branching bolt, repeated strike, ground strike, horizon storm; synchronize light flash and delayed thunder;
- wind: breeze, gusts, strong wind, gale, storm; grass/tree/crop deformation plus leaves, petals, pollen, dust, sand, snow and debris;
- clouds: wispy/cirrus, cumulus, scattered, overcast, dark storm, fast fronts, low clouds, dawn/dusk/night; cloud shadows;
- fog/mist: ground mist, morning fog, river/swamp mist, valley fog, waterfall mist, cave haze, dense storm fog;
- snow: sparse, normal, heavy, wet snow, blizzard, wind-driven, kicked-up snow and accumulation cues;
- hail: small/large hail particles, surface bounce/splash cues;
- dust/sand: motes, footsteps/impacts, vehicle trails, gusts, dust devils, sandstorm wall;
- leaves/petals/seeds: falling, swirling, gust-driven, seasonal variants;
- atmospheric insects: fireflies/gnats/pollen where biome/time requires;
- heat: heat haze/mirage above fire, desert, asphalt and machinery;
- cold: breath vapor, frost particles, drifting ice crystals;
- volcanic/industrial: ash fall, soot, steam vents, smoke plumes, sparks.

### Vegetation animation / environmental response
Do not keep vegetation static. Shared wind shader/system must support grass, crops, reeds, bushes, flowers, tree branches/crowns and hanging vines with per-species stiffness, gust response and distance LOD. Add interaction bending near player/animals/vehicles where affordable. Rain adds wetness; snow adds accumulation cues; storms increase sway; fire can transition vegetation to burning/scorched states.

### Ground interaction VFX
Maintain reusable effects per surface: dirt dust, sand kick, gravel chips, grass/leaf disturbance, mud splash, shallow-water splash, snow puff, stone dust, wood splinters, metal sparks, glass shards. Trigger from footsteps, running, landing, tools, combat, falling objects and vehicles. Scale by force/speed and surface material.

### Reflective polished surfaces
Include chrome, polished steel/aluminum, wet metal, glossy ceramic/tile, varnished wood, polished marble/granite, ice, glossy plastic and painted vehicle surfaces. Use roughness/normal variation; Poly Haven HDRIs provide CC0 reflection environments.

### Physical surface detail / decals
Maintain fingerprints, dust, grime, scratches, cracks, condensation, droplets, streaks, frost, ice, foam, wet edges, puddles, mud splashes, moss, leaks, scorch, impact, broken glass, soot, ash and waterline marks. Prefer parameterized state transitions.

### World content coverage
Continue broad approved sources for buildings/infrastructure/interiors, humans/NPC animations, animals/ecology, food/farming, resources/crafting/tools, weapons/armor, vehicles/logistics, machines/production/technology, VFX/destruction, audio and complete UI. Shared material/VFX systems must be reused across world assets.

## Environmental VFX composition rule
A production effect is a system, not one texture. Combine as appropriate: shader + particles + mesh/flipbook + light + decal + audio + environment/material response. Examples: storm = clouds + darkening + wind + rain + wetness + lightning + thunder + water response; waterfall = flowing water + foam + mist + spray + impact audio; fire = flame + embers + smoke + light + heat distortion + scorch.

## Material-state system requirement
Support dry↔wet, clean↔dirty, intact↔cracked/broken, warm↔frosted/condensed, calm↔storm water, still↔wind-blown vegetation, normal↔burning/scorched, day↔night reflection. Prefer shader parameters/masks over duplicate meshes.

## Performance / quality tiers
- High/Ultra: nearby high-density particles, richer shaders, important true/planar reflections and interaction VFX.
- Medium: reduced particles, SSR/probes, simplified fog/cloud/water layers.
- Low/distant: billboard/flipbook/static approximations, aggressive culling and cheap shaders.
- Weather emitters follow camera/local cells rather than simulating particles across the whole map.
- Vegetation wind runs in shared GPU shaders; avoid per-plant scripts.
- Pool/reuse impact/splash/fire emitters.

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