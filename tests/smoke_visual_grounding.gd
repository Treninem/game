extends Node

var errors: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    get_tree().root.add_child(world)
    get_tree().current_scene = world
    for _i in range(120):
        await get_tree().physics_frame
    var player := world.get_node("World/Player") as CharacterBody3D
    var avatar := player.get_node("Avatar")
    var human := avatar.get_node_or_null("HumanModel") as Node3D
    if human == null or human.find_children("*", "Skeleton3D", true, false).is_empty():
        errors.append("Avatar is missing its authored, skinned human model")
    if human != null:
        var anatomical := human.find_children("AnatomicalHuman", "MeshInstance3D", true, false)
        if anatomical.is_empty() or (anatomical[0] as MeshInstance3D).skin == null:
            errors.append("Selected anatomical human mesh is not connected to the live skeleton")
    if human != null and absf(absf(human.rotation.y) - PI) > 0.01:
        errors.append("Imported human is facing backward relative to walking direction")
    var animation_player := avatar.get("animation_player") as AnimationPlayer
    for key in ["Idle", "Walk", "Run", "Airborne", "Punch"]:
        if animation_player == null or not animation_player.has_animation(key):
            errors.append("Human animation is missing: " + key)
    var support := world.get_node("World/StoryStartSurface") as StaticBody3D
    if support.collision_layer != 0:
        errors.append("Invisible flat spawn support still overrides real terrain")
    _check_ground_gap(player)
    Input.action_press("move_forward")
    for _i in range(45):
        await get_tree().physics_frame
    Input.action_release("move_forward")
    _check_ground_gap(player)
    if String(avatar.get("active_animation")) != "Walk":
        errors.append("Human does not enter its walking animation when moving")
    for _i in range(20):
        await get_tree().physics_frame
    var jump := InputEventKey.new()
    jump.physical_keycode = KEY_SPACE
    jump.pressed = true
    player.call("_unhandled_input", jump)
    for _i in range(8):
        await get_tree().physics_frame
    if player.is_on_floor() or String(avatar.get("active_animation")) != "Airborne":
        errors.append("Human jump is not physical or does not use its airborne pose")
    for _i in range(90):
        await get_tree().physics_frame
    _check_ground_gap(player)
    var region := world.get_node("World/StartRegion")
    for water: MeshInstance3D in region.get_node("StartRiver").get_children():
        if not water.mesh is ArrayMesh:
            errors.append("River still uses box-shaped water geometry")
            break
        var vertices: PackedVector3Array = water.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
        for vertex in vertices:
            var distance_to_center := absf(vertex.x - WorldGeography.start_river_x(vertex.z))
            if absf(distance_to_center - WorldGeography.START_RIVER_HALF_WIDTH) > 0.01:
                errors.append("River edge no longer follows its carved channel")
                break
    for z in [-500.0, 0.0, 300.0]:
        var edge := Vector2(WorldGeography.start_river_x(z) + WorldGeography.START_RIVER_HALF_WIDTH, z)
        if absf(WorldData.elevation_at(edge) - WorldGeography.START_RIVER_WATER_LEVEL) > 0.12:
            errors.append("River surface edge floats above or below the bank")
    if errors.is_empty():
        print("VISUAL_GROUNDING_SMOKE_OK human=skinned animations=responsive feet=grounded spawn_support=retired water=curved shore=joined")
    else:
        for error in errors:
            push_error(error)
    world.queue_free()
    await get_tree().create_timer(0.1).timeout
    get_tree().quit(0 if errors.is_empty() else 1)

func _check_ground_gap(player: CharacterBody3D) -> void:
    var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, player.global_position + Vector3.DOWN * 3.0)
    query.exclude = [player.get_rid()]
    var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        errors.append("No physical ground below the walking human")
        return
    var point: Vector3 = hit["position"]
    if not player.is_on_floor() or absf(player.global_position.y - point.y) > 0.12:
        errors.append("Human walks above the ground: gap=%.3f" % (player.global_position.y - point.y))
