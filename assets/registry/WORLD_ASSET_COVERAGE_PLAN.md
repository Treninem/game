# ImPuls — Comprehensive World Asset Coverage Plan

Goal: build a coherent game-ready asset library, not indiscriminately collect files. Every third-party asset must have verified licensing, a real gameplay/world-building use, SOURCE.md/LICENSE.txt metadata, and an integration target.

## Verified additions / priorities

### Wildlife and ecosystem
- OpenGameArt Low poly 3D Pigeon — CC0, rigged + animated — https://opengameart.org/content/low-poly-3d-pigeon-model-rigged-animated-untextured — target `assets/animals/birds/pigeon/`.
- OpenGameArt Rabbit — CC0, rigged + animated, diffuse + normal map, Blend/FBX — https://opengameart.org/content/rabbit-0 — target `assets/animals/wildlife/rabbit/`.
- Quaternius Animated Fish Pack — CC0, 7 animated aquatic species — https://quaternius.com/packs/animatedfish.html — target `assets/animals/aquatic/quaternius_animated_fish/`.
- Quaternius Animated Cute Fish Pack — CC0, 52 models including animated fish plus fishing rods/lures — https://quaternius.com/packs/cutefish.html — target `assets/animals/aquatic/quaternius_cute_fish/` and useful fishing props under `assets/props/fishing/`.
- OpenGameArt CC0 3D Animals/Creatures collection is a discovery index only. It identifies useful categories including cobra, gorilla, hippo, tiger, crocodile, rhino, flying squirrel, raven, whale, penguin, shark, snail, lemur, bat, hornet/wasp and others. Every individual asset must still be license-verified before import.

### Transport and traversal
- Kenney Car Kit — CC0, 45 3D transport files — https://www.kenney.nl/assets/car-kit — `assets/vehicles/land/kenney_car_kit/`.
- Kenney Watercraft Kit — CC0, 45 3D boat/ship/watercraft files — https://kenney.nl/assets/watercraft-kit — `assets/vehicles/water/kenney_watercraft/`.

### Environment / survival
- Kenney Nature Kit — CC0, 330 3D nature files — https://kenney.nl/assets/nature-kit — `assets/nature/kenney_nature_kit/`.
- Kenney Survival Kit — CC0, 80 3D files with animation support — https://kenney.nl/assets/survival-kit — `assets/survival/kenney_survival_kit/`.

### Buildings / settlements / evolution
- Quaternius Medieval Village MegaKit — CC0, 304 modular models, glTF, Godot-ready project/collisions available — https://quaternius.com/packs/medievalvillagemegakit.html — `assets/buildings/medieval/quaternius_medieval_megakit/`.
- Quaternius Medieval Village Pack — CC0, 44 buildings/props — https://quaternius.com/packs/medievalvillage.html — supplementary rural/medieval variety.
- Quaternius Modular Medieval Building Pack — CC0, 30 modular pieces — https://quaternius.com/packs/modularmedievalbuildings.html.
- Quaternius Farm Buildings Pack — CC0, 13 farm buildings — https://quaternius.com/packs/farmbuildings.html.
- Quaternius Ultimate Fantasy RTS — CC0, 128 models including buildings in different evolution stages and nature — https://quaternius.com/packs/ultimatefantasyrts.html — useful for visible settlement/technology progression.

### Interiors
- Kenney Furniture Kit — CC0, 140 3D furniture/interior assets — https://kenney.nl/assets/furniture-kit — `assets/props/interior/kenney_furniture/`.

### Humans and gameplay animation
- Quaternius Universal Animation Library 2 — CC0, 130+ humanoid animations, Godot/Unity/Unreal compatible, including melee, armed combat, parkour, farming, fishing and zombie locomotion — https://quaternius.com/packs/universalanimationlibrary2.html — `assets/characters/animations/quaternius_ual2/`.

## Coverage map — collect by system, not randomly

### 1. Living ecosystem
Need adults + young where gameplay requires reproduction: farm animals, predators, prey, scavengers, birds, aquatic species, amphibians, reptiles, insects/pollinators. Need nests, eggs, dens, burrows, tracks, droppings, feathers, fur/hide, bones/carcasses, feed, troughs, cages/coops, barns, fences and veterinary/farming props.

### 2. Human civilization
Need NPC bodies, age/role variation, clothes by climate/era/profession, hair/beards, backpacks, tools carried in hands, merchants, farmers, hunters, miners, fishers, builders, guards, medics, craftspeople, bandits, survivors. Need universal animations for work, social interactions, traversal, combat, injury/death, carrying and mounted/vehicle states.

### 3. Buildings and interiors
Need primitive shelters, tents, huts, cabins, farmhouses, barns, stables, coops, workshops, warehouses, shops, markets, inns, houses, apartments, civic buildings, hospitals, schools, religious/cultural structures, factories, power/utilities, military structures, walls/towers/gates, ruins and advanced-era buildings. Interiors need furniture, storage, lighting, kitchens, sanitation, beds, workstations and clutter.

### 4. Resource economy / crafting
Need wood/logs/planks, stone/ore/metal, clay/bricks, sand/glass, fibers/cloth/leather, food ingredients, medicine plants, fuel, components, containers, workbenches, furnaces, kilns, anvils, sawmills, mills, looms, cooking stations, chemistry equipment and later electrical/mechanical parts.

### 5. Agriculture
Need crops in growth stages, seeds, fruit trees, vegetables, grain, hay/straw, soil states, irrigation, wells, pumps, tools, tractors/carts where era permits, silos, greenhouses, animal feed and harvest/storage props.

### 6. Biomes
Need temperate forest, conifer forest, grassland, farmland, swamp, river/lake, coast/ocean, mountain, cave, desert, tundra/snow, tropical region and underwater assets. Each needs terrain materials, vegetation, rocks, dead vegetation, debris, water-edge assets and biome-specific fauna.

### 7. Traversal / infrastructure
Need dirt paths, roads, rails if progression reaches them, bridges, docks, piers, stairs/ladders, ropes, fences/gates, signs, street furniture, drainage, utility poles/pipes/cables, tunnels and mine infrastructure.

### 8. Vehicles
Need carts/wagons, bicycles, boats/rafts, cars/trucks, agricultural/industrial vehicles and progression-era transport. Need damaged/wreck variants, wheels/parts, cargo attachment points and interiors where player can enter.

### 9. Survival presentation
Need campfires, tents, sleeping gear, backpacks, bottles/canteens, cookware, food portions, hunting/fishing equipment, traps, torches/lanterns, medical supplies, weather protection, storage and construction previews.

### 10. World state variants
For important destructible/buildable objects maintain intact, construction-stage, damaged, ruined/burned and repair states where practical. Vegetation needs young/mature/dead/cut variants. Resources need full/depleted states.

### 11. VFX and decals
Need fire/smoke/embers, rain/snow/fog, dust, mud/wetness, footprints/tracks, blood/injury where rating permits, water splashes/ripples/foam, leaves, sparks, electricity, construction dust, mining debris and environmental particles.

### 12. Audio pairing
Every major asset family eventually needs matching Foley/ambience: animal calls, footsteps by surface, doors, tools, crafting, machinery, vehicles, water/weather/fire, forests/caves/settlements and UI feedback.

## Selection policy
Do not grab everything. For each category: (1) identify gameplay need, (2) find 2–3 legally safe candidates, (3) choose the most coherent/complete/game-ready one, (4) prefer animated and glTF/GLB when applicable, (5) record source/license, (6) normalize scale/material/animation/LOD/collision, (7) reject redundant or visually incompatible assets unless they fill a real gap.
