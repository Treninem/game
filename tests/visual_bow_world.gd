extends SceneTree

const AUDIO_RETIREMENT = preload("res://tests/audio_retirement_probe.gd")

class CastInputProbe extends Node:
    func _input(event: InputEvent) -> void:
        if event.is_action_pressed("cast_magic"):
            print("CAST_INPUT_STAGE input paused=", get_tree().paused, " handled=", get_viewport().is_input_handled())
    func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("cast_magic"):
            print("CAST_INPUT_STAGE unhandled paused=", get_tree().paused)

var bow_blend_samples := 0
var watched_modifier: Node
var last_bow_process_frame := -1
var walked := 0.0
var captures: Array[String] = []
var player: CharacterBody3D
var observer: Camera3D
var request_airborne_draw := false
var airborne_draw_frame: Dictionary = {}

func _initialize() -> void:
    call_deferred("_run")

func _capture(label: String) -> void:
    await RenderingServer.frame_post_draw
    _capture_rendered(label)

func _capture_rendered(label: String) -> void:
    var path := "user://head-size-" + label + ".png"
    root.get_texture().get_image().save_png(path)
    captures.append(path)

func _frames(count: int) -> void:
    for i in range(count):
        var before := player.global_position
        await physics_frame
        walked += Vector2(player.global_position.x - before.x, player.global_position.z - before.z).length()
        _follow_player()
        _check_live_bow_arm()

func _follow_player() -> void:
    observer.global_position = player.global_position + player.global_basis * Vector3(2.1, 1.8, -4.7)
    observer.look_at(player.global_position + Vector3.UP * 1.15)
    observer.force_update_transform()

func _action(action: String) -> void:
    var event := InputEventAction.new()
    event.action = action
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    if action == "attack" and root.get_node("InventorySystem").call("equipped_item", "weapon") == "short_bow":
        assert(float(player.get("pending_bow_elapsed")) > 0.0)
    await physics_frame
    event = InputEventAction.new()
    event.action = action
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    await process_frame
    await RenderingServer.frame_post_draw

func _run() -> void:
    root.add_child(CastInputProbe.new())
    create_timer(180).timeout.connect(func(): push_error("FACE_NATIVE timeout"); quit(1))
    root.get_node("SettingsManager").call("set_quality_preset", 0)
    change_scene_to_file("res://scenes/character_creator.tscn")
    await process_frame
    await process_frame
    var creator := current_scene
    var appearance = load("res://scripts/character_appearance.gd")
    creator.call("select_preview_motion", 0)
    creator.set("profile", appearance.normalized({"sex": "female", "HeadSize": 0.23, "FaceHeight": 0.21, "FaceDepth": -0.18, "NoseWidth": -0.3, "NoseHeight": 0.24, "eye_color": 4, "height_cm": 195.0}))
    creator.call("_refresh")
    var expected: Dictionary = creator.get("profile").duplicate(true)
    assert(appearance.save_look(expected) == OK and appearance.load_look() == expected)
    creator.call("start_journey")
    while player == null or current_scene.name != "Bootstrap" or bool(player.get_meta("loading_gate_active", true)) or bool(player.get("ground_guard_active")):
        await physics_frame
        player = get_first_node_in_group("player") as CharacterBody3D
    for frame in range(40):
        await process_frame
    observer = Camera3D.new()
    observer.fov = 43
    current_scene.add_child(observer)
    observer.make_current()
    await _frames(20)
    assert(player.get_node("Avatar").get("current_profile") == expected)
    Input.action_press("move_forward")
    await _frames(90)
    await _capture("walk")
    Input.action_press("sprint")
    await _frames(80)
    await _capture("run")
    Input.action_release("sprint")
    Input.action_release("move_forward")
    await _frames(12)
    var jump_floor := player.global_position.y
    await _action("jump")
    await _frames(10)
    assert(player.global_position.y > jump_floor + 0.1)
    await _capture("tall-jump")
    await _frames(60)
    assert(player.is_on_floor())
    var state := root.get_node("GameState")
    var inventory := root.get_node("InventorySystem")
    state.call("add_item", "arrow", 3)
    for item in ["starter_axe", "short_bow"]:
        state.call("add_item", item, 1)
        inventory.call("equip", item)
        await _frames(4)
        if item == "short_bow":
            Input.action_press("move_forward")
            await _action("jump")
            request_airborne_draw = true
            airborne_draw_frame.clear()
        await _action("attack")
        await _frames(2)
        assert(float(player.get("attack_elapsed")) > 0.0)
        if item == "short_bow":
            # Check the exact rendered draw frame. Waiting for another draw
            # call can legitimately cross the 0.22 s release on a slow GPU.
            assert(not airborne_draw_frame.is_empty(), "No airborne bow draw frame was rendered")
            assert(float(airborne_draw_frame.pending) > 0.0)
            print("AIRBORNE_WORLD_POSE ", JSON.stringify(airborne_draw_frame))
            if airborne_draw_frame.pose != "Bow_Attack_Draw" or airborne_draw_frame.grounded:
                push_error("AIRBORNE_WORLD lost bow draw during jump")
                quit(1)
                return
        else:
            await _capture(item)
        await _frames(51)
        if item == "short_bow":
            assert(int(state.get("inventory").get("arrow", 0)) == 2)
            Input.action_release("move_forward")
            await _capture("bow-released")
            # Preserve the minimum coverage using distinct rendered poses,
            # rather than counting repeated physics observations of one frame.
            for extra in range(5):
                if bow_blend_samples >= 20:
                    break
                if int(state.get("inventory").get("arrow", 0)) == 0:
                    state.call("add_item", "arrow", 1)
                var arrows_before := int(state.get("inventory").get("arrow", 0))
                await _action("attack")
                await _frames(53)
                assert(int(state.get("inventory").get("arrow", 0)) == arrows_before - 1)
        inventory.call("unequip", "weapon")
    var save := root.get_node("SaveManager")
    assert(save.call("save_game", player, 9))
    var short_profile := expected.duplicate(true)
    short_profile.height_cm = 160.0
    state.call("set_world_value", "player_appearance", short_profile)
    player.get_node("Avatar").call("apply_appearance", short_profile)
    await _frames(5)
    assert(is_equal_approx(((player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D).height, 1.6))
    var walked_before := walked
    player.rotation.y += PI * 0.5
    Input.action_press("move_forward")
    await _frames(60)
    Input.action_release("move_forward")
    await _frames(12)
    assert(walked > walked_before + 1.0 and player.is_on_floor())
    await _capture("short-walk")
    var short_floor := player.global_position.y
    await _action("jump")
    await _frames(10)
    assert(player.global_position.y > short_floor + 0.1)
    await _capture("short-jump")
    await _frames(60)
    assert(player.is_on_floor())
    state.call("set_world_value", "player_appearance", appearance.preset(0))
    assert(save.call("load_game", player, 9))
    await _frames(8)
    assert(player.get_node("Avatar").get("current_profile") == expected)
    assert(walked > 8.0 and player.is_on_floor())
    assert(is_equal_approx(((player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D).height, 1.95))
    assert(is_equal_approx((player.get_node("CameraPivot") as Node3D).position.y, 1.35 * 195.0 / 180.0))
    var restored_eyes := player.get_node("Avatar").find_child("Eyes", true, false) as MeshInstance3D
    assert((restored_eyes.get_active_material(0) as StandardMaterial3D).albedo_texture == load("res://assets/production/characters/realistic/eyes/lightblue_eye.png"))
    var magic := root.get_node("MagicSystem")
    for attempt in range(10):
        if magic.call("selected_spell_id") == "heal":
            break
        await _action("next_spell")
    assert(magic.call("selected_spell_id") == "heal")
    var cast_counter := {"count": 0}
    magic.connect("spell_cast", func(_id: String):
        cast_counter.count += 1
        cast_counter.mana = float(state.get("mana"))
        cast_counter.health = float(state.get("health"))
    )
    state.set("health", 45.0)
    state.emit_signal("survival_changed")
    var mana_before := float(state.get("mana"))
    Input.action_press("move_forward")
    await _frames(10)
    print("CAST_BEFORE input_disabled=", root.is_input_disabled(), " player_unhandled=", player.is_processing_unhandled_input(), " focus=", root.has_focus())
    await _action("cast_magic")
    print("MAGIC_INPUT_DIAGNOSTIC ", JSON.stringify({"casts":cast_counter.count,"paused":paused,"dialogue":root.get_node("DialogueManager").get("is_open"),"mana":state.get("mana"),"cooldown":magic.call("cooldown_left", "heal"),"selected":magic.call("selected_spell_id"),"focus":str(root.gui_get_focus_owner())}))
    assert(cast_counter.count == 1)
    assert(float(cast_counter.health) >= 82.9 and is_equal_approx(float(cast_counter.mana), mana_before - 30.0))
    await _frames(6)
    var cast_visual := player.get_node("Avatar")
    assert(String(cast_visual.get("active_animation")) == "Cast_Left")
    assert(bool(cast_visual.get("grip_modifier").get("gait_applied")))
    await _capture("cast-free-hand")
    Input.action_release("move_forward")
    assert(root.get_node("SaveManager").call("save_game", player, 8))
    await _action("next_spell")
    assert(root.get_node("SaveManager").call("load_game", player, 8))
    assert(magic.call("selected_spell_id") == "heal" and float(magic.call("cooldown_left", "heal")) > 0.0)
    var loaded_mana := float(state.get("mana"))
    await _action("cast_magic")
    assert(cast_counter.count == 1 and float(state.get("mana")) >= loaded_mana - 0.001)
    await _capture("magic-after-load")
    print("MAGIC_NATIVE_SAVE_OK action=cast_magic selected=heal cooldown=restored blocked_cast=no_mana_cost")
    var panels := current_scene.get_node("UI/GameplayPanels")
    for cycle in range(12):
        panels.call("open_panel", "inventory" if cycle % 2 == 0 else "map")
        await RenderingServer.frame_post_draw
        assert(not root.get_node("MagicHUD").get("root").visible)
        if cycle == 10:
            await _capture("inventory-lifecycle")
        panels.call("close_panel")
        await process_frame
    assert(not paused and not panels.visible)
    print("UI_NATIVE_REOPEN_OK cycles=12 inventory+map gameplay_resumed=true")
    assert(bow_blend_samples >= 20)
    print("LIVE_BOW_BLEND_OK samples=", bow_blend_samples)
    for preset in [0,1,2,3]:
        root.get_node("SettingsManager").call("set_quality_preset",preset)
        for frame in range(30):await process_frame
        await _capture("outfit-quality-%d" % preset)
        if preset==1:
            var sample_start := Time.get_ticks_usec()
            for frame in range(120):await process_frame
            print("OUTFIT_WORLD_FRAME_SAMPLE frames=120 mean_ms=",float(Time.get_ticks_usec()-sample_start)/120000.0,
                " video_bytes=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
                " draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
    root.get_node("SettingsManager").call("set_quality_preset",0)
    print("FACE_CONTROLS_NATIVE_OK ", JSON.stringify({"walked_m": walked, "player_position_assignments": 0, "captures": captures, "look_roundtrip": true, "game_save_roundtrip": true, "bow_arrow_consumed": true, "morphs": 9, "physical_heights_cm": [160,195], "jump_both_heights": true}))
    change_scene_to_file("res://scenes/main_menu.tscn")
    for frame in range(12):
        await process_frame
    var menu_music: AudioStreamPlayer = current_scene.get_node("MenuMusic")
    var retired: Array[WeakRef] = [AUDIO_RETIREMENT.stream_reference(menu_music), AUDIO_RETIREMENT.playback_reference(menu_music)]
    menu_music.call("shutdown")
    assert(not menu_music.playing and menu_music.stream == null)
    var released: bool = await AUDIO_RETIREMENT.wait_retired(self, retired)
    assert(released, "Menu audio retained a decoder at world-probe exit")
    print("MENU_AUDIO_SHUTDOWN_OK stream=cleared mixer=drained")
    quit(0)

func _check_live_bow_arm() -> void:
    var visual := player.get_node("Avatar")
    var modifier: Node = visual.get("grip_modifier")
    if is_instance_valid(watched_modifier) and watched_modifier == modifier:
        return
    watched_modifier = modifier
    var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    modifier.modification_processed.connect(func(): _inspect_live_bow_arm(visual, skeleton))

func _inspect_live_bow_arm(visual: Node3D, skeleton: Skeleton3D) -> void:
    if not is_instance_valid(visual) or not is_instance_valid(skeleton):
        return
    var animator: AnimationPlayer = visual.get("animation_player")
    if animator.assigned_animation not in ["Bow_Attack_Draw", "Bow_Attack_Shoot"]:
        return
    var frame := Engine.get_process_frames()
    if frame == last_bow_process_frame:
        return
    last_bow_process_frame = frame
    var points := {}
    for bone: String in ["LeftArm", "RightArm", "RightForeArm", "RightHand", "Spine1", "Spine2", "Neck"]:
        points[bone] = player.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin))
    var center: Vector3 = points.Spine2
    var side: Vector3 = points.RightArm - points.LeftArm
    side.y = 0
    var radius_x := side.length() * 0.36
    side = side.normalized()
    var forward := Vector3(side.z, 0, -side.x)
    var ratio := float(visual.get("current_profile").get("height_cm", 180.0)) / 180.0
    for segment in [["RightArm", "RightForeArm"], ["RightForeArm", "RightHand"]]:
        for step in range(3 if segment[0] == "RightArm" else 1, 13):
            var point: Vector3 = (points[segment[0]] as Vector3).lerp(points[segment[1]], step / 12.0)
            if point.y <= points.Spine1.y or point.y >= points.Neck.y - 0.045 * ratio:
                continue
            var radial := pow((point - center).dot(side) / radius_x, 2) + pow((point - center).dot(forward) / (0.09 * ratio), 2)
            assert(radial >= 1.0, "Live bow blend enters central torso: " + str(segment) + " point=" + str(point))
    bow_blend_samples += 1
    print("LIVE_BOW_BLEND_SAMPLE ", bow_blend_samples)
    # The first Draw-labelled frame can correctly still be the initial
    # preparation pose. Require actual raised-hand geometry and clip progress,
    # while the physical draw is still pending, for the tension review image.
    if request_airborne_draw and animator.assigned_animation == "Bow_Attack_Draw" and not player.is_on_floor() and animator.current_animation_position >= 0.20 and points.RightHand.y >= points.Neck.y - 0.25 * ratio:
        _follow_player()
        assert(root.get_camera_3d() == observer)
        var head := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin) + Vector3.UP * 0.32 * ratio
        var foot := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("LeftToeBase")).origin) - Vector3.UP * 0.08 * ratio
        var head_pixel := observer.unproject_position(head)
        var foot_pixel := observer.unproject_position(foot)
        var frame_rect := root.get_visible_rect().grow(-24)
        assert(observer.is_position_in_frustum(head) and frame_rect.has_point(head_pixel), "Draw head cropped")
        assert(observer.is_position_in_frustum(foot) and frame_rect.has_point(foot_pixel), "Draw feet cropped")
        request_airborne_draw = false
        var observed := {"pose":String(animator.assigned_animation), "animation_time":animator.current_animation_position,"wrist_below_neck_m":points.Neck.y-points.RightHand.y,"head_pixel":str(head_pixel),"foot_pixel":str(foot_pixel),"grounded":player.is_on_floor(), "pending":float(player.get("pending_bow_elapsed")), "frame":frame}
        RenderingServer.frame_post_draw.connect(func():
            assert(Engine.get_process_frames() == int(observed.frame), "Draw image and skeleton observation differ by a frame")
            _capture_rendered("short_bow")
            airborne_draw_frame = observed
        , CONNECT_ONE_SHOT)
