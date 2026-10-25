ImPuls original Blender street kit,2026-10-24. CC0 1.0.

Source: assets/source/architecture/city_street/CityStreetKit.blend.
Production: assets/production/architecture/city_street/CityStreetKit.glb.
Three original modules,8880triangles total: chamfered paving with35mm outer ramp/39mm slab tops; hollow dressed-stone planted trough with real soil; tapered forged-iron lantern post with named Blender mounting marker. Existing production wall lantern, temperate bush and CottageYardKit flowers are reused at runtime; original upstream CC0 license/source records remain with those families. No new third-party pack or reference-image pixels are used.

Original fine-grained cut-stone albedo/OpenGLnormal/ORM maps are256px procedural Blender images, not scans. Mipmaps retained; normal and roughness maps enabled only atHigh/Ultra. Source image links are relative and all three maps are connected in Blender. Geometry/UV signature remains unchanged after material relinking. Godot exports named material factors rather than embedding duplicate textures.

Reproduction in a clean/private workspace: Blender --background --python-exit-code1 --python tools/author_city_stone_maps.py; then tools/build_city_street_kit.py; then tools/relink_city_street_source_maps.py. IMPULS_STREET_TREE selects a new private output folder (default portable). Existing output is protected against overwrite. Main integration reviews the result before promoting files.

INTEGRATED in the review branch only, not main.28paving panels,6planted troughs and4bounded medium+ street lights in one market square. Not20completed cities, full inhabited architecture or accepted concept/human artwork. See assets/registry/CITY_STREETSCAPE_2026-10-24.json.
