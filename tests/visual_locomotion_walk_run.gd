extends SceneTree

var player: CharacterBody3D
var camera: Camera3D
var travelled := 0.0

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        var before := player.global_position
        await physics_frame
        travelled += before.distance_to(player.global_position)
        camera.global_position = player.global_position + Vector3(2.7, 1.3, -2.3)
        camera.look_at(player.global_position + Vector3.UP * 1.0)

func _capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://gait-" + label + ".png")

func _run() -> void:
    create_timer(90).timeout.connect(func(): push_error("GAIT_VISUAL timeout"); quit(1))
    root.size = Vector2i(1280, 720)
    var stage: Node = load("res://scenes/stage1.tscn").instantiate()
    player = stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    stage.free()
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var ground := StaticBody3D.new()
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(300, 1, 300)
    collision.shape = shape
    ground.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = shape.size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.23, 0.25, 0.23)
    mesh.material_override = material
    ground.add_child(mesh)
    ground.position.y = -0.5
    world.add_child(ground)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -30, 0)
    light.light_energy = 1.5
    world.add_child(light)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.27, 0.34, 0.43)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.85, 0.9, 1.0)
    environment.environment.ambient_light_energy = 0.65
    world.add_child(environment)
    world.add_child(player)
    # This isolated physical floor is not streamed overworld terrain.
    player.call("_set_instanced_world_mode", true)
    player.global_position = Vector3(0, 0.08, 0)
    camera = Camera3D.new()
    camera.fov = 43
    world.add_child(camera)
    camera.make_current()
    for sex: String in ["male", "female"]:
        var appearance = load("res://scripts/character_appearance.gd")
        var profile: Dictionary = appearance.normalized({"sex": sex})
        root.get_node("GameState").call("set_world_value", "player_appearance", profile)
        player.get_node("Avatar").call("apply_appearance", profile)
        await _frames(20)
        Input.action_press("move_forward")
        await _frames(50)
        await _capture(sex + "-walk")
        Input.action_press("sprint")
        await _frames(12)
        await _capture(sex + "-sprint-transition")
        await _frames(40)
        await _capture(sex + "-run")
        Input.action_release("sprint")
        await _frames(12)
        await _capture(sex + "-walk-transition")
        Input.action_release("move_forward")
        await _frames(20)
    assert(travelled > 15.0, "Fixture failed to exercise actual walking/running")
    print("GAIT_VISUAL_OK walked_m=", travelled, " bodies=2 normal_input=true")
    quit(0)
