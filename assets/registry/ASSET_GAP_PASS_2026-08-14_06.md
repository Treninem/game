# ImPuls — Asset Gap Pass 06 (2026-08-14)

Purpose: continue filling only real gameplay gaps with license-safe assets. CC0 remains preferred. This pass covers remaining fauna, blacksmithing, insects/pollination, workshop machinery, and identifies non-CC0 fallbacks that must not be silently treated as CC0.

## Newly verified production candidates

### Low Poly Iron Anvil — OpenGameArt
Source: https://opengameart.org/content/low-poly-iron-anvil
License: CC0
Format: ZIP / 3D model
File: `Iron Anvil Low poly.zip` (~785 KB)
Geometry: 258 tris
Textures: 512x512 diffuse + specular
Target: `assets/props/workshops/blacksmith/anvil/opengameart_iron_anvil/`
Status: VERIFIED HIGH-PRIORITY production candidate after scale/material normalization.

### Bee — OpenGameArt
Source: https://opengameart.org/content/bee-0
License: CC0
Format: Blender
Notes: rigged mesh plus non-rigged version; texture dependencies must be kept together.
Target: `assets/animals/insects/bee/opengameart_bee/`
Status: VERIFIED candidate for apiary/pollination ecosystem after animation and scale checks.

### Spinning Machine Tools (low poly) — OpenGameArt
Source: https://opengameart.org/content/spinning-machine-tools-low-poly
License: CC0
Format: 7Z
Archive: `Spinning-Machine-Tools.7z` (~472 KB)
Notes: mechanical machine-tool set; despite the page title this is not a textile spinning-wheel set.
Target: `assets/technology/workshop/machine_tools/opengameart_spinning_machine_tools/`
Status: VERIFIED candidate for industrial/workshop progression. Inventory and exact machines must be inspected after extraction before runtime import.

### Bird — OpenGameArt
Source: https://opengameart.org/content/bird
License: CC0
Format: Blender
Notes: generic bird, rigged and animated; derived from a CC0 bird basemesh.
Target: `assets/animals/birds/generic/opengameart_bird/`
Status: VERIFIED generic flying-bird candidate; useful for flock/background wildlife but does not replace exact eagle/owl/raven species models.

### Bird basemesh / sparrow-like base — OpenGameArt
Source: https://opengameart.org/content/bird-basemesh
License: CC0
Format: Blender
Geometry: ~750 tris
Notes: generic/sparrow-tagged basemesh, explicitly not game-ready. Use only as a project-owned derivative base for sparrow/small-bird production models.
Target source: `assets/source_models/animals/birds/bird_basemesh/`
Status: VERIFIED SOURCE BASE; REMODEL/RIG/TEXTURE REQUIRED.

## Verified fauna pool retained

### CC0 3D Animals / Creatures collection
Source: https://opengameart.org/content/cc0-3d-animals-creatures
Use only after individual page verification.
Useful remaining entries in collection include Raven, Cobra, Butterfly, Rabbit, Deer, horse, fish, whale, shark, penguin, lemur and other wildlife.
Status: DISCOVERY INDEX ONLY; collection membership is not a substitute for individual production validation.

### 3D Animals under CC0 collection
Source: https://opengameart.org/content/3d-animals-under-cc0
Useful remaining coverage includes Pony, Mammuth, Camel basemesh, Butterfly, rabbit, wolf, horse, pig and multiple fish.
Status: DISCOVERY INDEX ONLY.

## Important license rejection / fallback notes

### [LPC] Farm
Source: https://opengameart.org/content/lpc-farm
License: CC-BY 4.0, not CC0.
Useful content includes apiaries/beehives, butter churner, cheese press, mayonnaise maker, barns, silos, chicken coop, animated windmill blades and water wheels.
Decision: DO NOT classify as CC0. Keep only as a design/reference fallback unless the project later explicitly allows attribution-bearing CC-BY assets.

### Workbench
Source: https://opengameart.org/content/workbench
License: CC-BY-SA / GPL family, not CC0.
Decision: rejected for the CC0-first production pool. Search/build a CC0 carpenter workbench instead.

### Honey Badger search false-positive
`AAC Honey Badger Lowpoly` is a firearm model, not an animal, and is CC-BY 3.0.
Decision: reject completely for wildlife coverage.

## Gaps still not honestly closed
No exact production-ready 3D CC0 candidate was verified in this pass for:
- goose / gosling
- piglet
- goat kid
- moose / elk
- badger
- raccoon
- owl
- eagle / hawk
- exact raven/crow production model (collection entry exists; individual page still needs verification)
- beehive/apiary 3D set
- cheese press / butter churn 3D
- textile loom / spinning wheel 3D
- pottery wheel / kiln 3D
- blacksmith bellows / forge-state set
- carpenter workbench / vise / sawbuck 3D
- tannery rack / hide-stretching frame
- fishing net production / net-drying rack

These remain explicit search or custom-generation tasks; do not mark them complete by substituting 2D assets or loosely related models.

## Binary-transfer status
Direct binary URLs can now be resolved for some OpenGameArt files (for example `goatlowrez.obj` and the iron-anvil ZIP), but the available external download bridge still failed to transfer the bytes into the working container. Therefore this pass records verified sources and exact target paths only. Do not claim the binary asset is in Git until a binary upload succeeds and the committed blob is verified.

## Next pass priority
1. Verify the individual 3D Raven page.
2. Search exact goose/gosling and piglet/goat-kid models beyond OpenGameArt.
3. Search CC0 3D workshop props: forge, bellows, loom, spinning wheel, pottery wheel, kiln, carpenter bench, tanning rack.
4. Search exact beehive/apiary and dairy-processing machinery.
5. Search exact moose/elk, raccoon, badger, owl, eagle/hawk.
6. If no quality CC0 asset exists, create project-owned models rather than lowering license or quality standards.
