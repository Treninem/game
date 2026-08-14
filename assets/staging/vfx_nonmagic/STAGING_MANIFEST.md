# Non-magic VFX staging manifest

These files are source-only staging material. They are intentionally not connected to Godot runtime code by this workflow.

Staged families:
- animated general particles / smoke / fire;
- air bubbles and impact sheets;
- volumetric-rendered flames, explosions, rings and shockwaves;
- explosion/bang audio recordings;
- splat/decal candidates for mud, oil, grime, liquids and residues;
- soft smoke/vapor textures;
- compact explosion atlas.

Main integration chat should deduplicate against `assets/vfx/third_party/`, choose production-quality subsets, optimize atlases/audio, and only then wire selected assets into gameplay.
