extends Node

# One decision owns both meshes. Independent visibility ranges can disagree
# because smoothing changes their AABB centers, leaving a gap or two bodies.
const NEAR_ENTER := 7.0
const FAR_ENTER := 9.0
const INTERVAL := 0.12
var near_body: MeshInstance3D
var far_body: MeshInstance3D
var visual: Node3D
var near_selected := true
var remaining := 0.0

func configure(owner_visual: Node3D) -> void:
    visual = owner_visual
    var model := visual.get("model") as Node3D
    near_body = model.find_child("HumanBody", true, false) as MeshInstance3D
    far_body = model.find_child("HumanBodyFar", true, false) as MeshInstance3D
    near_selected = true
    remaining = 0.0
    set_process(is_instance_valid(far_body) and is_instance_valid(near_body))
    if is_instance_valid(far_body) and is_instance_valid(near_body):
        near_body.visible = true
        far_body.visible = false

func _process(delta: float) -> void:
    # HumanoidVisual stops its animation-selection process after death and in
    # some inspection tools. Distance selection must still follow the camera.
    update(delta)

func update(delta: float) -> void:
    if not is_instance_valid(near_body) or not is_instance_valid(far_body) or not visual.is_visible_in_tree(): return
    remaining -= delta
    if remaining > 0.0: return
    remaining = INTERVAL
    var camera := visual.get_viewport().get_camera_3d()
    if camera == null: return
    var distance := camera.global_position.distance_to(visual.global_position + Vector3.UP * visual.global_basis.get_scale().y * 0.95)
    var selected := near_selected
    if near_selected and distance > FAR_ENTER: selected = false
    elif not near_selected and distance < NEAR_ENTER: selected = true
    if selected != near_selected:
        near_selected = selected
        near_body.visible = near_selected
        far_body.visible = not near_selected
