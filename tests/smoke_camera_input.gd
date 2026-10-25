extends "res://tests/smoke_boot_world.gd"

func _assert_pause_load_roundtrip(world: Node, player: CharacterBody3D) -> bool:
    # Headless DisplayServer always reports a visible cursor even after capture.
    # This test must run on Windows or under Xvfb with a real rendering backend.
    if DisplayServer.get_name() == "headless":
        _fail(18, "camera validation requires GODOT_SMOKE_GRAPHICAL=1 and a display")
        return false
    await get_tree().create_timer(0.3).timeout
    if Input.mouse_mode != SettingsManager.gameplay_mouse_mode():
        _fail(19, "loaded gameplay did not capture the mouse for camera control")
        return false
    var original_scale := float(SettingsManager.get_value("graphics", "ui_scale"))
    var original_compatibility := bool(SettingsManager.get_value("gameplay", "compatible_mouse"))
    var original_distance := float(SettingsManager.get_value("gameplay", "camera_distance"))
    for ui_scale in [0.75, 1.0, 1.5]:
        SettingsManager.set_value("graphics", "ui_scale", ui_scale)
        for compatible in [false, true]:
            SettingsManager.set_value("gameplay", "compatible_mouse", compatible)
            SettingsManager.capture_gameplay_mouse()
            await get_tree().create_timer(0.15).timeout
            if not await _check_mouse_motion(world, player):
                return false
            SettingsManager.set_camera_distance(5.5)
            var wheel := InputEventMouseButton.new()
            wheel.button_index = MOUSE_BUTTON_WHEEL_UP
            wheel.pressed = true
            Input.parse_input_event(wheel)
            await get_tree().process_frame
            if float(SettingsManager.get_value("gameplay", "camera_distance")) != 5.0:
                _fail(23, "mouse wheel does not zoom the gameplay camera")
                return false
            var menu := world.get_node("UI/GameMenu")
            menu.call("open_menu", "other")
            if not get_tree().paused or not menu.visible:
                _fail(24, "zoom pause check did not open the actual game menu")
                return false
            Input.parse_input_event(wheel)
            await get_tree().process_frame
            var yaw_before_close := player.rotation.y
            var pitch_before_close := (player.get_node("CameraPivot") as Node3D).rotation.x
            menu.call("close_menu")
            var stale_menu_motion := InputEventMouseMotion.new()
            stale_menu_motion.position = Vector2(205, 676)
            stale_menu_motion.relative = Vector2(-435, 316)
            stale_menu_motion.screen_relative = stale_menu_motion.relative
            Input.parse_input_event(stale_menu_motion)
            await get_tree().process_frame
            if absf(player.rotation.y - yaw_before_close) > 0.001 or absf((player.get_node("CameraPivot") as Node3D).rotation.x - pitch_before_close) > 0.001:
                _fail(26, "returning from a menu applies stale pointer motion and snaps the camera")
                return false
            if float(SettingsManager.get_value("gameplay", "camera_distance")) != 5.0:
                _fail(24, "scrolling a paused menu also zooms gameplay")
                return false
    SettingsManager.set_camera_distance(original_distance)
    SettingsManager.set_value("graphics", "ui_scale", original_scale)
    SettingsManager.set_value("gameplay", "compatible_mouse", original_compatibility)
    SettingsManager.capture_gameplay_mouse()
    print("CAMERA_INPUT_SMOKE_OK mouse=confined_or_captured yaw=responsive pitch=responsive scales=3 modes=2 warp=no_drift")
    return await super._assert_pause_load_roundtrip(world, player)

func _check_mouse_motion(world: Node, player: CharacterBody3D) -> bool:
    var old_rotation := player.rotation
    var pivot := player.get_node("CameraPivot") as Node3D
    var old_pitch := pivot.rotation
    var motion := InputEventMouseMotion.new()
    # Regression: a visible HUD control must not steal captured camera input.
    var overlay := Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    world.add_child(overlay)
    motion.position = Vector2(DisplayServer.window_get_size()) * 0.5
    if SettingsManager.uses_compatible_mouse():
        motion.position += Vector2(32.0, 12.0)
    motion.global_position = motion.position
    motion.relative = Vector2(32.0, 12.0)
    motion.screen_relative = motion.relative
    Input.parse_input_event(motion)
    await get_tree().process_frame
    var camera_moved := absf(player.rotation.y - old_rotation.y) > 0.01 and absf(pivot.rotation.x - old_pitch.x) > 0.005
    print("CAMERA_MOTION_CHECK scale=", SettingsManager.get_value("graphics", "ui_scale"), " compatible=", SettingsManager.uses_compatible_mouse(), " paused=", get_tree().paused, " mode=", Input.mouse_mode, " yaw_delta=", player.rotation.y - old_rotation.y, " pitch_delta=", pivot.rotation.x - old_pitch.x)
    if SettingsManager.uses_compatible_mouse():
        var turned := player.rotation.y
        var warp := InputEventMouseMotion.new()
        warp.position = Vector2(DisplayServer.window_get_size()) * 0.5
        warp.relative = -motion.relative
        warp.screen_relative = warp.relative
        Input.parse_input_event(warp)
        await get_tree().process_frame
        if absf(player.rotation.y - turned) > 0.001:
            _fail(22, "cursor recentering cancelled a real camera turn")
            return false
        var absolute := InputEventMouseMotion.new()
        absolute.position = get_viewport().get_visible_rect().get_center() + Vector2(24, 8)
        absolute.global_position = absolute.position
        Input.parse_input_event(absolute)
        await get_tree().process_frame
        if absf(player.rotation.y - turned) < 0.01:
            _fail(25, "absolute-only pointing motion leaves the camera frozen")
            return false
    player.rotation = old_rotation
    pivot.rotation = old_pitch
    if not camera_moved:
        _fail(20, "mouse movement did not rotate the loaded gameplay camera")
        return false
    overlay.queue_free()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.pressed = true
    var stamina_before := GameState.stamina
    Input.parse_input_event(click)
    await get_tree().process_frame
    if Input.mouse_mode != SettingsManager.gameplay_mouse_mode() or GameState.stamina < stamina_before - 1.0:
        _fail(21, "first gameplay click did not restore capture safely")
        return false
    return true
