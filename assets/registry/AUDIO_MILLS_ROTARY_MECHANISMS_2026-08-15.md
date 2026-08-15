# Mills / rotary mechanisms / pumps / wooden machinery SFX — 2026-08-15

Asset-research staging only. Nothing in this catalog is wired into gameplay, scenes, `project.godot`, autoloads, animation graphs, physics, or runtime scripts.

## Goal
Prepare legally usable and physically believable audio coverage for watermills, water wheels, windmills, millstones, grain handling, old pumps, wooden gear trains, shafts, bearings, cranks, capstans, ropes, pulleys, sluices and other large pre-industrial wooden machinery.

## Existing pinned physical material to reuse first

### General CC0 source library
- Status: `PINNED_VENDOR`.
- Path: `assets/audio/source_packs/cc0_public_domain_sounds/`.
- Pinned revision: `f2b6264f9ab89fabc266914c3654685d68c5a39b`.
- Root license: CC0/public-domain source pack as already audited elsewhere in this repository.

Relevant physically available subsets:
- `30-cc0-sfx-loops/`: creator-described machine loops, **two water-pump loops**, rolling, hand-saw and flowing-water material;
- `40-cc0-water-splash-slime-sfx/`: water loops/splashes for supporting wet layers only;
- `100-CC0-wood-metal-SFX/`: wood/metal contacts, hammer and mechanism-support material;
- `75-cc0-breaking-falling-hit-sfx/`: structural stress/failure support layers;
- `bb - Smol Mechanisms (May 2021)/`: small mechanism Foley;
- `bb - Toolbox Rummaging (Sept 2021)/`: drawers, metal brushes, clicks and handling Foley;
- `metal_interactions/`: additional metal contact material.

Important authenticity rule: generic machine loops, wood creaks and water loops are supporting layers. They must not be renamed as an authentic waterwheel, millstone or windmill recording unless auditioning proves the specific identity.

### Muges ambience
- Status: `PINNED_VENDOR_MIXED_FREE_LICENSES`.
- Path: `assets/audio/source_packs/ambient_sounds_muges/`.
- `stream.ogg` is useful for surrounding creek/river ambience but requires its existing CC BY attribution.
- Do not use a stream bed by itself as the sound of a turning waterwheel.

### Existing heavy-mechanism registry
See `assets/registry/AUDIO_HEAVY_MECHANISMS_MINING_COLLAPSE_2026-08-15.md` for chain, winch, timber strain and heavy mechanism material already audited. Do not duplicate those sources here.

## Verified external sources
Entries below are `APPROVED_SOURCE` or `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`. They are **not claimed to be physically vendored** unless a later asset step imports the actual files with source/license metadata.

### WWS Waterwheel — Wikimedia Commons / Work With Sounds
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:WWS_Waterwheel.ogg`.
- Recording: Torsten Nilsson / Work With Sounds.
- License: CC BY 4.0.
- File: Ogg Vorbis, about 1 min 36 s.
- Identity: real recording of an overshot water wheel starting and running at Rasmus Kvarn near Gränna, Sweden.
- Strong targets after audition/editing:
  - `WATERWHEEL_START_REAL`
  - `WATERWHEEL_RUN_REAL`
  - `WATERWHEEL_PADDLE_WATER_REAL`
  - `WATERWHEEL_AXLE_BUILDING_REAL`
- Preserve attribution and indicate edits if trimmed/looped/processed.

### WWS Floating mill water wheel — Wikimedia Commons / Work With Sounds
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:WWS_FloatingmillwaterwheelIslandofLove.ogg`.
- Recording: Work With Sounds / Technical Museum of Slovenia; sound recordist Dušan Oblak.
- License: CC BY 4.0.
- File: Ogg Vorbis, about 1 min 5 s.
- Identity: real water wheel of an operational floating mill on the Mura River near Ižakovci, Slovenia.
- Useful as a second authentic waterwheel character so every mill does not share one recording.
- Targets:
  - `WATERWHEEL_FLOATING_RUN_REAL`
  - `WATERWHEEL_RIVER_DRIVE_REAL`
  - `FLOATING_MILL_MECHANICAL_BED_REAL`

### Wasser Marsch — Wikimedia Commons
- Status: `APPROVED_SOURCE`.
- Source page: `https://commons.wikimedia.org/wiki/File:Wasser_Marsch.ogg`.
- Author: Hastdutoene.
- Rights: author released the recording to the public domain.
- File: about 1 min 9 s.
- Identity: water flow on a mill wheel at Schäferkämper water mill.
- Targets:
  - `MILL_WATER_FEED_REAL`
  - `WATERWHEEL_FLOW_REAL`
  - `FLUME_TO_WHEEL_REAL`
- This is useful specifically for water-on-wheel flow; keep axle/gearing on separate emitters/layers when possible.

### WWS Wooden bevel gear — stereo — Wikimedia Commons / Work With Sounds
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:WWS_Woddenbevelgear.ogg`.
- Recording: Torsten Nilsson / Work With Sounds.
- License: CC BY 4.0.
- File: Ogg Vorbis, about 1 min 39 s.
- Identity: real wooden bevel gear in Rasmus Kvarn; the gear transfers horizontal power from the waterwheel to vertical power for the millstones.
- Stereo recording includes more of the whole building than the close/mono recording.
- Targets:
  - `WOOD_BEVEL_GEAR_BUILDING_REAL`
  - `MILL_DRIVETRAIN_ROOM_REAL`
  - `WOOD_GEAR_ROTATE_HEAVY_REAL`

### WWS Wooden bevel gear — close mono — Wikimedia Commons / Work With Sounds
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:WWS_Woddenbevelgearmonorecording.ogg`.
- Recording: Work With Sounds / Torsten Nilsson.
- Work With Sounds licensing family: CC BY 4.0; verify and preserve source-page attribution at import time.
- File: Ogg Vorbis, about 1 min 39 s.
- Identity: closer mono recording near the millstones of the same wooden bevel gear system.
- Prefer this candidate for localized drivetrain emitters where the broader building recording would be too diffuse.
- Targets:
  - `WOOD_BEVEL_GEAR_CLOSE_REAL`
  - `GEAR_TOOTH_CLACK_REAL`
  - `WOOD_DRIVE_SHAFT_NEAR_REAL`

### WWS Floating mill grinding stones — Wikimedia Commons / Work With Sounds
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:WWS_FloatingmillgrindingstonesIslandofLove.ogg`.
- Recording: Work With Sounds / Technical Museum of Slovenia; sound recordist Boštjan Troha.
- License: CC BY 4.0.
- File: Ogg Vorbis, about 1 min 8 s.
- Identity: real operational floating mill with grinding stones driven by waterwheel/transmission shaft.
- Targets:
  - `MILLSTONE_GRIND_REAL`
  - `FLOATING_MILLSTONE_ROOM_REAL`
  - `MILLSTONE_DRIVETRAIN_COMBINED_REAL`
- Do not assume this source contains clean isolated grain impacts; audition before splitting into `WITH_GRAIN` / `EMPTY` states.

### Weald and Downland working water mill — Wikimedia Commons
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:Weald_and_Dowland_water_mill.ogg`.
- Author: Simon James.
- License: CC BY 2.0.
- File: binaural recording, about 1 min 14 s.
- Identity: working 17th-century water mill; description specifically notes cogs, building creaks and flour-grinding mechanism.
- Useful as a complete mill-interior reference/bed rather than a clean isolated component library.
- Targets:
  - `WATERMILL_INTERIOR_REAL`
  - `MILL_BUILDING_CREAK_REAL`
  - `MILL_COGS_AND_GRIND_REAL`

### WWS Powering mill — Wikimedia Commons / Work With Sounds
- Status: `APPROVED_SOURCE_ATTRIBUTION_REQUIRED`.
- Source page: `https://commons.wikimedia.org/wiki/File:WWS_Poweringmill.ogg`.
- Recording: Monika Widzicka / Work With Sounds.
- License: CC BY 4.0.
- File: Ogg Vorbis, about 34 s.
- Identity: real toothed-gear agricultural powering mill from ca. 1930; designed for draft-animal power, moved by two people for the recording.
- Important limitation: do not label this as ox/horse ambience; use it for the physical toothed gearing/transmission character only.
- Targets:
  - `TOOTHED_GEAR_DRIVE_REAL`
  - `ROTARY_POWER_TRANSMISSION_REAL`
  - `AGRICULTURAL_GEAR_MECHANISM_REAL`

### Chain winch sounds — OpenGameArt
- Status: already cataloged as `APPROVED_SOURCE` in the heavy-mechanism registry; referenced here to prevent duplication.
- Source page: `https://opengameart.org/content/chain-winch-sounds`.
- Author: bart.
- License: CC0.
- Archive: `winch.zip` (~1.5 MB).
- Authenticity note from author: synthesized/designed to imitate a real chain winch rather than a field recording.
- Suitable only as designed background/support for capstan/winch systems after auditioning.

### 30 CC0 SFX loops — OpenGameArt / already pinned physically
- Status: `PINNED_VENDOR` through the large CC0 source repository.
- Source page: `https://opengameart.org/content/30-cc0-sfx-loops`.
- Author: rubberduck.
- License: CC0.
- Creator lists 11 machine loops, **2 water-pump loops**, a rolling loop, hand saw, flowing water and other loops.
- For this project, the two creator-described water-pump loops can serve as real source assets for generic pump states after auditioning; do not invent an exact historical pump model from them.

### Scrapes — OpenGameArt
- Status: `APPROVED_SOURCE`.
- Source page: `https://opengameart.org/content/scrapes`.
- Author: AntumDeluge.
- License: CC0.
- Recorded by dragging an object over cinder block; supplied as OGG/WAV archive.
- Supporting targets only:
  - `STONE_GRIND_SUPPORT`
  - `WOOD_STONE_FRICTION_SUPPORT`
  - `GEAR_BIND_FRICTION_SUPPORT`
- Must not be labeled an authentic millstone recording.

## Semantic families

### Millstones / grinding
- `MILLSTONE_START`
- `MILLSTONE_STOP`
- `MILLSTONE_IDLE_ROTATE`
- `MILLSTONE_GRIND_EMPTY`
- `MILLSTONE_GRIND_WITH_GRAIN`
- `MILLSTONE_GRIND_HEAVY_LOAD`
- `MILLSTONE_BIND`
- `MILLSTONE_RELEASE`
- `MILLSTONE_STONE_CONTACT_BAD`
- `MILLSTONE_ROOM_BED`

### Grain handling
- `MILL_HOPPER_GRAIN_LOW`
- `MILL_HOPPER_GRAIN_HIGH`
- `GRAIN_POUR_SMALL`
- `GRAIN_POUR_LARGE`
- `GRAIN_TRICKLE`
- `FLOUR_SACK_SET_DOWN`
- `FLOUR_SACK_DRAG`
- `GRAIN_SACK_MOVE`
- `WOOD_BIN_OPEN`
- `WOOD_BIN_CLOSE`

### Wooden gear train / shafts
- `WOOD_GEAR_ROTATE_LIGHT`
- `WOOD_GEAR_ROTATE_HEAVY`
- `WOOD_BEVEL_GEAR_ROTATE`
- `GEAR_TOOTH_CLACK_LIGHT`
- `GEAR_TOOTH_CLACK_HEAVY`
- `GEAR_TOOTH_SKIP`
- `GEAR_BIND`
- `GEAR_RELEASE`
- `WOOD_SHAFT_ROTATE`
- `WOOD_SHAFT_STRAIN`
- `WOOD_BEARING_CREAK_LIGHT`
- `WOOD_BEARING_CREAK_HEAVY`
- `DRIVETRAIN_START`
- `DRIVETRAIN_STOP`

### Waterwheel / watermill exterior
- `WATERWHEEL_START`
- `WATERWHEEL_STOP`
- `WATERWHEEL_ROTATE_SLOW`
- `WATERWHEEL_ROTATE_MEDIUM`
- `WATERWHEEL_ROTATE_FAST`
- `WATERWHEEL_PADDLE_WATER`
- `WATERWHEEL_BUCKET_FILL`
- `WATERWHEEL_BUCKET_DUMP`
- `WATERWHEEL_AXLE_CREAK`
- `WATER_TROUGH_FLOW`
- `FLUME_WATER`
- `TAILRACE_WATER`
- `MILL_RIVER_BED`

### Sluice / water control
- `SLUICE_GATE_UNLOCK`
- `SLUICE_GATE_OPEN`
- `SLUICE_GATE_MOVE`
- `SLUICE_GATE_CLOSE`
- `SLUICE_WATER_START`
- `SLUICE_WATER_REDUCE`
- `SLUICE_WATER_STOP`
- `WOOD_GATE_STRAIN_WET`

### Windmill
- `WINDMILL_SAIL_WIND_LIGHT`
- `WINDMILL_SAIL_WIND_MEDIUM`
- `WINDMILL_SAIL_WIND_HEAVY`
- `WINDMILL_SAIL_FLAP`
- `WINDMILL_FRAME_CREAK_LIGHT`
- `WINDMILL_FRAME_CREAK_HEAVY`
- `WINDMILL_MAIN_SHAFT_ROTATE`
- `WINDMILL_BRAKE_ENGAGE`
- `WINDMILL_BRAKE_RELEASE`
- `WINDMILL_GEAR_LOOP`
- `WINDMILL_INTERIOR_BED`
- `WINDMILL_START`
- `WINDMILL_STOP`

Authenticity note: this audit did **not** find a clean, standalone, verified historical windmill SFX recording with licensing/source quality strong enough to treat as a finished audio family. Wind and generic wooden machinery may support a windmill, but the dedicated authentic windmill gap remains open.

### Pumps
- `HAND_PUMP_STROKE_UP`
- `HAND_PUMP_STROKE_DOWN`
- `HAND_PUMP_SUCTION`
- `HAND_PUMP_PRIME`
- `HAND_PUMP_WATER_OUTPUT`
- `PISTON_PUMP_LOOP_SLOW`
- `PISTON_PUMP_LOOP_FAST`
- `PUMP_VALVE_CLICK`
- `PUMP_DRY_STROKE`
- `PUMP_LOSE_PRIME`

The existing CC0 water-pump loops can cover generic continuous pump material after listening, but a historically specific hand-pump family remains a separate acquisition target.

### Rope / pulley / crank / capstan
- `ROPE_TENSION`
- `ROPE_RELEASE`
- `ROPE_CREAK_LIGHT`
- `ROPE_CREAK_HEAVY`
- `ROPE_PULLEY_SLOW`
- `ROPE_PULLEY_FAST`
- `WOOD_PULLEY_CREAK`
- `CAPSTAN_ROTATE`
- `CAPSTAN_STRAIN`
- `HAND_CRANK_ROTATE`
- `HAND_CRANK_STOP`
- `RATCHET_CLICK`
- `RATCHET_RELEASE`

Use the heavy-mechanism registry for existing chain/winch coverage; rope-specific material should not be substituted with metallic chain sounds.

## Physical behavior requirements for main development
These are integration notes only; this asset chat does not implement them.

- A stopped machine must not emit a rotating loop.
- Rotation cadence/pitch selection must follow actual shaft/wheel angular speed rather than a generic movement state.
- Waterwheel sound is layered: water feed/river + paddle/bucket interaction + wheel/axle + drivetrain + building resonance.
- Closing the sluice should reduce incoming water and then physically slow the wheel/drivetrain instead of instantly muting the entire mill.
- Millstones need load states. Grain feed changes grinding texture/intensity; an empty spinning millstone must not sound identical to a loaded one.
- Wooden gear clack density follows tooth passage and RPM; do not play random clacks unrelated to motion.
- Strain/creak intensity should react to load, damage, misalignment and speed.
- Windmill audio must separate wind on sails, fabric/sail movement, frame creaks, main shaft and interior drivetrain.
- Windmill speed must derive from actual usable wind and brake/load state, not merely global weather ambience.
- Pumps should be stroke-based when mechanically reciprocating. Suction, valve, handle/piston and water output should be separable where possible.
- Emitters belong at the physical source: wheel axle, gear pair, millstone, hopper, pump cylinder, sluice, pulley or sail assembly.
- Exterior river/wind ambience and interior wooden-building acoustics require separate reverb/occlusion handling.
- Avoid perfectly identical loops. Use multiple source segments, phase-safe edits and sparse one-shots where appropriate.
- Damage should create new local sounds (tooth skip, bearing strain, shaft rub, loose frame) rather than only lowering machine efficiency numerically.

## Machine state examples

### Healthy watermill
1. river/flume bed;
2. paddle/bucket water contact;
3. wheel/axle rotation;
4. wooden bevel/cog drivetrain;
5. millstone/grain load if engaged;
6. subtle building resonance/creak.

### Watermill with sluice closed
1. residual water/tailrace;
2. wheel slows physically;
3. drivetrain cadence decreases;
4. millstone coasts down if connected;
5. stationary structure returns to environmental ambience only.

### Windmill under gusts
1. external wind bed;
2. sail loading/flap responds to gusts;
3. rotational drivetrain follows actual RPM;
4. frame strain rises under gust load;
5. brake/stop states alter mechanism logically.

### Hand pump
1. handle/mechanical stroke;
2. piston/seal friction;
3. valve/suction event;
4. priming state if dry;
5. water output only once primed and supplied.

## Priority gaps after this audit
1. clean authentic historic windmill exterior and interior recordings;
2. windmill sail/fabric movement isolated from voice/tourist ambience;
3. historic hand-pump stroke/suction/output recordings;
4. isolated rope-over-wooden-pulley recordings under different loads;
5. dedicated sluice gate open/close plus water transition recordings;
6. isolated grain hopper/pour and flour/grain sack Foley;
7. clean millstone empty-vs-loaded comparison recordings;
8. waterwheel axle/bearing isolated from water bed;
9. separate wooden gear tooth/clack recordings at several RPM/load states;
10. damaged/misaligned wooden drivetrain recordings for believable failure states.

## Licensing / attribution handling
- CC0/public-domain assets may enter the CC0 pool after source identity and actual downloaded file are verified.
- CC BY assets must keep author, source page, license version and modification notice where required.
- Work With Sounds/Wikimedia recordings listed here are not CC0; keep them in an attribution-required pool.
- Do not copy a source into a `CC0-only` manifest just because Wikimedia Commons hosts it.
- Preserve original filename/source metadata for later traceability.

## Integration ownership
Main development owns auditioning, trimming, seamless-loop construction, loudness normalization, compression, runtime import settings, spatial emitters, RPM/load synchronization, material/state routing, occlusion/reverb, damage logic, variation/randomization and final playback. This asset-research chat only stages source/legal/semantic information.