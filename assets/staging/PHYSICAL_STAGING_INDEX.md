# ImPuls Game — Physical Staging Index

This file lists third-party asset packs whose real files are physically present under `assets/staging/` on `main`.

**Important:** physical staging does not mean gameplay integration. The main game-development flow must select, normalize and integrate assets deliberately. Do not redownload a pack already listed here unless replacing it with a better verified version.

## Storage policy

- Keep source-only assets under `assets/staging/`.
- Preserve `SOURCE.md` and `LICENSE.txt` with every third-party pack.
- Prefer one canonical production interchange format per large 3D pack to avoid repository bloat: GLB/glTF first, then FBX, then OBJ where required.
- A registry/source mention is not an import. Only folders physically present in the repository belong in this index.
- Check each batch failure file before treating a workflow run as complete.

## Verified physical batches

### Fauna, characters, animation and general items
Physical asset commit: `fef2efd7606e53c8755a7e7e45a02274dac8aa8b`

- `assets/staging/animals/quaternius_animal_pack_vol2/` — animated wolf, eagle, dog, cat and piranha.
- `assets/staging/animals/quaternius_animated_fish/` — seven animated aquatic species.
- `assets/staging/animals/quaternius_animals_pack_5/` — five additional animals.
- `assets/staging/characters/quaternius_animated_human/` — animated humanoid.
- `assets/staging/characters/quaternius_animated_characters_50plus/` — 50+ animated characters.
- `assets/staging/animations/quaternius_universal_animation_library_2_standard/` — reusable humanoid animation library.
- `assets/staging/characters/kenney_animated_characters_protagonists/`.
- `assets/staging/characters/kenney_animated_characters_retro/`.
- `assets/staging/items/kenney_generic_items/`.
- `assets/staging/items/kenney_blaster_kit/`.
- Batch failure file: `assets/staging/animals/FAUNA_CHARACTER_DOWNLOAD_FAILURES.txt` — verified empty after successful physical import.

### Food, farming, survival, streets and transport
Physical asset commit: `a08edf38abd8afd7b895b0d7f2b2ac486565d2e0`

- `assets/staging/food/quaternius_crops_100plus/` — crop growth/harvest models.
- `assets/staging/food/quaternius_food_100plus/` — food/consumables.
- `assets/staging/items/quaternius_survival_50plus/` — survival/camping props.
- `assets/staging/vehicles/quaternius_public_transport/`.
- `assets/staging/vehicles/quaternius_cars/`.
- `assets/staging/world/quaternius_modular_streets/`.
- `assets/staging/items/quaternius_medieval_weapons_2018/`.

The original RPG-items URL in this batch failed and was corrected in the next verified batch; do not interpret the historical failure line as the current RPG-item status.

### RPG items, village, dungeon, city buildings and medical props
Physical asset commit: `8482c0a0ab465b33037c1ed1d595ba02e835e663`

- `assets/staging/items/quaternius_rpg_items_100plus/` — corrected physical RPG item pack.
- `assets/staging/buildings/quaternius_medieval_village/` — houses, inn, blacksmith, mill, stable, sawmill, tower and village props.
- `assets/staging/world/quaternius_modular_dungeon/`.
- `assets/staging/buildings/quaternius_lowpoly_buildings/` — bank, shop, hospital, houses/flats and textures.
- `assets/staging/items/oga_medical_stuff/` — medical props; visually verify/remove any protected Red Cross emblem before production use.
- Batch failure file: `assets/staging/items/VILLAGE_DUNGEON_MEDICAL_DOWNLOAD_FAILURES.txt` — verified empty after successful physical import.

### Coherent modern city, modular architecture, factory and interiors
Physical asset commit: `4deb30bfd0b726f91b9f9e72aa1c6b5ba78addee`

- `assets/staging/city/kenney_city_kit_industrial/`.
- `assets/staging/city/kenney_city_kit_commercial/`.
- `assets/staging/city/kenney_city_kit_suburban/`.
- `assets/staging/city/kenney_city_kit_roads/`.
- `assets/staging/city/kenney_modular_buildings/`.
- `assets/staging/interiors/kenney_factory_kit/`.
- `assets/staging/interiors/quaternius_house_interior_120plus/`.
- `assets/staging/interiors/quaternius_furniture_pack/`.
- Batch failure file: `assets/staging/city/CITY_INTERIORS_DOWNLOAD_FAILURES.txt` — verified empty.

### Canonical nature, survival, food and furniture
Physical asset commit: `b3513f7421ebdd72e2af63d0f8ce0204f87abb99`

- `assets/staging/nature/kenney_nature_kit/` — large coherent nature library.
- `assets/staging/items/kenney_survival_kit/` — survival objects.
- `assets/staging/food/kenney_food_kit/` — coherent 3D food/kitchen library.
- `assets/staging/interiors/kenney_furniture_kit/` — coherent furniture library.
- Batch failure file: `assets/staging/items/KENNEY_WORLD_DOWNLOAD_FAILURES.txt` — verified empty.

### Medieval/fantasy construction and everyday props
Physical asset commit: `4c73f13c53077ebf7ee66fd7c1e37b0d43a11906`

- `assets/staging/medieval/kenney_castle_kit/`.
- `assets/staging/medieval/kenney_building_kit/`.
- `assets/staging/medieval/kenney_graveyard_kit/`.
- `assets/staging/medieval/quaternius_fantasy_props_megakit_standard/` — weapons, tools, food/vegetables, potions, market stalls, chests, furniture and general props.
- Batch failure file: `assets/staging/medieval/MEDIEVAL_WORLD_DOWNLOAD_FAILURES.txt` — verified empty.

## Main integration-chat checklist

Before adding a model to gameplay:

1. Search this index and the target staging folder first.
2. Prefer a coherent pack already used by the same district/biome/interior instead of mixing unrelated visual styles.
3. Normalize scale, axes, pivots and material naming.
4. Create or reuse collisions/LODs only in the integration flow, not in source-only staging.
5. Reuse shared materials, shaders and animation libraries where possible.
6. Keep source/license metadata with the original staged pack.
7. Do not mass-load the entire staging tree into a gameplay scene; integrate only selected production assets.

## Status vocabulary for every chat

- `DISCOVERED` — source found; no files in repo yet.
- `APPROVED` — source/license reviewed; still may not be downloaded.
- `STAGED_PHYSICAL` — real files confirmed under `assets/staging/`.
- `PRODUCTION_READY` — selected asset normalized/tested for Godot production use.
- `INTEGRATED` — asset is actually referenced by game scenes/resources/code.

Never use `IMPORTED` ambiguously; state the exact status above.