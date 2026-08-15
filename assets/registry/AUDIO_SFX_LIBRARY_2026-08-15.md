# ImPuls — Audio / SFX Source Library

This is a staging library only. Nothing under `assets/audio/` is automatically wired into gameplay, scenes, autoloads, `project.godot`, or runtime scripts from the asset-research chat.

## Rules
- Prefer CC0 / public-domain audio so commercial reuse does not depend on attribution.
- Preserve source and license information for every third-party pack.
- `STAGED` means actual audio is present in the repository (directly or as a pinned vendor submodule).
- `APPROVED_SOURCE` means the source/license was verified, but binary files are not yet physically vendored here.
- Do not hard-code audio filenames in gameplay from this library. Main game-development flow chooses and integrates semantic events later.
- Avoid giant uncurated dumps. Prefer useful surface/material/biome coverage with multiple variations.

## Library map

### Movement / footsteps
Target coverage: carpet, concrete/stone, grass, leaves, gravel, mud, snow, sand, shallow water, wood, metal; walking/running/sprinting/crouching/jumping/landing; clothing, gear, body movement and object handling.

- **STAGED — Kenney Impact Sounds mirror (CC0 1.0)**
  - Path: `assets/audio/third_party/kenney_impact_sounds/`
  - Pinned upstream commit: `999dd1684873f8b020a3aa5b26e713da21688924`
  - Contains real OGG footsteps including carpet, concrete, grass, snow and wood, plus many impact variants.
  - Original pack: Kenney Impact Sounds.
  - Vendor mirror: `Boyquotes/kenney-impact-sounds-for-godot`.
  - License is preserved in the submodule root (`LICENSE`, CC0 1.0 Universal).

- **APPROVED_SOURCE — Different steps on wood, stone, leaves, gravel and mud (OpenGameArt, CC0)**
  - Small complementary surface-footstep pack; useful for natural terrain gaps.

### Impacts / collisions / combat Foley
Target coverage: light/heavy generic hits, body/blunt hits, wood, stone, metal, glass, tools, bells, debris, drops, ricochets, blocks/parries and landing impacts.

- **STAGED — Kenney Impact Sounds mirror (CC0 1.0)** — same pinned library above.
- **APPROVED_SOURCE — 100 CC0 SFX (OpenGameArt, CC0)** — explosion, glass, hits, metal, slams, splash, switches, tools and wood.
- **APPROVED_SOURCE — 100 CC0 SFX #2 (OpenGameArt, CC0)** — doors, footsteps, glass, hits, metal, stone, thunder, wood, water and ambience/machine loops.

### Explosions / destruction
Target coverage: small/medium/large explosions, distant booms, debris, structural collapse, wood break, stone break, metal crash, glass shatter and secondary impacts.

- **APPROVED_SOURCE — 100 CC0 SFX (OpenGameArt, CC0)** — base explosion/destruction material.
- Do not bind these directly to VFX; main runtime should later select variations by force, material and distance.

### Water / liquid / rain
Target coverage: stream, river, lake edge, waterfall, rain on surfaces, puddles, splashes by size, wading, swimming, bubbles, drips and wet/slimy interactions.

- **APPROVED_SOURCE — 40 CC0 water / splash / slime SFX (OpenGameArt, CC0)** — bubbles, rain/water loops, splashes and slime.
- **APPROVED_SOURCE — Rain (loopable) (OpenGameArt, CC0)** — several long loopable rain recordings.
- **APPROVED_SOURCE — 30 CC0 SFX loops (OpenGameArt, CC0)** — rain, boiling/flowing water and ambience loops.

### Nature / weather / ambience
Target coverage: forest day/night, birds/insects, wind by intensity, leaves/branches, thunder near/far, storms, rain, caves, fields, coast, swamp, mountains, snow/blizzard and biome room tones.

- **APPROVED_SOURCE — Forest Ambience (OpenGameArt, CC0)** — lightweight forest ambience.
- **APPROVED_SOURCE — 100 CC0 SFX #2 (OpenGameArt, CC0)** — thunder and ambient loops.
- **APPROVED_SOURCE — 30 CC0 SFX loops (OpenGameArt, CC0)** — ambient/noise/rain/machine loops.

### Doors / knocks / construction / props
Target coverage: wood/metal doors, hinges, latches, locks, keys, knocks by material, cabinets, drawers, gates, chains, tools, construction and household props.

- **APPROVED_SOURCE — 100 CC0 SFX + 100 CC0 SFX #2 (OpenGameArt, CC0)** — doors, squeaks, slams, switches, tools, wood, metal, construction-related effects.

### Machines / settlement / technology
Target coverage: workshop, forge, saws, pumps, generators, industrial machinery, vehicles, distant settlement/city hum and technology/UI feedback.

- **APPROVED_SOURCE — 30 CC0 SFX loops (OpenGameArt, CC0)** — machines, saw, alarm and mechanical/ambient loops.
- Additional Kenney CC0 audio families may be staged later only when they fill a real gap.

### Magic
- Existing **STAGED** library: `assets/audio/third_party/oga_magic_cc0/`.
- Keep magic separate from physical Foley so semantic selection stays clear.

## Integration ownership
This asset-research chat only collects, audits and organizes source assets. The main game-development chat decides what to copy/import into production, how to normalize loudness, whether to convert formats, how to implement 3D attenuation/occlusion/reverb, random variation and event routing, and when to remove unused assets.
