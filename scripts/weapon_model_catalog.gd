extends RefCounted

# One model authority for the character's held weapon and inventory preview.
const SCENES := {
    "starter_axe": preload("res://assets/production/weapons/woodland/Axe_small.glb"),
    "stone_knife": preload("res://assets/production/weapons/woodland/Dagger.glb"),
    "short_bow": preload("res://assets/production/weapons/woodland/Bow_Wooden.glb")
}
const ARROW := preload("res://assets/production/weapons/woodland/Arrow.glb")

static func scene_for(item_id: String) -> PackedScene:
    return ARROW if item_id == "arrow" else SCENES.get(item_id) as PackedScene
