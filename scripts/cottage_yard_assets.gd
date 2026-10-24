extends RefCounted

const KIT_PATH := "res://assets/production/exteriors/cottage_yard/CottageYardKit.glb"
const NATURE := preload("res://scripts/production_nature.gd")
static var meshes: Dictionary = {}
static var materials: Dictionary = {}
static var white_texture: GradientTexture2D

static func material(kind: String) -> Material:
    if materials.has(kind): return materials[kind]
    var result: StandardMaterial3D
    if kind=="Stone":
        result = StandardMaterial3D.new()
        result.albedo_texture = load("res://assets/production/materials/ground/stone_paving.jpg")
        result.albedo_color = Color(0.65,0.62,0.56)
        result.uv1_triplanar = true
        result.uv1_world_triplanar = true
        result.uv1_scale = Vector3.ONE*0.45
        result.roughness = 0.98
        result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    else:
        result = preload("res://scripts/interior_surface_materials.gd").wood(Color(0.85,0.78,0.66) if kind!="RoofWood" else Color(0.72,0.67,0.58))
    materials[kind] = result
    return result

static func mesh(key: String) -> ArrayMesh:
    if meshes.is_empty():
        var source := (load(KIT_PATH) as PackedScene).instantiate() as Node3D
        for visual: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
            var model := visual.mesh.duplicate() as ArrayMesh
            for index in range(model.get_surface_count()):
                var original := visual.get_active_material(index) as StandardMaterial3D
                assert(original!=null,"Cottage kit lost its semantic materials")
                if visual.name=="MeadowFlowers":
                    var wind := ShaderMaterial.new()
                    wind.shader = preload("res://assets/shaders/environment/foliage_wind.gdshader")
                    if white_texture==null:
                        white_texture = GradientTexture2D.new()
                        white_texture.width = 2
                        white_texture.height = 2
                        white_texture.gradient = Gradient.new()
                        white_texture.gradient.colors = PackedColorArray([Color.WHITE,Color.WHITE])
                    wind.set_shader_parameter("albedo_texture",white_texture)
                    wind.set_shader_parameter("vegetation_tint",original.albedo_color)
                    wind.set_shader_parameter("height_anchor",true)
                    wind.set_shader_parameter("wind_strength",0.025)
                    NATURE.wind_materials[wind.get_instance_id()] = wind
                    model.surface_set_material(index,wind)
                else: model.surface_set_material(index,material(original.resource_name))
            meshes[String(visual.name)] = model
        source.free()
    assert(meshes.has(key),"Missing cottage kit model: "+key+" available="+str(meshes.keys()))
    return meshes[key]

static func batch(parent: Node3D,key: String,transforms: Array[Transform3D],distance: float = 220.0,shadows: bool = true) -> MultiMeshInstance3D:
    if transforms.is_empty(): return null
    var data := MultiMesh.new()
    data.transform_format = MultiMesh.TRANSFORM_3D
    data.mesh = mesh(key)
    data.instance_count = transforms.size()
    for i in range(transforms.size()):data.set_instance_transform(i,transforms[i])
    var result := MultiMeshInstance3D.new()
    result.name = key
    result.multimesh = data
    result.visibility_range_end = distance
    result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(result)
    return result

static func beam(a: Vector3,b: Vector3,thickness: float = 1.0) -> Transform3D:
    var y := (b-a).normalized()
    var helper := Vector3.FORWARD if absf(y.dot(Vector3.UP))>0.95 else Vector3.UP
    var x := y.cross(helper).normalized()
    var z := x.cross(y).normalized()
    return Transform3D(Basis(x*thickness,y*a.distance_to(b),z*thickness),(a+b)*0.5)

static func collision(parent: Node3D,label: String,transform: Transform3D,size: Vector3) -> void:
    var body := parent.get_node_or_null("PhysicalDetails") as StaticBody3D
    if body==null:
        body = StaticBody3D.new()
        body.name = "PhysicalDetails"
        parent.add_child(body)
    var shape := CollisionShape3D.new()
    shape.name = label
    shape.transform = transform
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
