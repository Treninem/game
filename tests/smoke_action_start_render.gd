extends SceneTree

var actor: CharacterBody3D
var visual: Node3D
var skeleton: Skeleton3D
var camera: Camera3D
var armed := false
var candidate := {}
var captured := {}
var captures := []
var phase := ""
var history := []
var last_observed := {}

func _initialize() -> void:call_deferred("_run")

func _observe_final_pose() -> void:
    if not armed:return
    candidate.clear()
    camera.global_position = actor.global_position + Vector3(2.1,1.8,-4.7)
    camera.look_at(actor.global_position + Vector3.UP*1.15)
    camera.force_update_transform()
    var animator: AnimationPlayer = visual.get("animation_player")
    var wrist := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightHand")).origin)
    var neck := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Neck")).origin)
    last_observed={"event":"modifier","phase":phase,"frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"pending":float(actor.get("pending_bow_elapsed")),"animation_time":animator.current_animation_position,"clip":String(animator.assigned_animation),"grounded":actor.is_on_floor(),"wrist_below_neck_m":neck.y-wrist.y,"animation_callback":int(animator.callback_mode_process)}
    if history.size()<64:history.append(last_observed.duplicate(true))
    if animator.assigned_animation=="Bow_Attack_Draw" and not actor.is_on_floor() and float(actor.get("pending_bow_elapsed"))>0 and animator.current_animation_position>=0.20 and wrist.y>=neck.y-0.25:
        candidate={"phase":phase,"frame":Engine.get_process_frames(),"pending":float(actor.get("pending_bow_elapsed")),"animation_time":animator.current_animation_position,"wrist_below_neck_m":neck.y-wrist.y}

func _finish_render() -> void:
    if not armed:return
    if history.size()<64:history.append({"event":"render","frame":Engine.get_process_frames(),"final_pose":last_observed.duplicate(true)})
    if candidate.is_empty():return
    if int(candidate.frame)!=Engine.get_process_frames():return
    var animator: AnimationPlayer = visual.get("animation_player")
    assert(animator.assigned_animation=="Bow_Attack_Draw" and float(actor.get("pending_bow_elapsed"))>0 and not actor.is_on_floor(),"Tension changed before its actual render")
    captured=candidate.duplicate(true)
    armed=false
    assert(root.get_texture().get_image().save_png("user://action-start-"+phase+".png")==OK,"Actual tension frame could not be saved")
    print("ACTION_START_RENDER_SAMPLE ",JSON.stringify(captured))

func _run() -> void:
    assert(DisplayServer.get_name()!="headless","Action start requires a real render backend")
    create_timer(80).timeout.connect(func():push_error("ACTION_START_RENDER watchdog");quit(1))
    var fixture = load("res://tests/physical_human_fixture.gd")
    var world:=Node3D.new()
    root.add_child(world)
    current_scene=world
    fixture.add_floor(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-35,-25,0)
    world.add_child(light)
    actor=fixture.player(world,Vector3(0,0.08,0))
    for i in range(30):await physics_frame
    assert(actor.is_on_floor())
    visual=actor.get_node("Avatar") as Node3D
    skeleton=visual.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
    camera=Camera3D.new()
    camera.fov=43
    world.add_child(camera)
    camera.make_current()
    var modifier: Node = visual.get("grip_modifier")
    modifier.modification_processed.connect(_observe_final_pose)
    RenderingServer.frame_post_draw.connect(_finish_render)
    var state:=root.get_node("GameState")
    var inventory:=root.get_node("InventorySystem")
    state.call("add_item","short_bow",1)
    state.call("add_item","arrow",10)
    assert(inventory.call("equip","short_bow"))
    for i in range(15):await physics_frame
    Engine.max_fps=5
    Input.action_press("move_forward")
    # All dispatch points exercise the real controller, with no position or
    # velocity assignments. This is an automated unit fixture, not manual play.
    for offset in range(9):
        while float(actor.get("attack_elapsed"))>0.0 or not actor.is_on_floor():await physics_frame
        var dispatch: String = "after_render" if offset==0 else "physics_offset_%d"%offset
        await RenderingServer.frame_post_draw
        for i in range(offset):await physics_frame
        assert(actor.is_on_floor())
        state.set("stamina",100.0)
        var jump:=InputEventAction.new()
        jump.action="jump"
        jump.pressed=true
        actor.call("_unhandled_input",jump)
        assert(actor.velocity.y>0,"Controller jump was not accepted")
        phase=dispatch
        history.clear()
        captured.clear()
        candidate.clear()
        armed=true
        var arrows_before:=int(state.get("inventory").get("arrow",0))
        actor.call("_try_shoot")
        assert(float(actor.get("pending_bow_elapsed"))>0)
        while armed and float(actor.get("pending_bow_elapsed"))>0:
            await physics_frame
            await RenderingServer.frame_post_draw
        if captured.is_empty():
            print("ACTION_START_RENDER_DIAGNOSTIC ",JSON.stringify(history))
            root.get_texture().get_image().save_png("user://action-start-rejected-"+phase+".png")
        assert(not captured.is_empty(),"No rendered raised airborne draw before actual release: "+dispatch)
        captures.append(captured.duplicate(true))
        while float(actor.get("pending_bow_elapsed"))>0:await physics_frame
        assert(int(state.get("inventory").get("arrow",0))==arrows_before-1)
    Input.action_release("move_forward")
    print("ACTION_START_RENDER_OK dispatches=9 render_cap=5 actual_jump=true raised_before_release=true finite_ammo=true")
    world.queue_free()
    await process_frame
    quit()
