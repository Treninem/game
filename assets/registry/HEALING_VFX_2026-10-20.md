# Healing presentation — review candidate

INTEGRATED in the review runtime: `scripts/vfx_library.gd` reuses the existing Kenney CC0 `light_01.png` from `assets/vfx/third_party/kenney_particle_pack/PNG (Transparent)/`. No new third-party files or download; the adjacent pack SOURCE.md and LICENSE.txt remain authoritative.

The primary healing effect replaces its opaque emissive sphere flash and two solid sphere bursts with a gentle short-range light and 32 textured alpha motes. Particle vertex color applies a lifetime alpha ramp, including transparent birth/death. Emitters are one-shot, last at most 1.2 seconds and retain the shared bounded effect ownership/cleanup. This change is limited to healing; other core effects retain their prior geometry/materials.

The existing secondary spell-cast flipbook remains separate. Overall magic art, character models, animation quality and forest appearance are not accepted by the owner. This is a local presentation correction, not a realism milestone.

Evidence: `docs/DEVELOPMENT_LOG_2026-10-20_HEAL_VFX.json`.
