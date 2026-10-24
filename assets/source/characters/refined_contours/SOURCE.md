# Editable contour family

Open `male.blend` or `female.blend` in Blender. The accepted original distance
body is hidden in the editable viewport to avoid two overlapping skins. It is
still exported and selected explicitly by the runtime distance helper.

These project-authored revisions reuse the existing CC0 MakeHuman body, native
UVs/rig/appearance targets and selected Rehman Polanski outfit, with existing
retargeted animation sources. Original licenses and provenance are preserved in
`assets/production/characters/realistic/` and the existing staging sources.
No new third-party pack or generated texture is involved.

`tools/refine_human_contours.py` reproduces the near/far GLB family from the
accepted portable `fitted_outfit` sources. Clothing triangulation metadata is
retained and reapplied after Blender export. All nine morphs are evaluated with
the same subdivision topology; the eyes retain per-globe bounds. All interpolated
near weights are preserved, while the original exported four weights are restored
on the distance body. Godot import requires its actual eight-weight near layout.

Image paths are relative to the repository and verified against physical source
files. `.gdignore` prevents game/editor import of these authoring documents.
Production exports are in `assets/production/characters/realistic_contours/`.
This source family does not replace or modify the accepted base input files.
