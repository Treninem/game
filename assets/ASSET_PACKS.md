# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import.

## Verified CC0 production packs

### Nature / terrain / vegetation
- Kenney Nature Kit — CC0 — https://kenney.nl/assets/nature-kit
- Kenney Survival Kit — CC0 — https://kenney.nl/assets/survival-kit
- Quaternius nature packs — CC0 — `assets/nature/quaternius/`
- Poly Haven — CC0 PBR textures/models/HDRIs — https://polyhaven.com/ — `assets/materials/polyhaven/`, `assets/lighting/hdri/polyhaven/`
Poly Haven assets are CC0 and may be redistributed/used commercially. Use its PBR/HDRI library for realistic environment/material support.

### Reflective materials / mirrors / glass / windows / water — high priority
These are not just flat textures. Production quality requires materials + shaders + probes/environment + surface detail.

**Mirrors** — `assets/materials/reflective/mirrors/`, `assets/shaders/reflection/`
- clean household mirror; bathroom mirror; old/dirty mirror; scratched/cracked mirror; tarnished/aged mirror; polished metal mirror-like surfaces;
- true reflection where practical using Godot reflection/viewport/probe techniques, with cheaper fallback for distant/small mirrors;
- support roughness, fingerprints, dust, edge grime, cracks, moisture/condensation and broken variants.
- Godot Shaders simple reflection shader code is CC0: https://godotshaders.com/shader/a-simple-reflection-shader/

**Glass and windows** — `assets/materials/glass/`, `assets/shaders/glass/`
- clear glass, slightly tinted glass, frosted/privacy glass, dirty/dusty glass, wet/rain-covered glass, fogged/condensed glass, scratched glass, cracked glass, shattered/broken glass, reinforced/industrial glass, bottle/display glass;
- windows need transparency/refraction, Fresnel-style reflection, roughness, thickness/edge tint where appropriate and day/night reflection balance;
- rain state needs droplets/streaks and changing wetness; cold/warm transitions may use condensation/fog masks;
- Godot Shaders Toon Glass code is CC0 and can be used as a lightweight/reference implementation: https://godotshaders.com/shader/toon-glass/

**Water** — `assets/materials/water/`, `assets/shaders/water/`, `assets/vfx/water/`
- ocean, lake, river, stream, pond, swamp, puddle, shallow water, deep water, clear/turbid/muddy water, sewer/industrial water and underwater materials;
- reflection + refraction + depth color + normals/waves + foam + shoreline + Fresnel response;
- animated small/medium/large waves, current direction, ripples, rain rings, object/footstep splashes, wake trails, waterfall foam/mist and shoreline spray;
- wind/storm must alter wave strength/direction; rain must generate ripples/splashes; day/night/clouds must affect reflections;
- use planar/probe/screen-space reflection selectively by quality tier rather than expensive perfect reflection everywhere.

**Reflective polished surfaces** — `assets/materials/reflective/`
Include chrome, polished steel, wet asphalt/stone, glossy tile, varnished wood, polished marble, ice and other surfaces that should reflect lights/environment. Keep roughness variations so they do not all look like perfect mirrors.

**Source strategy**
- Poly Haven is approved for CC0 PBR textures and HDRIs: https://polyhaven.com/ . HDRIs are important because glass, water, polished metal and mirrors need a believable environment to reflect.
- Shader code must have compatible redistribution rights; record source/license alongside imported shader.
- Surface-detail textures (scratches, fingerprints, droplets, grime, cracks, foam/noise/normal masks) must also be CC0/project-owned before bundling.

### Animated fire / smoke / particles — high priority
Approved CC0 sources already include OpenGameArt Animated Particle Effects #1/#2, Fire FX Burning Fire Animation, Lots of Game Effects, Kenney Particle Pack and Kenney Smoke Particles. Maintain candle/match/torch/campfire/fireplace/stove/forge/barrel/object/building/forest fire variants with embers, sparks, ash, smoke, heat distortion and extinguishing transitions.

### Weather / atmosphere / sky
Maintain calm-to-storm wind, drizzle-to-downpour rain, thunder/lightning, snow/blizzard, fog/mist, dust/sand storms, clouds, sky/HDRI and all surface reactions. Water responds with ripples/splashes/waves; windows with droplets/streaks; wet surfaces gain stronger reflections.

### Buildings / settlements / infrastructure
Maintain houses, apartments, huts, tents, farms, workshops, mines, warehouses, markets, hospitals, factories, castles, ruins, sewers, bunkers, roads, bridges, docks, fences, lights, pipes, cables and modular parts. Windows/doors must reference the shared glass/reflection material library instead of each building inventing a separate incompatible glass.

### Furniture / interiors / clutter
Maintain furniture, kitchen/bathroom props, mirrors, lamps, dishes, containers, books/papers, workshop/lab/medical/industrial/office props, trash and decorative clutter. Interior mirrors and glass objects reuse shared reflective materials.

### Humans / NPCs / animation
Quaternius Universal Animation Libraries remain approved CC0 sources. Maintain civilians, workers, farmers, hunters, guards and specialists with locomotion, work, tools, combat and interaction animations.

### Animals / ecology / creatures
Maintain domestic animals, wildlife, birds, fish, insects, aquatic life and hostile creatures with appropriate animation/ecosystem props.

### Food / farming / biology
Maintain crops/growth stages, ingredients, food/drink, spoilage variants, farming/irrigation/harvesting props.

### Items / resources / crafting / tools
Maintain raw resources, components, electronics, containers, trade goods, tools and worn/broken variants.

### Weapons / armor / combat props
Use verified CC0 weapon/armor packs already catalogued for gameplay-era needs.

### Vehicles / logistics / transportation
Maintain carts through advanced transport with cargo/interior/damage/audio needs. Vehicle windows, headlights and wet bodywork reuse shared glass/reflective materials.

### Machines / production / technology
Maintain crafting/production machinery, power, pipes/cables, laboratory/computer/communications/automation assets. Screens, lenses and polished machinery reuse shared reflective/glass systems.

### VFX / decals / destruction
Maintain fire, smoke, steam, dust, dirt, mud, water, rain/snow, leaves, fog, blood, tracks, impacts, scorch marks, cracks, broken glass, debris, electricity, leaks and status effects. Broken-window effects need crack decals/masks, shard meshes/particles and persistent broken states.

### Audio / ambience / Foley / music support
Maintain weather, water, footsteps, Foley, tools, combat, destruction, machinery, vehicles and UI audio. Glass requires taps, impacts, cracks, shatter and shard sounds; water requires splash, drip, rain-on-water, river, waves and underwater ambience.

### UI / icons / input / accessibility
Maintain complete game UI using verified CC0 packs already catalogued.

## Reflection quality tiers
- Ultra/high: true/planar/viewport reflections only for important nearby mirrors/water where justified.
- Medium: reflection probes/SSR/environment approximation plus normal/roughness detail.
- Low/distant: cubemap/HDRI/static approximation; no expensive per-object render.
- Never enable expensive real-time reflection on every window in a city. Batch/reuse materials and cull by distance/visibility.

## Import policy
1. Prefer `.glb`/`.gltf` for models; optimized PNG/WebP masks/textures for materials/VFX.
2. Import only verified free/redistributable content.
3. Do not dump huge archives blindly; import useful optimized production content.
4. Deduplicate meshes/materials/textures/animations/VFX atlases.
5. Normalize scale, orientation, pivots, collision, naming and LOD conventions.
6. Every third-party pack folder gets `SOURCE.md` and/or `LICENSE.txt` before production use.
7. Track dependencies: mesh + PBR maps + shader + probe/environment + VFX + audio + gameplay tag.
8. Never treat a registry entry as physically imported until files are actually present in the repository.

## Stable taxonomy
`nature`, `materials`, `lighting`, `world`, `buildings`, `interiors`, `characters`, `animations`, `animals`, `food`, `items`, `resources`, `tools`, `weapons`, `clothing`, `props`, `vehicles`, `machines`, `technology`, `shaders`, `vfx`, `decals`, `audio`, `music`, `ui`, `icons`, `prototype`.

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack. The goal is a broad reusable production library, not a random pile of downloads.