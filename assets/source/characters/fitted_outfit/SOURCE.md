# Fitted default outfit — review source

These editable male/female Blender files retain the native MakeHuman body,
rig, nine shape keys and ten existing animation clips. Existing MakeHuman
Community/MPFB and selected Rehman Polanski Viking clothing graphics are CC0;
their source/license files remain under `assets/staging/characters/` and
`assets/production/characters/realistic/`. No new third-party asset was sourced.

The inner cloth uses native body topology and weights with 6 mm clearance.
Two opening rings and exposed head/neck/hands remain protected. The joined
Clothing mesh has a separate matte OutfitLining material using only the
existing tunic cloth strip. Original outer cloth, other five parts and all
authored image pixels are preserved. This is a fixed default outfit, not a
complete armor or undressing system. Keep native unmasked source for future
outfit changes; do not display this masked body without its outfit.

Rebuild into an isolated directory with `tools/build_viking_humans.py` in
factory Blender, setting `IMPULS_CHARACTER_OUTPUT` explicitly. This invokes
`tools/garment_body_coverage.py`; it never writes production by default.
`tools/save_fitted_human_sources.py` saves portable editable copies with
repository-relative image paths and disabled thumbnail previews. Source
textures remain in their canonical folders instead of duplicate packed maps.

Exact accepted GLBs were refitted from retained byte-identical baseline
editable sources using the same fitting helper. Full builder reproduction
and its comparison are recorded in the acceptance journal. Re-export with
GLB, Actions animation mode, force sampling, morphs and morph normals enabled.
Runtime retains the already validated per-body normal/AO for the original
three outer material roles. The legacy map bakers do not support the added
lining role; do not blindly rebake it into outer material atlases.

Evidence and scope: `docs/DEVELOPMENT_LOG_2026-10-22_OUTFIT_FIT.json` and
`docs/review/2026-10-22-outfit-fit/`. Full artistic acceptance remains false.
