# ImPuls — Audio / SFX Source Library

This is a staging library only. Nothing under `assets/audio/` is automatically wired into gameplay, scenes, autoloads, `project.godot`, or runtime scripts from the asset-research chat.

## Status meanings
- `PHYSICAL` — files are stored directly in this repository.
- `PINNED_VENDOR` — the repository contains a Git submodule pinned to an exact upstream commit. Real audio stays in the source repository and can be fetched when needed without adding its entire binary history to the core game repository.
- `APPROVED_SOURCE` — source and license are verified, but the pack is not yet vendored or linked.

## Rules
- Prefer CC0 / public-domain audio so commercial reuse does not depend on attribution.
- Preserve source/license information for every third-party pack.
- Do not hard-code audio filenames into gameplay from this library. Main game-development flow chooses semantic events later.
- Avoid unnecessary duplicate archives and giant binary dumps in core Git history.
- Keep raw/source libraries separate from production-selected audio.

## Core pinned libraries

### Kenney Impact Sounds — lightweight core
- **PINNED_VENDOR**
- Path: `assets/audio/third_party/kenney_impact_sounds/`
- Upstream: `Boyquotes/kenney-impact-sounds-for-godot`
- Pinned commit: `999dd1684873f8b020a3aa5b26e713da21688924`
- License: CC0 1.0 Universal (`LICENSE` in submodule root).
- Coverage: real OGG footsteps on carpet, concrete, grass, snow and wood plus many impact variants.
- Purpose: small high-value pack that can be fetched without pulling the bulk archive.

### CC0 Public Domain Sounds — bulk source library
- **PINNED_VENDOR**
- Path: `assets/audio/source_packs/cc0_public_domain_sounds/`
- Upstream: `lavenderdotpet/CC0-Public-Domain-Sounds`
- Pinned commit: `f2b6264f9ab89fabc266914c3654685d68c5a39b`
- Root license: CC0 1.0 Universal.
- This is a large source library. It is intentionally linked as a submodule rather than copied into core history.
- Useful pack folders include:
  - `100-CC0-SFX`
  - `100-CC0-wood-metal-SFX`
  - `100-cc0-sfx-2`
  - `25-CC0-bang-sfx`
  - `25-CC0-mud-sfx`
  - `30-cc0-sfx-loops`
  - `40-cc0-water-splash-slime-sfx`
  - `75-cc0-breaking-falling-hit-sfx`
  - `80-CC0-RPG-SFX`
  - `80-CC0-creature-SFX`
  - `80-CC0-creature-sfx-2`
  - `Maximiliano-Stradex-Ambient`
  - `Micro Pack - Cat Meows`
  - `Micro Pack - Kitchen Knives`
  - `Micro Pack - MadameBerry - Stream Noises`
  - `bb - Smol Mechanisms (May 2021)`
  - `bb - Toolbox Rummaging (Sept 2021)`
  - `beast_or_animal`
  - `metal_interactions`
  - Kenney casino/digital/impact/interface/RPG/UI/voice packs.

## Coverage map

### Nature / weather / ambience
Need: forest day/night, birds/insects, wind by intensity, leaves/branches, rain, thunder near/far, storms, caves, fields, coast, swamp, mountains, snow/blizzard, streams/rivers and biome room tones.

Available/linked:
- `30-cc0-sfx-loops` — ambience, rain, water and mechanical loops.
- `40-cc0-water-splash-slime-sfx` — water/rain/bubble/splash loops and one-shots.
- `Micro Pack - MadameBerry - Stream Noises` — stream material.
- `Maximiliano-Stradex-Ambient` — ambient material for auditioning.
- **APPROVED_SOURCE** — Forest Ambience (OpenGameArt, CC0).
- **APPROVED_SOURCE** — Rain (loopable) (OpenGameArt, CC0).

### Movement / footsteps / body Foley
Need: carpet, concrete/stone, grass, leaves, gravel, mud, snow, sand, water, wood, metal; walking/running/sprinting/crouching/jumping/landing; cloth, gear and body movement.

Available/linked:
- Kenney Impact Sounds — carpet, concrete, grass, snow, wood footsteps.
- `100-cc0-sfx-2` — additional footsteps and material effects.
- `25-CC0-mud-sfx` — mud/wet-ground movement.
- **APPROVED_SOURCE** — Different steps on wood, stone, leaves, gravel and mud (OpenGameArt, CC0).

### Hits / collisions / combat Foley
Need: light/heavy generic hits, blunt/body hits, weapon contacts, blocks/parries, wood, stone, metal, glass, tools, bells, debris, drops, ricochets and landing impacts.

Available/linked:
- Kenney Impact Sounds.
- `100-CC0-SFX`.
- `100-CC0-wood-metal-SFX`.
- `100-cc0-sfx-2`.
- `75-cc0-breaking-falling-hit-sfx`.
- `metal_interactions`.

### Explosions / destruction
Need: small/medium/large explosions, distant booms, debris, collapse, breakage and secondary impacts.

Available/linked:
- `25-CC0-bang-sfx`.
- `100-CC0-SFX` — explosion/slam/glass/material effects.
- `75-cc0-breaking-falling-hit-sfx` — break/fall/hit variations.
- `100-CC0-wood-metal-SFX` — material destruction layers.

### Water / liquids
Need: stream, river, lake edge, waterfall, puddles, wading, swimming, splashes by size, bubbles, drips and wet/slimy interactions.

Available/linked:
- `40-cc0-water-splash-slime-sfx`.
- `30-cc0-sfx-loops`.
- `Micro Pack - MadameBerry - Stream Noises`.

### Doors / knocks / props / construction
Need: wood/metal doors, hinges, latches, locks, keys, knocks by material, cabinets, drawers, gates, chains, tools, construction and household props.

Available/linked:
- `100-CC0-SFX`.
- `100-cc0-sfx-2`.
- `100-CC0-wood-metal-SFX`.
- `Micro Pack - Kitchen Knives`.
- `bb - Smol Mechanisms (May 2021)`.
- `bb - Toolbox Rummaging (Sept 2021)`.

### Animals / creatures
Need: domestic animals, wildlife, birds, insects, creature movement, pain/aggression/calls and distant ecology layers.

Available/linked:
- `80-CC0-creature-SFX`.
- `80-CC0-creature-sfx-2`.
- `beast_or_animal`.
- `Micro Pack - Cat Meows`.

### Settlement / machinery / technology
Need: forge/workshop, saws, pumps, generators, industrial machinery, mechanisms, vehicles, distant settlement/city hum and technology/UI feedback.

Available/linked:
- `30-cc0-sfx-loops` — machine/pump/saw/alarm loops.
- `bb - Smol Mechanisms (May 2021)`.
- `metal_interactions`.
- Kenney digital/interface/UI families.

### Magic
- Existing **PHYSICAL** library: `assets/audio/third_party/oga_magic_cc0/`.
- Keep magic separate from physical Foley so semantic selection stays clear.

## Future gaps to fill deliberately
Do not duplicate existing coverage blindly. Highest-priority additions after auditioning current packs:
1. richer realistic forest/bird/insect ambience by biome and time of day;
2. strong wind/gust/storm/blizzard layers;
3. thunder at several distances with matching rain intensity;
4. sand, gravel, leaves, ice and deep-snow footsteps with walk/run variants;
5. cloth/leather/armor inventory and body Foley;
6. doors/knocks for several materials and room sizes;
7. large structural destruction/collapse layers;
8. farm/domestic-animal recordings and settlement crowds;
9. vehicle/mechanical families appropriate to each technology era;
10. indoor/outdoor room tones and acoustic transition layers.

## Integration ownership
This asset-research chat only collects, audits and organizes source assets. The main game-development chat decides what to select for production, how to normalize loudness, whether to convert formats, how to implement 3D attenuation/occlusion/reverb, random variation and event routing, and when to remove unused assets. No runtime files are modified here.
