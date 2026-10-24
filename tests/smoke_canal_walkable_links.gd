extends SceneTree
const DATA:=preload("res://scripts/capital_canal_data.gd")
func _initialize()->void:call_deferred("_run")
func _height(point:Vector3)->float:
    var xz:=Vector2(point.x,point.z);var bridge:=DATA.bridge_at(xz)
    return root.get_node("WorldData").elevation_at(xz) if is_inf(bridge.x) else DATA.deck_height(xz.x-bridge.x)
func _run()->void:
    assert(load("res://tests/canal_checkpoint_fixture.gd").ensure_legacy_checkpoint(self))
    assert(root.get_node("SaveManager").prepare_load(5));change_scene_to_file("res://scenes/world_loading.tscn")
    var player:CharacterBody3D
    var deadline:=Time.get_ticks_msec()+120000
    while current_scene==null or current_scene.name!="Bootstrap" or player==null or not bool(current_scene.get("startup_state_ready")) or player.ground_guard_active:
        await physics_frame;player=get_first_node_in_group("player") as CharacterBody3D
        if Time.get_ticks_msec()>deadline:push_error("Canal link fixture loading timeout");quit(1);return
    # Explicit static planning fixture. It does not move any citizen/avatar;
    # the existing separate whole-life gate still measures normal walking.
    current_scene.set_process(false)
    var life:Node3D=current_scene.get_node("World/CityDistrict").loaded_cells[Vector2i(7,-1)].get_node("CanalHousehold")
    var nav:=life.get_node("PublicSpaceNavigation");var actor:=life.get_node("CanalTrader")
    while not nav.grid_ready:
        await physics_frame
        if Time.get_ticks_msec()>deadline:push_error("Canal link raster readiness timeout");quit(1);return
    assert(node_added.is_connected(nav._on_node_added),"Loaded navigation loses geometry listener after world reparent")
    var poses:Array[Vector3]=[Vector3(27.34277,2.096661,-7.121094),Vector3(-27.34277,2.096661,-7.121094),Vector3(29.65039,.010484,-8.867676)]
    var samples:=0
    for pose:Vector3 in poses:
        var point:=life.to_global(pose)
        var target:=life.to_global(Vector3(-26 if pose.x>0 else 26,0,-5))
        for index in range(8):
            nav.routes.clear()
            var next:Vector3=nav.next_point(point,target,actor)
            var horizontal:=Vector2(next.x-point.x,next.z-point.z).length()
            assert(horizontal>.03,"A free physical bridge approach has no advancing waypoint")
            var support:=_height(next)
            assert(absf(support-point.y)<.35,"Planner snapped a deck citizen to the ground below the parapet")
            # Independent metre-by-metre support oracle: never cross a rail by
            # treating a free cell on a different elevation as a walking link.
            var previous:=point.y
            for sample in range(9):
                var on_link:=point.lerp(next,float(sample)/8)
                var height:=_height(on_link)
                assert(absf(height-previous)<.30,"Planned walking link contains an unsupported vertical step/drop")
                previous=height
            print("CANAL_LINK_SAMPLE from=",life.to_local(point)," to=",life.to_local(next)," support=",support)
            point=Vector3(next.x,support+.02,next.z);samples+=1
    # Real thin obstacle between free raster endpoints. Repair only its blocked
    # link, retain the obstacle, and reconnect automatically after its removal.
    var a:Vector2i=nav._nearest(nav._cell(Vector3(-60,0,30)))
    var b:=a+Vector2i(0,1);var c:=b+Vector2i(0,1)
    assert(not nav.grid.is_point_solid(a) and not nav.grid.is_point_solid(b) and not nav.grid.is_point_solid(c))
    var center:Vector2=nav.grid.get_point_position(a)
    var from:Vector3=nav.to_global(Vector3(center.x,0,center.y));from.y=_height(from)+.02
    var end_xz:Vector2=nav.grid.get_point_position(c)
    var goal:Vector3=nav.to_global(Vector3(end_xz.x,0,end_xz.y));goal.y=_height(goal)+.02
    var initial:=PhysicsShapeQueryParameters3D.new();var initial_capsule:=CapsuleShape3D.new();initial_capsule.radius=.34;initial_capsule.height=1.8;initial.shape=initial_capsule
    initial.transform=Transform3D(Basis.IDENTITY,from+Vector3.UP*1.02);initial.motion=goal-from
    var initial_sweep:=player.get_world_3d().direct_space_state.cast_motion(initial)
    print("THIN_INITIAL ",initial_sweep," graph=",nav._path(a,c))
    assert(initial_sweep.size()==2 and initial_sweep[0]>=.99999,"Thin fixture starts with an unrelated blocked connection")
    node_added.connect(func(node:Node):
        if node is CollisionShape3D and node.get_parent()!=null and node.get_parent().name=="ThinEdgeObstacle":
            print("THIN_EVENT shape_inside=",node.is_inside_tree()," parent_inside=",node.get_parent().is_inside_tree()," shape_ready=",node.shape!=null," parent=",node.get_parent().global_position," nav=",nav.global_position," bounds=",nav.lower_bound," ",nav.upper_bound))
    var obstacle:=StaticBody3D.new();obstacle.name="ThinEdgeObstacle";current_scene.add_child(obstacle)
    obstacle.global_position=from+Vector3(0,.78,.375)
    var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.15,1.6,.01);collision.shape=box;obstacle.add_child(collision)
    for frame in range(2):await physics_frame
    while not nav.grid_ready:await physics_frame
    assert(not nav.grid.is_point_solid(a) and not nav.grid.is_point_solid(b),"Thin-link fixture endpoints should remain physically free")
    var next:=from
    for attempt in range(9):
        next=nav.next_point(from,goal,actor)
        if Vector2(next.x-from.x,next.z-from.z).length()>.03:break
    assert(Vector2(next.x-from.x,next.z-from.z).length()>.03,"A blocked thin edge leaves the free actor frozen at its anchor")
    var query:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.34;capsule.height=1.8;query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,from+Vector3.UP*.9);query.motion=Vector3(next.x,from.y,next.z)-from
    var sweep:=player.get_world_3d().direct_space_state.cast_motion(query)
    assert(sweep.size()==2 and sweep[0]>=.99999,"Repaired route still crosses the actual thin obstacle")
    var direct:=PhysicsRayQueryParameters3D.create(from+Vector3.UP*.8,from+Vector3(0,.8,.75),1)
    var hit:=player.get_world_3d().direct_space_state.intersect_ray(direct)
    assert(not hit.is_empty() and hit.collider==obstacle,"The obstacle was removed to make navigation pass")
    print("THIN_WATCH connected=",obstacle.tree_exiting.is_connected(nav.invalidate)," inside=",collision.is_inside_tree()," point=",nav.to_local(collision.global_position)," signal=",node_added.is_connected(nav._on_node_added))
    obstacle.queue_free()
    for frame in range(2):await physics_frame
    while not nav.grid_ready:await physics_frame
    var restored:Vector3=nav.next_point(from,goal,actor)
    print("THIN_AFTER sweep=",player.get_world_3d().direct_space_state.cast_motion(initial))
    print("LINK_REBUILT from=",from," goal=",goal," next=",restored," raster=",nav.grid.get_id_path(a,c)," graph=",nav._path(a,c)," ready=",nav.grid_ready," ray=",player.get_world_3d().direct_space_state.intersect_ray(direct))
    assert(absf(restored.x-from.x)<.01 and restored.z>from.z+.5,"Removed obstacle leaves a stale forbidden edge")
    print("CANAL_WALKABLE_LINKS_OK measured_world=true static_planner_fixture=true actor_position_writes=0 samples=",samples," thin_obstacle_retained_and_repaired=true removed_edge_reconnected=true independent_unfrozen_lifecycle_required=true")
    quit(0)
