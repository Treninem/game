# Caves / Mines / Workshops / Settlement SFX Audit — 2026-08-15

Asset-research staging only. Nothing in this catalog is wired into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## Already pinned and physically available

### Forge / workshop / metal props
Source: `assets/audio/source_packs/cc0_public_domain_sounds/` pinned at `f2b6264f9ab89fabc266914c3654685d68c5a39b` (root CC0).

Audited real files:
- `100-CC0-wood-metal-SFX/hammer_01.ogg` and multiple hammer variants;
- key/metal/wood/door families in the same pack;
- `bb - Toolbox Rummaging (Sept 2021)/` with real WAV recordings such as metal brushes, thumps, clicks and drawer open/close interactions;
- `bb - Smol Mechanisms (May 2021)/` for cable coilers, buttons and small physical mechanisms;
- `metal_interactions/` for additional metal handling layers.

Suggested semantic families for later production selection:
`FORGE_HAMMER_LIGHT`, `FORGE_HAMMER_HEAVY`, `METAL_TOOL_HANDLE`, `METAL_SCRAPE`, `TOOLBOX_RUMMAGE`, `DRAWER_OPEN`, `DRAWER_CLOSE`, `MECH_CLICK`, `MECH_SMALL_LOOP`, `KEYS_JINGLE`.

### Structural break / fall / impact
Source: `75-cc0-breaking-falling-hit-sfx/` in the same pinned CC0 library.

Confirmed real OGG families include many `breaking`, `falling` and `hit` variants. These are useful source layers for:
- timber break;
- crate/furniture damage;
- loose debris;
- falling objects;
- secondary impacts after a collapse.

Do not use one generic break sound for every material. A building collapse should later combine material-specific primary failure, debris, dust/rumble and secondary object impacts.

Suggested semantic families:
`BREAK_GENERIC_SMALL`, `BREAK_GENERIC_MEDIUM`, `DEBRIS_FALL_SMALL`, `DEBRIS_FALL_MEDIUM`, `IMPACT_DEBRIS`, `COLLAPSE_LAYER_GENERIC`.

### Machine / ambient loops
Source: `30-cc0-sfx-loops/` in the pinned CC0 library.

Confirmed real OGG files include ambient loops and multiple machine loops. These are source material for workshop mechanisms, pumps, mills or background machinery only after auditioning; filenames alone do not establish a specific real machine identity.

Suggested later semantic groups:
`WORKSHOP_MACHINE_LOOP`, `PUMP_LOOP`, `MILL_MECHANISM_LOOP`, `INDUSTRIAL_ROOM_TONE`.

### Weather / fire / water bed already pinned
Source: `assets/audio/source_packs/ambient_sounds_muges/` pinned at `7ef9aefeeed93c37bca3cdb246a982dd1afce2f0`.

This source contains real ambient OGG material for fireplace, wind, heavy rain, forest rain, stream and thunderstorm. License metadata must remain per-file because this pack contains a mix of CC0 and CC BY sources.

Useful contexts:
`HEARTH_FIRE`, `FORGE_FIRE_LAYER` after auditioning, `WIND_OUTSIDE`, `RAIN_ROOF_LAYER`, `STREAM_NEARBY`, `STORM_DISTANT`.

### Compact CC0 utility pack
Source: `assets/audio/source_packs/sound_cc0_misc/` pinned at `0bdbbe370c42897e12b7c5b0b26d96228e0d2931`.

Real WAV utility material includes bells, metal, steel and switches. Good for bells, workshop props, small mechanisms and layered metallic impacts.

## Newly verified CC0 sources for selective import

These are `APPROVED_SOURCE`, not `PINNED_VENDOR`: the pages and licenses are verified, but the audio files are not yet copied into core history.

### Loopable Dungeon Ambience — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Author: JaggedStone.
- File: `dungeon_ambient_1.ogg` (~1.6 MB).
- Character: seamless dungeon/cave ambience with low-frequency wind and water drips.
- Production targets: `CAVE_WET_BED`, `DUNGEON_WET_BED`, `UNDERGROUND_WIND_LOW`.

### Dark Cavern Ambient — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Author: Paul Wortmann.
- Two OGG versions, including a continuous loop.
- Useful as a darker designed cavern layer, not as the universal sound of every natural cave.
- Production targets: `CAVERN_DARK_DESIGNED`, `RUINS_UNDERGROUND_DARK`.

### Dripping water loop — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Source credited on OpenGameArt to Independent.nu / qubodup submission.
- Real drip loop suitable for cellar, cave, mine or wet basement layering.
- Production targets: `CAVE_DRIP_LOOP`, `CELLAR_DRIP`, `MINE_WATER_DRIP`.

### Blacksmith's Hammer — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Author: VishwaJai.
- Real hammer-on-anvil recording with WAV and MP3 variants.
- Production targets: `ANVIL_HIT_REAL`, `BLACKSMITH_HAMMER_REAL`.

### Fast Hammer SFX — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Compact OGG derived from workshop hammering material.
- Useful for rapid crafting/repair rhythms only where a physical worker is actually hammering.
- Production target: `CRAFT_HAMMER_FAST`.

### Crowd Shouting/Speaking Ambience — OpenGameArt
- Status: `APPROVED_SOURCE`.
- License: CC0.
- Author: StarNinjas.
- Mixed crowd speaking/shouting ambience.
- Useful for market unrest, demonstrations, military gatherings and distant crowd reactions; it is not a neutral tavern conversation bed by itself.
- Production targets: `CROWD_SHOUTING`, `MARKET_UNREST`, `ARMY_CROWD`.

### The Shop — OpenGameArt / LEGIT Audio free samples
- Status: `APPROVED_SOURCE`.
- License: CC0 for the free files distributed through the OpenGameArt entry.
- Contains room-tone / shop / appliance / drone sample material in WAV and MP3 archives.
- Production targets after auditioning: `SHOP_INTERIOR_BED`, `WORKSHOP_ROOM_TONE`, `INTERIOR_MECHANICAL_BED`.
- Do not assume the license of paid LEGIT Audio products is the same; this approval applies only to the free OpenGameArt files described as CC0 on that page.

## Context design rules

### Natural cave
Base should normally be sparse:
- near-silence / air tone;
- occasional water drip if geology is wet;
- localized stream only when water physically exists;
- falling grit/stone rarely;
- bats/animals only where actual fauna exists.

Avoid a constant horror drone in every cave.

### Mine
Layer by actual activity:
- pickaxe/hammer impacts only where workers are working;
- carts, chains, wood supports, ropes and mechanisms positioned at their real sources;
- water pumps or drainage only if the mine has them;
- deeper galleries need longer reverberant tails than entrances.

### Forge / smithy
Separate emitters later for:
- hearth/fire;
- bellows;
- anvil hammer;
- metal handling;
- quench water/steam;
- grinding/filing;
- tools placed/dropped;
- door/workshop room tone.

A single looping `blacksmith ambience` should not replace actual physical actions.

### Market
Use layers rather than one repeated crowd file:
- quiet population murmur;
- individual vendors positioned at stalls;
- carts/animals/footsteps;
- coin/bag/crate interactions;
- occasional raised voices;
- unrest/shouting only when the simulation state justifies it.

### Tavern / inn
Still needs a dedicated neutral interior family:
- low conversation murmur;
- chairs/benches;
- ceramic/glass/wood cups;
- pouring;
- fireplace where present;
- doors;
- footsteps on actual floor material;
- kitchen layer if the kitchen is nearby;
- laughter/shouts as sparse events rather than an endless loop.

### Gates / chains / winches
Current small-mechanism and metal packs are useful building blocks, but a dedicated realistic family is still needed for:
- heavy chain movement;
- chain tension/release;
- wooden/iron portcullis;
- gate hinges;
- winches/capstans;
- rope pulley;
- drawbridge movement.

### Structural destruction
Later production events should be layered by structure:
- timber house: wood crack -> beam failure -> roof/furniture debris -> dust/secondary impacts;
- stone wall: stone fracture -> masonry chunks -> low rumble -> smaller debris;
- mixed building: simultaneous but material-weighted layers;
- distant collapse: attenuated low-frequency event, not the same close-up sample played quieter.

## Highest-priority gaps after this audit
1. dedicated pickaxe-on-rock / mining strike family;
2. heavy chains, gates, winches, pulleys and drawbridge mechanisms;
3. bellows, forge fire roar, metal quench and grinding/file families;
4. neutral tavern/crowd conversation bed without intelligible repeated dialogue;
5. market stall, crate, sack, coin and merchant-prop Foley;
6. large timber collapse families;
7. masonry/stone structural collapse families;
8. mine-cart wheels/rails and wooden support creaks;
9. cave bats/rodents and underground fauna;
10. large mill/waterwheel/windmill mechanism families.

## Integration ownership
Main development owns actual playback, 3D positioning, occlusion, room reverb, surface/material routing, synchronization with animations and random variation. This research chat only audits and stages legal source material; no runtime integration is performed here.
