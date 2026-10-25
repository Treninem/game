# Blender source for the ImPuls house kit

Project-authored geometry, Blender 5.2:

- `TimberWindow.blend`: bevelled posts/rails, cross mullions, sill and apron,
  one separate glass plane. Default opening 1.35 x 1.15 metres.
- `RoomTimberwork.blend`: corner posts, knee braces, wall plates and ceiling
  ties for a 12 x 10 x 3.2 metre room.

Rebuild from repository root with Blender's background `--python` option using
`tools/build_interior_window.py` and `tools/build_house_timberwork.py`. Builders
write these editable sources and the GLBs under
`assets/production/interiors/architecture/`. The source directory is excluded
from Godot imports by `.gdignore`; the game uses the exported GLBs.

Runtime materials reuse the reviewed CC0 plank texture documented in
`assets/production/interiors/materials/SOURCE.md`; texture assignment is in
`scripts/enterable_building.gd`. No external brush libraries are required for
these meshes. Blender may warn about unused default brush material paths when
saving; they are not exported model dependencies.

Visual target and remaining scope: `docs/design/IMPULS_VISUAL_CONCEPT_2026-10-21.md`.

HouseholdProps.blend contains 19 normalized CC0 Quaternius derivatives, rebuilt by tools/build_household_props.py. Detailed selections and license: assets/production/interiors/architecture/HouseholdProps.SOURCE.md and HouseholdProps.LICENSE.txt.

HousePartition.blend and HouseLivingDetails.blend contain project-authored physical partition panels, arched hearth, pleated curtains, rounded bedding and woven rugs, built by the matching tools/build_house_partition.py and tools/build_house_living_details.py. Their geometry-only GLBs use shared reviewed materials in Godot. These are initial concept-led review assets; full visual acceptance remains open.
