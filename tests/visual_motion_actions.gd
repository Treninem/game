extends SceneTree

var player: CharacterBody3D
var camera: Camera3D
var travelled := 0.0
var observations := []
var final_pose := {}
var observed_modifier: Node

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int) -> void:
    for frame in range(count):
        _watch_final_pose()
        var before := player.global_position
        await physics_frame
        travelled += before.distance_to(player.global_position)
        camera.global_position = player.global_position + Vector3(3.4, 1.25, -0.6)
        camera.look_at(player.global_position + Vector3.UP * 1.0)

func _capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    observations.append({"label":label,"clip":player.get_node("Avatar").get("animation_player").assigned_animation,"rate":player.get_node("Avatar").get("animation_player").speed_scale,"grounded":player.is_on_floor(),"velocity":str(player.velocity),"final_pose":final_pose.duplicate(true)})
    root.get_texture().get_image().save_png("user://gait-" + label + ".png")

func _run() -> void:
    create_timer(150).timeout.connect(func(): push_error("GAIT_VISUAL timeout"); quit(1))
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
    camera.fov = 44
    world.add_child(camera)
    camera.make_current()
    for sex: String in ["male", "female"]:
        var appearance = load("res://scripts/character_appearance.gd")
        var profile: Dictionary = appearance.normalized({"sex": sex})
        root.get_node("GameState").call("set_world_value", "player_appearance", profile)
        player.get_node("Avatar").call("apply_appearance", profile)
        await _frames(20)
        var normal_walk: float = player.get("walk_speed")
        player.set("walk_speed", 1.8)
        Input.action_press("move_forward")
        for phase in range(4):
            await _frames(8)
            await _capture(sex + "-slow-walk-" + str(phase))
        player.set("walk_speed", normal_walk)
        for phase in range(4):
            await _frames(8)
            await _capture(sex + "-normal-move-" + str(phase))
        Input.action_press("sprint")
        for phase in range(4):
            await _frames(8)
            await _capture(sex + "-run-" + str(phase))
        Input.action_release("sprint")
        await _event("jump")
        for phase in range(4):
            await _frames(10)
            await _capture(sex + "-jump-" + str(phase))
        for side: String in ["Left", "Right"]:
            var apex: Dictionary = observations[observations.size() - 3].final_pose
            var descent: Dictionary = observations[observations.size() - 2].final_pose
            assert(float(apex.get(side, 0.0)) > 55.0, "Rendered jump stayed in locomotion at apex")
            assert(float(apex[side]) > float(descent.get(side, 180.0)) + 10.0, "Rendered jump does not extend on descent")
        Input.action_release("move_forward")
        await _frames(30)
        assert(player.is_on_floor())
        var state := root.get_node("GameState")
        var inventory := root.get_node("InventorySystem")
        for item in ["starter_axe", ""]:
            if item != "":
                state.call("add_item", item, 1)
                inventory.call("equip", item)
            else:
                inventory.call("unequip", "weapon")
            await _frames(35)
            if item != "":
                Input.action_press("move_forward")
                await _frames(12)
            await _event("attack")
            for phase in range(4):
                await _frames(6)
                await _capture(sex + "-" + ("axe" if item != "" else "punch") + "-" + str(phase))
            Input.action_release("move_forward")
        inventory.call("unequip", "weapon")
        await _frames(30)
    assert(travelled > 15.0, "Fixture failed to exercise actual walking/running")
    print("MOTION_ACTIONS_OK walked_m=", travelled, " bodies=2 normal_input=true")
    var file := FileAccess.open("user://motion-actions.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(observations))
    file.close()
    quit(0)

func _event(action: String) -> void:
    var event := InputEventAction.new()
    event.action = action
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    await physics_frame
    event = InputEventAction.new()
    event.action = action
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _watch_final_pose() -> void:
    var visual := player.get_node("Avatar")
    var modifier: Node = visual.get("grip_modifier")
    if is_instance_valid(observed_modifier) and observed_modifier == modifier:
        return
    observed_modifier = modifier
    final_pose.clear()
    var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    modifier.modification_processed.connect(func():
        for side: String in ["Left", "Right"]:
            var hip := skeleton.get_bone_global_pose(skeleton.find_bone(side + "UpLeg")).origin
            var knee := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Leg")).origin
            var ankle := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Foot")).origin
            final_pose[side] = rad_to_deg((knee - hip).angle_to(ankle - knee))
    )
