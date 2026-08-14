# ImPuls — Infrastructure, Nature, Survival & Dungeon Expansion

Goal: fill world-building gaps systematically rather than accumulating random assets. Only CC0 sources verified on official/creator pages are approved for automatic use.

## Approved high-value packs

### Kenney — Nature Kit
Source: https://kenney.nl/assets/nature-kit
License: CC0
Files: 330 3D assets
Coverage: trees, rocks, foliage, terrain/nature elements.
Target: `assets/environment/nature/kenney_nature_kit/`
Use: forests, fields, wilderness, biome dressing, procedural scattering.

### Kenney — Survival Kit
Source: https://kenney.nl/assets/survival-kit
License: CC0
Files: 80 3D assets; animation support.
Coverage: structures, survival items, tools and resources.
Target: `assets/gameplay/survival/kenney_survival_kit/`
Use: gathering/crafting camps, early-game survival, interactable props.

### Kenney — City Kit Roads
Source: https://www.kenney.nl/assets/city-kit-roads
License: CC0
Files: 70 3D assets with variations.
Coverage: roads/city/town infrastructure.
Target: `assets/infrastructure/roads/kenney_city_roads/`

### Kenney — 3D Road Tiles
Source: https://www.kenney.nl/assets/3d-road-tiles
License: CC0
Files: 300 3D road tiles.
Target: `assets/infrastructure/roads/kenney_3d_road_tiles/`
Use: broad modular road network and intersections.

### Kenney — Train Kit
Source: https://opengameart.org/content/train-kit (Kenney CC0 mirror; prefer official Kenney distribution when downloading)
License: CC0
Files: nearly 50 train/rail/tram/trolley/track models.
Target: `assets/transport/rail/kenney_train_kit/`
Use: railway era, freight/passenger transport, stations and track networks.

### Quaternius — Modular Dungeon Pack
Source: https://quaternius.com/packs/medievaldungeon.html
License: CC0
Models: 41
Formats: FBX, OBJ, Blend
Coverage: modular walls, barrels, torches, potions and dungeon props.
Target: `assets/locations/dungeons/quaternius_modular_dungeon/`

### Quaternius — Ultimate Modular Ruins Pack
Source: https://quaternius.com/packs/ultimatemodularruins.html
License: CC0
Models: 90
Formats: FBX, OBJ, Blend
Coverage: modular ruins, dungeons, props and an animated character.
Target: `assets/locations/ruins/quaternius_modular_ruins/`

## World systems these packs must support

### Infrastructure
- dirt paths, village roads, paved roads, intersections, bridges and crossings
- rail tracks, switches, stations, platforms, freight areas
- signs, fences, gates, street furniture and lighting
- settlement-to-settlement transport corridors
- damaged/abandoned variants where available or generated in-project

### Nature and biomes
- deciduous/conifer forests, fields, meadows, rocky terrain
- river/lake/coast dressing
- mountains, cliffs, caves, boulders and scree
- dead/fallen trees, stumps, logs and branches
- biome-specific vegetation and seasonal variants
- LOD/impostor strategy for huge open-world sight distances

### Survival loop
- camp construction and shelter
- gathering resources
- tools and crafting stations
- storage and containers
- fire/cooking
- hunting/fishing support props
- repair/damage states

### Underground and ruins
- mines and natural caves are distinct from authored dungeons
- dungeon corridors/rooms/doors/traps/loot dressing
- abandoned mines need supports, carts, rails, lamps, ore/rock piles and collapses
- ruins need intact -> weathered -> damaged -> collapsed states
- cave entrances must connect naturally to exterior biome terrain

## Missing-asset search priorities
1. Dedicated mining kit: mine carts, supports, ore veins, crushers, furnaces, mine lamps.
2. Farming equipment: ploughs, carts, irrigation, hay tools, crop-stage meshes.
3. Horse tack and carts/wagons.
4. Bridges: wood, stone, modern/industrial variants.
5. Medical/herbal props and interiors.
6. Clothing/armor modular sets for population diversity.
7. Regional architecture rather than one repeated village style.
8. Burned/flooded/abandoned building variants.
9. Snow/arctic, swamp, coast, desert and high-mountain biome-specific props.
10. Missing animal families and juveniles, nests/burrows/tracks.

## Quality rules
- Prefer coherent packs over isolated mismatched models.
- A pack must fill a gameplay/world-system gap to be approved.
- Keep source/license metadata beside every imported pack.
- Prefer glTF/GLB; convert source formats during import pipeline when required.
- Normalize scale/material naming/collision/LOD before runtime use.
- Raw archives are staging artifacts, not permanent runtime content.
- Do not import NC/ND/editorial/ripped/unknown-license assets.
- Avoid duplicate packs that add no meaningful visual or gameplay variation.
