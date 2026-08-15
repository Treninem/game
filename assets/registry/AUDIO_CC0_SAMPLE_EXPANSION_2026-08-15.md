# CC0 Sound Source Expansion — 2026-08-15

Asset-research staging only. Nothing in this catalog is wired into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## New pinned source libraries

### sound-cc0 misc
- Status: `PINNED_VENDOR`.
- Path: `assets/audio/source_packs/sound_cc0_misc/`.
- Upstream: `code4fukui/sound-cc0`.
- Pinned commit: `0bdbbe370c42897e12b7c5b0b26d96228e0d2931`.
- The upstream README describes the sound collection as public-domain / CC0 and explicitly permits personal and commercial use without attribution.
- The repository also carries a public-domain-style license notice.
- Real WAV coverage includes bells, cracker/pop-style effects, metal/steel impacts, switches and other compact utility sounds.
- Suggested future semantic groups: `BELL_SMALL`, `BELL_PROP`, `METAL_HIT_LIGHT`, `STEEL_HIT`, `SWITCH_MECHANICAL`, `POP_SMALL`.

### Stargate CC0 Sample Pack
- Status: `PINNED_VENDOR`.
- Path: `assets/audio/source_packs/stargate_cc0_sample_pack/`.
- Upstream: `stargatedaw/stargate-sample-pack`.
- Pinned commit: `dbfd6ec52d4ed53b60bdbea5fc6adf295127c027`.
- Root license: CC0 1.0 Universal.
- This is a large real-sample source library intentionally linked as a Git submodule so its binary history does not bloat the core game repository.
- The upstream tree contains real WAV/AIFF samples organized into families such as percussion/drums and other reusable raw sound material.
- Treat it as an audition/source-design library rather than binding gameplay directly to upstream filenames.
- Useful later for layered impacts, rhythmic/mechanical accents, object hits, UI/accent stingers and original sound-design construction.

## Already pinned environment pack — do not duplicate

### AmbientSounds
- Status: `PINNED_VENDOR`.
- Path: `assets/audio/source_packs/ambient_sounds_muges/`.
- Upstream: `Muges/ambientsounds`.
- Pinned commit: `7ef9aefeeed93c37bca3cdb246a982dd1afce2f0`.
- Contains real looping OGG environment recordings.
- Per-source licensing is mixed but commercial-friendly and must be preserved per file:
  - fireplace — CC0;
  - wind — CC0;
  - heavy rain — CC BY;
  - forest rain — CC BY;
  - stream — CC BY;
  - thunderstorm — CC BY.
- Attribution metadata must remain available for CC BY selections.
- Suggested semantic groups: `FIREPLACE_LOOP`, `WIND_LOOP`, `RAIN_HEAVY_LOOP`, `FOREST_RAIN_LOOP`, `STREAM_LOOP`, `THUNDERSTORM_LOOP`.

## Verified wildlife / ecology sources not yet physically vendored
These stay `APPROVED_SOURCE` until a robust physical import path is used. Do not claim they are stored in the game repository yet.

- public-domain wolf howl material — target `WOLF_HOWL`;
- public-domain barred-owl call — target `OWL_CALL`;
- public-domain frog/wetland recordings — target `FROG_WETLAND`;
- CC0 goose call — target `GOOSE_CALL`;
- CC0 horse-gallop material — target `HORSE_GALLOP`;
- CC0 morning bird-flock ambience — target `BIRD_DAWN_BED`.

## Production rules
- Never infer a real animal species from a generic creature filename without listening verification.
- Keep designed monsters separate from realistic wildlife.
- Use multiple variants, randomized selection and cooldowns for repeated one-shots.
- Continuous environment loops should be layered by biome, weather, time of day and physical location rather than played globally.
- Horse/animal movement sounds should later follow actual gait and terrain surface.
- CC BY selections require preserved author/source/license attribution even when the surrounding game is commercial.
- Raw source libraries are not production-ready by default: audition, trim, normalize and convert only in the main development flow.

## Remaining high-priority sound families
1. ducks and geese: calls, flock takeoff, wing movement, water landing;
2. wolves: howl, growl, pant, whine, attack and body movement;
3. foxes: bark/scream/whine;
4. deer: calls, alarm, movement;
5. farm set: cows/calves, pigs/piglets, chickens/rooster, sheep/lambs, goats, dogs;
6. horse complete family: breathing, snort, neigh, tack plus walk/trot/gallop on several surfaces;
7. swamp: frogs, mosquitoes, insects, wetland birds;
8. forest night: owls, insects, distant mammals;
9. cave ecology: bats, rodents, drips and room tone;
10. settlement ambience: crowd, market, tavern, forge and workshops.

## Runtime ownership
This chat only collects, verifies and organizes source audio. Runtime event routing, 3D emitters, attenuation, occlusion, reverb, biome systems, animal AI binding and final production selection belong to the main game-development flow.
