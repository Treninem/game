# ImPuls Asset Gap Pass 05 — 2026-08-14

Goal: fill functional world gaps rather than collect random models. All production imports must retain per-asset license/source metadata. Prefer CC0; non-CC0 entries remain candidates only and must not enter the production library without explicit approval.

## Newly verified CC0 source pools

### Kenney — Retro Medieval Kit
Source: https://opengameart.org/content/retro-medieval-kit
License: CC0
Coverage: 100+ / 120 optimized low-poly medieval objects; GLB, FBX, OBJ; engine compatible.
Use: settlement props, fortification details, siege/medieval world dressing and fallback objects.
Target: `assets/world/medieval/kenney_retro_medieval/`

### Quaternius — Fantasy Props MegaKit
Source: https://quaternius.com/packs/fantasypropsmegakit.html
License: CC0
Coverage: 200+ props including tools, weapons, vegetables, potions, market stalls, chests, furniture and breakables. glTF/FBX/OBJ; optimized/shared textures; Godot support in Source version.
Use: professions, crafting, shops, homes, taverns, workshops, loot and destructibles.
Target: `assets/props/quaternius_fantasy_props/`

### Quaternius — Medieval Village MegaKit
Source: https://quaternius.com/packs/medievalvillagemegakit.html
License: CC0
Coverage: 300+ modular walls, floors, roofs, stairs and environment pieces; glTF/FBX/OBJ; Godot support.
Use: modular villages, shops, workshops, interiors/exteriors and construction variants.
Target: `assets/buildings/medieval/quaternius_village/`

### Quaternius — Farm Buildings
Source: https://quaternius.itch.io/lowpoly-farm-buildings
License: CC0
Coverage: 13 farm buildings.
Use: barns, animal/farm zones and rural settlements.
Target: `assets/buildings/farm/quaternius/`

### Kenney — Factory Kit
Source: https://opengameart.org/content/factory-kit
License: CC0
Coverage: 140+ optimized industrial/factory/warehouse/conveyor objects.
Use: industrial age, production lines, warehouses, logistics and automation.
Target: `assets/industry/kenney_factory/`

### OpenGameArt — CC0 3D collection
Source: https://opengameart.org/content/3d-assets-cc0
License rule: collection is CC0-oriented but every selected item still receives individual source/license verification before import.
Promising coverage indexed in the collection: 3D Mine Assets, Crystal Mine, medieval blacksmith/sawmill/tavern/well/harbour props, caves, industrial packs, bridges, medical/first-aid props, fishing pole, corn, vegetation, survival tools, ruined/destroyed city assets, rail/vehicle/environment items, additional animals including boar/raven/cobra/crocodile/whale.
Target staging: `assets/staging/opengameart_cc0_verified/`

## Functional gaps now tracked

### Mining / geology
Need coherent sets for: mine entrance, timber supports, rails/carts, ore carts, pickaxes, shovels, lanterns, ropes, pulleys, ladders, winches, ore piles, coal, iron/copper/tin/gold/silver ores, crystals, underground water, cave formations, collapse rubble, warning props, processing/crushing/smelting stages.

### Farming
Need: ploughs, hoes, scythes, sickles, forks, wheelbarrows, carts, seed bags, hay/straw, troughs, fences/gates, coops, nests, barns, silos, wells, irrigation, mills; crop lifecycle variants for wheat/barley/oats/rye/corn/potato/carrot/cabbage/onion/beans/flax plus fruit/berries where biome appropriate.

### Animal husbandry
Need species-specific housing/feeders, nests, eggs, milk containers, shearing props, tack/saddles/harness, manure/compost systems, young-animal variants and footprints/tracks.

### Transport before engines
Need wagon/cart/chariot classes, wheel/axle variants, horse tack/harness, cargo loads, damaged/broken variants, hitching posts, stables and road-side repair props.

### Health / medicine
Need bandages, splints, herbs, mortar/pestle, bottles, medical bags, beds, examination furniture, first-aid/clinic props and later-era hospital equipment. Avoid branded or prescription-specific commercial products.

### Clothing / equipment
Need modular civilian/work clothing by climate and profession, hats/gloves/boots/backpacks, rain/cold gear, aprons, mining/farming gear, armor progression and wearable attachment points. Prioritize generic unbranded assets.

### Infrastructure
Need wells, pumps, aqueduct/water pipes, drainage/sewers, bridges by material/era, docks/piers, cranes, warehouses, road signs, street furniture, power/utility progression, rail stations and track-side props.

### World-state variants
For key assets seek/build: pristine, used/worn, dirty/muddy, wet, snowy/frosted, burned, damaged, broken, abandoned/overgrown and repair/construction states. Do not duplicate full meshes where shader/material/decal variants can solve the state efficiently.

## Selection discipline
1. Do not import a pack just because it is free.
2. Every pack must close a gameplay/world-building gap or replace a weaker placeholder.
3. Prefer coherent packs sharing art direction/material atlases.
4. Prefer glTF/GLB and Godot-ready content.
5. Track polygon count, texture memory, skeleton/animations, LOD and collision readiness.
6. Use modular assets and material variants to reduce repository/runtime size.
7. Keep paid tiers out of the required baseline; the game must remain buildable with freely obtainable assets.
8. Non-CC0/attribution assets are not production defaults while equivalent CC0 options exist.

## Next gap pass
Prioritize: exact mine equipment -> horse carts/harness -> crop lifecycle sets -> regional/climate clothing -> bridges/water infrastructure -> clinics/medicine -> burned/ruined building variants -> snowy/tropical/swamp/desert settlement variants -> remaining fauna and young animals -> insects/pollinators -> aquatic ecosystem props.
