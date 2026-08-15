extends Node3D

const GEOGRAPHY := preload("res://scripts/world_geography.gd")
const RIVER_Z_MIN := -1700.0
const RIVER_Z_MAX := 1700.0
const RIVER_SEGMENT_LENGTH := 100.0
const RIVER_WIDTH := GEOGRAPHY.START_RIVER_HALF_WIDTH * 2.0
const FORD_Z := -760.0
const FORD_STONE_COUNT := 11

var river_segment_count: int = 0
var ford_stone_count: int = 0
var water_material: StandardMaterial3D
var stone_material: StandardMaterial3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_DISABLED
    water_material = _make_water_material()
    stone_material = _make_material(Color(0.30, 0.31, 0.30), 0.96)
    _build_river()
    _build_old_ford()

func _build_river() -> void:
    var river_root := Node3D.new()
    river_root.name = "StartRiver"
    add_child(river_root)

    var z := RIVER_Z_MIN
    var index := 0
    while z < RIVER_Z_MAX:
        var next_z := minf(z + RIVER_SEGMENT_LENGTH, RIVER_Z_MAX)
        var p0 := Vector2(GEOGRAPHY.start_river_x(z), z)
        var p1 := Vector2(GEOGRAPHY.start_river_x(next_z), next_z)
        var delta := p1 - p0
        var center := (p0 + p1) * 0.5

        var water := MeshInstance3D.new()
        water.name = "RiverWater_%02d" % index
        var mesh := BoxMesh.new()
        mesh.size = Vector3(RIVER_WIDTH, 0.06, delta.length() + 5.0)
        mesh.material = water_material
        water.mesh = mesh
        water.position = Vector3(center.x, GEOGRAPHY.START_RIVER_WATER_LEVEL, center.y)
        water.rotation.y = atan2(delta.x, delta.y)
        water.visibility_range_end = 980.0
        river_root.add_child(water)

        river_segment_count += 1
        index += 1
        z = next_z

func _build_old_ford() -> void:
    var ford_root := Node3D.new()
    ford_root.name = "OldFord"
    add_child(ford_root)

    var river_x := GEOGRAPHY.start_river_x(FORD_Z)
    var width := RIVER_WIDTH + 10.0
    for i in range(FORD_STONE_COUNT):
        var t := float(i) / float(FORD_STONE_COUNT - 1)
        var x := river_x - width * 0.5 + width * t
        var z_offset := sin(float(i) * 1.37) * 1.8
        var size := Vector3(4.6 + float(i % 3) * 0.7, 0.65, 4.1 + float((i + 1) % 3) * 0.6)
        var body := StaticBody3D.new()
        body.name = "FordStone_%02d" % i
        body.position = Vector3(x, GEOGRAPHY.START_RIVER_WATER_LEVEL + 0.15, FORD_Z + z_offset)
        body.rotation.y = float(i) * 0.31
        ford_root.add_child(body)

        var mesh_node := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = size
        mesh.material = stone_material
        mesh_node.mesh = mesh
        body.add_child(mesh_node)

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        ford_stone_count += 1

func _make_water_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.045, 0.24, 0.34, 0.74)
    material.roughness = 0.16
    material.metallic = 0.02
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _make_material(color: Color, roughness_value: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness_value
    return material
