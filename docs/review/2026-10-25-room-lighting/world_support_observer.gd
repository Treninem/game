extends Node

var probe := preload("res://tests/humanoid_skin_probe.gd").new()
var samples: Array = []
var last_frame := -1
var want_capture := false

func _ready() -> void:
    get_tree().node_added.connect(_watch)
    for node in get_tree().root.find_children("*","SkeletonModifier3D",true,false): _watch(node)

func _watch(node: Node) -> void:
    if node.name=="WeaponGrip" and node is SkeletonModifier3D:
        var callback := _measure.bind(node)
        if not node.modification_processed.is_connected(callback):
            node.modification_processed.connect(callback)

func _measure(modifier: SkeletonModifier3D) -> void:
    var frame := Engine.get_process_frames()
    if frame==last_frame or (not want_capture and frame%20!=0):return
    var visual:Node3D=modifier.get("visual")
    if not is_instance_valid(visual):return
    var actor:=visual.get_parent() as CharacterBody3D
    if actor==null or actor.name!="Player":return
    want_capture=false;last_frame=frame
    var skeleton:=modifier.get_skeleton()
    var points:Dictionary=probe.points(visual,skeleton)
    var row:Dictionary={"frame":frame,"actor":actor.global_position,"grounded":actor.is_on_floor(),"velocity":actor.velocity,"clip":visual.get("active_animation"),"physical_height":actor.get_node("CollisionShape3D").shape.height,"support_contacts":modifier.get("support").get("contacts").duplicate(true),"root_offset":modifier.get("support").get("root_offset"),"feet":{}}
    for side:String in ["Left","Right"]:
        var lowest:=Vector3.INF
        for point:Vector3 in points[side]:
            if point.y<lowest.y:lowest=point
        var hit:=actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(lowest+Vector3.UP*.45,lowest+Vector3.DOWN*1.5,actor.collision_mask,[actor.get_rid()]))
        row.feet[side]={"lowest":lowest,"vertices":points[side].size(),"hit":not hit.is_empty()}
        if not hit.is_empty():
            row.feet[side].gap=lowest.y-Vector3(hit.position).y
            row.feet[side].collider=str(hit.collider.get_path())
            row.feet[side].normal=hit.normal
    samples.append(row)
    if samples.size()%20==0:_flush()

func _flush() -> void:
    FileAccess.open("user://ordinary-world-support.json",FileAccess.WRITE).store_string(JSON.stringify({"independent_full_boot_vertices":true,"actual_collision_rays":true,"actor_positions_assigned":false,"samples":samples},"  "))

func _exit_tree() -> void:
    _flush()
