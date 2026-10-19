# Woodland weapons

Selected from existing physical source:
`assets/staging/sourcechat_b36/models/quaternius_ultimate_rpg_items/`.
Quaternius Low Poly RPG Pack, CC0. Source metadata and license retained there;
LICENSE.txt here is copied verbatim. No new download was needed.

Normalized authored models: axe 0.65 m, dagger 0.35 m, bow 1.1 m, arrow 0.7 m.
Regenerate with Blender and `tools/prepare_weapon_visuals.py`.
The avatar places items at a measured native palm frame after skeletal animation,
with authored handle offsets and closed finger joints. The imported normalization
transform is retained. Runtime bow draw uses a two-bone right-arm solve, replaces
the authored straight cord with two hand-following segments, and displays the
existing normalized arrow. Arrow flight uses swept collision and gravity. A shot
releases after the 0.22 s draw; the axe contact pose matches its 0.22 s wind-up.
No new external assets were downloaded for the 0.10.7.3 grip follow-up.
The dagger is a visual proxy for the early knife, not a photorealistic stone tool.
