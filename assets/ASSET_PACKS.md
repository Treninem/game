# ImPuls Game — Shared Asset Pack Registry

This file is the canonical asset registry for all development chats working on this game.

## Rule for every development chat
Before generating a replacement asset, check this registry and the `assets/` tree. Reuse suitable existing assets first. New imported assets must have a compatible license and their source/license must be recorded here.

## Approved CC0 packs

### Nature / terrain / vegetation
- Kenney Nature Kit — 330 3D files — CC0 1.0
  Source: https://kenney.nl/assets/nature-kit
  Target: `assets/nature/kenney_nature_kit/`
- Kenney Foliage Pack — 100 2D files — CC0 1.0
  Source: https://kenney.nl/assets/foliage-pack
  Target: `assets/nature/foliage/`
- Quaternius Ultimate Nature Pack — 150 models — CC0
  Source: https://quaternius.com/packs/ultimatenature.html
  Target: `assets/nature/quaternius_ultimate_nature/`
- Quaternius Ultimate Stylized Nature Pack — 63 models plus seamless textures/normal maps — CC0
  Source: https://quaternius.com/packs/ultimatestylizednature.html
  Target: `assets/nature/quaternius_stylized_nature/`
- Quaternius Stylized Nature MegaKit — 116 models including 40 trees, 35 plants/flowers, 27 rocks, grass and bushes — CC0
  Source: https://quaternius.itch.io/stylized-nature-megakit
  Target: `assets/nature/quaternius_nature_megakit/`
- Quaternius Simple Nature Pack — trees, grass, rocks, bushes — CC0
  Source: https://quaternius.com/packs/simplenature.html
  Target: `assets/nature/quaternius_simple_nature/`

Subfolders/categories to maintain: `trees/`, `grass/`, `plants/`, `flowers/`, `bushes/`, `rocks/`, `stone/`, `sand/`, `soil/`, `snow/`, `cliffs/`, `water/`.

### Buildings / settlements
- Quaternius Ultimate Buildings Pack — modular textured buildings — CC0
  Source: https://quaternius.com/packs/ultimatetexturedbuildings.html
  Target: `assets/buildings/quaternius_ultimate_buildings/`
- Quaternius Buildings Pack — CC0
  Source: https://quaternius.com/packs/buildings.html
  Target: `assets/buildings/quaternius_buildings/`
- Quaternius Farm Buildings Pack — CC0
  Source: https://quaternius.com/packs/farmbuildings.html
  Target: `assets/buildings/quaternius_farm_buildings/`

### Humans / characters / NPCs
- Quaternius CC0 character library: Animated Characters, Animated Human Low Poly, LowPoly RPG Characters, posed humans and Universal Animation Library.
  Reference collection: https://opengameart.org/content/all-cc0-uploader-quaternius
  Target: `assets/characters/humans/`
- Keep reusable animations in `assets/characters/animations/` and separate civilian, survivor, merchant, worker, warrior and NPC variants.

### Animals / creatures
- Quaternius CC0 animal library: farm animals, fish and animated low-poly animals.
  Reference collection: https://opengameart.org/content/all-cc0-uploader-quaternius
  Target: `assets/animals/`
- OpenGameArt CC0 animal/creature assets may be used only after confirming the individual asset license.

### Items / props / tools / weapons
- Kenney Generic Items — 160 items/tools/household sprites — CC0
  Source: https://www.kenney.nl/assets/generic-items
  Target: `assets/items/kenney_generic_items/`
- Quaternius Fantasy Props MegaKit Standard — 200+ furniture, tools, weapons, books, potions, breakables and props — CC0
  Source: https://quaternius.itch.io/fantasy-props-megakit
  Target: `assets/props/quaternius_fantasy_props/`
- Quaternius CC0 collection also includes survival props, medieval weapons, guns, food, furniture, crops and interiors.
  Reference: https://opengameart.org/content/all-cc0-uploader-quaternius

Maintain categories: `items/`, `tools/`, `weapons/melee/`, `weapons/ranged/`, `weapons/ammo/`, `food/`, `containers/`, `furniture/`, `crafting/`, `resources/`.

### VFX / elements / particles
Create and maintain reusable game-ready VFX under:
- `assets/vfx/water/` — splashes, foam, rain, waterfalls, ripples
- `assets/vfx/fire/` — flames, embers, sparks, smoke
- `assets/vfx/wind/` — leaves, grass response, wind streaks
- `assets/vfx/dust/` — footsteps, impacts, ambient dust
- `assets/vfx/smoke/`
- `assets/vfx/fog/`
- `assets/vfx/snow/`
- `assets/vfx/mud/`
- `assets/vfx/debris/`
- `assets/vfx/blood/`
- `assets/vfx/magic/`

For effects that cannot be represented well by static packs, prefer Godot shaders/GPUParticles and generated project-owned textures rather than importing assets with unclear rights.

### UI
- Kenney UI Pack — CC0
  Source: https://kenney.nl/assets/ui-pack
  Target: `assets/ui/kenney_ui_pack/`
- Kenney UI Pack Adventure — 130 UI assets — CC0
  Source: https://kenney.nl/assets/ui-pack-adventure
  Target: `assets/ui/kenney_ui_adventure/`
- Kenney UI Pack RPG Expansion — CC0
  Source: https://kenney.nl/assets/ui-pack-rpg-expansion
  Target: `assets/ui/kenney_ui_rpg/`

UI must cover HUD, inventory, crafting, equipment, map/fog-of-war, quests, character, skills, technology, trading, building, settings and 10-slot save/load screens.

## License policy
Prefer CC0. Do not import assets with unclear redistribution or commercial-use rights. Preserve original license/readme/source metadata when importing. Paid versions/bundles are not required when a free CC0 Standard version exists.

## Integration priority
1. Terrain, trees, grass, rocks, water and environmental VFX
2. Buildings, interiors and settlement props
3. Humans/NPCs and reusable animation library
4. Animals and creatures
5. Items, resources, crafting tools and weapons
6. Fire, wind, dust, smoke, weather and interaction VFX
7. Complete game UI

## Cross-chat rule
Every ChatGPT/Codex development session working on `Treninem/game` must read this registry before adding art. Existing approved assets are the default source. If an asset is missing, first search for a legally compatible free/CC0 pack; if none fits, generate a project-owned asset. Add every newly approved pack to this registry so all chats share the same asset library.