extends SceneTree

const DATA:=preload("res://scripts/capital_canal_data.gd")
var player:CharacterBody3D

func _initialize()->void:call_deferred("_run")

func _world_ready()->bool:
    if current_scene==null or current_scene.name!="Bootstrap":return false
    var actor:=get_first_node_in_group("player") as CharacterBody3D
    return actor!=null and bool(current_scene.startup_state_ready) and not actor.ground_guard_active

func _run()->void:
    create_timer(170).timeout.connect(func():push_error("CAPITAL_CANALS timeout");quit(1))
    var saves:=root.get_node("SaveManager")
    assert(load("res://tests/canal_checkpoint_fixture.gd").ensure_legacy_checkpoint(self),"Use the earned checkpoint, or explicitly select the CI fixture")
    change_scene_to_file("res://scenes/world_loading.tscn")
    var deadline:=Time.get_ticks_msec()+120000
    while not _world_ready():
        await process_frame
        if Time.get_ticks_msec()>deadline:push_error("CANAL old-save bootstrap stuck");quit(1);return
    player=get_first_node_in_group("player") as CharacterBody3D
    current_scene.set_process(false)
    for frame in range(40):await physics_frame
    assert(not player.ground_guard_active and player.is_on_floor(),"Old road save must acquire the real new bridge")
    var bridge_center:Vector2=DATA.bridges()[1]
    assert(Vector2(player.global_position.x,player.global_position.z).distance_to(bridge_center)<.2)
    assert(absf(player.global_position.y-DATA.BRIDGE_DECK_TOP)<.09,"Legacy road checkpoint remains embedded below the deck")
    var state:=root.get_node("GameState");var inventory:Dictionary=state.inventory.duplicate(true);var coins:int=state.coins
    var effects:=root.get_node("WorldVFX")
    assert(effects.surface_at(Vector3(bridge_center.x,2.2,bridge_center.y))=="stone")
    assert(effects.surface_at(Vector3(bridge_center.x,0,bridge_center.y+30))=="water")
    var grass_point:=bridge_center+Vector2(-36,30)
    assert(effects.surface_at(Vector3(grass_point.x,root.get_node("WorldData").elevation_at(grass_point),grass_point.y))=="grass")
    var path_point:=bridge_center+Vector2(-26,30)
    assert(effects.surface_at(Vector3(path_point.x,root.get_node("WorldData").elevation_at(path_point)+.006,path_point.y))=="stone")
    assert(coins==20 and int(inventory.get("berries",0))==11 and int(inventory.get("water_flask",0))==9)
    assert(saves.save_game(player,6))
    var file:=FileAccess.open("user://save_slot_06.json",FileAccess.READ);var payload:Dictionary=JSON.parse_string(file.get_as_text());file.close()
    assert(payload.save_version==6 and payload.world_geometry_revisions.capital_canals==1)
    var space:=player.get_world_3d().direct_space_state
    var canals:GDScript=load("res://scripts/capital_canals.gd")
    var triangles:=0
    for part:Dictionary in canals.parts.values():triangles+=part.mesh.get_faces().size()/3
    assert(triangles==43348,"Authored bridge/quay geometry was lost")
    assert(canals.stone.albedo_texture.get_image().has_mipmaps() and canals.stone.normal_texture.get_image().has_mipmaps())
    var opening:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(bridge_center.x,.5,bridge_center.y-12),Vector3(bridge_center.x,.5,bridge_center.y+12),1,[player.get_rid()]))
    assert(opening.is_empty(),"Actual streamed arch opening is sealed by an invisible box")
    var pier:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(bridge_center.x+8,.5,bridge_center.y-12),Vector3(bridge_center.x+8,.5,bridge_center.y+12),1,[player.get_rid()]))
    assert(not pier.is_empty() and bool(pier.collider.get_meta("measured_bridge_collision",false)))
    var ray:=PhysicsRayQueryParameters3D.create(Vector3(bridge_center.x,.5,bridge_center.y+30),Vector3(bridge_center.x,-2,bridge_center.y+30),1,[player.get_rid()])
    var hit:=space.intersect_ray(ray)
    assert(not hit.is_empty() and absf(Vector3(hit.position).y+DATA.DEPTH)<.015,"Canal still has a flat/invisible ground cover")
    var surfaces:=current_scene.find_children("CapitalCanalWater","MeshInstance3D",true,false)
    assert(not surfaces.is_empty(),"Continuous canal surface missing from actual streamed world")
    for surface:MeshInstance3D in surfaces:
        var arrays:=surface.mesh.surface_get_arrays(0)
        for vertex:Vector3 in arrays[Mesh.ARRAY_VERTEX]:
            var world:=surface.to_global(vertex)
            assert(absf(world.y-DATA.WATER_LEVEL)<.001)
            assert(DATA.distance_to_channel(Vector2(world.x,world.z))<=DATA.HALF_WIDTH+.025)
    var dry:=DATA.CENTER+Vector2(-65,35);var goal:=DATA.CENTER+Vector2(65,35)
    var waypoint:=DATA.navigation_target(dry,goal)
    assert(absf(waypoint.x-DATA.CENTER.x)>48 and waypoint.y==DATA.bridges()[1].y,"Resident did not choose the shorter crossing from the actual goal")
    assert(DATA.navigation_target(DATA.CENTER+Vector2(-70,330),DATA.CENTER+Vector2(-65,340))==DATA.CENTER+Vector2(-65,340))
    # Reload the just-saved bridge state through the real scene boundary.
    assert(saves.prepare_load(6));change_scene_to_file("res://scenes/world_loading.tscn")
    while not _world_ready():await process_frame
    player=get_first_node_in_group("player") as CharacterBody3D
    for frame in range(24):await physics_frame
    assert(player.is_on_floor() and not player.ground_guard_active)
    assert(state.coins==coins and state.inventory==inventory)
    print("CAPITAL_CANALS_CORE_OK legacy_bridge_save=true physical_basin=true continuous_water=true closest_goal_crossing=true actual_scene_disk_restore=true inventory_money_unchanged=true")
    quit(0)
