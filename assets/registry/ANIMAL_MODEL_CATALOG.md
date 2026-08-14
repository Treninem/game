# ImPuls — Verified CC0 Animal Model Catalog

Purpose: canonical cross-chat catalog for animal models approved for the game. Every model imported into runtime must keep source/license metadata and be normalized for Godot.

## Verified packs

### Quaternius — Ultimate Animated Animal Pack
Source: https://quaternius.com/packs/ultimateanimatedanimals.html
License: CC0
Formats: FBX, OBJ, Blend, glTF
Models: 12; 12+ animations per animal.
Verified species: Cow, Donkey, Deer, Alpaca, Bull, Fox, Shiba Inu, Stag, Husky, Wolf, White Horse, Horse.
Target: `assets/animals/quaternius_ultimate_animated/`

### Quaternius — Farm Animal Pack
Source: https://quaternius.com/packs/farmanimal.html
License: CC0
Formats: FBX, OBJ, Blend
Models: 7 animated farm animals.
Verified bundle species: Pig, Pug/Dog, Sheep, Horse, Cow, Llama, Zebra.
Target: `assets/animals/farm/quaternius_farm_animals/`

### Kenney — Cube Pets
Source: https://kenney.nl/assets/cube-pets
License: CC0
Category: 3D animated
Files: 24
Tags explicitly include pet, animal, dog, cat.
Target: `assets/animals/pets/kenney_cube_pets/`

### OpenGameArt — Rooster (Animated)
Source: https://opengameart.org/content/rooster-animated
License: CC0
Format/package: ZIP with Blender model; rigged and animated; diffuse + normal texture.
Target: `assets/animals/birds/chicken/opengameart_rooster/`
Status: VERIFIED dedicated rooster production candidate.

### OpenGameArt — Boar
Source: https://opengameart.org/content/boar
License: CC0
Format: Blender
Model: rigged/textured wild boar/warthog, about 1k tris; walk and attack animations included.
Target: `assets/animals/wildlife/boar/opengameart_boar/`
Status: VERIFIED dedicated wild-boar production candidate.

### OpenGameArt — Low Poly 3D Pig
Source: https://opengameart.org/content/low-poly-3d-pig
License: CC0
Format: Blender
Model: dedicated low-poly pig; commercial use explicitly permitted by author under CC0.
Target: `assets/animals/farm/pig/opengameart_low_poly_pig/`
Status: VERIFIED additional pig model.

### OpenGameArt — 3D Animals collection
Source: https://opengameart.org/content/3d-animals
License: mixed per entry — import ONLY entries whose individual page confirms CC0.
Useful indexed dedicated models include Chicken (animated), Hen and chicks, Rigged Duck, Rigged Duckling, Low Poly Bear, Low Poly Cub, Low Poly Fox, Low Poly Rabbit, Low Poly Pig, Low Poly Cow, Low Poly Deer.
Target staging: `assets/animals/opengameart_cc0/`
Rule: collection membership alone is not license proof; verify every selected entry before importing.

### OpenGameArt — White Bear (Low poly)
Source: https://opengameart.org/content/white-bear-low-poly
License: CC0
Model: textured low-poly bear, not rigged.
Target: `assets/animals/wildlife/bear/opengameart_white_bear/`
Status: VERIFIED bear model; requires project rig/animations or replacement with animated CC0 bear later.

### Quaternius — Cube World Kit
Source: https://quaternius.com/packs/cubeworldkit.html
License: CC0
Formats: FBX, OBJ, Blend, glTF
Models: 108 including animated characters, animals, enemies and environment.
Target: `assets/animals/quaternius_cube_world/`

### Kenney — Prototype Kit
Source: https://www.kenney.nl/assets/prototype-kit
License: CC0
Category: 3D animated; 145 files; includes animal/character/vehicle/building assets.
Target staging: `assets/prototype/kenney_prototype_kit/`

## Required species matrix

### Domestic / farm
- [x] Dog — Quaternius + Kenney
- [x] Cat — Kenney Cube Pets
- [x] Horse — Quaternius
- [x] Pig — Quaternius Farm Animal Pack + dedicated OpenGameArt CC0 pig
- [x] Cow / bull — Quaternius
- [x] Sheep — Quaternius
- [x] Rooster — dedicated animated CC0 OpenGameArt model verified
- [~] Chicken / hen / chicks — dedicated OGA candidates located; individual license verification required before production import
- [~] Duck / duckling — rigged OGA candidates located; individual license verification required
- [ ] Goose / gosling — dedicated verified model still required
- [ ] Piglet — exact dedicated verified model still required
- [ ] Goat / kid — exact dedicated verified model still required
- [~] Rabbit domestic — candidate located; individual verification required

### Wildlife
- [x] Fox — Quaternius
- [x] Wolf — Quaternius
- [x] Deer / stag — Quaternius
- [x] Bear — CC0 White Bear model verified; animation still required
- [~] Hare / rabbit — dedicated candidate located; verify individual license
- [x] Wild boar — dedicated rigged/textured CC0 OpenGameArt model; walk + attack animations
- [ ] Moose / elk
- [ ] Squirrel
- [ ] Badger
- [ ] Raccoon

### Birds
- [x] Rooster
- [~] Chicken / hen / chicks
- [~] Duck / duckling
- [ ] Goose
- [ ] Pigeon
- [ ] Crow / raven
- [ ] Sparrow
- [ ] Eagle / hawk
- [ ] Owl
- [ ] Seagull

### Aquatic / other
- [ ] Fish families
- [~] Frog — candidate listed in OGA 3D Animals collection
- [ ] Snake
- [ ] Lizards
- [ ] Insects/pollinators

## Buildings expansion
### Quaternius — Farm Buildings Pack
Source: https://quaternius.com/packs/farmbuildings.html
License: CC0
Models: 13 farm buildings
Formats: FBX, OBJ, Blend
Target: `assets/buildings/farm/quaternius_farm_buildings/`
Status: VERIFIED for farms, animal housing and rural settlements.

### Kenney — Castle Kit
Source: https://kenney.nl/assets/castle-kit
License: CC0
Category: 3D; 75 files
Target: `assets/buildings/castle/kenney_castle_kit/`
Status: VERIFIED.

## Animation baseline
Production animals should support where appropriate: idle, walk, run, eat/graze/peck, drink, sleep/rest, alert, flee, attack/defend, hit/injury, death, young interaction, vocalization triggers, turning and transitions. Birds additionally need takeoff, flight, glide, landing and perch.

## Runtime integration rules
1. Prefer glTF/GLB when available.
2. Preserve source and license metadata.
3. Normalize scale to approximate real-world species size.
4. Add collision/navigation profile.
5. Standardize animation naming.
6. Generate LODs for distance rendering.
7. Reuse materials/atlases where practical.
8. Never mark a candidate as production-ready until its individual license is verified.
9. Every imported third-party folder requires SOURCE.md and LICENSE.txt.
10. CC0 assets may be modified/rematerialed to maintain coherent ImPuls art direction.

## Search priority next
Chicken/hen/chicks individual verification -> duck/duckling verification -> goose/pigeon -> piglet -> rabbit/hare -> goats -> birds -> fish/insects.
