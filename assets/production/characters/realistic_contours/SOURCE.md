# Refined human contours — review family, 23 October 2026

The live human selector uses these two GLBs. They derive from the existing CC0
MakeHuman fitted male/female sources and selected Rehman Polanski Viking outfit.
Retained animation provenance and licenses remain in the sibling `realistic/`
directory and the original physical source packs; no new download or bitmap.

Blender evaluates one Catmull-Clark level on the rendered body control surface,
preserving open clothing-mask boundaries, and two levels on the eyes with each
globe's original bounds retained for Basis and all nine appearance shapes.
The five other parts, all ten source clips, bind frames, outer clothing triangles
and embedded authored images pass an independent GLB preservation comparison.

Eight named skinned parts are required. `HumanBody` is the refined near surface;
`HumanBodyFar` is the exact accepted original exported body, including its four
weights. The near surface retains the fifth influence where present, using the
engine's eight-weight layout. `humanoid_detail_lod.gd` selects only one body with
7/9 metre hysteresis. Directly instantiating the raw GLB without that selector
would display both bodies. Eyes, hair and clothes remain shared at both ranges.

The old family is retained as the exact comparison reference and for the already
open user review process. Existing wardrobe/detail/eye atlases remain in that
sibling directory. Generated extracted PNGs and `.import` metadata are rebuilt by
Godot from the self-contained GLBs; do not commit duplicate extracted images.

Editable files: `assets/source/characters/refined_contours/`.
Reproducer: `tools/refine_human_contours.py`, run by Blender in background mode,
with `IMPULS_CHARACTER_OUTPUT` pointing to a new isolated destination. Inputs are
the accepted `fitted_outfit/*.blend` plus the retained original GLBs (for exact
distance weights). The builder refuses to overwrite prior candidate GLBs.

This remains a fixed default costume with a covered-body mask, not an undressing
system. It is a bounded contour/material improvement; realistic skin shading,
expressions, hair, age diversity, complete clothing and artistic acceptance are
still open. Increased mesh density is not a photorealism or frame-rate claim.
