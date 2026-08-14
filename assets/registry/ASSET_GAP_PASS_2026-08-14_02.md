# ImPuls — Asset Gap Pass 2026-08-14 / 02

This pass records only individually verified CC0 sources that close remaining gameplay/world gaps. Do not import binaries until the exact asset file is downloaded from the verified source and SOURCE.md + LICENSE.txt are placed beside it.

## Ruins / destruction / post-crisis states

### OpenGameArt — 3D Apocalyptic Building / City
Source: https://opengameart.org/content/3d-apocalyptic-building-city-cc0
License: CC0
Contents: 7 different low-poly skyscraper ruins, rotten billboards, wreckage; source .blend included.
Target: `assets/buildings/ruins/opengameart_apocalyptic_city/`
Use: destroyed modern city districts, crisis aftermath, abandoned zones.
Status: VERIFIED.

### OpenGameArt — Destroyed City Assets
Source: https://opengameart.org/content/destroyed-city-assets
License: CC0
Contents: 3 destroyed buildings, 2 damaged road segments, 6 rubble/rock blocks.
Target: `assets/buildings/ruins/opengameart_destroyed_city/`
Use: damaged roads, rubble fields, urban destruction states.
Status: VERIFIED.

### OpenGameArt — Broken Stone Slab
Source: https://opengameart.org/content/broken-stone-slab
License: CC0
Formats: Blend, FBX, OBJ
Textures: PBR maps including albedo, metalness, roughness, normal, AO.
Target: `assets/world/ruins/opengameart_broken_stone_slab/`
Use: tombs, ancient ruins, ritual/archaeological areas.
Status: VERIFIED.

## Bridges / crossings / piers

### OpenGameArt — Bridges and Stuff
Source: https://opengameart.org/content/bridges-and-stuff
License: CC0
Contents: low-poly bridges, pier, ladder, steps; wood/stone themed.
Target: `assets/world/infrastructure/bridges/opengameart_bridges_and_stuff/`
Use: rivers, fishing villages, docks, climbing and traversal.
Status: VERIFIED.

## Regional architecture / modern Eastern-European city coverage

### OpenGameArt — Residential building (lowpoly apartment block)
Source: https://opengameart.org/content/residential-building-lowpoly-apartment-block
License: CC0
Type: low-poly Soviet/Russian-style residential apartment block; PBR-tagged.
Target: `assets/buildings/regional/eastern_europe/opengameart_residential_block/`
Use: modern/post-Soviet districts, survival settlements, abandoned-city regions.
Status: VERIFIED.

### OpenGameArt — Ordinary House
Source: https://opengameart.org/content/ordinary-house
License: CC0
Files: ZIP, OBJ and 3DS variants; two texture variants.
Target: `assets/buildings/residential/opengameart_ordinary_house/`
Use: generic low-density residential districts and small settlements.
Status: VERIFIED.

## Modular settlement baseline

### Quaternius — Medieval Village MegaKit
Source: https://quaternius.com/packs/medievalvillagemegakit.html
License: CC0
Models: 304
Formats: FBX, OBJ, Blend, glTF
Godot: source version includes Godot implementation and optimized collisions.
Target: `assets/buildings/medieval/quaternius_medieval_village_megakit/`
Use: villages, workshops, interiors/exteriors, modular settlement generation.
Status: VERIFIED.

### OpenGameArt / Kenney — Modular 3D Buildings
Source: https://opengameart.org/content/modular-3d-buildings
License: CC0
Contents: 100 modular building/city elements.
Target: `assets/buildings/modular/kenney_modular_buildings_oga/`
Use: city block prototyping and low-poly modular settlement filler.
Status: VERIFIED.

## Character fallback / NPC customization base

### OpenGameArt — Character Base Model
Source: https://opengameart.org/content/character-base-model
License: CC0
Type: rigged low-poly character base model; color customization for hair/clothes/skin supported through texture edits.
Target: `assets/characters/humans/opengameart_character_base/`
Use: fallback NPC base, prototypes, clothing/role variations when higher-priority modular characters do not fit.
Status: VERIFIED.

## Nature baseline confirmation

### Kenney — Nature Kit
Source: https://kenney.nl/assets/nature-kit
License: CC0
Files: 330 3D assets
Target: `assets/nature/kenney_nature_kit/`
Use: trees, rocks, foliage and general biome dressing.
Status: VERIFIED.

## Missing exact targets after this pass

Still search individually before production import:
- goose + gosling
- piglet exact model
- goat + kid
- elk/moose
- squirrel, badger, raccoon
- crow/raven, sparrow, eagle/hawk, owl, seagull
- realistic/usable horse tack: saddle, reins, harness, wagon hitch
- plow, scythe, sickle, wheelbarrow and other agriculture tools as coherent set
- water mill and windmill with useful animation pivots
- beehive/apiary set
- dairy/cheese production props
- water/sewer infrastructure
- tundra, swamp, alpine and coastline biome-specific kits
- burned building variants and fire-damaged props

## Import quality rules

1. Prefer glTF/GLB for runtime.
2. Keep a source package only if it adds editing value; do not dump duplicate formats into runtime folders.
3. Every third-party folder must contain `SOURCE.md` and `LICENSE.txt`.
4. Create collision proxies, LODs and normalized Godot scale before marking production-ready.
5. Reuse shared textures/materials when possible.
6. Ruined/damaged variants should be linked to their intact gameplay archetype instead of treated as unrelated props.
7. Regional architecture gets biome/culture tags so world generation does not mix incompatible styles randomly.
8. A search hit is not enough: each exact imported file must have its individual license page verified.
