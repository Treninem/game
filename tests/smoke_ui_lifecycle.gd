extends Node

class TransientPanel:
    extends Control
    var frame: PanelContainer
    func _init() -> void:
        add_to_group("gameplay_panels")
        frame = PanelContainer.new()
        frame.custom_minimum_size = Vector2(420, 240)
        add_child(frame)

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var guard := get_node("/root/UILayoutGuard")
    var player_marker := Node3D.new()
    player_marker.add_to_group("player")
    add_child(player_marker)
    var magic_hud := get_node("/root/MagicHUD")
    for frame in range(2):
        await get_tree().process_frame
    assert(magic_hud.get("root").visible, "Magic HUD absent during gameplay")
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = true
    for frame in range(2):
        await get_tree().process_frame
    assert(not magic_hud.get("root").visible, "Magic HUD overlaps paused panels")
    get_tree().paused = false
    for frame in range(2):
        await get_tree().process_frame
    assert(magic_hud.get("root").visible, "Magic HUD does not return after closing panels")
    player_marker.queue_free()
    for cycle in range(12):
        var panel := TransientPanel.new()
        add_child(panel)
        # A scene can close between discovery and its deferred layout callback.
        guard.call("_discover")
        panel.free()
        for frame in range(2):
            await get_tree().process_frame
    var live := TransientPanel.new()
    add_child(live)
    for index in range(500):
        var unrelated := Node3D.new()
        live.add_child(unrelated)
    for frame in range(6):
        await get_tree().process_frame
    assert(guard.get("watched").size() == 1, "Closed panels remain in layout tracking")
    assert(guard.get("watched").has(live.get_instance_id()), "New panel was not discovered")
    var bounds := live.frame.get_global_rect()
    var viewport := get_viewport().get_visible_rect()
    assert(viewport.encloses(bounds), "New panel leaves viewport after streamed-node burst")
    assert(not get_tree().paused, "Layout changes pause gameplay")
    live.queue_free()
    for frame in range(3):
        await get_tree().process_frame
    assert(guard.get("watched").is_empty(), "Freed panel remains watched")
    print("UI_LIFECYCLE_OK reopen=12 streamed_nodes=500 bounds=inside stale=cleared")
    get_tree().quit(0)
