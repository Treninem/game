extends SceneTree

const DATA:=preload("res://scripts/capital_canal_data.gd")
var player:CharacterBody3D
var walked:=0.
var floor_samples:Array=[]
var foot_samples:Array=[]
var captures:Array[String]=[]

func _initialize()->void:call_deferred("_run")

func _ready_world()->bool:
    if current_scene==null or current_scene.name!="Bootstrap":return false
    player=get_first_node_in_group("player") as CharacterBody3D
    return player!=null and bool(current_scene.startup_state_ready) and not player.ground_guard_active

func _walk(offset:Vector2)->bool:
    print("CANAL_WALK_TO ",offset)
    var target:=preload("res://scripts/capital_data.gd").CENTER+offset
    var deadline:=Time.get_ticks_msec()+70000
    while Vector2(player.global_position.x,player.global_position.z).distance_to(target)>.30:
        var direction:=target-Vector2(player.global_position.x,player.global_position.z)
        player.rotation.y=atan2(-direction.x,-direction.y);player.camera.rotation=Vector3.ZERO
        var previous:=player.global_position;Input.action_press("move_forward");await physics_frame
        walked+=Vector2(player.global_position.x-previous.x,player.global_position.z-previous.z).length()
        if Time.get_ticks_msec()>deadline:push_error("Canal ordinary walk blocked: "+str(player.global_position));quit(1);return false
    Input.action_release("move_forward")
    for frame in range(18):await physics_frame
    await create_timer(.65).timeout
    assert(player.is_on_floor(),"Canal traversal lost physical support")
    floor_samples.append({"xz":str(offset),"y":player.global_position.y})
    await _feet(str(offset))
    print("CANAL_WALK_REACHED ",offset," walked_m=",walked)
    return true

func _capture(offset:Vector3,look:Vector3,label:String)->void:
    var camera:=Camera3D.new();current_scene.add_child(camera)
    var center:Vector2=preload("res://scripts/capital_data.gd").CENTER
    camera.global_position=Vector3(center.x,0,center.y)+offset;camera.look_at(Vector3(center.x,0,center.y)+look);camera.fov=66;camera.make_current()
    for frame in range(3):await process_frame;await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png("user://canal-"+label+".png")==OK)
    captures.append("user://canal-"+label+".png")
    print("CAPITAL_CANAL_CAPTURE ",label)
    player.camera.make_current();camera.queue_free()

func _interact(target: Node3D, point: Vector3) -> bool:
    # Face the actor as a real mouse turn does, then let the camera probe settle
    # on the same side. Rotating only the camera behind an open door can create
    # an impossible backwards aim which the reach/front guard rightly rejects.
    var toward := point - player.global_position
    player.rotation.y = atan2(-toward.x, -toward.z)
    player.camera.rotation = Vector3.ZERO
    for frame in range(4):
        await physics_frame
    player.camera.look_at(point, Vector3.UP)
    player.interaction_ray.force_raycast_update()
    if player.interaction_ray.get_collider() != target:
        push_error("Native interaction ray did not select %s; hit %s" % [target.name, player.interaction_ray.get_collider()])
        quit(1)
        return false
    player.call("_try_interact")
    await physics_frame
    return true

func _feet(label:String) -> void:
    var visual:=player.get_node("Avatar") as Node3D
    var boots:=visual.find_child("Boots",true,false) as MeshInstance3D
    var capture:RefCounted=load("res://tests/gpu_skinned_vertex_probe.gd").new()
    capture.setup(root,boots,0);await capture.calibrate();capture.begin_capture()
    await process_frame;await RenderingServer.frame_post_draw
    var points:PackedVector3Array=capture.finish_capture();assert(points.size()==3530)
    var lowest:=Vector3(0,INF,0)
    for point:Vector3 in points:
        var world:=boots.to_global(point)
        if world.y<lowest.y:lowest=world
    var query:=PhysicsRayQueryParameters3D.create(lowest+Vector3.UP*.5,lowest-Vector3.UP*.5,1,[player.get_rid()])
    var hit:=player.get_world_3d().direct_space_state.intersect_ray(query)
    assert(not hit.is_empty() and player.is_on_floor(),"Street traversal lost actual physical support")
    var gap:=lowest.y-Vector3(hit.position).y
    assert(gap>=-.02 and gap<=.04,"Rendered street sole penetrates/floats: "+label+" gap="+str(gap))
    foot_samples.append({"label":label,"vertices":points.size(),"gap_m":gap,"surface":String(hit.collider.name)})
    capture.dispose()

func _room_walk(home: Node3D, destination: Vector3) -> bool:
    var deadline:=Time.get_ticks_msec()+45000
    while Vector2(home.to_local(player.global_position).x - destination.x, home.to_local(player.global_position).z - destination.z).length() > 0.24:
        var point: Vector3 = home.get_node("HouseRooms").waypoint(home.to_local(player.global_position), destination, player)
        var toward := home.to_global(point) - player.global_position
        player.rotation.y = atan2(-toward.x, -toward.z)
        var before := player.global_position
        Input.action_press("move_forward")
        await physics_frame
        walked += before.distance_to(player.global_position)
        if Time.get_ticks_msec() > deadline:
            Input.action_release("move_forward")
            push_error("Actual capital home room walk blocked: " + str(home.to_local(player.global_position)))
            quit(1)
            return false
    Input.action_release("move_forward")
    for frame in range(10):await physics_frame
    await create_timer(.65).timeout
    if not player.is_on_floor():
        push_error("Capital concept room walk lost physical support")
        quit(1)
        return false
    return true

var square:Node3D
var cell:Node3D
var proof:={"player_position_assignments":0,"manual_play":false,"foot_samples":[]}

func _run()->void:
    assert(load("res://tests/canal_checkpoint_fixture.gd").ensure_legacy_checkpoint(self))
    assert(root.get_node("SaveManager").prepare_load(5));change_scene_to_file("res://scenes/world_loading.tscn")
    var deadline:=Time.get_ticks_msec()+120000
    while not _ready_world():
        await physics_frame
        if Time.get_ticks_msec()>deadline:push_error("Street scale actual-load timeout");quit(1);return
    current_scene.set_process(false)
    var state:=root.get_node("GameState");state.world_minutes=9*60
    root.get_node("SettingsManager").set_quality_preset(1)
    var original_items:Dictionary=state.inventory.duplicate(true);var original_coins:int=state.coins
    var look:Dictionary=state.get_world_value("player_appearance",{}).duplicate(true);look.height_cm=200.0
    state.set_world_value("player_appearance",look)
    player.get_node("Avatar").apply_appearance(look)
    for frame in range(12):await physics_frame
    assert(is_equal_approx(player.get("appearance_height_cm"),200.0))
    for point:Vector2 in [Vector2(1125,-160),Vector2(1125,-210),Vector2(1154,-210),Vector2(1154,-195)]:
        if not await _walk(point):return
    await _capture(Vector3(1159,2.4,-202),Vector3(1151,1.1,-189),"human-scale-promenade")
    var jump_event:=InputEventAction.new();jump_event.action="jump";jump_event.pressed=true
    Input.parse_input_event(jump_event);Input.flush_buffered_events();await physics_frame
    jump_event=InputEventAction.new();jump_event.action="jump";Input.parse_input_event(jump_event);Input.flush_buffered_events()
    for frame in range(10):await physics_frame
    assert(not player.is_on_floor());await _capture(Vector3(1159,2.4,-202),Vector3(1154,1.3,-195),"two-metre-jump")
    for frame in range(70):await physics_frame
    assert(player.is_on_floor());await _feet("200cm-after-jump")
    var city:=current_scene.get_node("World/CityDistrict")
    var flowers:=0;var styles:Dictionary={};var ordinary_streets:=0
    for cell:Node3D in city.loaded_cells.values():
        flowers+=int(cell.get_meta("canal_flower_beds",0))
        if float(cell.get_meta("carriage_width_m",0))==6.0:ordinary_streets+=1
        if cell.has_meta("promenade_width_m"):assert(float(cell.get_meta("promenade_width_m"))==3.0)
        for mesh:MeshInstance3D in cell.find_children("*","MeshInstance3D",true,false):
            if mesh.material_override is ShaderMaterial and mesh.material_override.shader==preload("res://assets/shaders/environment/street_paving.gdshader"):
                styles[mesh.material_override.resource_name]=true
    assert(flowers>0 and ordinary_streets>0 and styles.size()>=5)
    assert(state.inventory==original_items and state.coins==original_coins)
    assert(root.get_node("SaveManager").save_game(player,10))
    assert(root.get_node("SaveManager").load_game(player,10))
    assert(float(state.get_world_value("player_appearance",{}).get("height_cm",0))==200.0)
    var report:={"height_cm":200,"controlled_appearance_fixture":true,"ordinary_automated_input":true,"manual_play":false,"player_position_assignments":0,"clock_frozen_fixture":true,"walked_m":walked,"GPU_sole_samples":foot_samples,"inventory_money_unchanged":true,"actual_disk_height_round_trip":true,"loaded_flower_beds":flowers,"loaded_surface_styles":styles.keys(),"ordinary_6m_carriageways":ordinary_streets,"promenade_m":3.0,"grand_arterials_and_bridge_geometry_retained":true,"visual_acceptance":false,"captures":captures}
    await _capture(Vector3(985,12,-194),Vector3(960,1,-160),"residential-lanes-and-flowers")
    await _palette(report)
    var file:=FileAccess.open("user://human-street-scale.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("HUMAN_STREET_SCALE_OK ",JSON.stringify(report));quit(0)

func _palette(report:Dictionary)->void:
    # Independent lit render of every surface at the same physical scale.
    if current_scene!=null:current_scene.queue_free()
    for frame in range(3):await process_frame
    var studio:=Node3D.new();root.add_child(studio);current_scene=studio
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-65,-20,0);sun.light_energy=1.0;studio.add_child(sun)
    var environment:=WorldEnvironment.new();var settings:=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color(.18,.19,.20)
    settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.6;environment.environment=settings;studio.add_child(environment)
    var palette:=preload("res://scripts/street_surface_palette.gd")
    var names:Dictionary={}
    for index in range(palette.TYPES.size()):
        var tile:=MeshInstance3D.new();var slab:=BoxMesh.new();slab.size=Vector3(2.4,.04,2.4);tile.mesh=slab;tile.material_override=palette.material(index)
        tile.position=Vector3(float(index%5)*2.5,.02,float(index/5)*2.5);studio.add_child(tile)
        names[palette.TYPES[index].id]=true
        var photo:Texture2D=palette.material(index).get_shader_parameter("stone_texture")
        assert(photo.get_image().has_mipmaps(),"Paving photograph lost physical mip levels")
    assert(names.size()==15)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=13.4;camera.position=Vector3(5,16,2.5);studio.add_child(camera);camera.look_at(Vector3(5,0,2.5),Vector3.FORWARD);camera.make_current()
    for frame in range(5):await process_frame;await RenderingServer.frame_post_draw
    var image:=root.get_texture().get_image();assert(image.save_png("user://street-palette-15.png")==OK)
    report["palette_rendered_at_same_scale"]=15;report["palette_ids"]=names.keys()
