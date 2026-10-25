extends SceneTree

var player:CharacterBody3D
var home:Node3D
var camera:Camera3D
var records:Array=[]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(100).timeout.connect(func():push_error("Room lighting review timeout");quit(1))
    root.size=Vector2i(1280,720)
    root.get_node("SettingsManager").set_quality_preset(2)
    root.get_node("SettingsManager").set_value("graphics","vsync",false)
    root.get_node("GameState").world_minutes=22*60
    var world:=Node3D.new();root.add_child(world);current_scene=world
    var env:=WorldEnvironment.new();env.environment=Environment.new()
    env.environment.background_mode=Environment.BG_COLOR
    env.environment.background_color=Color(.025,.035,.055)
    env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color=Color(.65,.72,.85);env.environment.ambient_light_energy=.13
    world.add_child(env)
    home=load("res://scripts/enterable_building.gd").new();home.configure(Vector3(12,3.2,10),1);world.add_child(home)
    var decorator:Node=load("res://scripts/settlement_interior_visuals.gd").new();world.add_child(decorator)
    assert(decorator.decorate_building(home))
    var stage:Node=load("res://scenes/stage1.tscn").instantiate()
    player=stage.get_node("World/Player");player.get_parent().remove_child(player);stage.free()
    world.add_child(player);player.call("_set_instanced_world_mode",true);player.position=Vector3(.5,.25,1.8)
    camera=Camera3D.new();camera.fov=75;world.add_child(camera);camera.make_current()
    for i in range(35):await physics_frame
    assert(player.is_on_floor(),"Player did not settle on the actual furnished-room floor")
    Input.action_press("move_forward")
    for i in range(12):await physics_frame
    Input.action_release("move_forward")
    for i in range(12):await physics_frame
    assert(player.is_on_floor())
    player.set_physics_process(false)
    for door in home.get_node("HouseRooms").room_doors:door.set_open(true,true)
    var candidate:SpotLight3D=home.room_lantern
    print("WALL_LIGHT_INITIAL actor=",player.global_position," shadows=",candidate.shadow_enabled," quality=",root.get_node("SettingsManager").get_value("graphics","quality_preset"))
    assert(candidate!=null and candidate.shadow_enabled)
    assert(candidate.spot_angle<90 and (-candidate.global_basis.z).dot(Vector3.BACK)>.9)
    var original:=OmniLight3D.new();original.transform=candidate.transform
    original.light_color=candidate.light_color;original.light_energy=candidate.light_energy
    original.omni_range=candidate.spot_range;original.shadow_enabled=true
    home.add_child(original)
    var views:Dictionary={"hall":[Vector3(.5,1.65,3.4),Vector3(.5,1.2,-3)],"dining":[Vector3(1.4,1.7,-1.8),Vector3(4,1.0,-.3)],"bedroom":[Vector3(-1.65,1.7,-2.6),Vector3(-4,1,-3.7)],"kitchen":[Vector3(2.5,1.7,3.0),Vector3(5.1,1.1,3.8)]}
    # The old light exists only in this controlled before/after visual fixture.
    for label:String in ["before","after"]:
        candidate.visible=label=="after";original.visible=label=="before"
        home.set_process(false)
        for view:String in views:
            camera.position=views[view][0];camera.look_at(views[view][1])
            for i in range(12):await RenderingServer.frame_post_draw
            var image:=root.get_texture().get_image()
            assert(image.save_png("user://wall-light-"+label+"-"+view+".png")==OK)
            records.append({"mode":label,"room":view,"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"player_grounded":player.is_on_floor(),"room_count":home.room_count,"real_furniture":home.get_meta("real_furniture_visuals"),"window_count":home.window_lights.size()})
    var details:Node=home.get_node("LivingDetails")
    # Close views use the same camera/light; only the cloth response toggles.
    camera.position=Vector3(-2.5,1.4,-2.8);camera.look_at(Vector3(-4.0,.65,-3.25))
    for detailed in [false,true]:
        for label:String in details.FABRIC_LABELS:
            if not details.materials.has(label):continue
            var material:StandardMaterial3D=details.materials[label]
            material.normal_enabled=detailed;material.ao_enabled=detailed
            material.roughness_texture=details.FABRIC_ORM if detailed else null
        for i in range(8):await RenderingServer.frame_post_draw
        assert(root.get_texture().get_image().save_png("user://wall-light-fabric-"+("after" if detailed else "before")+".png")==OK)
    original.queue_free()
    home.set_process(true)
    for preset in [0,1,2,3,0,2]:
        root.get_node("SettingsManager").set_quality_preset(preset)
        assert(candidate.shadow_enabled==(preset>0))
        for label:String in details.FABRIC_LABELS:
            if not details.materials.has(label):continue
            var material:StandardMaterial3D=details.materials[label]
            assert(material.normal_enabled==(preset>=2) and material.ao_enabled==(preset>=2))
            assert((material.roughness_texture!=null)==(preset>=2))
            assert(material.metallic==0.0)
            assert(material.normal_texture.get_image().has_mipmaps())
    FileAccess.open("user://wall-light-rooms.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture_initial_player_position":true,"manual_play":false,"controlled_night_lighting":true,"records":records},"  "))
    print("WALL_LIGHT_ROOMS_OK rooms=4 before_after=true player_grounded=true quality_modes=4")
    quit(0)
