extends Node3D

const SETTLEMENTS := preload("res://scripts/world_settlements.gd")
const KIT := preload("res://scripts/cottage_yard_assets.gd")
var player: CharacterBody3D

func _ready() -> void:
    get_tree().create_timer(100).timeout.connect(func():push_error("Cottage yards watchdog");get_tree().quit(1))
    call_deferred("_run")

func _frames(count: int) -> void:
    for i in range(count):await get_tree().physics_frame

func _park(point: Vector3) -> void:
    # Explicit stationary contract fixture; graphical walking is separate.
    player.global_position = point
    player.global_position.y = WorldData.elevation_at(Vector2(point.x,point.z))+0.08
    player.velocity = Vector3.ZERO

func _run() -> void:
    GameState.reset_new_game()
    GameState.set_world_value("current_realm","cottage_yard_fixture")
    var settlements := SETTLEMENTS.new()
    add_child(settlements)
    settlements.set_process(false)
    var village: Node3D = settlements.materialize_settlement_for_test("border_village_01")
    assert(int(village.get_meta("house_yard_count",0))==7,"A village home lost its connected yard")
    for key in ["TimberBeam","StoneCourse","GardenFence","WindowPlanter","TimberStore","MeadowFlowers"]:
        var mesh := KIT.mesh(key)
        assert(mesh.get_surface_count()>0 and mesh.get_aabb().size.is_finite())
    assert(absf(KIT.mesh("GardenFence").get_aabb().size.y-1.05)<0.01)
    var flower_mesh := KIT.mesh("MeadowFlowers")
    var pigments: Dictionary = {}
    for surface in range(flower_mesh.get_surface_count()):
        var wind := flower_mesh.surface_get_material(surface) as ShaderMaterial
        var pigment: Color = wind.get_shader_parameter("vegetation_tint")
        pigments[wind.resource_name] = pigment
        assert(maxf(pigment.r,maxf(pigment.g,pigment.b))>minf(pigment.r,minf(pigment.g,pigment.b))+0.03,"Blender export lost flower/leaf pigment")
    assert(flower_mesh.get_surface_count()==3,"Flower semantic surfaces were merged")
    var berries: Array[Node3D] = []
    var chest: HouseholdFurniture
    var gate: DoorInteractable
    for home: Node3D in village.get_children():
        if not home is EnterableBuilding:continue
        assert(home.has_node("CottageExterior"))
        var exterior := home.get_node("CottageExterior")
        assert(int(exterior.get_meta("beam_members"))>30)
        assert((exterior.get_node("WindowPlanter") as MultiMeshInstance3D).multimesh.instance_count==home.window_count)
        var yard := home.get_node("GardenYard") as Node3D
        _check_gate_access(home,yard)
        assert(yard.has_meta("access_path") and PackedVector2Array(yard.get_meta("access_path")).size()>1)
        for child in yard.get_children():
            if child.is_in_group("garden_berry"):berries.append(child)
        if chest==null:chest=yard.get_node_or_null("GardenChest") as HouseholdFurniture
        if gate==null:gate=yard.get_node("GardenGate") as DoorInteractable
    assert(berries.size()>=10 and chest!=null)
    var stage := load("res://scenes/stage1.tscn").instantiate() as Node
    player = stage.get_node("World/Player") as CharacterBody3D
    player.get_parent().remove_child(player)
    stage.free()
    player.position=village.position+Vector3(0,1,0)
    add_child(player)
    player.call("_set_instanced_world_mode",true)
    player.set_physics_process(false)
    await _frames(4)
    var berry := berries[0]
    var before := int(GameState.inventory.get("berries",0))
    _park(berry.global_position+berry.global_basis.z*10)
    berry.call("interact",player)
    assert(int(GameState.inventory.get("berries",0))==before,"Remote berry harvesting succeeds")
    _park(berry.global_position+berry.global_basis.z*1.15)
    var obstacle := StaticBody3D.new()
    obstacle.transform = Transform3D(berry.global_basis,berry.global_position+berry.global_basis.z*0.55+Vector3.UP)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size=Vector3(1,2,.15)
    shape.shape=box
    obstacle.add_child(shape)
    add_child(obstacle)
    await _frames(3)
    berry.call("interact",player)
    assert(int(GameState.inventory.get("berries",0))==before,"Berry harvesting passes through a wall")
    obstacle.free()
    await _frames(3)
    for i in range(3):berry.call("interact",player)
    assert(int(GameState.inventory.get("berries",0))==before+3 and int(berry.get("uses"))==0)
    berry.call("interact",player)
    assert(int(GameState.inventory.get("berries",0))==before+3,"Depleted garden duplicates berries")
    assert(berry.get_child_count()>1 and berry.visible,"Harvest deletes the perennial bush")
    var berry_key := String(berry.get("persistent_id"))
    var gate_key := gate.persistence_key
    var closed_basis: Basis = (gate.get_parent() as Node3D).global_basis*Basis(Vector3.UP,gate.closed_rotation_y)
    var opening: Vector3 = gate.global_position+closed_basis*Vector3(1,.5,0)
    var query := PhysicsRayQueryParameters3D.create(opening-closed_basis.z*.7,opening+closed_basis.z*.7,1,[player.get_rid()])
    gate.set_open(false,true)
    await _frames(3)
    assert(get_world_3d().direct_space_state.intersect_ray(query).get("collider")==gate,"Closed garden gate is not physical")
    gate.set_open(true,true)
    await _frames(3)
    assert(get_world_3d().direct_space_state.intersect_ray(query).get("collider")!=gate,"Open gate blocks its original opening")
    gate.set_open(false,true)
    _park(chest.approach_point())
    await _frames(3)
    assert(chest.transfer(player,"berries",true,2),"Yard storage cannot accept the real harvest")
    chest.open_storage(player)
    await _frames(4)
    assert(chest.chest_animation!=null and chest.lid_target,"Real garden chest lid animation is not bound")
    DialogueManager.close_dialogue()
    var chest_key := chest.furniture_id
    assert(SaveManager.save_game(player,3))
    gate.set_open(true,true)
    GameState.set_world_value("garden:"+berry_key,{"remaining":3,"ready_at":-1})
    assert(SaveManager.load_game(player,3))
    berry.call("restore")
    gate.restore_saved_state()
    assert(int(berry.get("uses"))==0 and not gate.opened and chest.contents().get("berries",0)==2)
    var original_day := GameState.world_day
    GameState.world_day=original_day+1
    berry.call("restore")
    assert(int(berry.get("uses"))==0,"Garden regrows before its two-day deadline")
    village.free()
    village=settlements.materialize_settlement_for_test("border_village_01")
    await _frames(4)
    var restored: Node3D
    for node: Node3D in get_tree().get_nodes_in_group("garden_berry"):
        if String(node.get("persistent_id"))==berry_key:restored=node
    assert(restored!=null and int(restored.get("uses"))==0,"Streaming resets depleted harvest")
    assert(GameState.get_world_value(gate_key,true)==false)
    assert(GameState.get_world_value(chest_key,{}).get("items",{}).get("berries",0)==2)
    GameState.world_day=original_day+2
    restored.call("restore")
    assert(int(restored.get("uses"))==3,"Mature garden does not regrow after persisted deadline")
    var second := settlements.materialize_settlement_for_test("border_village_02") as Node3D
    assert(int(second.get_meta("house_yard_count",0))==8,"Second village lost connected household plots")
    for home: Node3D in second.get_children():
        if not home is EnterableBuilding:continue
        assert(home.has_node("CottageExterior") and home.has_node("GardenYard"))
        _check_gate_access(home,home.get_node("GardenYard"))
        assert(PackedVector2Array(home.get_node("GardenYard").get_meta("access_path")).size()>1)
    print("COTTAGE_YARDS_OK homes=15 exterior=measured windows=clear plots=connected berries=finite line_of_sight=physical gates=saved chest=animated disk=roundtrip streaming=persistent regrowth=two_days")
    get_tree().quit(0)

func _check_gate_access(home: Node3D,yard: Node3D) -> void:
    var offset: Vector2 = yard.get_meta("plot_offset")
    var size: Vector2 = yard.get_meta("plot_size")
    var polygons: Array = yard.get_node("GardenAccess").get_meta("path_polygons")
    for sample in range(15):
        var p := home.to_global(Vector3(offset.x,0,offset.y+size.y*.5+lerpf(-.10,3.0,float(sample)/14.0)))
        var covered := false
        for polygon: PackedVector2Array in polygons:
            if Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),polygon):covered=true;break
        assert(covered,"Soil path stops before the real garden gate: "+String(home.name))
