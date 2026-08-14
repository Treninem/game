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
- Godot Asset Store Frosted Glass FX — CC0, Godot 4.1+, customizable refraction, Gaussian/mipmap blur, roughness blur, chromatic aberration and rim lighting — https://store.godotengine.org/asset/binbun3d/frosted-glass-fx/
- Godot Shaders Rain on Glass — shader code CC0 — https://godotshaders.com/shader/rain-on-glass-2/
- Godot Shaders reflection/glass code may be used only where the individual shader license is compatible/verified.
Required variants: clean mirror, aged/tarnished/dirty/scratched/cracked mirror; clear/tinted/frosted/privacy glass; dusty, wet, rain-streaked, fogged/condensed, scratched, cracked, shattered and reinforced glass; vehicle windows, display glass, bottles/lenses/screens. Windows must react to weather and day/night environment rather than being a static blue texture.

### Water / wet surfaces — high priority
Folders: `assets/materials/water/`, `assets/shaders/water/`, `assets/vfx/water/`, `assets/decals/wet/`.
- Binbun Godot Water — CC0 water shader with world-space caustics, refraction, depth, customizable foam and smooth/toon shading — https://forum.godotengine.org/t/free-water-shader-with-caustics-cc0/134925
- TomAzod Godot Water Splash VFX — CC0 dynamic splash with ripples, foam, bubbles, pillar and ready Godot scenes/scripts — https://tomazod.itch.io/godot-splash-vfx
- Godot Shaders Rain Puddles with Screen Space Reflections — shader code CC0 — https://godotshaders.com/shader/rain-puddles-with-screen-space-reflections/
Water coverage: ocean, lake, river, stream, pond, swamp, puddle, shallow/deep water, clear/turbid/muddy water, sewer/industrial water, underwater. Effects: small/medium/large waves, currents, shoreline foam, waterfall, mist, spray, caustics, refraction, depth color, Fresnel, rain rings, footsteps/object splashes, wakes, bubbles, droplets and wetness transitions. Wind/storm increases wave strength; rain creates ripples and splashes; sky/time/weather alter reflection.
Wet materials must include wet asphalt, stone, soil, wood, roofs and vehicle surfaces with dynamic roughness/darkening/reflection instead of separate duplicate meshes.

### Animated fire / smoke / particles
Approved CC0 sources include OpenGameArt animated fire/particle sets and Kenney Particle Pack / Smoke Particles. Maintain candle, lighter, torch, campfire, fireplace, stove, forge, barrel/object/building/grass/forest fires plus sparks, embers, ash, heat distortion, multiple smoke densities and extinguishing steam/smoke.

### Weather / atmosphere / sky — expanded
Maintain a unified dynamic weather system, not disconnected visual tricks:
- rain: drizzle/light/normal/heavy/downpour/wind-driven; roof/ground/water/window reactions;
- storms: dark cloud fronts, local/distant branching lightning, sky flash, delayed thunder, gusts/hail;
- wind: calm through storm, vegetation sway, airborne leaves/dust/sand/snow/debris;
- snow: light/normal/heavy/blizzard plus accumulation cues;
- fog/mist: morning, river/swamp, valley, dense storm, cave/interior haze;
- clouds: wispy, scattered, cumulus, overcast, storm fronts, fast-moving layers, cloud shadows;
- dust/sand/pollen/leaves/embers and other atmospheric particles.
Kenney Particle Pack — 80 CC0 VFX sprites — https://www.kenney.nl/assets/particle-pack
Kenney Smoke Particles — 70 CC0 smoke/explosion VFX files — https://www.kenney.nl/assets/smoke-particles
Prefer Godot GPUParticles3D + shaders + WorldEnvironment/light/audio synchronization and quality LODs.

### Reflective polished surfaces
Include chrome, polished steel/aluminum, wet metal, glossy ceramic/tile, varnished wood, polished marble/granite, ice, glossy plastic and painted vehicle surfaces. Use roughness/normal variation so not everything becomes a perfect mirror. Poly Haven HDRIs provide CC0 environments for believable reflections.

### Physical surface detail / decals
Maintain reusable CC0/project-owned masks and decals for fingerprints, dust, grime, scratches, cracks, condensation, droplets, streaks, frost, ice, foam, wet edges, puddles, mud splashes, moss, leaks, scorch, impact and broken-glass states. Prefer parameterized materials so one base material can transition clean→dirty→wet→damaged.

### World content coverage
Continue maintaining broad approved sources for buildings/infrastructure/interiors, humans/NPC animations, animals/ecology, food/farming, resources/crafting/tools, weapons/armor, vehicles/logistics, machines/production/technology, VFX/destruction, audio and complete UI. Building/vehicle/interior assets must reuse shared glass/water/reflection materials instead of inventing incompatible one-off materials.

## Material-state system requirement
Production assets should support state changes where gameplay/weather needs them: dry↔wet, clean↔dirty, intact↔cracked/broken, warm↔frosted/condensed, calm↔wind/storm water, day↔night reflection. Prefer shader parameters/masks and shared materials over duplicating full textures for every state.

## Reflection quality tiers
- Ultra/high: true/planar/viewport reflections only for important nearby mirrors/water where justified.
- Medium: SSR/reflection probes/environment approximation + normal/roughness detail.
- Low/distant: cubemap/HDRI/static approximation; no expensive per-object render.
- Never enable expensive true reflection on every city window. Reuse materials, cull by distance/visibility and expose graphics quality controls.

## Import policy
1. Prefer `.glb`/`.gltf` for models and optimized PNG/WebP masks/atlases for materials/VFX.
2. Import only verified free/redistributable content; preserve source/license metadata.
3. Do not dump huge archives blindly; import useful optimized production content.
4. Deduplicate meshes/materials/textures/animations/VFX atlases.
5. Normalize scale, orientation, pivots, collision, naming and LOD conventions.
6. Every third-party pack folder gets `SOURCE.md` and/or `LICENSE.txt` before production use.
7. Track dependencies: mesh + PBR maps + shader + probe/environment + VFX + audio + gameplay tag.
8. Never treat a registry entry as physically imported until files are actually present in the repository.

## Stable taxonomy
`nature`, `materials`, `lighting`, `world`, `buildings`, `interiors`, `characters`, `animations`, `animals`, `food`, `items`, `resources`, `tools`, `weapons`, `clothing`, `props`, `vehicles`, `machines`, `technology`, `shaders`, `vfx`, `decals`, `audio`, `music`, `ui`, `icons`, `prototype`.

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack. Goal: a coherent reusable production library, not a random pile of downloads.