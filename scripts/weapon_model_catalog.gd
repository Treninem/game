extends RefCounted

# One model authority for the character's held weapon and inventory preview.
const SCENES := {
    "starter_axe": preload("res://assets/production/weapons/woodland/Axe_small.glb"),
    "stone_knife": preload("res://assets/production/weapons/woodland/Dagger.glb"),
    "short_bow": preload("res://assets/production/weapons/settler_equipment/Bow_Wooden.gltf")
}
const ARROW := preload("res://assets/production/weapons/settler_equipment/Arrow.gltf")

const ARROW_NOCK_Y := -0.343
const ARROW_TIP_Y := 0.350

static func flight_basis(heading: Vector3) -> Basis:
    var up := Vector3.FORWARD if absf(heading.dot(Vector3.UP)) > 0.999 else Vector3.UP
    return Basis.looking_at(heading, up)

static func scene_for(item_id: String) -> PackedScene:
    return ARROW if item_id == "arrow" else SCENES.get(item_id) as PackedScene
