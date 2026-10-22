extends RefCounted

# Lightweight physical-player harness. Uses the real controller, visual and
# camera scripts/child hierarchy from stage1, without loading unrelated cities.
# Its flat floor is test geometry, not a substitute for the actual game world.
static func add_floor(world: Node3D) -> void:
    var floor_body := StaticBody3D.new()
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(160, 1, 160)
    collider.shape = shape
    floor_body.add_child(collider)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = shape.size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.24, 0.29, 0.25)
    material.roughness = 0.95
    mesh.material_override = material
    floor_body.add_child(mesh)
    floor_body.position.y = -0.5
    world.add_child(floor_body)

static func player(parent: Node3D, position: Vector3) -> CharacterBody3D:
    # Load after SceneTree autoload initialization. Preloading this controller
    # while compiling a --script harness cannot resolve SettingsManager yet.
    var actor := load("res://scripts/player_controller.gd").new() as CharacterBody3D
    actor.name = "Player"
    actor.position = position
    var collider := CollisionShape3D.new()
    collider.name = "CollisionShape3D"
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    collider.shape = capsule
    collider.position.y = 0.9
    actor.add_child(collider)
    var avatar := load("res://scripts/humanoid_visual.gd").new() as Node3D
    avatar.name = "Avatar"
    actor.add_child(avatar)
    var pivot := load("res://scripts/third_person_camera.gd").new() as Node3D
    pivot.name = "CameraPivot"
    pivot.position.y = 1.35
    var camera := Camera3D.new()
    camera.name = "Camera3D"
    camera.position = Vector3(0, 0.55, 5.5)
    camera.far = 1100
    camera.near = 0.08
    var ray := RayCast3D.new()
    ray.name = "InteractionRay"
    ray.target_position = Vector3(0, 0, -7)
    ray.collide_with_areas = true
    camera.add_child(ray)
    pivot.add_child(camera)
    actor.add_child(pivot)
    parent.add_child(actor)
    actor.call("_set_instanced_world_mode", true)
    # _ready initially enters the controller's overworld surface guard. Set
    # the fixture spawn only after switching to this physical interior floor.
    actor.position = position
    actor.velocity = Vector3.ZERO
    return actor
