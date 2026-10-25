# Authored bow and arrow

Selected project-owned Blender geometry from `assets/staging/project_owned/settler_equipment_2026_10_24/SettlerEquipment.blend`. Source code, editable master and exact original CC0 texture provenance are retained there and under licenses/. No rejected donor geometry is used in these two models. Axe/knife remain separate pending review.

Godot Y-up metres; bow palm (-0.070708,0,0), arrow nock seat (0,-0.343,0), arrow tip (0,0.350,0). The tip is 0.693m ahead of the string seat; the complete arrow is 0.700m long. The three Draw blend shapes must remain intact. RestCord is hidden only on held bows. Runtime endpoint displacement is bound once to the actual horn shape data, without replacing imported mesh buffers. Each instance owns its own weights. Inventory and workshop displays use the same catalog.

Texture import descriptors intentionally enable mip levels. Compiled .godot caches are excluded. Visual character and whole-world quality remain open; this package does not add rarity, upgrades or repair.
