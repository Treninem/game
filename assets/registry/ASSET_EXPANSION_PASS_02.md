# ImPuls — Asset Expansion Pass 02

Goal: build a coherent reusable asset library, not a random dump. Sources below were checked as CC0 on their publisher pages. Runtime import still requires SOURCE.md/LICENSE.txt, optimization, scale/material normalization and Godot validation.

## Newly approved coverage

### Water / boats / ports
- Kenney Watercraft Kit — 45 3D transport assets — CC0 — https://kenney.nl/assets/watercraft-kit
Target: `assets/vehicles/watercraft/kenney_watercraft/`
Use: boats, ships, water transport, fishing/trade/harbor gameplay.

### Food / kitchens / survival economy
- Kenney Food Kit — 200 3D food/kitchen assets — CC0 — https://kenney.nl/assets/food-kit
Target: `assets/items/food/kenney_food_kit/`
Use: hunger system, cooking, shops, markets, farming outputs, loot and interiors.

### Furniture / interiors
- Kenney Furniture Kit — 140 3D assets — CC0 — https://kenney.nl/assets/furniture-kit
Target: `assets/props/interiors/kenney_furniture/`
Use: homes, inns, shops, offices, workshops and player construction.

### Industry / production
- Kenney Factory Kit — 140 3D assets, variations and animation — CC0 — https://kenney.nl/assets/factory-kit
Target: `assets/buildings/industry/kenney_factory/`
Use: warehouses, conveyors, factories, industrial progression, production chains.

### Settlements / modern evolution
- Kenney City Kit Suburban — 40 3D city assets — CC0 — https://kenney.nl/assets/city-kit-suburban
Target: `assets/buildings/suburban/kenney_city_suburban/`
- Kenney Retro Urban Kit — 120 3D urban assets — CC0 — https://www.kenney.nl/assets/retro-urban-kit
Target: `assets/buildings/urban/kenney_retro_urban/`
Use these for later settlement/technology eras rather than forcing medieval art into every progression stage.

### Advanced technology / space era
- Kenney Modular Space Kit — 40 modular 3D assets with animation/variations — CC0 — https://kenney.nl/assets/modular-space-kit
Target: `assets/technology/space/kenney_modular_space/`
Keep inactive until progression reaches advanced technology.

### Nature / biome diversity
- Kenney Nature Kit — 330 3D nature assets — CC0 — https://kenney.nl/assets/nature-kit
- Quaternius Ultimate Nature Pack — 150 models — CC0 — https://quaternius.com/packs/ultimatenature.html
- Quaternius Stylized Nature MegaKit — 116 models incl. 40 trees, 35 plants/flowers, 27 rocks; glTF and Godot support — CC0 — https://quaternius.com/packs/stylizednaturemegakit.html
Targets under `assets/nature/`.

### Building progression
- Quaternius Ultimate Fantasy RTS — 128 textured models including buildings in different evolution stages plus nature — CC0; FBX/OBJ/Blend/glTF — https://quaternius.com/packs/ultimatefantasyrts.html
Target: `assets/buildings/progression/quaternius_fantasy_rts/`
Useful for visually communicating settlement growth/upgrades.

## Coverage that must be considered before adding more packs

Do not search only by nouns. Search by gameplay system and state variants:
- construction: foundation/frame/finished/damaged/ruined/burning/repaired/upgraded;
- agriculture: soil states, seeds, crop growth stages, harvest, hay, feed, fences, pens, barns, silos;
- animals: adult/young/sex variants when useful, carcass/meat/hide/horn/egg/milk outputs, tracks/nests/burrows;
- forestry: saplings, mature/fallen/dead trees, logs, stumps, branches, firewood;
- mining: ore nodes, exposed veins, carts, supports, rails, lamps, rubble, mine entrances;
- crafting: benches, furnaces, anvils, kilns, mills, looms, storage, containers;
- settlement economy: stalls, signs, crates, sacks, barrels, carts, counters, currency/commodity props;
- survival: tents, camps, fires, beds, cookware, water containers, traps, fishing gear;
- infrastructure: roads, paths, bridges, docks, wells, drainage, power/utility progression;
- interiors: doors/windows/stairs/ceilings/lighting/storage/sanitation/decor;
- environment: cliffs/caves/shorelines/riverbanks/swamps/snow/desert/tundra/tropical variants;
- weather/disasters: puddles, mud, snow accumulation, debris, smoke, fire, flood/storm aftermath;
- vehicles: carts/wagons/boats/cars/trucks plus wreck/damaged/cargo variants;
- human life: clothing by occupation/era, tools-in-hand, carrying, sitting, sleeping, eating, crafting, farming, mining, fishing, building, trading;
- combat/hunting: armor, shields, bows, arrows, melee equipment, traps, camp props; avoid importing unnecessary duplicates;
- technology eras: primitive -> medieval/agrarian -> industrial -> modern -> advanced/sci-fi, with visual continuity.

## Selection rule
Before approving a new pack, answer: (1) which uncovered gameplay system does it support, (2) does an approved pack already cover it, (3) is its style compatible, (4) is license definitely safe, (5) is it worth repository/runtime size. Prefer fewer broad coherent packs over hundreds of unrelated marketplace models.
