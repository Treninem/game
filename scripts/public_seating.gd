extends RefCounted

static func plan(npc:CharacterBody3D,routine:Dictionary) -> Dictionary:
    var navigation:=npc.get_parent().get_node_or_null("PublicSpaceNavigation")
    if navigation==null:return routine
    var benches:Array[Node]=npc.get_tree().get_nodes_in_group("public_rest_furniture")
    var key:String="public_rest:"+String(npc.citizen_id)
    var raw:Variant=GameState.get_world_value(key,{})
    var saved:Dictionary=raw.duplicate(true) if raw is Dictionary else {}
    var eligible:bool=routine.phase in ["meal","social"]
    if not eligible:
        var leaving:bool=not String(saved.get("seat","")).is_empty()
        if is_instance_valid(npc.used_furniture) and npc.used_furniture.is_in_group("public_rest_furniture"):
            npc._leave_furniture();leaving=true
        if leaving:
            for bench:HouseholdFurniture in benches:bench.release(npc.citizen_id)
            saved.seat="";saved.departing=true;saved.phase=routine.phase
            GameState.set_world_value(key,saved)
        if bool(saved.get("departing",false)):
            var destination:Vector3=npc.get_parent_node_3d().to_global(routine.target)
            if not navigation.contains(npc.global_position) or Vector2(destination.x-npc.global_position.x,destination.z-npc.global_position.z).length()<.3:
                saved.departing=false;GameState.set_world_value(key,saved)
            else:
                var point:Vector3=navigation.next_point(npc.global_position,destination,npc,.27)
                routine.target=npc.get_parent_node_3d().to_local(point)
                routine.phase="public_departure";routine.arrival_radius=.08;routine.indoor_path=true
                routine.navigation_pending=true;routine.measured_public_link=true
        return routine
    if saved.get("phase","")!=routine.phase:
        if is_instance_valid(npc.used_furniture) and npc.used_furniture.is_in_group("public_rest_furniture"):npc._leave_furniture()
        for bench:HouseholdFurniture in benches:bench.release(npc.citizen_id)
        saved={"phase":routine.phase,"seat":"","seated_seconds":0.0}
    if not navigation.grid_ready:
        routine.target=npc.position;routine.arrival_radius=.1
        if not is_instance_valid(npc.used_furniture):
            for bench:HouseholdFurniture in benches:
                var distance:=Vector2(bench.approach_point().x-npc.global_position.x,bench.approach_point().z-npc.global_position.z).length()
                if bench.furniture_id==saved.get("seat","") and bench.occupant==npc.citizen_id and distance<.4:
                    npc.used_furniture=bench;break
        if is_instance_valid(npc.used_furniture) and npc.used_furniture.is_in_group("public_rest_furniture"):
            routine.public_furniture=npc.used_furniture
        return routine
    var goal:Vector3=npc.get_parent_node_3d().to_global(routine.target)
    var selected:HouseholdFurniture
    var cost:=INF
    for bench:HouseholdFurniture in benches:
        if bench.get_parent().get_parent()!=npc.get_parent() or bench.global_position.distance_to(goal)>24:continue
        if not bench.occupant.is_empty() and bench.occupant!=npc.citizen_id:continue
        if bench.furniture_id==saved.get("seat",""):
            selected=bench;break
        var score:=npc.global_position.distance_to(bench.approach_point())+2*bench.global_position.distance_to(goal)
        if score<cost and navigation.can_reach(npc.global_position,bench.approach_point(),npc):selected=bench;cost=score
    if selected==null or not selected.claim(npc.citizen_id):return routine
    npc.used_furniture=selected
    saved.seat=selected.furniture_id;GameState.set_world_value(key,saved)
    var destination:=selected.approach_point()
    var point:Vector3=navigation.next_point(npc.global_position,destination,npc,.24)
    routine.target=npc.get_parent_node_3d().to_local(point)
    routine.arrival_radius=.15;routine.indoor_path=true
    routine.navigation_pending=true;routine.measured_public_link=true
    routine.walking="Идёт на обеденный перерыв" if routine.phase=="meal" else "Идёт к месту встречи"
    if Vector2(npc.global_position.x-destination.x,npc.global_position.z-destination.z).length()<.24:
        routine.target=npc.get_parent_node_3d().to_local(destination)
        routine.erase("navigation_pending")
        routine.arrival_radius=.27;routine.public_furniture=selected
        routine.activity="Отдыхает в обеденный перерыв" if routine.phase=="meal" else "Отдыхает и общается"
    return routine

static func use(npc:CharacterBody3D,furniture:HouseholdFurniture,delta:float) -> void:
    if not furniture.claim(npc.citizen_id):return
    furniture.apply_rest_pose(npc,npc.visual)
    var key:String="public_rest:"+String(npc.citizen_id)
    var saved:Dictionary=GameState.get_world_value(key,{}).duplicate(true)
    saved.seated_seconds=minf(3600.0,maxf(0,float(saved.get("seated_seconds",0)))+delta)
    GameState.set_world_value(key,saved)
