# Asset pass 09 — agriculture, markets, food, settlements

Verified CC0 sources only. This pass focuses on coherent gameplay systems rather than collecting random assets.

## Approved / verified sources

### Quaternius — Ultimate Crops Pack
Source: https://quaternius.com/packs/ultimatecrops.html
License: CC0
Inventory: 102 crop models with five growth stages.
Formats: FBX, OBJ, Blend.
Use: farming lifecycle, field variation, harvesting, crop progression.
Target: `assets/environment/agriculture/crops/quaternius_ultimate_crops/`

### Kenney — Mini Market
Source: https://www.kenney.nl/assets/mini-market
License: CC0
Inventory: 20 3D market/shop models with variations/animation support.
Use: shops, stalls, settlement economy, trade interiors.
Target: `assets/buildings/commerce/kenney_mini_market/`

### Kenney — Food Kit
Source: https://www.kenney.nl/assets/food-kit
License: CC0
Inventory: 200 3D food/kitchen assets.
Use: hunger system, cooking, stores, taverns, kitchens, loot, production outputs.
Target: `assets/items/food/kenney_food_kit/`

### Kenney — Watercraft Kit
Source: https://kenney.nl/assets/watercraft-kit
License: CC0
Inventory: 45 3D boats/ships/watercraft.
Use: fishing, transport, trade, ports, rivers and coastal gameplay.
Target: `assets/vehicles/watercraft/kenney_watercraft_kit/`

### Quaternius — Medieval Village MegaKit
Source: https://quaternius.com/packs/medievalvillagemegakit.html
License: CC0
Inventory: 304 modular models; glTF/FBX/OBJ/Blend; Godot source implementation available in source tier.
Use: villages, houses, workshops, inns, stores, farms, settlement expansion.
Target: `assets/buildings/settlements/quaternius_medieval_village_megakit/`

### Kenney — Retro Fantasy Kit
Source: https://www.kenney.nl/assets/retro-fantasy-kit
License: CC0
Inventory: 100 3D medieval/fantasy town/building models.
Use: low-cost distant settlement LODs, prototypes and stylistic fallback pieces.
Target: `assets/buildings/settlements/kenney_retro_fantasy/`

## Gameplay coverage added by this pass

Agriculture must support: soil preparation -> seed -> five-stage crop growth -> harvest -> storage -> processing -> cooking/trade.

Markets must support: stall/shop shell -> shelves/crates -> displayed goods -> merchant NPC -> stock variation -> closed/open states -> damaged/abandoned states.

Food must support: raw ingredient -> prepared ingredient -> cooked meal -> preserved food -> spoiled variant where needed. Avoid requiring a unique mesh for every state when material swaps or decals are enough.

Water economy must support: fishing spot -> small boat -> catch/container -> dock -> market -> larger cargo craft. Keep vessels modular where possible.

Settlement construction should reuse modular wall/roof/door/window pieces and generate building variation procedurally instead of storing hundreds of nearly identical houses.

## Still missing / next search priorities

1. Horse carts, wagons, harness, saddle, reins and pack-animal equipment.
2. Detailed farm implements: plough, harrow, scythe, sickle, hoe, pitchfork, wheelbarrow, watering equipment.
3. Mills: windmill/watermill machinery, millstones, grain sacks and flour production props.
4. Orchards and berry systems with growth/harvest states.
5. Hay/straw lifecycle: cut grass, windrow, haystack, bale, stable feed.
6. Dairy chain: bucket, milk churn, cheese/butter production.
7. Butchery/fish processing assets appropriate to the game's survival economy.
8. Wells, pumps, troughs, irrigation channels and water storage.
9. Beehives/apiary, honey and wax production.
10. Animal shelters: coop, kennel, pigsty, stable, barn interiors, nests and feeding stations.

## Import quality rules

- Prefer glTF/GLB at runtime; convert FBX/OBJ sources where necessary.
- Preserve source URL and CC0 evidence in each imported pack directory.
- Generate collisions and LODs where useful.
- Atlas compatible low-poly materials when this reduces draw calls without destroying visual consistency.
- Do not import duplicate meshes solely because they occur in multiple packs.
- Keep source packs separate from normalized game-ready derivatives.
- Do not mark an asset production-ready until actual downloaded inventory has been inspected.
