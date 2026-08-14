# ImPuls — Verified CC0 Animal Model Catalog

Purpose: canonical cross-chat catalog for animal models approved for the game. Every model imported into runtime must keep source/license metadata and be normalized for Godot.

## Verified packs

### Quaternius — Ultimate Animated Animal Pack
Source: https://quaternius.com/packs/ultimateanimatedanimals.html
License: CC0
Formats: FBX, OBJ, Blend, glTF
Models: 12; 12+ animations per animal.
Verified species visible in published bundle listings: Cow, Donkey, Deer, Alpaca, Bull, Fox, Shiba Inu, Stag, Husky, Wolf, White Horse, Horse.
Target: `assets/animals/quaternius_ultimate_animated/`
Priority use: fox, dogs, horses, deer, wolves, cattle.

### Quaternius — Farm Animal Pack
Source: https://quaternius.com/packs/farmanimal.html
License: CC0
Formats: FBX, OBJ, Blend
Models: 7 animated farm animals.
Verified bundle species: Pig, Pug/Dog, Sheep, Horse, Cow, Llama, Zebra.
Target: `assets/animals/farm/quaternius_farm_animals/`
Priority use: pig, dog, horse, sheep, cattle.

### Kenney — Cube Pets
Source: https://kenney.nl/assets/cube-pets
License: CC0
Category: 3D animated
Files: 24
Tags explicitly include pet, animal, dog, cat.
Target: `assets/animals/pets/kenney_cube_pets/`
Priority use: dogs/cats and additional domestic pets where art direction permits.

### Quaternius — Zombie Apocalypse Kit
Source: https://quaternius.com/packs/zombieapocalypsekit.html
License: CC0
Formats: FBX, OBJ, Blend, glTF
Models: 60; includes 2 dogs plus animated humans/enemies/environment/vehicles.
Target animal subset: `assets/animals/dogs/quaternius_zombie_apocalypse/`
Target human subset: `assets/characters/humans/quaternius_zombie_apocalypse/`

### Quaternius — Cube World Kit
Source: https://quaternius.com/packs/cubeworldkit.html
License: CC0
Formats: FBX, OBJ, Blend, glTF
Models: 108 including animated characters, animals, enemies and environment.
Target: `assets/animals/quaternius_cube_world/`
Use only species/assets individually inventoried after download.

### Kenney — Prototype Kit
Source: https://www.kenney.nl/assets/prototype-kit
License: CC0
Category: 3D; animated; variations
Files: 145
Tags include animal, character, vehicle, building.
Target staging: `assets/prototype/kenney_prototype_kit/`
Use for prototypes/placeholders until coherent final models are available.

## Required species matrix

### Domestic / farm
- [x] Dog — Quaternius animated packs + Kenney Cube Pets
- [x] Cat — Kenney Cube Pets
- [x] Horse — Quaternius Ultimate Animated + Farm Animal Pack
- [x] Pig — Quaternius Farm Animal Pack
- [x] Cow / bull — Quaternius animated packs
- [x] Sheep — Quaternius Farm Animal Pack
- [ ] Piglet — exact dedicated model still required
- [ ] Chicken / rooster / chick — exact dedicated models still required
- [ ] Duck / duckling — exact dedicated models still required
- [ ] Goose / gosling — exact dedicated models still required
- [ ] Goat / kid — exact dedicated models still required
- [ ] Turkey — exact dedicated model still required
- [ ] Rabbit domestic — exact dedicated model still required

### Wildlife
- [x] Fox — Quaternius Ultimate Animated Animal Pack
- [x] Wolf — Quaternius Ultimate Animated Animal Pack
- [x] Deer / stag — Quaternius Ultimate Animated Animal Pack
- [ ] Bear — exact dedicated CC0 model still required
- [ ] Hare / rabbit — exact dedicated CC0 model still required
- [ ] Wild boar — exact dedicated CC0 model still required
- [ ] Moose / elk — exact dedicated model still required
- [ ] Squirrel — exact dedicated model still required
- [ ] Badger — exact dedicated model still required
- [ ] Raccoon — exact dedicated model still required

### Birds
- [ ] Pigeon — exact dedicated CC0 model still required
- [ ] Crow / raven
- [ ] Sparrow
- [ ] Eagle / hawk
- [ ] Owl
- [ ] Seagull

### Aquatic / other
- [ ] Fish families
- [ ] Frog
- [ ] Snake
- [ ] Lizards
- [ ] Insects/pollinators

## Animation baseline
Every production animal should ultimately support, where biologically appropriate: idle variants, walk, run, eat/graze/peck, drink, sleep/rest, alert, flee, attack/defend, hit/injury, death, reproduction/young interaction, species vocalization triggers, turning and locomotion transitions. Birds additionally need takeoff, flight, glide, landing and perch. Aquatic species need swim/turn/depth transitions.

## Runtime integration rules
1. Prefer glTF/GLB when available.
2. Keep original source package out of runtime export if unnecessary.
3. Normalize scale against real-world approximate species size.
4. Add simple collision and navigation/avoidance profile.
5. Standardize skeleton/animation names where practical.
6. Generate LODs for animals visible at distance.
7. Use texture atlases/material reuse where practical.
8. Do not claim a species is covered until the actual downloaded pack inventory confirms it.
9. Every imported third-party folder requires SOURCE.md and LICENSE.txt.
10. CC0 assets may be rematerialed/recolored to maintain one coherent ImPuls art direction.

## Search priority next
Chicken/rooster/chick -> duck/goose/pigeon -> bear -> hare/rabbit -> wild boar/piglet -> goats -> broader birds -> fish/insects.
