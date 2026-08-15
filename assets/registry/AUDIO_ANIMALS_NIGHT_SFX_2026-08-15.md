# Animals / Birds / Night Ecology SFX — 2026-08-15

Asset-research staging only. Nothing in this catalog is wired into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## Status policy
- `PINNED_VENDOR` — real sound files are already available through a pinned source submodule.
- `APPROVED_SOURCE` — license/source verified, but the files have not been copied or linked into the game repository yet.
- Realistic animal recordings must stay separate from designed creature/monster vocals.

## Already available: pinned CC0 animal material
Source library: `assets/audio/source_packs/cc0_public_domain_sounds/`
Pinned upstream commit: `f2b6264f9ab89fabc266914c3654685d68c5a39b`
Root license: CC0 1.0 Universal.

### Domestic cat recordings
- Status: `PINNED_VENDOR`.
- Folder: `Micro Pack - Cat Meows/`.
- Contains a substantial family of real cat-meow WAV recordings, including feeding/food-time behavior; source library also carries alternate encoded variants.
- Production semantic targets: `CAT_MEOW_SOFT`, `CAT_MEOW_NORMAL`, `CAT_MEOW_INSISTENT`, `CAT_FEEDING`, `CAT_DISTANT`.
- Do not trigger the same clip repeatedly; use randomized variants with cooldowns.

### Creature / generic beast vocals
- Status: `PINNED_VENDOR`.
- Folders: `80-CC0-creature-SFX/`, `80-CC0-creature-sfx-2/`, `beast_or_animal/`.
- `80-CC0-creature-SFX/` includes real OGG assets such as barking/breathing plus many designed creature vocalizations.
- `beast_or_animal/` is generic beast/animal sound-design material rather than a verified wildlife field-recording library.
- Use for monsters, supernatural fauna or layered aggression only after auditioning.
- Never label a generic beast effect as a specific real species without listening verification.

## Verified CC0 sources for selective import
These sources are approved for later selective import. They are not marked `PINNED_VENDOR` until real files are physically linked/copied into the repository.

### Ambient Bird Sounds — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Author: isaiah658.
- Ambient bird/chirping field material suitable for cutting into beds and individual randomized calls.
- Production targets: `BIRD_DAY_BED`, `BIRD_NEAR_RANDOM`, `BIRD_FAR_RANDOM`, `FOREST_DAY_SCATTER`.

### Crickets Ambient Noise — loopable — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Loopable outdoor/night cricket ambience.
- Production targets: `CRICKET_NIGHT_LOOP`, `FIELD_NIGHT_INSECTS`, `FOREST_NIGHT_INSECTS`.

### Bear Growls — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Bear growls derived from U.S. Fish & Wildlife Service source material; distributed in compact lossless/lossy audio variants.
- Production targets: `BEAR_GROWL_LOW`, `BEAR_ALERT`, `BEAR_AGGRESSION`.
- Still need separate bear breathing, movement, cub and attack/body Foley for a full species family.

### Horse Trotting / Horse movement — OpenGameArt animal catalog
- Status: `APPROVED_SOURCE`.
- CC0 horse movement material is available in the animal-sound catalog.
- Production targets: `HORSE_TROT_LOOP`, `HORSE_STEP`, `HORSE_GALLOP` after individual license verification of each selected item.
- Horse whinny/snort/breathing remain separate required families.

### Farm / domestic-animal CC0 candidates — OpenGameArt animal catalog
Verified catalog contains CC0/public-domain candidates for multiple useful families, including sheep, goats, dogs, pigs/chickens and other farm/animal material.
- Production targets: `SHEEP_BAA`, `GOAT_BLEAT`, `DOG_BARK`, `DOG_GROWL`, `PIG_VOCAL`, `CHICKEN_CALL`, `FARM_BED`.
- Each selected source must be checked individually before physical import; catalog membership alone is not treated as sufficient license metadata.

### Additional wildlife candidates — OpenGameArt animal catalog
Useful candidate families surfaced for bats, crows, rabbits, donkeys, wolves and other wildlife/domestic animals.
- Production targets only after individual source verification: `BAT_SCREECH`, `CROW_CAW`, `RABBIT_EAT`, `DONKEY_BRAY`, `WOLF_*`.

## Ecology layers by world context

### Forest day
Use a quiet continuous bed plus sparse randomized calls:
- distant bird bed;
- near bird one-shots;
- leaf/branch rustle;
- occasional woodpecker/crow/other distinctive calls only where biome-appropriate;
- small-animal movement should be positional, not baked into every loop.

### Forest night
- crickets/insects as a base layer;
- sparse owl/night-bird calls once a dedicated verified family is imported;
- distant mammal calls;
- wind/leaf layers from weather state;
- avoid constant dramatic monster sounds in ordinary wilderness.

### Fields / farmland
- insects + sparse birds;
- cattle/sheep/goat/chicken/dog one-shots positioned around physical animals;
- stable/barn bed only near actual farm structures;
- horse hoof loops must be driven by physical gait/surface later, not used as ambience.

### Village / town
- cats/dogs should originate from actual nearby animals or courtyards;
- dawn can increase rooster/bird activity;
- night reduces domestic activity and increases insects/distant dogs;
- do not create a universal repeating “village animals” loop that ignores population and location.

### Swamp / wetland
Still needs dedicated verified families for frogs, mosquitoes, wetland birds and dense insects. Existing generic creature effects are not a substitute for real ecology.

### Mountains / wilderness
Still needs sparse high-altitude birds, wind-appropriate fauna, wolves and region-specific mammals. Keep call density low to preserve scale and distance.

## Species-family completeness rule
For an animal intended to exist physically in the game, one sound is not enough. Prefer families containing:
- idle/neutral;
- alert;
- social/call;
- pain/distress where appropriate;
- aggression/attack where appropriate;
- breathing/sniffing where audible;
- eating/drinking;
- movement/foot contact when the species needs distinctive locomotion;
- young/juvenile variants only when juveniles physically exist.

## Highest-priority remaining gaps
1. owl/night-bird family;
2. frogs + mosquitoes + swamp insects;
3. adult cattle/moo + calf variants;
4. horse whinny/snort/breath + walk/trot/gallop by surface;
5. chickens/rooster flock set;
6. pigs/boars separated into domestic and wild families;
7. wolf howl/growl/pant/attack family;
8. fox calls;
9. deer calls/movement;
10. bear movement/breathing/attack beyond growls;
11. ducks/geese/waterfowl;
12. rodents/bats for barns, caves and ruins.

## Runtime ownership
The main development flow owns species binding, 3D emitters, gait synchronization, distance attenuation, occlusion, reverb, randomization, cooldowns and biome/time-of-day ecology. This asset-research chat only stages and audits sources.