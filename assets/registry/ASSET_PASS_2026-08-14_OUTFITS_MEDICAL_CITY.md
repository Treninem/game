# ImPuls — Asset Pass: Outfits, Medical, City, Infrastructure

Date: 2026-08-14

This pass expands the reusable CC0 asset library without dumping random packs into the repository. Every source below is selected because it fills a concrete production need.

## Character clothing / armor

### Quaternius — Modular Character Outfits: Fantasy
Source: https://quaternius.com/packs/modularcharacteroutfitsfantasy.html
License: CC0
Models: 74 total entries; 12 outfits built from 62 modular parts
Formats: FBX, OBJ, Blend, glTF
Rigging: humanoid; compatible with Universal Base Characters and Universal Animation Library
Use cases: civilian/farmer/hunter/guard/merchant/worker/warrior outfit variation, armor progression, NPC visual variety
Target: `assets/characters/outfits/quaternius_fantasy_modular/`
Status: VERIFIED

### Quaternius — Animated Knight Pack
Source: https://quaternius.com/packs/knightcharacter.html
License: CC0
Models: 10
Animated: yes
Includes: knight character, swords, helmets and accessories
Formats: FBX, OBJ, Blend
Target: `assets/characters/armor/quaternius_knight/`
Status: VERIFIED

### Quaternius — Ultimate Modular Women Pack
Source: https://quaternius.com/packs/ultimatemodularwomen.html
License: CC0
Characters: 10; 24 animations each; modular body parts; humanoid rig version
Formats: FBX, OBJ, Blend, glTF
Target: `assets/characters/humans/quaternius_modular_women/`
Status: VERIFIED

## Medical / survival-health assets

### OpenGameArt — First Aid Kit 3D
Source: https://opengameart.org/content/first-aid-kit-3d
Direct archive: https://opengameart.org/sites/default/files/_first_aid_kit_3d_v1.1.zip
License: CC0
Formats: BLEND, OBJ
Complexity: 140 triangles
Texture: 512x512 diffuse
Target: `assets/items/medical/opengameart_first_aid_kit/`
Status: VERIFIED; ready for import

### OpenGameArt — Medical Stuff
Source: https://opengameart.org/content/medical-stuff
Direct archive: https://opengameart.org/sites/default/files/Medical_0.zip
License: CC0
Contains: medical box, pill, pill bottle, syringe, gauze
Target: `assets/items/medical/opengameart_medical_stuff/`
Status: VERIFIED; ready for import
Important: do not use protected Red Cross emblem variants; use neutral/fictional medical markings in game textures.

### OpenGameArt — Hospital / Medical Center from Moscow
Source: https://opengameart.org/content/hospital-medical-center-from-moscow
License: CC0
Type: 3D building
Use cases: modern/abandoned medical facility, survival/post-crisis region, urban medical infrastructure
Target: `assets/buildings/medical/opengameart_moscow_medical_center/`
Status: VERIFIED; inspect geometry/materials before production use

## Modern city and infrastructure

### Quaternius — Downtown City MegaKit
Source: https://quaternius.com/packs/downtowncitymegakit.html
License: CC0
Models: 315 / 300+ modular environment pieces
Formats: FBX, Blend, glTF
Features: modular buildings/street pieces, 7 example buildings, shared optimized textures; Source edition has Godot project, simple collisions, wear controls, fake interiors
Use cases: modern progression era, city blocks, shops, offices, apartments, streets, warehouses
Target: `assets/buildings/city/quaternius_downtown_megakit/`
Status: VERIFIED

### Kenney — City Kit Roads
Source: https://www.kenney.nl/assets/city-kit-roads
License: CC0
Files: 70
Category: 3D city/roads
Target: `assets/world/roads/kenney_city_roads/`
Status: VERIFIED

### Kenney — Modular Buildings
Source: https://www.kenney.nl/assets/modular-buildings
License: CC0
Files: 100
Category: 3D modular city/town/buildings
Target: `assets/buildings/kenney_modular_buildings/`
Status: VERIFIED

## Future progression

### Quaternius — Modular Sci-Fi MegaKit
Source: https://quaternius.com/packs/modularscifimegakit.html
License: CC0
Models: 277 / 270+ modular environment pieces
Formats: FBX, OBJ, Blend, glTF
Use only for late-game/high-technology progression: labs, advanced industry, corridors, stations, enclosed technical spaces
Target: `assets/technology/scifi/quaternius_modular_scifi/`
Status: VERIFIED

## Environment and biome foundation

### Quaternius — Ultimate Nature Pack
Source: https://quaternius.com/packs/ultimatenature.html
License: CC0
Models: 150
Formats: FBX, OBJ, Blend
Use cases: reusable vegetation/rocks/terrain props for temperate, forest, mountain and rural biome dressing
Target: `assets/nature/quaternius_ultimate_nature/`
Status: VERIFIED

### Kenney — Holiday Kit
Source: https://www.kenney.nl/assets/holiday-kit
License: CC0
Files: 100
Animation support: yes
Use selectively for snow/winter settlement props and seasonal environment dressing; do not import holiday-specific clutter unless needed.
Target staging: `assets/biomes/winter/kenney_holiday_subset/`
Status: VERIFIED source; selective import only

## Animation coverage

### Quaternius — Universal Animation Library 2
Source: https://quaternius.com/packs/universalanimationlibrary2.html
License: CC0
Animations: 130+
Godot compatible
Coverage: melee combos, parkour, farming, fishing, zombie locomotion and other actions
Target: `assets/characters/animations/quaternius_universal_2/`
Status: VERIFIED

### Quaternius — Universal Animation Library
Source: https://quaternius.com/packs/universalanimationlibrary.html
License: CC0
Animations: 120+
Coverage: directional locomotion, jog, sprint, push, crawl, swim, sit, death, combat and emotes
Target: `assets/characters/animations/quaternius_universal_1/`
Status: VERIFIED

## Import priorities created by this pass

1. Medical props: first-aid kit, syringe/gauze/medicine containers.
2. Modular outfits for civilian/work/profession/guard variation.
3. Female modular NPC set to prevent population repetition.
4. Modern city progression assets for later eras.
5. Winter subset only where it genuinely improves cold-region biome coverage.
6. Sci-fi kit remains late-game and must not leak visually into primitive/medieval/industrial eras.

## Quality rules

- Do not import whole packs blindly.
- Prefer glTF/GLB for Godot runtime.
- Every imported folder must contain `SOURCE.md` and `LICENSE.txt`.
- Remove duplicate meshes/materials/textures before shipping.
- Generate simple collision and LOD where needed.
- Keep real-world trademarks/protected humanitarian emblems out of final game textures unless independently cleared.
- Build NPC outfit palettes by profession, wealth, climate and technological era instead of random color swaps.
