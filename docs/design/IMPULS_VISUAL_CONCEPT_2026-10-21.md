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

## Owner clarifications, 21–22 October 2026

The owner rejected the sparse rooms again: use the supplied house board as the visual acceptance target, with complete functional zones rather than counting isolated props. Ordinary homes need at least two living/private rooms and a kitchen; plans, furnishings and beds must vary with building type, wealth and household composition. Some homes house one adult, others several adults or parents with children. Children must have guardians and age-appropriate appearance, routines and schooling. Adults need real occupations and outputs (shop, smithy, guild and adventuring among them), not only profession text.

NPCs must choose their path from the environment rather than follow a prescribed sequence of room points. The current bounded interior A* implementation computes routes from physical walls, furniture and doors; existing needs/routines still choose goals. This is local game AI, not a connected language model.

Current review adds four physical spaces, working internal doors, a fourth window for the rear bedroom, dining seats, storage/cooking objects and Blender-authored textiles/hearth. Two bounded size-dependent layouts and one/two place settings are checked. Children/schools/family graphs, diverse occupation-specific plans and jobs, cooking/fuel mechanics and full artistic acceptance are still open. Other city townhouse plans have not been replaced by this package.

## Settlement and landscape clarification, 22 October 2026

The owner explicitly requires coherent streets, squares, yards, gardens/flowerbeds, village fields/meadows/vegetable gardens, estates, barns and domestic livestock. Landscape must include mountains, valleys, rivers and lakes as a connected geography. Paths use stone paving, gravel and compacted earth according to purpose. The current road package joins existing houses to clear streets and fixes contact with physical ground; it does not establish completed settlement layout, farms, animals or concept-quality mountains. Existing anchors and user save identities remain protected.
