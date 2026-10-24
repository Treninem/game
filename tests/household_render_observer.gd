extends Node

var start_usec := 0
var idle_usec := 0
var pre_draw_usec := 0
var previous_draw_usec := 0
var last_flush_usec := 0
var last_print_usec := 0
var physics_callbacks := 0
var previous_physics_callbacks := 0
var minimum_physics_delta := INF
var maximum_physics_delta := 0.0
var modifiers_frame := -1
var modifier_costs: Dictionary = {}
var samples: Array = []
var intervals: Array[float] = []
var render_phases: Array[float] = []
var idle_phases: Array[float] = []
var draw_call_sum := 0.0
var draw_call_max := 0.0
var total_samples := 0
var metadata: Dictionary = {}

func _ready() -> void:
    start_usec = Time.get_ticks_usec()
    metadata = {"platform": OS.get_name(), "adapter": RenderingServer.get_video_adapter_name(),
        "engine": Engine.get_version_info(), "passive_observer": true,
        "normal_clock_required": true, "render_loop_changed": false,
        "graphics_changed": false, "actor_positions_changed": false,
        "scope": "Unchanged continuous household diagnostic with observer overhead. Draw signal intervals do not isolate GPU execution; software-renderer measurements are not target-PC FPS."}
    get_tree().process_frame.connect(_idle_begin)
    RenderingServer.frame_pre_draw.connect(_draw_begin)
    RenderingServer.frame_post_draw.connect(_draw_end)
    get_tree().node_added.connect(_watch_modifier)
    for node in get_tree().root.find_children("*", "SkeletonModifier3D", true, false):
        _watch_modifier(node)
    _flush()

func _physics_process(delta: float) -> void:
    physics_callbacks += 1
    minimum_physics_delta = minf(minimum_physics_delta, delta)
    maximum_physics_delta = maxf(maximum_physics_delta, delta)

func _idle_begin() -> void:
    idle_usec = Time.get_ticks_usec()

func _draw_begin() -> void:
    pre_draw_usec = Time.get_ticks_usec()

func _draw_end() -> void:
    var now := Time.get_ticks_usec()
    if previous_draw_usec > 0:
        var interval := float(now - previous_draw_usec) / 1000.0
        var render_phase := float(maxi(0, now - pre_draw_usec)) / 1000.0
        var idle_phase := float(maxi(0, pre_draw_usec - idle_usec)) / 1000.0
        intervals.append(interval)
        render_phases.append(render_phase)
        idle_phases.append(idle_phase)
        total_samples += 1
        var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
        draw_call_sum += draw_calls
        draw_call_max = maxf(draw_call_max, draw_calls)
        if total_samples <= 12 or total_samples % 15 == 0 or interval > 250:
            samples.append({"elapsed_wall_ms": float(now - start_usec) / 1000.0,
                "engine_process_frame": Engine.get_process_frames(),
                "engine_physics_frame": Engine.get_physics_frames(),
                "observed_physics_callbacks": physics_callbacks,
                "physics_callbacks_since_last_draw": physics_callbacks - previous_physics_callbacks,
                "frame_interval_ms": interval, "idle_to_pre_draw_ms": idle_phase,
                "pre_to_post_draw_ms": render_phase,
                "process_monitor_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
                "physics_monitor_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
                "draw_calls": draw_calls,
                "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
                "modifier_frame": modifiers_frame,
                "modifier_self_costs": modifier_costs.values().duplicate(true)})
            if samples.size() > 512:
                samples.remove_at(12)
    previous_physics_callbacks = physics_callbacks
    previous_draw_usec = now
    if now - last_flush_usec > 1000000:
        _flush()
    if now - last_print_usec > 15000000:
        print("HOUSEHOLD_RENDER_PROFILE ", JSON.stringify(_summary()))
        last_print_usec = now

func _watch_modifier(node: Node) -> void:
    if not node is SkeletonModifier3D or node.name not in ["WeaponGrip", "ClothingClearance"]:
        return
    var callback := _record_modifier.bind(node)
    if not node.modification_processed.is_connected(callback):
        node.modification_processed.connect(callback)

func _record_modifier(node: Node) -> void:
    var frame := Engine.get_process_frames()
    if modifiers_frame != frame:
        modifiers_frame = frame
        modifier_costs.clear()
    var visual := node.get("visual") as Node3D
    if not is_instance_valid(visual):
        return
    var clearance: RefCounted = node.get("clearance")
    var support: RefCounted = node.get("support") if node.name == "WeaponGrip" else node.get("seated_support")
    var response: RefCounted = node.get("motion_response")
    var row: Dictionary = modifier_costs.get(node.get_instance_id(), {
        "actor": String(visual.get_parent().name), "modifier": String(node.name), "calls": 0,
        "clearance_usec": 0, "support_usec": 0, "response_usec": 0, "cold_geometry_usec": 0})
    row.calls += 1
    if clearance != null:
        row.clearance_usec += int(clearance.get("last_usec"))
        var data: Dictionary = clearance.get("data")
        row.cold_geometry_usec = int(data.get("cold_build_usec", 0))
    if support != null:
        row.support_usec += int(support.get("last_cost_usec"))
    if response != null:
        row.response_usec += int(response.get("last_cost_usec"))
    modifier_costs[node.get_instance_id()] = row

func _stats(values: Array[float]) -> Dictionary:
    if values.is_empty():
        return {"samples": 0}
    var ordered := values.duplicate()
    ordered.sort()
    var total := 0.0
    for value in values:
        total += value
    return {"samples": values.size(), "mean_ms": total / values.size(),
        "median_ms": ordered[ordered.size() / 2],
        "p95_ms": ordered[mini(ordered.size() - 1, int(ordered.size() * .95))],
        "max_ms": ordered.back()}

func _summary() -> Dictionary:
    return {"elapsed_wall_ms": float(Time.get_ticks_usec() - start_usec) / 1000.0,
        "frames": _stats(intervals), "idle_to_pre_draw": _stats(idle_phases),
        "pre_to_post_draw": _stats(render_phases),
        "observed_physics_callbacks": physics_callbacks,
        "minimum_physics_delta": minimum_physics_delta if is_finite(minimum_physics_delta) else 0,
        "maximum_physics_delta": maximum_physics_delta,
        "time_scale": Engine.time_scale, "physics_ticks_per_second": Engine.physics_ticks_per_second,
        "max_physics_steps_per_frame": Engine.max_physics_steps_per_frame,
        "viewport": str(get_tree().root.size), "scale_3d": get_tree().root.scaling_3d_scale,
        "mean_draw_calls": draw_call_sum / maxi(1, total_samples), "max_draw_calls": draw_call_max,
        "video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}

func _flush() -> void:
    last_flush_usec = Time.get_ticks_usec()
    var residents: Array = []
    for actor in get_tree().get_nodes_in_group("settlement_npc"):
        residents.append({"name": String(actor.name), "position": actor.position,
            "activity": actor.get("activity"), "velocity": actor.velocity})
    var file := FileAccess.open("user://household-render-profile.json", FileAccess.WRITE)
    if file == null:
        push_error("Cannot persist continuous household render measurements")
        return
    file.store_string(JSON.stringify({"metadata": metadata, "summary": _summary(),
        "residents": residents, "samples": samples}, "  "))
    file.close()
