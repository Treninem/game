# Ambient Life / Aquatic / Wildlife CC0 Registry — 2026-08-14

Purpose: approved discovery sources for background ecology and world ambience. Registry entry does not mean physical import.

## Approved CC0 packs
- Quaternius Animated Fish Pack — 7 animated aquatic species — CC0 — https://quaternius.com/packs/animatedfish.html — target `assets/animals/aquatic/quaternius_animated_fish/`.
- Quaternius Animated Cute Fish Pack — 52 animated fish models plus fishing rods/lures — CC0 — https://quaternius.com/packs/cutefish.html — target `assets/animals/aquatic/quaternius_cute_fish/`.
- Quaternius Ultimate Animated Animal Pack — 12 animals with 12+ animations each, glTF available — CC0 — https://quaternius.com/packs/ultimateanimatedanimals.html — target `assets/animals/quaternius_ultimate_animated/`.
- Quaternius Farm Animal Pack — 7 animated farm animals — CC0 — https://quaternius.com/packs/farmanimal.html — target `assets/animals/farm/quaternius_farm_animals/`.
- OpenGameArt Animated Birds 32x32 — small CC0 animated bird sprites, suitable for distant/impostor/fallback use — https://opengameart.org/content/animated-birds-32x32 — target `assets/animals/birds/oga_animated_birds_2d/`.

## Runtime ecology rules
1. Nearby animals use real animated models; distant flocks/schools use cheaper impostors/particles where style allows.
2. Fish schools respond to current/depth/obstacles and flee from disturbances.
3. Birds respond to time of day, weather, settlements and player disturbance instead of orbiting one fixed point.
4. Insects/fireflies/pollen are biome/time/season-driven ambience, not permanent global emitters.
5. Use spawning budgets per biome cell to avoid simulating thousands of background creatures.
6. Aquatic life should integrate with underwater fog/caustics/particles and water quality rather than being placed in empty clear volumes.

## Missing categories to continue sourcing
- 3D flying birds with flight/landing/perch animations;
- butterflies, bees, dragonflies, flies/gnats and fireflies;
- frogs/amphibians, reptiles, crabs/shellfish and small aquatic creatures;
- schooling ocean species and freshwater species separated by biome;
- nests, dens, burrows, tracks, feathers, eggs, droppings and feeding props.
