# ImPuls Game — Shared Asset Pack Registry

Canonical asset registry for every development chat/agent working on this game.

## Mandatory cross-chat rule
Before generating or importing art, check this registry and the `assets/` tree. Reuse approved assets first. If missing, search free/CC0 sources; generate project-owned assets only when no suitable pack exists. Record source/license for every import.

## Verified CC0 production packs

### Nature / terrain / vegetation
- Kenney Nature Kit — 330 3D assets — CC0 — https://kenney.nl/assets/nature-kit — `assets/nature/kenney_nature_kit/`
- Kenney Survival Kit — 80 3D survival/nature assets with animation — CC0 — https://kenney.nl/assets/survival-kit — `assets/survival/kenney_survival_kit/`
- Quaternius Ultimate Nature Pack / Stylized Nature MegaKit / Simple Nature Pack — CC0 — `assets/nature/quaternius/`
- Poly Haven — CC0 PBR textures/models/HDRIs — https://polyhaven.com/ — `assets/materials/polyhaven/`, `assets/lighting/hdri/polyhaven/`
Maintain biome-ready trees, dead trees, logs, stumps, roots, branches, grass, reeds, moss, vines, flowers, bushes, crops, mushrooms, rocks, ores, stone, gravel, sand, clay, soil, mud, snow, ice, cliffs, caves, coast, beaches, riverbanks, swamp, desert, tundra, temperate, tropical, alpine and underwater vegetation.

### Animated fire / smoke / particles — high priority
- OpenGameArt Animated Particle Effects #1 — 14 animated effects/variations, fire/flame/smoke/magic, 1024x1024 sheets, 128x128 cells, 30 FPS, 64 frames — CC0 — https://opengameart.org/content/animated-particle-effects-1 — `assets/vfx/animated/oga_particlefx_1/`
- OpenGameArt Animated Particle Effects #2 — animated fire variants, lighter flame, air/bubbles and other effects, mostly 30 FPS / 64 frames — CC0 — https://opengameart.org/content/animated-particle-effects-2 — `assets/vfx/animated/oga_particlefx_2/`
- OpenGameArt Fire FX Burning Fire Animation — 40-frame transparent looping burning fire — CC0 — https://opengameart.org/content/fire-fx-burning-fire-animation — `assets/vfx/fire/oga_burning_fire/`
- OpenGameArt Lots of Game Effects — animated fire/explosion/aura spritesheets — CC0 — https://opengameart.org/content/lots-of-game-effects — `assets/vfx/animated/oga_lots_effects/`
- Kenney Particle Pack — 80 particle/light/shader sprites; suitable for fire, smoke, sparks, electricity and procedural weather — CC0 — https://www.kenney.nl/assets/particle-pack — `assets/vfx/particles/kenney_particle_pack/`
- Kenney Smoke Particles — 70 smoke/explosion VFX files — CC0 — https://www.kenney.nl/assets/smoke-particles — `assets/vfx/smoke/kenney_smoke_particles/`

Fire coverage required: candle, match/lighter, torch, campfire, fireplace, stove, brazier, forge/furnace, burning barrel, small object fire, building fire, forest/grass fire, spreading surface fire, embers, sparks, ash, heat distortion, multiple smoke densities, extinguishing steam/smoke and wet-fire transitions. Do not rely on one sprite animation for all scales. Prefer layered Godot GPUParticles + animated flipbooks + lights + distortion for production fire.

### Weather / atmosphere / sky
- OpenGameArt Lightning Animation — animated lightning texture — CC0 — https://opengameart.org/content/lightning-animation — `assets/vfx/weather/lightning/oga_lightning/`
- OpenGameArt 2D Spell Effects — CC0 animated effects including fire, lightning and rain-like effects — https://opengameart.org/content/2d-spell-effects — `assets/vfx/animated/oga_spell_effects/`
- OpenGameArt Special Effects CC0 collection — discovery collection containing lightning, animated fire, fog and other CC0 effects; verify each child asset before physical import — https://opengameart.org/content/special-effects-cc0

Weather system must support multiple intensities and transitions, not just binary on/off effects:
- wind: calm, breeze, strong wind, gusts, gale, storm; direction/speed variation; tree/grass/crop response; airborne leaves, pollen, dust, sand, snow and debris;
- rain: drizzle, light, normal, heavy, downpour, wind-driven rain; near-camera streaks plus distant rain volume; roof/ground splashes, puddle ripples, wetness and runoff;
- thunderstorm: layered clouds/darkening, local/distant lightning, branching bolts, sky flash, randomized thunder delay, heavy rain, gusts and optional hail;
- snow: sparse flakes, normal snow, blizzard, wind-driven snow, ground accumulation cues and snow kicked by footsteps;
- fog/mist: low ground mist, river/swamp mist, morning fog, dense weather fog and interior/cave haze;
- dust/sand: ambient dust motes, footsteps/impacts, vehicle trails, gust clouds, dust storm/sandstorm;
- clouds: clear, scattered, overcast, storm, fast-moving fronts, dawn/dusk variants;
- water response: rain ripples, splash rings, foam, stronger waves under wind/storm, waterfall mist and shoreline spray.

For Godot production, prefer scalable 3D/procedural effects: GPUParticles3D for rain/snow/embers/dust/leaves; shaders for wind deformation, wetness, puddles, water waves, heat haze and cloud movement; decals for wet/impact traces; DirectionalLight/WorldEnvironment changes for lightning flashes and storm darkening. Flipbook sprites are source textures, not the entire weather implementation.

### Buildings / settlements / infrastructure
Approved families include Kenney modular/city/fantasy/castle kits and Quaternius medieval/downtown/fantasy modular kits. Maintain houses, apartments, huts, tents, farms, barns, mills, workshops, smithies, mines, quarries, lumber camps, warehouses, markets, taverns, inns, shops, hospitals, schools, administration, factories, power/utility buildings, castles, towers, walls, gates, ruins, dungeons, sewers, caves, bunkers, roads, paths, sidewalks, rails, bridges, docks, piers, fences, signs, streetlights, pipes, cables, poles, drains, wells and modular construction parts.

### Furniture / interiors / clutter
Maintain beds, chairs, tables, shelves, cupboards, wardrobes, lamps, fireplaces, stoves, kitchen/bathroom props, dishes, barrels, crates, sacks, baskets, bottles, books, papers, tools, workshop clutter, storage, market displays, laboratory/medical props, industrial props, office props, trash, rubble and decorative clutter. Quaternius Fantasy Props MegaKit Standard is an approved broad CC0 source.

### Humans / NPCs / animation
- Quaternius Universal Animation Library — 120+ animations — CC0 — https://quaternius.com/packs/universalanimationlibrary.html
- Quaternius Universal Animation Library 2 — 130+ animations incl. melee, armed combos, parkour, farming, fishing, zombies — CC0 — https://quaternius.com/packs/universalanimationlibrary2.html
Maintain civilians, survivors, merchants, workers, farmers, hunters, guards, specialists and role variants with locomotion, tools, work, combat and interaction animations.

### Animals / ecology / creatures
Maintain domestic animals, livestock, mounts, forest/plains/desert/tundra/tropical wildlife, birds, fish, amphibians, reptiles, insects, pollinators, predators, scavengers, aquatic life and hostile/fantasy creatures where appropriate. Include idle/feed/drink/walk/run/flee/attack/sleep/swim/fly/death animation needs, nests/dens/tracks/droppings and ecosystem props.

### Food / farming / biology
Maintain seeds, crops by growth stage, fruit/vegetables, grain, herbs, mushrooms, meat, fish, eggs, milk, prepared meals, drinks, cooking ingredients, spoilage variants, farming equipment, irrigation, compost, animal feed and harvesting props.

### Items / resources / crafting / tools
Maintain wood/logs/planks, stone, clay, sand, coal, ores, ingots, scrap, fibers, cloth, leather, rope, glass, chemicals, fuels, components, electronics, batteries, containers and trade goods. Include common hand/farming/repair/measuring tools and damaged/worn variants.

### Weapons / armor / combat props
Use verified CC0 weapon/armor packs already catalogued for gameplay-era needs. Maintain melee/ranged equipment, ammo, shields, protective clothing, impacts, casings and damage/debris assets.

### Vehicles / logistics / transportation
Maintain carts, wagons, bicycles, cars, trucks, tractors, construction/agricultural vehicles, boats, ships, trains/rail assets and later advanced transport, with separate cargo/interior/damage/audio needs.

### Machines / production / technology
Maintain crafting benches, furnaces, kilns, forges, mills, pumps, generators, motors, conveyors, tanks, pipes, valves, cables, electrical equipment, batteries, renewable power, laboratory equipment, computers, communications, automation/robotics and era progression variants.

### VFX / decals / destruction
Maintain fire/flames/embers/sparks, smoke/steam, dust, dirt, mud, water, rain/snow, leaves, wind streaks, fog, blood, footprints, tire tracks, impacts, scorch marks, cracks, broken glass, debris, electricity, leaks, poison/gas, healing/status effects and interaction highlights. Dynamic environmental VFX should react to world state: weather intensity, wind vector, surface material, shelter/roof detection, fire size/fuel and player distance.

### Audio / ambience / Foley / music support
Maintain biome ambience, birds/insects/wildlife, wind/weather/thunder, fire/water, caves/interiors, footsteps by surface, cloth/gear Foley, eating/drinking, crafting/tools, mining/chopping, farming, combat, impacts, destruction, construction, machines, engines, vehicles, doors/containers, UI, alarms and interactions. Weather audio needs multiple wind/rain intensities and near/far thunder variants synchronized with visual storm events.

### UI / icons / input / accessibility
Maintain complete HUD/inventory/equipment/crafting/map/quests/skills/trading/building/settings/accessibility/save-load UI and controller/input prompts using verified CC0 packs already catalogued.

## Weather/fire quality rule
Do not treat a single texture or spritesheet as a finished effect. Production effects combine appropriate layers (particles, shader, light, audio, decals, world/environment response). Effects must have LOD/culling and quality tiers so heavy rain, forests on fire or storms do not freeze the game. Distant effects use cheaper representations; only visible/nearby particles are simulated at high quality.

## Import policy
1. Prefer `.glb`/`.gltf` for Godot models; PNG/WebP flipbooks and masks for VFX; retain source/license metadata.
2. Import only files actually distributed in a verified free tier.
3. Do not dump huge archives blindly; import useful production content and optimized runtime variants.
4. Deduplicate meshes/materials/textures/animations/VFX atlases.
5. Normalize scale, orientation, pivots, collision, naming and LOD conventions.
6. Every third-party pack folder gets `SOURCE.md` and/or `LICENSE.txt` before production use.
7. Repeated world effects need distance culling/LOD; avoid kilometer-wide particle emitters.
8. Track dependencies: source texture + material/shader + particle scene + audio + light/decal + gameplay tag.
9. Never treat a registry entry as physically imported until files are actually present in the repository.

## Stable taxonomy
`nature`, `materials`, `lighting`, `world`, `buildings`, `interiors`, `characters`, `animations`, `animals`, `food`, `items`, `resources`, `tools`, `weapons`, `clothing`, `props`, `vehicles`, `machines`, `technology`, `vfx`, `decals`, `audio`, `music`, `ui`, `icons`, `prototype`.

Every development session working on `Treninem/game` must read this file before adding art and update it when approving another pack. The goal is a broad reusable production library, not a random pile of downloads.