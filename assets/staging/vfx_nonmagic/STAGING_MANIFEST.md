# Non-magic VFX staging manifest

These files are source-only staging material. They are intentionally not connected to Godot runtime code by this workflow.

Staged families:
- animated general particles / smoke / fire;
- air bubbles and physical hit sheets;
- volumetric-rendered flames, explosions, rings and shockwaves;
- multiple transparent explosion atlas families;
- explosion/bang audio recordings;
- splat/decal candidates for mud, oil, grime, liquids and residues;
- soft smoke/vapor textures;
- water caustics, drops and splash candidates;
- lightning and rain animation candidates.

Main integration chat should deduplicate against production assets, choose production-quality subsets, optimize atlases/audio and only then wire selected assets into gameplay.
