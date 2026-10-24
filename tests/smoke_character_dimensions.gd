extends Node3D

var failures: Array[String] = []
const APPEARANCE := preload("res://scripts/character_appearance.gd")

func _ready() -> void:
    call_deferred("_run")

func _box(at: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    body.add_child(collider)
    add_child(body)

func _run() -> void:
    var before := GameState.snapshot()
    GameState.set_world_value("player_appearance", APPEARANCE.preset(0))
    var world := preload("res://scenes/stage1.tscn").instantiate()
    var player := world.get_node("World/Player") as CharacterBody3D
    var original_shape := (player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
    player.get_parent().remove_child(player)
    world.free()
    var spawn := WorldGeography.START_SPAWN
    var origin := Vector3(spawn.x, WorldData.elevation_at(spawn), spawn.y)
    _box(origin + Vector3(0, -0.5, 0), Vector3(20, 1, 20))
    _box(origin + Vector3(3, 2.05, 0), Vector3(2, 0.4, 6))
    add_child(player)
    player.set_physics_process(false)
    player.set_process_input(false)
    player.global_position = origin + Vector3.UP * 0.08
    var visual := player.get_node("Avatar")
    visual.set_process(false)
    var collider := player.get_node("CollisionShape3D") as CollisionShape3D
    var base_position := player.global_position
    for height in [160.0, 195.0, 200.0, 180.0]:
        var profile := APPEARANCE.preset(0)
        profile.height_cm = height
        visual.call("apply_appearance", profile)
        for frame in range(3):
            await get_tree().physics_frame
        var capsule := collider.shape as CapsuleShape3D
        if not is_equal_approx(capsule.height, height / 100.0):
            failures.append("Physical capsule does not match selected height")
        if not is_zero_approx(collider.position.y - capsule.height * 0.5) or player.global_position.distance_to(base_position) > 0.0001:
            failures.append("Height adjustment displaced the feet/root")
        if not is_equal_approx((player.get_node("CameraPivot") as Node3D).position.y, 1.35 * height / 180.0):
            failures.append("Camera pivot does not follow height or accumulates scaling")
        if not player.test_move(player.global_transform, Vector3.DOWN * 0.2):
            failures.append("Feet capsule does not find its actual floor")
        var hits_low_roof := player.test_move(player.global_transform, Vector3(3, 0, 0))
        if hits_low_roof != (height > 177.0):
            failures.append("Physical low passage ignores height: %s hits=%s" % [height, hits_low_roof])
    if collider.shape == original_shape or not is_equal_approx(original_shape.height, 1.8):
        failures.append("Resizing one actor modified the shared scene capsule")
    # Ordinary2.2m doors must pass both extremes. A1.85m low beam still
    # blocks the tall actor; these two volumes are deliberately separate.
    _box(origin+Vector3(-3,2.4,0),Vector3(1,.4,6))
    for height:float in [160,200]:
        visual.call("apply_appearance",{"height_cm":height})
        for frame in range(3):await get_tree().physics_frame
        if player.test_move(player.global_transform,Vector3(-3,0,0)):
            failures.append("Ordinary2.2m passage blocks selected height: "+str(height))
    for sex:String in ["male","female"]:
        for height:float in [160,180,195,200]:
            var identity:="stature-fixture:"+sex+str(height)
            GameState.set_world_value("appearance:"+identity,{"sex":sex,"height_cm":height})
            var npc:CharacterBody3D=load("res://scripts/settlement_npc.gd").new()
            npc.set_meta("citizen_id",identity);npc.body_sex=sex
            npc.position=origin+Vector3(0,.08,6)
            add_child(npc);npc.set_physics_process(false)
            var npc_shape:=npc.get_node("CollisionShape3D") as CollisionShape3D
            var npc_capsule:=npc_shape.shape as CapsuleShape3D
            if absf(npc_capsule.height-height/100.0)>.00001 or absf(npc_shape.position.y-height/200.0)>.00001:
                failures.append("Citizen physics do not match stature: "+identity)
            if absf(npc.get_node("Visual").scale.y-height/180.0)>.00001:
                failures.append("Citizen model and collision disagree: "+identity)
            npc.queue_free();await get_tree().process_frame
    var home:Node3D=load("res://scripts/enterable_building.gd").new()
    home.configure(Vector3(12,3.2,10));home.position=origin+Vector3(-30,0,0);add_child(home)
    assert(absf(float(home.doorway_height)-float(home.floor_thickness)-2.20)<.0001)
    assert(is_equal_approx(float(home.doorway_width),1.20))
    for height:float in [160,180,200]:
        visual.call("apply_appearance",{"height_cm":height})
        var passage:=player.global_transform;passage.origin=home.global_position+Vector3(0,float(home.floor_thickness)+.04,6)
        home.front_door.set_open(false,true)
        for frame in range(3):await get_tree().physics_frame
        if not player.test_move(passage,Vector3(0,0,-2)):failures.append("Closed real home door has no collision")
        home.front_door.set_open(true,true)
        for frame in range(3):await get_tree().physics_frame
        if player.test_move(passage,Vector3(0,0,-2)):failures.append("Real1.2m by2.2m clear home door blocks height "+str(height))
    home.queue_free();await get_tree().process_frame
    var profile:=APPEARANCE.normalized({"height_cm":200.0})
    GameState.set_world_value("player_appearance",profile)
    if not SaveManager.save_game(player,10):failures.append("Cannot save2m character")
    GameState.set_world_value("player_appearance",APPEARANCE.preset(0))
    if not SaveManager.load_game(player,10) or float(GameState.get_world_value("player_appearance",{}).get("height_cm",0))!=200.0:
        failures.append("Disk round trip lost2m stature")
    player.queue_free()
    await get_tree().process_frame
    GameState.load_snapshot(before)
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("CHARACTER_DIMENSIONS_OK heights=160,195,200,180 grounded_root=stable low_roof=physical camera=scaled shared_shape=isolated")
    get_tree().quit(0 if failures.is_empty() else 1)
