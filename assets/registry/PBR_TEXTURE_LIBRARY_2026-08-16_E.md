# CC0 PBR texture library — 2026-08-16 E

Purpose: source-only material library for ImPuls. This research chat does not edit Godot materials, scenes, shaders or runtime code.

All sources below were verified as CC0/public-domain style resources suitable for commercial use. Main game-development chat must download only the resolutions/maps needed for the current milestone and preserve source/license metadata.

## Recommended Godot texture policy

- Use OpenGL normal maps (`Normal GL`) when a source offers both DX and GL normals.
- Default to 1K for small props, distant LODs, clutter and repeated secondary surfaces.
- Default to 2K for buildings, terrain tiles near the player and major environment pieces.
- Reserve 4K+ for genuinely large/hero surfaces where 2K visibly fails; do not bulk-import 4K/8K libraries.
- Prefer reusable tiled materials and trim sheets over unique textures for every mesh.
- Keep diffuse/albedo, normal and roughness as the minimum useful PBR set; add AO/displacement only when the material or scene benefits enough to justify memory cost.
- Main chat should pack channels and generate Godot import presets only after selecting the final materials.

## Stone / castles / ruins / roads

### Poly Haven — Rock Tile Floor
Source: `https://polyhaven.com/a/rock_tile_floor`
License: CC0.
Use: castle courtyards, old paved roads, ruins, monastery/fort floors.
Maps available: diffuse, Normal GL/DX, roughness, AO, displacement.

### Poly Haven — Stone Tiles 03
Source: `https://polyhaven.com/a/stone_tiles_03`
License: CC0.
Use: aged streets, dungeon floors, dirty town paths, mossy old masonry floors.
Maps available up to 8K; prefer 1K/2K for normal gameplay use.

### Poly Haven — Mossy Rock
Source: `https://polyhaven.com/a/mossy_rock`
License: CC0.
Use: damp ruins, forest rocks, cave mouths, river edges.

### Poly Haven — Lichen Rock
Source: `https://polyhaven.com/a/lichen_rock`
License: CC0.
Use: cliffs, old castle foundations, alpine/temperate rocks.

### ambientCG — Rock027
Source: `https://ambientcg.com/view?id=Rock027`
License: CC0.
Use: gray cliff/stone faces, caves, mine walls, rocky biomes.
1K/2K/4K+ PBR archives available.

## Terrain / dirt / paths / biome blending

### Poly Haven — Aerial Ground Rock
Source: `https://polyhaven.com/a/aerial_ground_rock`
License: CC0.
Use: dry rocky ground, dirt-road shoulders, sparse scrub terrain.
Designed for large-area terrain coverage.

### Poly Haven — Aerial Grass Rock
Source: `https://polyhaven.com/a/aerial_grass_rock`
License: CC0.
Use: grassy cliffs, rocky hills, cave/rock transitions, temperate mountains.

### Poly Haven — Aerial Rocks 02
Source: `https://polyhaven.com/a/aerial_rocks_02`
License: CC0.
Use: large cliff faces, mountains and cave-region terrain.

### Poly Haven — Coast Land Rocks 01
Source: `https://polyhaven.com/a/coast_land_rocks_01`
License: CC0.
Use: coastal cliffs, rocky beaches, sea-facing terrain, island edges.

### ambientCG — Ground002
Source: `https://ambientcg.com/view?id=Ground002`
License: CC0.
Tags: dirt, gravel, pebbles.
Use: village roads, yard ground, camps, farm lanes, mine approaches.

### ambientCG — Moss001
Source: `https://ambientcg.com/view?id=Moss001`
License: CC0.
Use: forest floors, damp rocks, ruin blending, swamp/river-edge accents.

## Roofs

### Poly Haven — Roof Tiles
Source: `https://polyhaven.com/a/roof_tiles`
License: CC0.
Use: weathered terracotta/clay roofs for warmer settlements and older towns.

### Poly Haven — Grey Roof Tiles
Source: `https://polyhaven.com/a/grey_roof_tiles`
License: CC0.
Use: damp northern villages, gray ceramic roofs, mossy old houses.

### Poly Haven — Roof Slates 03
Source: `https://polyhaven.com/a/roof_slates_03`
License: CC0.
Use: castles, wealthy town houses, churches, colder/wetter regions.

## Wood

### Poly Haven — Moss Wood
Source: `https://polyhaven.com/a/moss_wood`
License: CC0.
Use: abandoned bridges, damp docks, old fences, ruined cabins, swamp structures.

### Poly Haven — Medieval Wood
Already verified in the earlier asset registry.
Use: beams, doors, carts, interiors, medieval props and timber-frame architecture.

### ambientCG — Wood015
Source: `https://ambientcg.com/view?id=Wood015`
License: CC0.
Use: generic reusable wood material fallback for props/buildings where a more specific staged wood is unnecessary.

## Walls / plaster

### Poly Haven — Medieval Wall 02
Already verified in the earlier asset registry.
Use: village/castle wall surfaces where the existing art direction fits.

### ambientCG — PaintedPlaster016
Source: `https://ambientcg.com/view?id=PaintedPlaster016`
License: CC0.
Tags: broken, old, painted plaster, brick, wall.
Use: worn village interiors/exteriors, old shops, taverns, damaged houses.

## Metal / tools / gates

### ambientCG — Metal022
Source: `https://ambientcg.com/view?id=Metal022`
License: CC0.
Tags: old, rust, rusty spots, steel.
Use: mine hardware, old gates, hinges, chains, tools, dungeon props.

### ambientCG — Metal010
Source: `https://ambientcg.com/view?id=Metal010`
License: CC0.
Tags: brushed, scratched steel.
Use: cleaner weapons/tools/armor accents and maintained metal structures.

### ambientCG — CorrugatedSteel008A
Source: `https://ambientcg.com/view?id=CorrugatedSteel008A`
License: CC0.
Use sparingly for later industrial/modern zones; do not mix into medieval settlements unless the location specifically calls for it.

## Existing high-priority materials from earlier research

- Poly Haven `Medieval Wood`.
- Poly Haven `Medieval Wall 02`.
- Poly Haven `Cobblestone Floor 001`.

These remain priority materials for the initial medieval settlement visual language.

## Suggested biome/material families

### Temperate village / farmland
- Cobblestone Floor 001 / Ground002.
- Medieval Wood / Wood015.
- Medieval Wall 02 / PaintedPlaster016.
- Grey Roof Tiles or Roof Tiles.
- Moss001 only as localized damp variation.

### Forest / ruins
- Mossy Rock + Lichen Rock.
- Moss Wood.
- Aerial Grass Rock.
- Stone Tiles 03 / Rock Tile Floor for old paths and ruins.

### Mountains / caves / mines
- Rock027.
- Aerial Rocks 02.
- Aerial Ground Rock.
- Metal022 for old mine hardware.
- Medieval Wood for supports/planks.

### Coast / harbor
- Coast Land Rocks 01.
- Moss Wood for wet docks/old piers.
- Rock Tile Floor for harbor paving.
- Metal022 for anchors/chains/old hardware.

## Performance rule for the main chat

Do not download or import every resolution. Start from 1K/2K JPG or compressed game-ready maps. Validate visual quality in-engine before escalating a material to 4K. Repeated terrain and building materials should be tiled/instanced and reused across compatible assets.

## Ownership boundary

This research chat only records verified texture sources and recommended usage. The main game-development chat owns downloading final map sets, Godot import settings, channel packing, shaders/materials, triplanar/terrain blending, decals, UV fixes and performance testing.
