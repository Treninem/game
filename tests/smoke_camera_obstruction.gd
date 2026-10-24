extends Node3D
var failures: Array[String] = []

class ReachTarget extends StaticBody3D:
    var interactions := 0
    var hits := 0
    func interact(_player: Node) -> void:
        interactions += 1
    func take_damage(_amount: float, _source: Node) -> void:
        hits += 1

func _wall(position: Vector3, size: Vector3) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = position
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    add_child(body)
    return body

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var world := preload("res://scenes/stage1.tscn").instantiate()
    var player := world.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    world.free()
    var spawn := WorldGeography.START_SPAWN
    var height := WorldData.elevation_at(spawn)
    var origin := Vector3(spawn.x, height, spawn.y)
    _wall(origin + Vector3.DOWN * 0.5, Vector3(30, 1, 30))
    var back_wall := _wall(origin + Vector3(0, 2.5, 2.2), Vector3(12, 5, 0.3))
    add_child(player)
    player.global_position = origin + Vector3.UP * 0.08
    player.rotation.y = 0
    player.call("_begin_ground_guard", true)
    var pivot := player.get_node("CameraPivot") as Node3D
    pivot.rotation = Vector3.ZERO
    var camera := pivot.get_node("Camera3D") as Camera3D
    SettingsManager.set_camera_distance(5.5)
    for frame in range(90):
        await get_tree().physics_frame
    if camera.position.z > 1.80 or camera.position.z < 1.2:
        failures.append("Camera clips through the rear wall or collapses unnecessarily: %f" % camera.position.z)
    player.rotation.y = PI * 0.5
    for frame in range(90):
        await get_tree().physics_frame
    if camera.position.z < 5.4:
        failures.append("Camera does not return to its distance after turning away from a wall")
    var side_wall := _wall(origin + Vector3(2.3, 2.5, 0), Vector3(0.12, 5, 12))
    for frame in range(3):
        await get_tree().physics_frame
    if camera.position.z > 1.96:
        failures.append("Camera crosses a thin wall during a turn")
    # Overlap the camera sphere without pushing the player's capsule sideways.
    var before_overlap := player.global_position
    var near_wall := _wall(origin + Vector3(0, 2.08, 0), Vector3(12, 0.04, 12))
    for frame in range(3):
        await get_tree().physics_frame
    if camera.position.z > 0.01:
        failures.append("Camera ignores a wall overlapping the cast origin")
    if player.global_position.distance_to(before_overlap) > 0.03:
        failures.append("Overlapping-origin fixture unexpectedly moved the player")
    near_wall.queue_free()
    side_wall.queue_free()
    back_wall.queue_free()
    await get_tree().process_frame
    for frame in range(3):
        await get_tree().physics_frame
    if camera.position.z <= 0 or camera.position.z >= 5.4:
        failures.append("Camera return after obstruction is not smooth")
    SettingsManager.set_camera_distance(100)
    SettingsManager.load_settings()
    if float(SettingsManager.get_value("gameplay", "camera_distance")) != 9.0:
        failures.append("Camera zoom is not clamped and persisted")
    SettingsManager.set_camera_distance(-10)
    if float(SettingsManager.get_value("gameplay", "camera_distance")) != 2.0:
        failures.append("Camera minimum zoom is not clamped")
    SettingsManager.set_camera_distance(5.5)
    await _check_reach(player, pivot, camera)
    if failures.is_empty():
        print("CAMERA_OBSTRUCTION_OK walls=solid thin_wall=safe overlapping_origin=safe recovery=smooth zoom=persisted reach=bounded melee=no_back_hits no_wall_reach=true")
    for failure in failures:
        push_error(failure)
    get_tree().quit(0 if failures.is_empty() else 1)

func _check_reach(player: CharacterBody3D, pivot: Node3D, camera: Camera3D) -> void:
    player.rotation = Vector3.ZERO
    pivot.rotation = Vector3.ZERO
    var target := ReachTarget.new()
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.8, 3, 0.3)
    collision.shape = shape
    target.add_child(collision)
    add_child(target)
    target.global_position = player.global_position + Vector3(0, 1.1, -1.6)
    var ray := camera.get_node("InteractionRay") as RayCast3D
    for distance: float in [2.0, 9.0]:
        SettingsManager.set_camera_distance(distance)
        for frame in range(90):
            await get_tree().physics_frame
        ray.force_raycast_update()
        player.call("_try_interact")
        player.attack_elapsed = 0
        GameState.stamina = 100
        player.call("_try_attack")
    if target.interactions != 2 or target.hits != 2:
        failures.append("Near interaction/melee breaks with zoom: interactions=%d hits=%d" % [target.interactions, target.hits])
    var blocker := _wall(player.global_position + Vector3(0, 0.85, -0.7), Vector3(3, 1.7, 0.1))
    for frame in range(3):
        await get_tree().physics_frame
    ray.force_raycast_update()
    if ray.get_collider() != target:
        failures.append("Reach fixture must let the camera see over the chest-high wall")
    player.call("_try_interact")
    player.attack_elapsed = 0
    player.call("_try_attack")
    if target.interactions != 2 or target.hits != 2:
        failures.append("Camera view permits reaching or striking through a wall")
    blocker.queue_free()
    await get_tree().process_frame
    target.global_position = player.global_position + Vector3(0, 1.1, -6)
    for frame in range(3):
        await get_tree().physics_frame
    ray.target_position = Vector3(0, 0, -30)
    ray.force_raycast_update()
    player.call("_try_interact")
    if target.interactions != 2:
        failures.append("Zoom increases the hero's physical interaction range")
    target.global_position = player.global_position + Vector3(0, 1.1, 1.6)
    for frame in range(3):
        await get_tree().physics_frame
    # Reproduce the previous third-person ray selecting someone behind the hero.
    camera.position.z = 5.5
    ray.target_position = Vector3(0, 0, -10)
    ray.force_raycast_update()
    if ray.get_collider() != target:
        failures.append("Behind-target regression fixture did not select its target")
    player.attack_elapsed = 0
    player.call("_try_attack")
    player.call("_try_interact")
    if target.interactions != 2 or target.hits != 2:
        failures.append("Third-person ray hits a target behind the hero")
    SettingsManager.set_camera_distance(5.5)
