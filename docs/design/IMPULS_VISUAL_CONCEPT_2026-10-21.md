# ImPuls — supplied visual target, 21 October 2026

The owner supplied `impuls-concepts-2026-10-21/world-concept.png` and
`impuls-concepts-2026-10-21/house-concept.png` and requested Blender authoring,
Godot integration and verification in the actual game. These are reference
boards, not production models, proof of implemented content or an instruction
to replace established geography, saves or working systems. Rights beyond
owner-supplied project reference use have not been established.

## Observed direction

Original semi-realistic medieval fantasy: believable human proportions,
layered clothing, articulated hands, grounded motion; varied terrain and dense
vegetation; timber, plaster, stone and tile with readable construction and
material scale. Do not substitute primitive bodies, flat box houses or a painted
concept image for playable geometry.

Homes need structural depth: exposed posts and ceiling ties, knee braces,
recessed glazed windows, projecting sills, doors and usable stairs. Rooms combine
cool daylight with restrained warm hearth/lantern lighting. Objects imply use:
bedding, utensils, storage, books, tools and occupation-specific work surfaces.
Protect doors, human headroom, furniture approach points and NPC routes.

The second board distinguishes a poor cottage, family home, wealthy home,
tavern, smithy, shop, hunter, fisherman, herbalist/alchemist, guard, mage,
ruler/castle and underground/special dwellings. These need different plans and
activity zones, not one shell with different labels. Preserve the canonical
world's names and locations when selecting sites.

## Implementation and acceptance

Author/edit selected meshes in Blender; retain reproducible builders and local
editable `.blend` files, export GLB, apply reviewed existing textures and proper
UVs, and wire the model into live Godot scenes/code. Reuse appropriate existing
licensed sources rather than discarding everything solely because it was
authored elsewhere. Inspect anatomy, topology, deformation, collisions, LOD and
materials according to asset type. Staging alone is not integration.

Start with a coherent ordinary family home and its inhabitants: exterior,
interior, lighting, usable furniture, doors, paths, daily actions and saves.
Expand the kit to the other building types and the wider region after inspecting
rendered gameplay, not after a parse-only check. Do not claim the whole board is
complete from the window/timber package.

Current first implementation: `tools/build_interior_window.py` and
`tools/build_house_timberwork.py`, integrated by `scripts/enterable_building.gd`.
The larger architecture kit, room plans, hearths, clutter, people, animals and
regional landscape still require substantial work and owner acceptance.
