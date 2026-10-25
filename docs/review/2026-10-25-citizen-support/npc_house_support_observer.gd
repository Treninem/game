extends Node

var probe := preload("res://tests/humanoid_skin_probe.gd").new()
var samples: Array = []
var last_frames: Dictionary = {}

func _ready() -> void:
    get_tree().node_added.connect(_watch)
    for node in get_tree().root.find_children("*", "SkeletonModifier3D", true, false): _watch(node)

func _watch(node: Node) -> void:
    if node is SkeletonModifier3D and node.name == "ClothingClearance":
        var callback := _measure.bind(node)
        if not node.modification_processed.is_connected(callback):
            node.modification_processed.connect(callback)

func _measure(modifier: SkeletonModifier3D) -> void:
    var frame := Engine.get_process_frames()
    if frame % 60 != 0 or last_frames.get(modifier.get_instance_id(), -1) == frame: return
    last_frames[modifier.get_instance_id()] = frame
    var visual: Node3D = modifier.get("visual")
    var actor := visual.get_parent() as CharacterBody3D
    if actor == null: return
    var points: Dictionary = probe.points(visual, modifier.get_skeleton())
    var row := {"frame":frame, "actor":String(actor.name), "activity":actor.get_meta("activity", "idle"), "routine":actor.get("activity"), "grounded":actor.is_on_floor(), "position":actor.global_position, "velocity":actor.get_real_velocity(), "clip":visual.get("active_animation"), "feet":{}}
    var support: Variant = modifier.get("seated_support")
    row.support_usec = int(support.get("last_cost_usec")) if support != null else 0
    for side: String in ["Left", "Right"]:
        var low := Vector3.INF
        for point: Vector3 in points[side]:
            if point.y < low.y: low = point
        var excluded: Array[RID] = [actor.get_rid()]
        var seat: RID = actor.get_meta("rest_surface_rid", RID())
        if seat.is_valid(): excluded.append(seat)
        var hit := actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(low+Vector3.UP*.35,low+Vector3.DOWN*.8,actor.collision_mask,excluded))
        row.feet[side] = {"vertices":points[side].size(),"hit":not hit.is_empty()}
        if not hit.is_empty():
            row.feet[side].gap = low.y - Vector3(hit.position).y
            row.feet[side].collider = str(hit.collider.get_path())
    samples.append(row)
    _flush()

func _flush() -> void:
    FileAccess.open("user://npc-house-support.json", FileAccess.WRITE).store_string(JSON.stringify({"independent_all_boot_vertices":true,"rays":true,"actor_positions_assigned_by_observer":false,"samples":samples},"  "))

func _exit_tree() -> void: _flush()
