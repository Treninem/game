# Starter equipment source review

Four new meshes authored in Blender5.2: a continuous curved ash axe haft with a hollow forged eye and sharpened steel head, a closed flaked-stone knife with a wrapped handle, a continuous tapered bow with horn nocks and three Draw morph meshes, and a70cm arrow with three curved opaque feather vanes and an open string nock.

This is editable source, not an accepted production replacement. The live catalog still uses the previous woodland set. Do not feed these new bow meshes through the old triangle-stripping string routine: it destroys their imported morphs. Runtime string endpoints must follow both moving horn nocks; the new arrow nock seat is-.343m and its tip+.350m. The authored palm anchors preserve the existing three grip coordinates in metres.

Open SettlerEquipment.blend to edit all four objects. The master packs the five selected images and lays out its four object roots for inspection; per-object glTF exports were made before these layout offsets. Run author_equipment.py in background Blender with IMPULS_WEAPON_OUTPUT pointing to an isolated folder under the repository's build directory. It intentionally does not overwrite production assets or normal Blender preferences.

Geometry and authoring code are project-authored CC0. Texture files are unchanged copies of verified physical CC0 sources: Simple Textures cedar/leather (https://opengameart.org/content/simple-textures), and a52/rubberduck PBR Industrial Asset Pack scratched steel color/normal/roughness (https://opengameart.org/content/pbr-industrial-asset-pack). Their original source/license metadata is retained under licenses/. Shared external textures are stored once; glTF is the only production interchange candidate. The native .blend master is retained for editing.

Godot4.7.1 GL Compatibility on Intel UHD610 rendered four matched before/after models, four oblique views and the full bow flex. Source images contain explicit mip levels in the isolated reviewer. These are deliberately forced offscreen asset captures, not ordinary gameplay, performance evidence or complete-character approval. Review frames are under docs/review/2026-10-24-starter-equipment-source/.

Before production: improve the knife flake and handle treatment further; validate the complete bow limb/string/nock coupling, both human bodies and supported heights, action transitions, fletcher/market displays, projectiles, inventory, crafting and disk restoration. Static isolated model renders do not satisfy those gates. No rarity/upgrade/repair system or whole-world art completion is claimed.
