# ImPuls — Asset Gap Pass 05 (2026-08-14)

Purpose: continue closing verified CC0 gaps across fauna, farming tools, animal transport, mills and settlement production. This file records production candidates only; actual binary import still requires a successful binary transfer and format/quality validation.

## Newly verified fauna

### Goat — OpenGameArt
Source: https://opengameart.org/content/goat
License: CC0
Format: OBJ
File: goatlowrez.obj (~1.4 MB)
Notes: single-object low-poly goat, no rig, no textures. Suitable as a base mesh/prototype; requires project materials and rig/animations before production use.
Target: `assets/animals/farm/goat/opengameart_goat/`
Status: VERIFIED SOURCE; NOT YET PRODUCTION-RIGGED.

### Flying Squirrel — OpenGameArt
Source: https://opengameart.org/content/flying-squirrel
License: CC0
Format: Blender
File: squirrel.blend (~1.8 MB)
Notes: rigged, but source itself describes the rig as poor. Use as fallback/reference only unless re-rigged and reworked.
Target: `assets/animals/wildlife/squirrel/opengameart_flying_squirrel/`
Status: VERIFIED SOURCE; RE-RIG REQUIRED.

### Raven coverage
Source collection: https://opengameart.org/content/cc0-3d-animals-creatures
License policy: collection is CC0-oriented, but individual Raven entry must still be opened and checked before binary import.
Target: `assets/animals/birds/raven/`
Status: CANDIDATE LOCATED; INDIVIDUAL PAGE VERIFICATION REQUIRED.

### Moose/owl fallback UI reference
Kenney Animal Pack Redux includes moose and owl under CC0, but it is 2D. Keep only as UI/bestiary/reference fallback; do not substitute it for required 3D production wildlife.
Source: https://opengameart.org/content/animal-pack-redux
Target: `assets/ui/bestiary/kenney_animal_pack_redux/`

## Farming / crafting tools

### Medieval Tools Pack — OpenGameArt
Source: https://opengameart.org/content/medieval-tools-pack
License: CC0
Archive: medieval_tools_pack.7z (~1.3 MB)
Contents: 12 tools including pitchfork, shovel, hoe, sickle, axe, scythe, rake, broom, saw, pickaxe and hammer.
Geometry: approximately 56–188 tris per tool; 256x256 textures; packed in one Blender source.
Target: `assets/items/tools/farming/opengameart_medieval_tools/`
Status: HIGH-PRIORITY VERIFIED SOURCE.

### Inventory Items pack — OpenGameArt
Source: https://opengameart.org/content/inventory-items
License: CC0
Contents: 60+ items including basket, bucket, chisel, grinder, hammer, mortar and pestle, pickaxe, saw, shears, shovel, sickle, syringe, fishing rod, ore chunks and food.
Target staging: `assets/items/opengameart_inventory_items/`
Rule: extract only useful objects instead of importing the full 40 MB Blender source into runtime.
Status: VERIFIED SOURCE; SELECTIVE EXTRACTION ONLY.

## Animal-powered transport

### Horse Drawn Carriage — OpenGameArt
Source: https://opengameart.org/content/horse-drawn-carriage
License: CC0
Format: Blender
File: WOZ.blend (~767 KB)
Quality warning: source comments report missing textures, many separate pieces and poor engine-readiness. Treat as structural/reference source, not a production-ready carriage.
Target staging: `assets/vehicles/animal_drawn/carriage/opengameart_horse_carriage_reference/`
Status: VERIFIED LICENSE; REBUILD/OPTIMIZATION REQUIRED.

### Handwagon — OpenGameArt
Source: https://opengameart.org/content/handwagon
License: CC0
Formats: DAE, OBJ; AO maps included.
Target: `assets/vehicles/handcarts/opengameart_handwagon/`
Status: VERIFIED production candidate after scale/material normalization.

## Mills / rural industry

### Animated Windmill — OpenGameArt
Source: https://opengameart.org/content/windmill-4
License: page lists CC0 (also CC-BY 4.0); use under CC0 terms as explicitly offered on page.
Format: Blender
Notes: animated blades.
Target: `assets/buildings/industry/windmill/opengameart_animated_windmill/`
Status: VERIFIED SOURCE.

### Old Windmill — OpenGameArt
Source: https://opengameart.org/content/old-windmill
License: CC0
Format: Blender
Notes: complete 3D windmill; page states textures are public domain.
Target: `assets/buildings/industry/windmill/opengameart_old_windmill/`
Status: VERIFIED SOURCE.

### Stylized Windmill — OpenGameArt
Source: https://opengameart.org/content/stylized-wildmill-isometric-with-parts-to-build-animationand-blend
License: CC0
Formats: FBX, OBJ, Blend
Notes: separated parts suitable for animation; potential fallback for lower-detail settlements.
Target: `assets/buildings/industry/windmill/opengameart_stylized_windmill/`
Status: VERIFIED SOURCE.

## Settlement-production coverage to keep searching
- watermill with usable wheel animation
- water-powered sawmill production-ready model
- beehive/apiary 3D set
- cheese press / butter churn / dairy workbench
- grain mill interior machinery
- bakery oven and baking tools
- smokehouse / drying racks
- tannery tools and racks
- loom / spinning wheel / tailoring workbench
- pottery wheel / kiln
- blacksmith bellows / anvil / forge states
- carpenter bench / vise / sawbuck
- rope-making / fishing-net production props

## Remaining fauna gaps
High priority: goose + gosling, piglet, goat kid, moose/elk, badger, raccoon, normal squirrel, crow/raven production model, owl, eagle/hawk, sparrow, seagull, amphibians, snakes/lizards, insects/pollinators.

## Explicit rejection / caution
- OpenGameArt `Sickle` page located in this pass is GPL/CC-BY-SA, not CC0; do not import it under the project's CC0-first policy.
- Horse Drawn Carriage is license-safe but not production-ready; do not mark it runtime-ready without rebuild.
- Flying Squirrel is CC0 but source warns about rig quality; re-rig before use.
- 2D animal packs may serve UI/bestiary/maps only and do not satisfy 3D wildlife requirements.

## Binary import note
Direct file URLs were resolved for several OpenGameArt assets, but the current external binary-download bridge failed to transfer the archive/model bytes into the working container. Therefore this commit records verified sources and target paths only; it does not falsely claim that the binary models are already present in Git.
