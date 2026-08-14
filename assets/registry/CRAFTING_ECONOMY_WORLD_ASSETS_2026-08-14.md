# ImPuls — Crafting, Economy & World Asset Coverage

Goal: avoid random asset hoarding. Assets are selected because they support gameplay loops, settlements, professions, exploration, crafting, economy, interiors, world storytelling, destruction and progression.

## Verified high-value CC0 packs

### Quaternius — Fantasy Props MegaKit
Source: https://quaternius.com/packs/fantasypropsmegakit.html
License: CC0
Models: 211 / 200+ depending distribution tier
Formats: FBX, OBJ, Blend, glTF
Coverage: tools, vegetables, market stalls, chests, furniture, books, potions, breakables, weapons and general medieval/fantasy props.
Optimization: shared texture sets; low-poly meshes. Godot implementation exists in Source edition.
Target: `assets/props/quaternius_fantasy_props/`
Priority: VERY HIGH because one coherent pack covers many gameplay systems.

### Quaternius — Medieval Village MegaKit
Source: https://quaternius.com/packs/medievalvillagemegakit.html
License: CC0
Models: 304 / 300+
Formats: FBX, OBJ, Blend, glTF
Coverage: walls, floors, stairs, roofs, doors, windows, vines and modular settlement construction.
Target: `assets/buildings/quaternius_medieval_village_megakit/`
Priority: VERY HIGH for city/village expansion and reusable interiors/exteriors.

### Kenney — Survival Kit
Source: https://kenney.nl/assets/survival-kit
License: CC0
Files: 80
Category: 3D, animated
Coverage: survival/nature gameplay props.
Target: `assets/props/survival/kenney_survival_kit/`

### Quaternius — Modular Weapons Pack
Source: https://quaternius.com/packs/medievalweapons.html
License: CC0
Models: 24
Formats: FBX, OBJ, Blend
Coverage: swords, daggers, bows, shields, hammers and related medieval equipment.
Target: `assets/items/equipment/quaternius_modular_weapons/`

### Kenney — Castle Kit
Source: https://kenney.nl/assets/castle-kit
License: CC0
Files: 75
Coverage: modular castle/medieval architecture.
Target: `assets/buildings/castle/kenney_castle_kit/`

## CC0 discovery pool requiring per-item validation
OpenGameArt CC0 3D collection currently indexes useful assets including: medieval houses and modular building packs; sawmill; blacksmith; tavern; wells; church; harbour; ruins; mine assets; crystal mine; furniture and interiors; survival props; fishing pole; first-aid kit; tools/toolboxes; bridges; boats/docks; vegetation; food; farm crops; containers; destructible boxes; cemetery props; lamps; industrial props; electrical infrastructure; destroyed-city assets.
Source collection: https://opengameart.org/content/3d-assets-cc0
Rule: collection is discovery only. Verify each individual asset page and license before production import.

## Gameplay-driven asset matrix

### Professions and crafting
- blacksmith: forge, anvil, bellows, tongs, hammer, molds, racks, coal, ingots, workbench
- carpenter: saws, axes, planes, chisels, benches, logs, boards, beams, joinery
- miner: pickaxe, shovel, lantern, carts, rails, supports, ore piles, crystals, mine entrances
- farmer: hoes, sickles, scythes, ploughs, seed sacks, baskets, irrigation, barns, mills
- hunter: bows, traps, quivers, skinning/work tables, trophies, camps
- fisherman: rods, nets, traps, hooks, boats, docks, fish crates, drying/smoking racks
- cook/baker: ovens, cauldrons, pans, knives, dishes, ingredients, bread, meals
- healer/apothecary: herbs, bottles, mortar/pestle, bandages, first aid, shelves, beds
- tailor/leatherworker: cloth, hides, thread, needles, looms, racks, tanning/work tables
- merchant: stalls, counters, scales, crates, barrels, coin storage, signs
- builder: scaffolding, ladders, ropes, pulleys, masonry, timber, construction stages

### Resource chains
Each important resource should have world source -> gathered item -> processed material -> crafted product.
Examples:
- tree -> log -> plank -> beam/furniture/building
- ore vein -> ore -> ingot -> tool/weapon/hardware
- stone -> rubble/block -> wall/road/building
- grain -> harvested crop -> flour -> bread/food
- animal -> wool/milk/eggs/hide/meat -> processed goods
- herbs -> harvested plant -> dried ingredient -> medicine/potion
- fish -> caught fish -> cleaned/dried/cooked food

### Settlement life
Need coherent sets for homes, taverns, inns, shops, markets, workshops, barns, warehouses, guard posts, gates, walls, wells, mills, docks, churches/temples, cemeteries, administration, prisons, stables, roads, bridges and signage.

### Interiors
Every enterable building should avoid empty-box design. Populate with furniture, storage, lighting, food, dishes, tools, books, clutter, textiles, containers and profession-specific objects. Create clean/used/damaged variants where useful.

### Exploration and dungeons
Need cave/mine modules, ruins, underground supports, doors/gates, traps, treasure containers, crystals/ore, roots/vines, bones/remains, camp remnants, torches/lanterns, ritual/ancient props and environmental storytelling objects.

### Infrastructure
Need roads, paths, bridges, docks, fences, gates, drainage, wells, water tanks, mills, power/industrial props for later eras, street furniture, lighting, signs and transport-related props.

### Damage/state variants
Important interactive props should support intact -> used/worn -> damaged -> broken/destructible states where gameplay benefits. Buildings need construction and damage stages rather than one static mesh.

## Selection rules
1. Prefer coherent large CC0 packs over hundreds of unrelated single models.
2. Do not import an asset merely because it exists; it must fill a gameplay/world-building gap or be a useful variation.
3. Prefer glTF/GLB and Godot-ready content.
4. Keep art direction coherent by rematerialing/retexturing CC0 models when necessary.
5. Avoid duplicate near-identical assets unless they add biome, class, quality, age or damage variation.
6. Every imported third-party folder gets SOURCE.md and LICENSE.txt.
7. Large raw source archives stay out of runtime exports.
8. Production assets require collision/LOD/material/scale review.

## Next gaps
Dedicated goose/gosling; piglet; goat/kid; broader birds; insects; additional fish; biome-specific wildlife; profession NPC clothing; armor/clothing sets; mine/cave modules; farm machinery and crop growth stages; carts/wagons; saddles/tack; market/shop interiors; medical/apothecary props; construction-stage architecture; ruined/burned/flooded variants; regional architecture and biome props.
