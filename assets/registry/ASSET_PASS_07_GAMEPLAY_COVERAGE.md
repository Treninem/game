# ImPuls Asset Pass 07 — gameplay coverage

Date: 2026-08-14

Goal: continue building a curated, legally safe asset library. Do not import random models just because they are free. Every asset must close a concrete world/gameplay need, improve an existing placeholder, or provide a reusable modular system.

## Newly verified CC0 source families

### Mining / underground
- OpenGameArt CC0 mining assets collection: mine tracks, mine carts, pickaxes, jars, pipes/contraptions; reported FBX + glTF and Godot-ready materials. Candidate for `assets/world/mining/` after individual archive/license verification.
- Kenney Mini Dungeon: 25 CC0 3D files with animation/variations. Candidate for compact dungeon dressing and underground gameplay.

Required coverage before mining is production-ready:
- mine entrance, timber supports, rails, switches, carts, ore carts, ladders, ropes, winches, pulleys, lamps, crates, barrels, ore piles, coal, iron/copper/gold-like generic ores, crystals, rubble, cave props, blocked tunnels, collapsed variants, water seepage props, mine workshop, storage and extraction/loading area.

### Farms / villages
- Quaternius Farm Buildings Pack: 13 CC0 farm buildings, FBX/OBJ/Blend.
- Quaternius Medieval Village MegaKit: CC0 modular village; free Standard distribution provides a large modular subset; source page lists glTF/FBX/OBJ compatibility.
- Quaternius Medieval Village Pack: 44 CC0 buildings/props.
- Kenney Medieval Town base: modular CC0 walls, roofs, floors and roads.

Required farm coverage:
- farmhouse, barn, stable, chicken coop, pigsty, sheep/goat enclosure, hay storage, grain storage, shed, well, troughs, fences/gates, scarecrow, field props, carts, sacks, baskets, tools, harvested crop piles, manure/compost props, animal feed and water containers.

### Props / economy / interiors
- Quaternius Fantasy Props MegaKit Standard: CC0 medieval props; tools, vegetables, potions, market stalls, chests, furniture, weapons and breakables. Shared textures make it useful for memory-efficient dressing.
- Existing furniture/food/survival packs remain preferred where they fit the art direction.

Required economy coverage:
- market stalls and awnings, merchant counters, scales, weights, coin containers, sacks, crates, baskets, shop signs, shelves, display tables, books/ledgers, candles/lanterns, storage jars, tavern furniture, kitchen equipment, workshop clutter.

### Fortifications / settlements
- Kenney Castle Kit: 75 CC0 files.
- Kenney Tower Defense Kit: 160 CC0 files, useful for walls/defensive structures/variations.
- Kenney Retro Medieval Kit: CC0, GLB/FBX/OBJ, useful only if visual style matches or as blockout/reference.

Required fortification coverage:
- walls, towers, gates, gatehouses, battlements, stairs, bridges, palisades, barricades, watch posts, guard props, siege-damage variants, rubble, burned wood, broken doors/gates.

### Rail / transport
- Kenney Train Kit: almost 50 CC0 train/rail/tram models including spline-oriented track. Keep as future-era infrastructure, not for the initial medieval/rural region unless the game design reaches an industrial area.

### Characters / animals
- Quaternius CC0 catalogue continues to cover animated farm animals, RPG characters, humanoids, monsters and animation libraries.
- Farm Animal Pack explicitly covers pig, cow, horse, llama, pug/dog and sheep.

Still prioritize missing or weak species individually: chicken/chick, rooster, duck/duckling, goose/gosling, pigeon, rabbit/hare, fox, bear, wild boar/boarlet, piglet, goat/kid, deer/fawn, wolf, fish, insects and biome-specific wildlife. Do not claim a species is covered until the downloaded archive is inspected.

## New systemic categories to source deliberately

### Clothing and wearable variants
- peasant/commoner clothes
- farmer, miner, blacksmith, hunter, fisherman, lumberjack, merchant, healer, cook, guard, soldier
- cold-weather and rain variants
- hats, hoods, gloves, boots, belts, bags/backpacks
- armor layers: cloth/leather/mail/plate where appropriate
- damaged/dirty/wet variants should preferably be material-driven rather than separate meshes

### Horse and animal equipment
- saddle, saddle blanket, bridle, reins, harness, packs, saddlebags
- cart/wagon shafts and hitching
- trough, hay rack, stable stall, grooming tools
- avoid decorative tack that cannot be animated with the chosen horse rig

### Medicine and care
- healer table, beds, stools, shelves, bandages, generic bottles, mortar/pestle, herbs, bowls, cloth, water containers, crutches/splints
- avoid modern branded/medical-device assets in historical areas

### Water and sanitation
- wells, buckets, pumps where era-appropriate, troughs, barrels, cisterns, drainage channels, gutters, docks, piers, bridges, ferries
- wet/mossy material variants and waterline props

### Environmental storytelling
For every settlement type, source enough props to tell stories without dialogue:
- abandoned house
- recently occupied camp
- workshop in active use
- burned structure
- collapsed/neglected structure
- wealthy vs poor interiors
- storage shortage / plentiful harvest
- guarded checkpoint
- hunting/fishing camp

### Wildlife ecology props
- nests, eggs, burrows, dens, tracks/footprints, feathers, antlers, bones/skulls where appropriate, feeding sites, scratching/rubbing marks
- these should support quests/tracking rather than exist as decoration only

## Import quality gate
An asset is not production-ready until:
1. license is confirmed and stored locally;
2. original source URL is stored in SOURCE.md;
3. archive inventory is inspected;
4. format imports correctly into the current Godot version;
5. scale/orientation are normalized;
6. textures/materials are checked;
7. skeleton and animation clips are checked for animated assets;
8. collision strategy is assigned;
9. LOD/visibility range strategy is assigned for world assets;
10. file and node names are normalized;
11. duplicate functionality is rejected unless the new asset is a clear visual/technical upgrade;
12. asset is tagged by biome, settlement type, profession and gameplay use where relevant.

## Priority for next passes
P0: missing core fauna and young variants; farm structures/props; mine carts/rails/supports; carts/wagons/harness; common NPC clothing.
P1: regional building variation; bridges/docks; healer/market/tavern/workshop interiors; caves/ruins; damage states.
P2: industrial/rail infrastructure; specialized biome wildlife; decorative variety.

This registry is planning/verification metadata. Actual binary imports must remain curated to avoid repository bloat and incompatible art-direction mixtures.
