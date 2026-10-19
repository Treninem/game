# Native human character family â€” 0.10.7.2 review

INTEGRATED in the character review candidate: `assets/production/characters/realistic/male.glb` and `female.glb` are referenced by `scripts/humanoid_visual.gd`. This is an initial family, not a completed photorealistic wardrobe.

Sources: official MakeHuman Community MPFB core graphics and MakeHuman system graphics, CC0. No MPFB GPL executable code is embedded. The selected source files and licenses live in `assets/staging/characters/makehuman_mpfb_core/` and `makehuman_system_selected/`, with SHA-256 manifests. These new selections await main confirmation; STAGED_PHYSICAL on main is not claimed.

Native MakeHuman body weights and bone definitions are retained. Existing ten Quaternius-derived clips are reused from the previous citizen asset, retargeted with separate normalized bind and actor frames; Idle uses a relaxed native stance. Forward knee constraints preserve ankle contact. Garment weights are smoothed on connected topology; authored UV islands separate shirt and trousers. Author clothing/footwear masks remove hidden body faces. Cuffs end at the wrist. Hair tint uses a project shader with the CC0 strand textures.

There are separate skin, eyes, brows, two hair meshes, clothing and footwear; four synchronized morph targets, and ten presets, five per sex. The editor is reached from New Game and stores the selected appearance through the existing game-save world state. Old saves get a bounded default. Material caches depend on color choices, not every slider position.

Reproduce with `tools/build_realistic_humans.py`; validate with `tools/validate_realistic_characters.py` and `tests/smoke_character_creator.tscn`. Full gameplay, native rendering and performance results belong to the character development journal. Body height is normalized near 1.8 m; morph ranges are bounded. Initial garments are generic long-sleeved shirts, trousers and plain shoes; full armor, garment swapping, age presets and advanced facial controls remain unfinished.

## Weapon grip follow-up â€” 0.10.7.3

INTEGRATED in the review runtime: native hand joints close around independently measured axe/bow handle points. The per-actor post-animation modifier preserves lower-body locomotion during attacks and follows camera pitch. Runtime arm clips replace the source bow/axe poses with a documented contact schedule. Existing B36 bow/arrow geometry is reused; a procedural cord follows the drawing fingers, and a wrapper preserves arrow normalization. Tests cover measured shaft contact, finger bend, arrow size/aim, paused equip, cancellation/load and physical damage. This is initial grip/animation refinement, not a claim of motion-capture quality or a complete combat system.

## Surface follow-up — 2026-10-19

INTEGRATED in the review runtime: existing CC0 garment AO/normal and footwear diffuse in `realistic/details`, anisotropic mipmapped materials, differentiated cloth/skin/eye roughness and 4x MSAA in the character editor. No new body geometry or photorealism claim. Both bodies received native editor captures and the bounded actual-world weapon pass; evidence: `docs/DEVELOPMENT_LOG_2026-10-19_CHARACTER_SURFACES.json`.

## Character surfaces follow-up — 2026-10-19

INTEGRATED in the review runtime: existing CC0 garment AO/normal and footwear diffuse in `realistic/details`, anisotropic materials and editor MSAA. No new body geometry. Evidence: `docs/DEVELOPMENT_LOG_2026-10-19_CHARACTER_SURFACES.json`.
