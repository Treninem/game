extends RefCounted

var failures: Array[String] = []
var checked := 0
var worst_penetration := 0.0
var worst_support_gap := 0.0
var costs: Array[int] = []

func run(parent: Node3D) -> Array[String]:
    var tree := parent.get_tree()
    var floor_body := StaticBody3D.new()
    floor_body.position = Vector3(60, -0.5, 0)
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(8, 1, 8)
    collision.shape = box
    floor_body.add_child(collision)
    parent.add_child(floor_body)
    var step := StaticBody3D.new()
    step.position = Vector3(60.6, 0.11, 0)
    var step_collision := CollisionShape3D.new()
    var step_box := BoxShape3D.new()
    step_box.size = Vector3(1.2, 0.22, 4)
    step_collision.shape = step_box
    step.add_child(step_collision)
    parent.add_child(step)
    step.collision_layer = 0
    var stage := load("res://scenes/stage1.tscn").instantiate() as Node
    var player := stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    stage.free()
    player.set_physics_process(false)
    player.set_process_input(false)
    parent.add_child(player)
    player.set_physics_process(false)
    assert(not player.is_physics_processing())
    player.call("_set_instanced_world_mode", true)
    player.rotation = Vector3.ZERO
    var visual := player.get_node("Avatar") as Node3D
    visual.set_process(false)
    var probe := preload("res://tests/humanoid_skin_probe.gd").new()
    for sex: String in ["male", "female"]:
        for height: float in [160.0, 180.0, 195.0, 200.0]:
            var profile := {"sex":sex, "height_cm":height, "Build":-0.5 if height == 160.0 else (0.5 if height == 195.0 else 0.0)}
            GameState.set_world_value("player_appearance", profile)
            visual.call("apply_appearance", profile)
            visual.set("appearance_revision", GameState.state_revision)
            var animator: AnimationPlayer = visual.get("animation_player")
            var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
            var modifier: Node = visual.get("grip_modifier")
            var data := {"capture":false}
            modifier.modification_processed.connect(func():
                if data.capture:
                    data.capture = false
                    data.points = probe.points(visual, skeleton)
            )
            for terrain: String in ["ledge_left", "ledge_right"]:
                floor_body.rotation = Vector3.ZERO
                floor_body.position.x = 56.0 if terrain == "ledge_left" else 64.0
                step.collision_layer = 1 if terrain == "step" else 0
                if terrain == "cross_slope":
                    floor_body.rotation.z = deg_to_rad(12.0)
                elif terrain == "ramp":
                    floor_body.rotation.x = deg_to_rad(20.0)
                player.position = Vector3(59.98 if terrain == "ledge_left" else 60.02, 0.9, 0)
                for frame in range(18):
                    await tree.physics_frame
                    player.velocity = Vector3.DOWN * 5.0
                    player.move_and_slide()
                if not player.is_on_floor():
                    failures.append("Support fixture did not acquire floor: " + terrain)
                    continue
                player.velocity = Vector3.ZERO
                if terrain == "flat":
                    # First frame of a newly attached grounding modifier must
                    # already support the sole, before temporal settling.
                    modifier.set("support", preload("res://scripts/humanoid_grounding.gd").new())
                    animator.play("Idle", 0.0)
                    animator.seek(0.0, true)
                    animator.pause()
                    data.erase("points")
                    data.capture = true
                    skeleton.advance(1.0 / 60.0)
                    await tree.process_frame
                    var first := INF
                    for side: String in ["Left", "Right"]:
                        for point: Vector3 in data.get("points", {}).get(side, PackedVector3Array()):
                            first = minf(first, point.y)
                    if first < -0.015 or first > 0.020:
                        failures.append("First rendered support frame floats: %s/%s gap=%s" % [sex, height, first])
                for clip: String in ["Walk"]:
                    InventorySystem.unequip("weapon")
                    var item := "starter_axe" if clip == "Axe_Chop" else ("short_bow" if clip == "Bow_Attack_Draw" else "")
                    if item != "":
                        GameState.add_item(item, 1)
                        InventorySystem.equip(item)
                    for phase: float in [0.25, 0.75]:
                        animator.play(clip, 0.0)
                        animator.seek(animator.get_animation(clip).length * phase, true)
                        animator.pause()
                        for frame in range(6):
                            skeleton.advance(1.0 / 60.0)
                            await tree.process_frame
                        data.erase("points")
                        data.capture = true
                        skeleton.advance(1.0 / 60.0)
                        await tree.process_frame
                        var points: Dictionary = data.get("points", {})
                        if points.is_empty():
                            failures.append("Missing final skinned support snapshot")
                            continue
                        var lowest := INF
                        for side: String in ["Left", "Right"]:
                            for point: Vector3 in points[side]:
                                if (terrain == "ledge_left" and point.x > 60.0) or (terrain == "ledge_right" and point.x < 60.0):
                                    continue
                                lowest = minf(lowest, point.y - _height(point, terrain))
                        worst_penetration = minf(worst_penetration, lowest)
                        worst_support_gap = maxf(worst_support_gap, lowest)
                        if lowest < -0.015 or lowest > 0.020:
                            failures.append("Skinned sole misses physical surface: %s/%s/%s/%s/%s gap=%.5f" % [sex, height, terrain, clip, phase, lowest])
                        var support: RefCounted = modifier.get("support")
                        costs.append(int(support.get("last_cost_usec")))
                        checked += 1
    InventorySystem.unequip("weapon")
    player.queue_free()
    floor_body.queue_free()
    step.queue_free()
    await tree.process_frame
    costs.sort()
    print("HUMANOID_EDGE_CHECKED poses=",checked," bodies=2 heights=4 ledge_sides=2 actions=1 phases=2 all_boot_vertices=true min_gap=",worst_penetration," max_gap=",worst_support_gap," modifier_p95_usec=",costs[int(costs.size()*0.95)] if not costs.is_empty() else -1)
    return failures

func _height(point: Vector3, terrain: String) -> float:
    if terrain == "step":
        return 0.22 if point.x >= 60.0 else 0.0
    if terrain == "cross_slope":
        return 0.5 / cos(deg_to_rad(12.0)) - 0.5 + tan(deg_to_rad(12.0)) * (point.x - 60.0)
    if terrain == "ramp":
        return 0.5 / cos(deg_to_rad(20.0)) - 0.5 - tan(deg_to_rad(20.0)) * point.z
    return 0.0
