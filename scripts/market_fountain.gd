extends StaticBody3D

const MODEL := preload("res://assets/production/architecture/market_court/MarketFountain.glb")
const USE_KEY := "fountain:capital:market:uses"
var basins: Array[MeshInstance3D] = []

func _ready() -> void:
    name = "MarketFountain"
    add_to_group("public_water_source")
    add_to_group("map_fixture")
    set_meta("map_footprint",Vector2(5.4,5.4))
    var visual := MODEL.instantiate()
    add_child(visual)
    var water := ShaderMaterial.new()
    water.shader = preload("res://assets/shaders/environment/ice_surface.gdshader")
    water.set_shader_parameter("freeze_amount",0.0)
    water.set_shader_parameter("water_color",Color(.055,.20,.22,.88))
    water.set_shader_parameter("wave_strength",.003)
    var stream := StandardMaterial3D.new()
    stream.albedo_color = Color(.24,.46,.48,.55)
    stream.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    stream.roughness = .2
    stream.cull_mode = BaseMaterial3D.CULL_DISABLED
    for mesh:MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
        if mesh.name == "FountainStone":
            mesh.material_override = preload("res://assets/production/exteriors/family_home/Stone.tres")
            var collision := CollisionShape3D.new()
            collision.name = "StoneBasinCollision"
            collision.shape = mesh.mesh.create_trimesh_shape()
            add_child(collision)
            collision.global_transform = mesh.global_transform
        elif String(mesh.name) in ["LowerWater","UpperWater"]:
            mesh.material_override = water
            basins.append(mesh)
        else:
            mesh.material_override = stream

func interact(actor:Node) -> void:
    if not actor is Node3D or actor.global_position.distance_to(global_position) > 3.8:
        return
    if GameState.thirst >= 99.9:
        GameState.notify("Жажда уже утолена")
        return
    GameState.thirst = minf(100.0,GameState.thirst+35.0)
    var uses := clampi(int(GameState.get_world_value(USE_KEY,0)),0,2147483646)
    GameState.set_world_value(USE_KEY,uses+1)
    GameState.survival_changed.emit()
    GameState.notify("Вы напились из фонтана")
