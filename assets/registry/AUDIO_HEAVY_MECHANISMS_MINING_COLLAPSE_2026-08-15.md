# Heavy mechanisms / mining / forge / settlement / collapse SFX — 2026-08-15

Asset-research staging only. Nothing in this catalog is wired into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## New pinned CC0 source

### Medieval weapons contact sample library
- Status: `PINNED_VENDOR`.
- Path: `assets/audio/source_packs/cc0_medieval_weapons/`.
- Upstream: `PanderMusubi/sound-effects-library-weapons`.
- Pinned commit: `e58b20e350765ebc3e0c54e80cf6b285fb28e470`.
- License: CC0 1.0 / public domain according to upstream README and LICENSE.
- Important scope note: this Git repository is a compact packaged/sample subset, not the complete larger Still North Media library described in the README.
- Physically present medieval sample at this pin: `samples/axe-norse-sword-blade-on-blade.ogg` plus MP3 mirror. The repository also contains one firearm sample family, which is not a priority for the current fantasy/open-world production stage.
- Safe semantic target after auditioning: `WEAPON_BLADE_CONTACT_HEAVY`.
- Do not claim the full draw/sheath/bow/arrow library is physically vendored from this Git repository merely because the README describes that larger source collection.

## Already pinned physical source coverage

### General CC0 world library
Source: `assets/audio/source_packs/cc0_public_domain_sounds/` at `f2b6264f9ab89fabc266914c3654685d68c5a39b`.

Useful existing families already physically reachable through the pinned submodule:
- `100-cc0-sfx-2/`: doors, footsteps/material interaction, glass, impacts, metal, stone, thunder, wood, switches and ambient/machine/construction/street/water loops;
- `100-CC0-wood-metal-SFX/`: hammers, keys, wood/metal interactions and door material;
- `75-cc0-breaking-falling-hit-sfx/`: many breaking/falling/hit OGG variants;
- `30-cc0-sfx-loops/`: ambient/machine and other loops;
- `bb - Toolbox Rummaging (Sept 2021)/`: metal brushes, thumps, clicks, drawer movement and physical toolbox Foley;
- `bb - Smol Mechanisms (May 2021)/`: small physical mechanisms;
- `metal_interactions/`: extra handling/contact layers.

### Compact utility CC0 source
Source: `assets/audio/source_packs/sound_cc0_misc/` at `0bdbbe370c42897e12b7c5b0b26d96228e0d2931`.
Coverage includes bells, metal/steel and switch-like utility WAV material.

These existing packs should be auditioned before importing duplicates from elsewhere.

## Verified CC0 sources for selective later import
These are `APPROVED_SOURCE`, not `PINNED_VENDOR`, unless a real file/submodule is later added to this repository.

### Chain winch sounds — OpenGameArt
- License: CC0.
- Author: bart.
- Archive: `winch.zip` (~1.5 MB).
- The author states the sound was synthesized/designed to imitate a real winch.
- Useful as a designed background/mechanism layer, but **must not be labelled an authentic field recording of a chain winch**.
- Targets: `CHAIN_WINCH_DESIGNED`, `WINCH_BACKGROUND_DESIGNED`.

### Mining sample — OpenGameArt
- License: CC0.
- Author: jordan4ibanez.
- File: `mining.ogg` (~215 KB).
- Candidate for rock/mining strike auditioning.
- Targets: `MINING_STRIKE_ROCK`, `PICK_ROCK_DESIGNED` after listening verification.

### Breaking Rock — OpenGameArt
- License: CC0.
- Author: themightyglider.
- File: `rock_break.ogg` (~9 KB).
- Candidate for small/medium rock fracture and mining debris layers.
- Targets: `ROCK_BREAK_SMALL`, `ROCK_FRACTURE_LAYER`.

### tree chop fall thud — OpenGameArt
- License: CC0.
- Author: kheetor.
- File: `chop-tree-fall.ogg` (~195 KB).
- Contains chopping, creak/fall transition and ground-impact material.
- Targets: `TREE_CHOP`, `TREE_CREAK_FALL`, `TREE_FALL_IMPACT` after splitting/auditioning if appropriate.

### bart CC0 workshop/mechanism collection — OpenGameArt
- Verified collection contains CC0 candidates such as workshop sounds, metal clangs, pings/filing, steam/boiler/release and mechanism material.
- Keep as selective source pool; import individual files only after checking each page and avoiding redundant copies.
- Targets: `FORGE_BELLOWS`, `FORGE_STEAM`, `METAL_FILE`, `METAL_GRIND`, `WORKSHOP_TOOL_LOOP`, `MECHANISM_HEAVY`.

## Semantic family plan

### Gates / chains / winches
Required production families:
- `CHAIN_MOVE_LIGHT`
- `CHAIN_MOVE_HEAVY`
- `CHAIN_TENSION`
- `CHAIN_RELEASE`
- `CHAIN_DROP`
- `WINCH_CRANK`
- `WINCH_RATCHET`
- `PULLEY_ROPE`
- `CAPSTAN_LOOP`
- `GATE_WOOD_OPEN`
- `GATE_WOOD_CLOSE`
- `GATE_IRON_OPEN`
- `GATE_IRON_CLOSE`
- `PORTCULLIS_MOVE`
- `DRAWBRIDGE_MOVE`

The current chain-winch approved source is a designed layer, not sufficient by itself for an authentic heavy gate/portcullis family.

### Mining / mine carts
Required:
- `MINING_STRIKE_ROCK`
- `PICK_ROCK_LIGHT`
- `PICK_ROCK_HEAVY`
- `ROCK_BREAK_SMALL`
- `ROCK_BREAK_LARGE`
- `ROCK_DEBRIS_FALL`
- `MINE_CART_ROLL`
- `MINE_CART_RAIL_JOINT`
- `MINE_CART_RAIL_SQUEAL`
- `MINE_CART_BRAKE`
- `MINE_CART_IMPACT`
- `MINE_SUPPORT_CREAK`
- `MINE_SUPPORT_FAILURE`

Mine-cart audio later must react to speed, wheel/rail condition and tunnel acoustics instead of using one constant loop.

### Forge / smithy
Required:
- `FORGE_FIRE_LOW`
- `FORGE_FIRE_HIGH`
- `FORGE_BELLOWS`
- `ANVIL_HIT_LIGHT`
- `ANVIL_HIT_HEAVY`
- `METAL_HANDLE_HOT`
- `METAL_FILE`
- `METAL_GRIND`
- `FORGE_QUENCH`
- `FORGE_STEAM`
- `TOOL_PLACE_METAL`
- `TOOL_DROP_METAL`

The already pinned hammer/metal packs cover much of the impact base. Remaining priority is bellows, quench, filing/grinding and sustained forge-fire behavior.

### Tavern / inn / market props
Required neutral layers:
- `TAVERN_MURMUR_NEUTRAL`
- `TAVERN_LAUGHTER_SPARSE`
- `TAVERN_CHAIR_WOOD`
- `TAVERN_TABLE_PROP`
- `VESSEL_CERAMIC`
- `VESSEL_GLASS`
- `POUR_LIQUID`
- `BOTTLE_PLACE`
- `MUG_PLACE`
- `COIN_HANDLING`
- `COIN_POUCH`
- `SACK_MOVE`
- `CRATE_MOVE`
- `MARKET_STALL_WOOD`
- `MARKET_CROWD_NEUTRAL`

Neutral beds should avoid clearly intelligible repeated speech; distinctive laughter, arguments and shouts should be sparse event emitters instead of an endless loop.

### Large structural destruction
Required layered families:
- `TIMBER_CRACK_LARGE`
- `TIMBER_BEAM_FAILURE`
- `TIMBER_COLLAPSE_CLOSE`
- `TIMBER_COLLAPSE_DISTANT`
- `ROOF_COLLAPSE`
- `MASONRY_FRACTURE`
- `STONE_CHUNK_FALL`
- `STONE_COLLAPSE_CLOSE`
- `STONE_COLLAPSE_DISTANT`
- `DEBRIS_SMALL`
- `DEBRIS_MEDIUM`
- `DEBRIS_LARGE`
- `EARTH_RUMBLE_CLOSE`
- `EARTH_RUMBLE_DISTANT`

Do not create a universal building-destruction sound. Timber, masonry, mixed structures and distance each need different layer weighting.

## Physical-world rules for later integration
- Heavy gates/portcullises must emit mechanism, hinge/rail and chain/rope sounds from their actual moving parts.
- A chain under tension should not sound like loose dropped chain.
- Mine strikes should originate from the actual pick/rock contact and stop when workers stop.
- Mine-cart rolling should follow movement speed and rail joints; stationary carts stay silent.
- Forge actions should be driven by actual worker actions and equipment, not a permanent blacksmith loop.
- Tavern/market murmur density should follow actual nearby population.
- Destruction needs close and distant variants; simply lowering the volume of a close collapse is not enough.
- Semantic event names are the stable API; source filenames remain source metadata only.

## Highest-priority gaps after this stage
1. authentic recorded heavy chain family;
2. real portcullis / drawbridge / large gate mechanisms;
3. real mine-cart wheels, rail joints, squeal and brake;
4. forge bellows, quench, filing and grinding families;
5. neutral tavern/market murmur without repeated intelligible dialogue;
6. coin/pouch/sack/crate/ceramic/pouring market-and-tavern Foley;
7. large recorded timber structural collapse;
8. large masonry/stone collapse and debris;
9. rope pulleys/capstans and heavy wooden mechanisms;
10. mill/waterwheel/windmill mechanism families.

## Integration ownership
Main development owns production selection, normalization, compression/streaming, 3D emitters, occlusion, room reverb, distance models, animation synchronization and runtime event routing. This asset-research chat only stages and audits legal source material.