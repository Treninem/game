extends Node3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const PATHS := preload("res://scripts/terrain_paths.gd")
const NATURE_ROOT := "res://assets/production/nature/kenney_nature_kit/Models/GLTF format/"
const LOG_LARGE: PackedScene = preload(NATURE_ROOT + "log_large.glb")
const STUMP_DETAIL: PackedScene = preload(NATURE_ROOT + "stump_roundDetailed.glb")

const TRACK_WIDTH := 6.4
const TRACK_STEP := 6.0
const RUT_OFFSET := 1.65
const TRACK_POINTS: Array[Vector2] = [
    Vector2(285.0, 138.0),
    Vector2(470.0, 150.0),
    Vector2(650.0, 120.0)
]

var road_segment_count: int = 0
var civilization_sign_count: int = 0
var logging_sign_count: int = 0
var fishing_sign_count: int = 0
var timber_material: StandardMaterial3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_DISABLED
    timber_material = _material(Color(0.29, 0.17, 0.075, 1.0), 0.97)
    _build_old_cart_track()
    _build_logging_signs()
    _build_fishing_signs()

func _build_old_cart_track() -> void:
    var road_root := Node3D.new()
    road_root.name = "OldCartTrack"
    add_child(road_root)

    # This forest spur joins the canonical road at 650,120. The old second
    # overlay continued all the way through the village as floating flat boxes.
    var footprints: Array[PackedVector2Array] = []
    var left: Array[PackedVector2Array] = []
    var right: Array[PackedVector2Array] = []
    for i in range(TRACK_POINTS.size()-1):
        var a := TRACK_POINTS[i]
        var b := TRACK_POINTS[i+1]
        var side := Vector2(-(b-a).y,(b-a).x).normalized()*RUT_OFFSET
        var count := ceili(a.distance_to(b)/TRACK_STEP)
        for index in range(count):
            var start := a.lerp(b,float(index)/count)
            var finish := a.lerp(b,float(index+1)/count)
            footprints.append(PATHS.strip(start,finish,TRACK_WIDTH))
            left.append(PATHS.strip(start-side,finish-side,0.28))
            right.append(PATHS.strip(start+side,finish+side,0.28))
            road_segment_count += 1
    PATHS.add(road_root,"TrackBed",footprints,"soil",0.03)
    var left_visual := PATHS.add(road_root,"WheelRutLeft",left,"soil",0.04)
    var right_visual := PATHS.add(road_root,"WheelRutRight",right,"soil",0.04)
    var rut := PATHS.material("soil").duplicate() as StandardMaterial3D
    rut.albedo_color = Color(0.55,0.49,0.38)
    if left_visual!=null: left_visual.material_override = rut
    if right_visual!=null: right_visual.material_override = rut
    civilization_sign_count += road_segment_count

func _build_logging_signs() -> void:
    var root := Node3D.new()
    root.name = "OldLoggingSigns"
    add_child(root)

    var stump_positions: Array[Vector2] = [
        Vector2(360, 215), Vector2(385, 230), Vector2(410, 205), Vector2(442, 224), Vector2(468, 197)
    ]
    for i in range(stump_positions.size()):
        var world := stump_positions[i]
        var visual := STUMP_DETAIL.instantiate() as Node3D
        if visual == null:
            continue
        visual.name = "CutStump_%02d" % i
        visual.position = Vector3(world.x, WorldData.elevation_at(world), world.y)
        visual.rotation.y = float(i) * 0.83
        visual.scale = Vector3.ONE * (1.0 + float(i % 3) * 0.12)
        root.add_child(visual)
        logging_sign_count += 1
        civilization_sign_count += 1

    var log_positions: Array[Vector2] = [Vector2(405, 246), Vector2(423, 248), Vector2(441, 246)]
    for i in range(log_positions.size()):
        var world := log_positions[i]
        var holder := StaticBody3D.new()
        holder.name = "FelldLog_%02d" % i
        holder.position = Vector3(world.x, WorldData.elevation_at(world) + 0.28, world.y)
        holder.rotation.y = 1.42 + float(i) * 0.05
        root.add_child(holder)

        var visual := LOG_LARGE.instantiate() as Node3D
        if visual != null:
            visual.name = "Model"
            visual.scale = Vector3.ONE * 1.18
            holder.add_child(visual)

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(3.8, 0.55, 0.75)
        collision.shape = shape
        holder.add_child(collision)
        logging_sign_count += 1
        civilization_sign_count += 1

func _build_fishing_signs() -> void:
    var root := Node3D.new()
    root.name = "OldFishingPlace"
    add_child(root)

    var z := 370.0
    var river_x := GEOGRAPHY.start_river_x(z)
    var bank_x := river_x - GEOGRAPHY.START_RIVER_BANK_WIDTH - 7.0
    var bank := Vector2(bank_x, z)
    root.position = Vector3(bank.x, WorldData.elevation_at(bank), bank.y)

    # A simple abandoned drying/fishing rack. It is physical world evidence, not
    # a quest marker; later interaction systems can attach rope, fish and ownership.
    for x_offset in [-1.8, 1.8]:
        var post := StaticBody3D.new()
        post.name = "RackPost"
        post.position = Vector3(x_offset, 1.35, 0.0)
        root.add_child(post)
        var mesh_node := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.09
        mesh.bottom_radius = 0.12
        mesh.height = 2.7
        mesh.radial_segments = 6
        mesh.material = timber_material
        mesh_node.mesh = mesh
        post.add_child(mesh_node)
        var collision := CollisionShape3D.new()
        var shape := CylinderShape3D.new()
        shape.radius = 0.12
        shape.height = 2.7
        collision.shape = shape
        post.add_child(collision)
        fishing_sign_count += 1
        civilization_sign_count += 1

    var beam := MeshInstance3D.new()
    beam.name = "RackCrossBeam"
    var beam_mesh := BoxMesh.new()
    beam_mesh.size = Vector3(4.0, 0.16, 0.16)
    beam_mesh.material = timber_material
    beam.mesh = beam_mesh
    beam.position = Vector3(0, 2.45, 0)
    root.add_child(beam)
    fishing_sign_count += 1
    civilization_sign_count += 1

    # Two thin abandoned poles point toward the river and make the site readable
    # from the bank without placing modern-looking props in the medieval region.
    for i in range(2):
        var pole := MeshInstance3D.new()
        pole.name = "FishingPole_%02d" % i
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.035
        mesh.bottom_radius = 0.055
        mesh.height = 2.8
        mesh.radial_segments = 6
        mesh.material = timber_material
        pole.mesh = mesh
        pole.position = Vector3(-0.7 + float(i) * 1.4, 0.65, 1.4)
        pole.rotation_degrees = Vector3(65.0, 0.0, 0.0)
        root.add_child(pole)
        fishing_sign_count += 1
        civilization_sign_count += 1

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
