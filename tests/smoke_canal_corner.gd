extends SceneTree
var life:Node3D
var trader:CharacterBody3D
var artisan:CharacterBody3D
var ready_time:=0
var escaped:=false
func _initialize()->void:call_deferred("_run")
func _run()->void:
    assert(load("res://tests/canal_checkpoint_fixture.gd").ensure_legacy_checkpoint(self))
    assert(root.get_node("SaveManager").prepare_load(5));change_scene_to_file("res://scenes/world_loading.tscn")
    var player:CharacterBody3D
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or not bool(current_scene.get("startup_state_ready")) or player.ground_guard_active:
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
    current_scene.set_process(false)
    life=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i(7,-1)].get_node("CanalHousehold")
    trader=life.get_node("CanalTrader");artisan=life.get_node("CanalFletcher")
    trader._leave_furniture();artisan._leave_furniture()
    # Explicit reconstruction of the actual CI-blocked pose. The full
    # no-position-assignment lifecycle remains an independent required gate.
    trader.position=Vector3(47.18457,.047286,-7.13916);trader.velocity=Vector3.ZERO
    root.get_node("GameState").world_minutes=18*60
    var deadline:=Time.get_ticks_msec()+60000;var trace:=Time.get_ticks_msec()+5000
    while trader.get_meta("activity","")!="sit":
        await physics_frame
        var navigation:=life.get_node("PublicSpaceNavigation")
        if navigation.grid_ready:
            if ready_time==0:ready_time=Time.get_ticks_msec()
            escaped=escaped or Vector2(trader.position.x-47.18457,trader.position.z+7.13916).length()>1.0
            assert(escaped or Time.get_ticks_msec()-ready_time<8000,"Resident remains pinned to the actual CI bridge bevel")
        assert(absf(trader.move_speed-1.45)<.0001 and trader.collision_mask==1)
        if Time.get_ticks_msec()>trace:
            trace=Time.get_ticks_msec()+5000
            var nav:=life.get_node("PublicSpaceNavigation")
            var seat:=trader.used_furniture as Node3D
            print("CORNER_TRACE local=",trader.position," velocity=",trader.velocity," phase=",trader.routine_phase," seat=",seat.name if seat!=null else "none"," ready=",nav.grid_ready)
            if seat!=null and nav.grid_ready:
                var target:Vector3=nav.next_point(trader.global_position,seat.approach_point(),trader)
                var point:=Vector2(target.x,target.z);var data:=preload("res://scripts/capital_canal_data.gd");var bridge:=data.bridge_at(point)
                var height:float=data.deck_height(point.x-bridge.x) if not is_inf(bridge.x) else root.get_node("WorldData").elevation_at(point)
                var actual:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.34;capsule.height=1.8;actual.shape=capsule;actual.exclude=[trader.get_rid(),artisan.get_rid(),player.get_rid()]
                actual.transform=Transform3D(Basis.IDENTITY,Vector3(target.x,height+.94,target.z))
                var hits:=trader.get_world_3d().direct_space_state.intersect_shape(actual,8)
                var names:Array=[]
                for hit:Dictionary in hits:names.append(String(hit.collider.name))
                print("CORNER_NEXT local=",life.to_local(target)," actual_foot_capsule_hits=",names," cached=",nav.routes.get(trader.get_instance_id(),{}))
            for index in range(trader.get_slide_collision_count()):print("CORNER_CONTACT ",trader.get_slide_collision(index).get_collider()," normal=",trader.get_slide_collision(index).get_normal())
        if Time.get_ticks_msec()>deadline:push_error("Actual CI bridge-corner pose cannot reach its free public seat");quit(1);return
    assert(escaped and trader.used_furniture.is_in_group("public_rest_furniture"))
    print("CANAL_CORNER_OK actual_CI_pose_fixture=true normal_walk=true escape_bound_s=8 independent_full_lifecycle_required=true local=",trader.position)
    quit(0)
