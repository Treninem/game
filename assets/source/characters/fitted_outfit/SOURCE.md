# Fitted default outfit - editable review sources

The two Blender files retain the existing MakeHuman body/rig, nine shape keys,
ten source clips and selected Rehman Polanski Viking outfit. Existing graphics
are CC0; source licenses remain under assets/staging/characters/ and the
production character folders. No new pack, image, human identity or artistic
acceptance is claimed.

The redundant visible OutfitLining shell has been removed. Original outer
positions, normals, UVs, weights, morphs and accepted triangles remain intact;
the previous covered-body mask still protects exposed head, neck and hands.
This is a fixed costume. Do not display the masked body without its outfit.
Full garment swapping and cloth-on-cloth intersection repair remain open.

Run tools/export_fitted_outfit.py in factory Blender with --python-exit-code 1.
Its default output is an isolated build folder; IMPULS_CHARACTER_OUTPUT selects
another candidate folder. Sources contain repository-relative image paths and
no duplicate packed maps. The producer preserves four accepted exported
influences and uses the compressed accepted_outer_triangulation_v1 reference
stored in Clothing to restore the original quad diagonals after export.
Ordinary Blender export can retessellate a quad when adjoining lining is
removed. Intentional refits/retopology need a new explicitly reviewed reference
and full validation.

Compare an accepted baseline and candidate independently with
tools/check_outfit_shell_removal.py. It requires original images, seven parts,
exposed body, bind frames, outer corners/triangles/normals/UVs/weights, nine
morphs and ten source clip channels/times to agree. A parse-only result does
not replace these checks. Runtime WorkStanding is authored separately in
scripts/humanoid_work_poses.gd; legacy ground Working remains available.

Existing per-body outer AO/normal maps retain unchanged UVs. No new bake or
texture enlargement is part of this revision. Full artistic quality,
faces/hair, tool manipulation and extreme-pose layer contacts remain open.

Evidence: docs/DEVELOPMENT_LOG_2026-10-22_WORK_WARDROBE.json and
docs/review/2026-10-22-work-wardrobe/. Stable release is not published.
