# Horse / cart / wagon / road transport SFX — 2026-08-15

Asset-research staging only. This file does not wire audio into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## Goal
Prepare a legal source pool and semantic plan for believable horse travel, carts, wagons, carriages, tack, wooden wheels, axles, road surfaces and pass-by ambience.

## Existing pinned material to reuse first

### General CC0 source library
- Status: `PINNED_VENDOR`.
- Path: `assets/audio/source_packs/cc0_public_domain_sounds/`.
- Pin: `f2b6264f9ab89fabc266914c3654685d68c5a39b`.
- Audit result for this stage: the repository tree did not expose clearly named `horse`, `hoof`, `cart`, or `wagon` source files at the pinned revision, so generic impacts/mechanisms from this pack must not be mislabeled as authentic horse or wagon recordings.
- Still useful for supporting layers only: wood creaks, impacts, rattles, mud, gravel-like contacts, small mechanisms and material interaction after auditioning.

### Kenney RPG Audio
- Status: `PINNED_VENDOR`.
- Path: `assets/audio/third_party/kenney_rpg_audio/`.
- Pin: `22eb79bb843bbcadcaa6ed119353a33265ffad11`.
- Useful only as supporting Foley (gear/leather/cloth/creaks/doors) after auditioning; do not label these files as horse tack without listening verification.

### Heavy-world/mechanism registry
See `assets/registry/AUDIO_HEAVY_MECHANISMS_MINING_COLLAPSE_2026-08-15.md` for chain, mechanism, timber and structural layers that can support carts/wagons where physically appropriate.

## Verified external sources
The following entries are `APPROVED_SOURCE` only unless explicitly promoted later. They are not claimed to be physically stored in this repository.

### Horse Trotting — OpenGameArt
- Status: `APPROVED_SOURCE`.
- Source page: `https://opengameart.org/content/horse-trotting`.
- Author: EZduzziteh.
- License: CC0.
- File: `Trot.ogg` (~138.4 KB).
- Important authenticity note: this is a designed/foley horse-trot imitation made with household materials, not a field recording of a real horse.
- Good target after audition: `HORSE_TROT_FOLEY_NEUTRAL`.
- Do not use it as the only horse movement sound family.

### Six Horses Galloping By — Wikimedia Commons
- Status: `APPROVED_SOURCE`.
- Source page: `https://commons.wikimedia.org/wiki/File:Six_Horses_Galloping_By.ogg`.
- License: CC0 1.0.
- Description previously verified: six horses galloping toward and past the listener.
- Good targets: `HORSE_GALLOP_GROUP_APPROACH`, `HORSE_GALLOP_GROUP_PASSBY`, `HORSE_GALLOP_GROUP_DEPART` after editing/auditioning.
- Preserve the original source metadata when imported.

### Horse neigh / Wiehern — Wikimedia Commons
- Status: `APPROVED_SOURCE`.
- Source page: `https://commons.wikimedia.org/wiki/File:Wiehern.ogg`.
- Rights status: copyright holder dedicated the recording to the public domain.
- Target: `HORSE_NEIGH` / `HORSE_WHINNY` after auditioning.

### Wooden wagon on pavement — Wikimedia Commons / Work With Sounds
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:WWS_Woodenwagon.ogg`.
- Recording: Monika Widzicka / Work With Sounds project.
- License: CC BY 4.0; attribution is required.
- Length: about 16 seconds; source describes a wooden wagon moving on pavement, recorded in the National Museum of Agriculture and Agricultural-Food Industry in Szreniawa, Poland.
- The recorded educational wagon was moved by two people; it is therefore useful for wheel/body/axle mechanics but should not be presented as a complete horse-drawn-wagon recording.
- Targets: `WAGON_WOOD_PAVEMENT_LOOP`, `WAGON_WHEEL_WOOD_PAVEMENT`, `WAGON_BODY_RATTLE`, `WAGON_AXLE_CREAK` after stem/edit isolation where practical.

### Bicycle Sounds — OpenGameArt
- Status: `APPROVED_SOURCE`.
- Source page: `https://opengameart.org/content/bicycle-sounds`.
- Author: AntumDeluge.
- License: CC0.
- Includes wheel/spoke material.
- Use only for selective supporting wheel/spoke/rattle design after auditioning; do not call bicycle recordings authentic wagon wheels.

### Mechanical Sounds — OpenGameArt
- Status: `APPROVED_SOURCE`.
- Source page: `https://opengameart.org/content/mechanical-sounds`.
- Author: BMacZero.
- License: CC0.
- Files include clanks, light clunks, rattle, squeaky clicks and mechanical movement.
- Useful targets: axle hardware, latch, brake, suspension/connection and cart-body rattle layers after auditioning.

### Fantasy Sound Effects (Tinysized SFX) — OpenGameArt
- Status: `APPROVED_SOURCE`.
- Source page: `https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx`.
- License: CC0.
- 96 organic/unprocessed sounds (apart from normalization), including pouch, coins, creaks, leather sheath, metal contacts, boots, water/pouring and related Foley.
- Useful as a legal source pool for tack-adjacent leather, pouch, strap and travel-prop layers, but individual files must be auditioned before semantic assignment.

## License correction: Horse Gallop Loop
- Source page: `https://opengameart.org/content/horse-gallop-loop`.
- Author/uploader: AntumDeluge; underlying recording credit: Alan McKinney.
- Correct license: **CC BY 3.0**, not CC0.
- Attribution to Alan McKinney is required if used.
- Status for this project: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED` only.
- Do not copy this entry into a CC0-only manifest.

## Horse movement semantic families

### Walk
- `HOOF_WALK_DIRT`
- `HOOF_WALK_GRASS`
- `HOOF_WALK_MUD`
- `HOOF_WALK_GRAVEL`
- `HOOF_WALK_COBBLE`
- `HOOF_WALK_STONE`
- `HOOF_WALK_WOOD`
- `HOOF_WALK_SNOW`
- `HOOF_WALK_ICE`

### Trot
- `HOOF_TROT_DIRT`
- `HOOF_TROT_GRASS`
- `HOOF_TROT_MUD`
- `HOOF_TROT_GRAVEL`
- `HOOF_TROT_COBBLE`
- `HOOF_TROT_STONE`
- `HOOF_TROT_WOOD`
- `HOOF_TROT_SNOW`

### Canter / gallop
- `HOOF_CANTER_DIRT`
- `HOOF_CANTER_GRASS`
- `HOOF_CANTER_COBBLE`
- `HOOF_GALLOP_DIRT`
- `HOOF_GALLOP_GRASS`
- `HOOF_GALLOP_MUD`
- `HOOF_GALLOP_GRAVEL`
- `HOOF_GALLOP_COBBLE`
- `HOOF_GALLOP_STONE`
- `HOOF_GALLOP_WOOD`
- `HOOF_GALLOP_SNOW`

Do not produce surface variants by changing EQ alone. The contact/transient and debris response need to match the real ground material.

## Horse body / vocal families
- `HORSE_NEIGH_SOFT`
- `HORSE_NEIGH_LOUD`
- `HORSE_WHINNY`
- `HORSE_SNORT`
- `HORSE_BREATH_IDLE`
- `HORSE_BREATH_EXERTION`
- `HORSE_SHAKE`
- `HORSE_STAMP`
- `HORSE_SCRAPE_GROUND`
- `HORSE_EAT`
- `HORSE_DRINK`
- `HORSE_STARTLED`

Vocals should be event-based and sparse; a horse must not endlessly loop neighing.

## Tack / saddle / harness families
- `TACK_LEATHER_CREAK_LIGHT`
- `TACK_LEATHER_CREAK_HEAVY`
- `SADDLE_SHIFT`
- `SADDLE_MOUNT_WEIGHT`
- `SADDLE_DISMOUNT_WEIGHT`
- `REINS_MOVE`
- `HARNESS_TENSION`
- `HARNESS_RELEASE`
- `BIT_JINGLE`
- `BUCKLE_JINGLE`
- `STIRRUP_METAL_LIGHT`
- `STIRRUP_IMPACT`
- `SADDLE_BAG_MOVE`
- `CARGO_STRAP_CREAK`

Tack layers should respond to gait and rider/cargo movement rather than play as one constant loop.

## Cart / wagon / carriage families

### Wheel / axle
- `CART_WHEEL_WOOD_DIRT`
- `CART_WHEEL_WOOD_COBBLE`
- `CART_WHEEL_WOOD_MUD`
- `CART_WHEEL_WOOD_WOODBRIDGE`
- `WAGON_WHEEL_HEAVY_DIRT`
- `WAGON_WHEEL_HEAVY_COBBLE`
- `WAGON_WHEEL_HEAVY_MUD`
- `WAGON_WHEEL_HEAVY_WOODBRIDGE`
- `AXLE_CREAK_LIGHT`
- `AXLE_CREAK_HEAVY`
- `HUB_RATTLE`
- `WHEEL_RIM_RATTLE`

### Chassis / load
- `CART_BODY_RATTLE_LIGHT`
- `WAGON_BODY_RATTLE_HEAVY`
- `CARRIAGE_BODY_CREAK`
- `CARGO_CRATE_RATTLE`
- `CARGO_BARREL_RATTLE`
- `CARGO_SACK_SHIFT`
- `CARGO_METAL_JINGLE`
- `BENCH_CREAK`

### Movement events
- `CART_START`
- `CART_STOP`
- `WAGON_START_HEAVY`
- `WAGON_STOP_HEAVY`
- `CARRIAGE_TURN`
- `WHEEL_BUMP_SMALL`
- `WHEEL_BUMP_LARGE`
- `WHEEL_RUT_DROP`
- `CART_BRAKE`
- `WAGON_BRAKE_HEAVY`
- `WHEEL_DAMAGE`
- `AXLE_DAMAGE`
- `WHEEL_BREAK`

## Vehicle classes must sound different
- Hand cart: light wheel/contact noise, sparse wood creak, no horse tack.
- Small farm cart: light wheel character, moderate body rattle, light cargo.
- Heavy wagon: lower/heavier wheel impact, stronger axle/body creaks, cargo-dependent rattles.
- Passenger carriage: tighter mechanism, interior body resonance, seat/door suspension layers.
- Supply wagon: heavier load, metal hardware and cargo-dependent rattle as appropriate.

Do not reuse one universal `wagon_loop` for every vehicle class.

## Runtime behavior requirements for main development
- Hoof cadence must be driven by the horse gait/animation and actual movement speed.
- Hoof surface set must switch from the physical contact material under each hoof, including wooden bridges and cobbles.
- Stationary horses and parked wagons must not play movement loops.
- Wagon wheel speed, bump frequency and body rattle intensity should derive from vehicle speed and terrain roughness.
- Axle/body creaks should respond to suspension/body movement and load, not run continuously at identical volume.
- Horse tack should become more active at trot/gallop and when turning, mounting, stopping or changing load.
- Approaching/pass-by/departing groups should use spatialized event recordings/layers rather than simple stereo volume automation when dedicated recordings exist.
- Indoor/stable acoustics and outdoor road acoustics require different reverb/occlusion treatment.
- Emitters belong to actual horse hooves, horse body, wheel/axle and cargo positions.

## Priority gaps after this audit
1. authentic single-horse hoof walk/trot/gallop recordings on dirt and grass;
2. authentic hoof families on cobble/stone and wooden bridge;
3. authentic horse snort/breath/exertion family;
4. real saddle/reins/bit/stirrup/harness recordings;
5. wooden cart/wagon on dirt and gravel;
6. heavy wagon on cobble and mud;
7. axle/hub/wheel squeaks with clean isolated recordings;
8. loaded crate/barrel/sack wagon layers;
9. carriage interior/bench/suspension Foley;
10. horse group approach/pass-by/depart variations.

## Integration ownership
Main development owns auditioning, editing, normalization, compression, 3D emitters, gait synchronization, surface detection, vehicle physics routing, occlusion/reverb, variation/randomization and final runtime use. This asset-research chat only stages and audits source material.
