# ImPuls — CC0 3D Model Expansion (2026-08-14)

Only sources verified as CC0/public-domain are approved here. Prefer GLB/glTF for Godot, keep source/license metadata, optimize meshes/textures before runtime use.

## Animals — required coverage
Target taxonomy: chicken/chick, dog, cat, horse, bear, fox, rabbit/hare, wild boar, pig/piglet, duck, goose, pigeon/birds, cow, goat, sheep, deer, wolf, fish and additional wildlife.

### Approved packs
- Kenney Cube Pets — 24 animated 3D models — CC0 — https://kenney.nl/assets/cube-pets — target `assets/animals/kenney_cube_pets/`. Verified source explicitly tags dog/cat and animation.
- Quaternius Ultimate Animated Animal Pack — 12 animals, 12+ animations each — CC0 — https://quaternius.com/packs/ultimateanimatedanimals.html — target `assets/animals/quaternius_ultimate_animated/`.
- Quaternius Farm Animal Pack — 7 animated farm animals — CC0 — https://quaternius.com/packs/farmanimal.html — target `assets/animals/farm/quaternius_farm_animals/`.
- Quaternius Cube World Kit — animated animals/characters plus environment — CC0 — https://quaternius.com/packs/cubeworldkit.html — target `assets/animals/quaternius_cube_world/`.
- Kenney Prototype Kit — 145 3D files; animal/character/building tags, animation/variations — CC0 — https://www.kenney.nl/assets/prototype-kit — target `assets/prototype/kenney_prototype_kit/`.

Do not mark a specific species production-ready until the actual downloaded pack inventory confirms that species. Missing species should be filled with another individually verified CC0 model rather than a mixed/unknown-license marketplace asset.

## Buildings / settlements
- Kenney Modular Buildings — 100 modular 3D files — CC0 — https://kenney.nl/assets/modular-buildings — `assets/buildings/kenney_modular_buildings/`.
- Kenney Building Kit — 80 3D files, animation support — CC0 — https://www.kenney.nl/assets/building-kit — `assets/buildings/kenney_building_kit/`.
- Kenney City Kit Commercial — 50 3D city/commercial files — CC0 — https://www.kenney.nl/assets/city-kit-commercial — `assets/buildings/kenney_city_commercial/`.
- Kenney Castle Kit — 75 3D medieval/castle files — CC0 — https://kenney.nl/assets/castle-kit — `assets/buildings/kenney_castle_kit/`.
- Coding Creature City Props Kit 1 — 130+ game-ready urban models, FBX/GLB/OBJ — CC0 — https://codingcreature.com/assets/city-props-kit-1/ — `assets/buildings/codingcreature_city_props_1/`.
- Public Domain Game Assets — Low Poly Town, Office Building, Wooden Shack, Capitol Building and other models — site-wide CC0 — https://gameassets.joshmoody.org/ — import individually under `assets/buildings/public_domain_game_assets/` with per-model SOURCE metadata.

## Humans / NPCs
- Kenney Animated Characters Protagonists — 8 animated 3D characters — CC0 — https://www.kenney.nl/assets/animated-characters-protagonists — `assets/characters/humans/kenney_animated_protagonists/`.
- Kenney Blocky Characters — 20 animated 3D files — CC0 — https://kenney.nl/assets/blocky-characters — `assets/characters/humans/kenney_blocky_characters/`.
- Quaternius Ultimate Modular Men — 11 modular characters, 24 animations each — CC0 — https://quaternius.com/packs/ultimatemodularcharacters.html — `assets/characters/humans/quaternius_modular_men/`.

## High-detail environment supplement
- Poly Haven models/textures/HDRIs — all CC0 — https://polyhaven.com/ — use for realistic architecture props, nature props, PBR materials and lighting under existing Poly Haven folders.

## Import rules
1. Download only from the creator/official distribution page where possible.
2. Save `SOURCE.md` and `LICENSE.txt` in every third-party pack directory.
3. Prefer `.glb`/`.gltf`; FBX/OBJ are source/fallback formats.
4. Normalize Godot scale, forward axis, skeleton naming, materials, collisions and animation names.
5. Generate LODs/collision proxies for large meshes and compress textures before shipping.
6. Do not commit unknown-license, NC, ND, editorial-only, ripped, branded or copyrighted-game models.
7. Git repository is not a dumping ground for huge raw archives: keep useful game-ready assets; use Git LFS/external artifact storage if binary volume becomes large.

## Current source verification notes
- Kenney pages above explicitly state Creative Commons CC0.
- Poly Haven states all assets are CC0 and usable for any purpose.
- Coding Creature City Props Kit 1 states CC0 and provides FBX/GLB/OBJ.
- Public Domain Game Assets states site assets are CC0/public domain.
