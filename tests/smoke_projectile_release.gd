extends SceneTree

func _initialize() -> void:call_deferred("_run")

func _run() -> void:
    create_timer(150).timeout.connect(func():push_error("Projectile release fixture timed out");quit(1))
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var state := root.get_node("GameState")
    assert(load("res://tests/visual_bow_world.gd") != null, "Native world observer failed to compile")
    state.call("reset_new_game")
    var fixture = load("res://tests/physical_human_fixture.gd")
    fixture.add_floor(world)
    var actor := fixture.player(world, Vector3(0, 0.08, 0)) as CharacterBody3D
    for i in range(25):await physics_frame
    assert(actor.is_on_floor())
    state.call("add_item", "short_bow", 1)
    state.call("add_item", "arrow", 5)
    assert(root.get_node("InventorySystem").call("equip", "short_bow"))
    for i in range(20):await process_frame
    # Deliberate transform edits isolate the contract between rendered poses
    # and later physics ticks. This is a unit fixture, not a gameplay journey.
    actor.set_physics_process(false)
    var visual := actor.get_node("Avatar") as Node3D
    visual.set_process(false)
    var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var animator: AnimationPlayer = visual.get("animation_player")
    actor.call("_try_shoot")
    assert(animator.assigned_animation == "Bow_Attack_Draw", "Accepted draw waited for a later render to start")
    animator.play("Bow_Attack_Draw")
    animator.advance(0.1)
    skeleton.advance(0.0)
    # One corrected pose, then several physics transforms with NO render in
    # between. Re-deriving a local point from the old world point on each
    # transform would make the oracle stale in exactly the way we are testing.
    var old_point: Vector3 = visual.get("last_draw_point")
    var local_point := actor.to_local(old_point)
    assert(local_point.length() > 0.2 and local_point.length() < 2.5)
    var maximum_error := 0.0
    for scenario: Vector4 in [Vector4(0, 0.9, -0.7, 0), Vector4(1.2, 0, 0, PI * 0.5), Vector4(-0.6, 0.5, 0.8, -PI * 0.4)]:
        actor.set("attack_elapsed", 0.0)
        state.set("stamina", 100.0)
        actor.call("_try_shoot")
        assert(animator.assigned_animation == "Bow_Attack_Draw")
        actor.global_position += Vector3(scenario.x, scenario.y, scenario.z)
        actor.rotation.y += scenario.w
        var expected := actor.to_global(local_point)
        var predicted: Vector3 = visual.call("arrow_release_point")
        assert(expected.distance_to(old_point) > 0.3)
        var arrows_before := int(state.get("inventory").get("arrow", 0))
        actor.call("_update_bow_shot", 0.23)
        assert(animator.assigned_animation == "Bow_Attack_Shoot", "Actual release did not start its pose immediately")
        assert(int(state.get("inventory").get("arrow", 0)) == arrows_before - 1)
        var arrow: Node3D
        for candidate in get_nodes_in_group("weapon_projectile"):
            if not candidate.is_queued_for_deletion():arrow = candidate
        assert(arrow != null, "Real controller did not create a projectile")
        var error := arrow.global_position.distance_to(expected)
        print("PROJECTILE_RELEASE_SAMPLE ", JSON.stringify({"scenario":str(scenario),"local":str(local_point),"predicted":str(predicted),"expected":str(expected),"actual":str(arrow.global_position),"hand_radius":predicted.distance_to(actor.global_position),"error":error}))
        maximum_error = maxf(maximum_error, error)
        assert(error < 0.0001, "Arrow left the old world-space pose instead of the moving hand: error=" + str(error))
        arrow.queue_free()
    root.get_node("InventorySystem").call("unequip", "weapon")
    visual.call("_refresh_weapon")
    assert(not (visual.call("arrow_release_point") as Vector3).is_finite(), "Unequipped bow retained a valid stale release point")
    actor.set("attack_elapsed", 0.0)
    state.set("stamina", 100.0)
    actor.call("_try_attack")
    assert(animator.assigned_animation == "Punch", "Accepted punch waited for another render")
    actor.call("_on_spell_cast", "heal")
    assert(animator.assigned_animation == "Cast_Left")
    assert(root.get_node("InventorySystem").call("equip", "short_bow"))
    visual.call("_refresh_weapon")
    actor.call("_on_spell_cast", "heal")
    assert(animator.assigned_animation == "Cast_Right")
    print("ACTION_POSE_START_OK draw=true release=true punch=true cast_left=true cast_right=true event_synchronous=true")
    print("PROJECTILE_RELEASE_OK transformed_cases=3 maximum_error_m=", maximum_error, " actual_controller=true actual_projectile=true transform_unit_fixture=true")
    world.queue_free()
    await process_frame
    quit()
