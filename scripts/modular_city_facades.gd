extends RefCounted

const ROOT := "res://assets/production/medieval/quaternius_city_core/"
const COURT := preload("res://scripts/cottage_yard_assets.gd")
static var photo_materials: Dictionary = {}
static var cached_modules: Dictionary = {}
static var gable_mesh: ArrayMesh
var groups: Dictionary = {}
var detail_counts := {"timber":0,"window_boxes":0,"flowers":0,"authored_houses":0}

func _module(path: String) -> Array:
    if cached_modules.has(path):
        return cached_modules[path]
    var scene := load(path) as PackedScene
    var source := scene.instantiate() as Node3D
    var result: Array = []
    _collect(source, Transform3D.IDENTITY, result)
    source.free()
    cached_modules[path] = result
    return result

func _collect(node: Node3D, inherited: Transform3D, result: Array) -> void:
    var transform := inherited * node.transform
    if node is MeshInstance3D:
        var visual := node as MeshInstance3D
        var mesh := visual.mesh.duplicate() as ArrayMesh
        for surface in range(mesh.get_surface_count()):
            mesh.surface_set_material(surface, _city_material(visual.get_active_material(surface)))
        result.append({"mesh": mesh, "transform": transform})
    for child in node.get_children():
        if child is Node3D:
            _collect(child, transform, result)

func _add_mesh(mesh: Mesh, transform: Transform3D, distance: float = 520.0) -> void:
    var key := mesh.get_instance_id()
    if not groups.has(key):
        groups[key] = {"mesh": mesh, "transforms": [], "range_end":distance}
    groups[key].transforms.append(transform)
    groups[key].range_end = minf(float(groups[key].range_end),distance)

func _add_module(path: String, transform: Transform3D) -> void:
    for part: Dictionary in _module(path):
        _add_mesh(part.mesh, transform * Transform3D(part.transform))

func add_house(origin: Vector3, yaw: float, footprint: Vector2, stories: int, brick: bool = false, authored: bool = false) -> void:
    var house := Transform3D(Basis(Vector3.UP, yaw), origin)
    if authored and stories in [2,3]:
        _add_module("res://assets/production/architecture/townhouse/Townhouse_%d.glb"%stories,house*Transform3D(Basis.from_scale(Vector3(footprint.x/8.0,1,footprint.y/10.0)),Vector3.ZERO))
        detail_counts.authored_houses += 1
        for level in range(stories):
            for x:float in [-2.4,2.4]:
                var point:=Vector3(x*footprint.x/8.0,level*3.12+.72,footprint.y*.5+.27)
                _add_mesh(COURT.mesh("WindowPlanter"),house*Transform3D(Basis.from_scale(Vector3(.85,1,1)),point),180.0)
                detail_counts.window_boxes += 1
                for offset:float in [-.42,0,.42]:
                    _add_mesh(COURT.mesh("MeadowFlowers"),house*Transform3D(Basis.from_scale(Vector3.ONE*.8),point+Vector3(offset,.26,0)),180.0)
                    detail_counts.flowers += 1
        return
    var style := "UnevenBrick" if brick else "Plaster"
    var straight := ROOT + "Wall_%s_Straight.gltf" % style
    var window := ROOT + "Wall_%s_Window_Wide_Round.gltf" % style
    var doorway := ROOT + "Wall_%s_Door_Round.gltf" % style
    var count_x := maxi(2, roundi(footprint.x / 2.0))
    var count_z := maxi(2, roundi(footprint.y / 2.0))
    var step_x := footprint.x / count_x
    var step_z := footprint.y / count_z
    for story in range(stories):
        var height := float(story) * 3.12
        for index in range(count_x):
            var x := -footprint.x * 0.5 + (index + 0.5) * step_x
            var front := doorway if story == 0 and index == count_x / 2 else window if index % 2 == 0 else straight
            _add_module(front, house * Transform3D(Basis.from_scale(Vector3(step_x / 2.0, 1, 1)), Vector3(x, height, footprint.y * 0.5)))
            _add_module(window if index % 2 == 0 else straight, house * Transform3D(Basis(Vector3.UP, PI) * Basis.from_scale(Vector3(step_x / 2.0, 1, 1)), Vector3(x, height, -footprint.y * 0.5)))
            if front == doorway:
                _add_module("res://assets/production/medieval/building_shell/Door_1_Flat.gltf", house * Transform3D(Basis.IDENTITY, Vector3(x, 0.05, footprint.y * 0.5 + 0.06)))
        for index in range(count_z):
            var z := -footprint.y * 0.5 + (index + 0.5) * step_z
            for side: float in [-1.0, 1.0]:
                _add_module(window if index % 2 == 0 else straight, house * Transform3D(Basis(Vector3.UP, side * PI * 0.5) * Basis.from_scale(Vector3(step_z / 2.0, 1, 1)), Vector3(side * footprint.x * 0.5, height, z)))
    var roof_base := house * Transform3D(Basis.IDENTITY, Vector3(0, float(stories) * 3.12, 0))
    var roof_scale := Basis.from_scale(Vector3((footprint.x + 0.8) / 8.0, 0.65, (footprint.y + 0.8) / 8.0))
    _add_module(ROOT + "Roof_RoundTiles_8x8.gltf", roof_base * Transform3D(roof_scale, Vector3.ZERO))
    _add_mesh(_gables(), roof_base * Transform3D(roof_scale, Vector3.ZERO))
    _add_module(ROOT + "Prop_Chimney.gltf", roof_base * Transform3D(Basis.IDENTITY, Vector3(footprint.x * 0.22, 1.2, -footprint.y * 0.18)))
    _add_townhouse_details(house,footprint,stories,count_x,step_x)

func _gables() -> ArrayMesh:
    if gable_mesh != null:
        return gable_mesh
    var material := _photo_plaster()
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_material(material)
    for z: float in [-4.0, 4.0]:
        var corners := [Vector3(-4, -0.05, z), Vector3(0, 5.5, z), Vector3(4, -0.05, z)]
        if z < 0:
            corners.reverse()
        for corner: Vector3 in corners:
            surface.add_vertex(corner)
    surface.generate_normals()
    gable_mesh = surface.commit()
    return gable_mesh

func finish(parent: Node3D) -> void:
    for group: Dictionary in groups.values():
        var instances := MultiMesh.new()
        instances.transform_format = MultiMesh.TRANSFORM_3D
        instances.mesh = group.mesh
        instances.instance_count = group.transforms.size()
        for index in range(instances.instance_count):
            instances.set_instance_transform(index, group.transforms[index])
        var batch := MultiMeshInstance3D.new()
        batch.name = "AuthoredCityFacades_%d" % parent.get_child_count()
        batch.multimesh = instances
        batch.visibility_range_end = float(group.range_end)
        parent.add_child(batch)
    apply_surface_quality(int(SettingsManager.get_value("graphics","quality_preset")))
    parent.set_meta("concept_facade_details",detail_counts.duplicate())
    groups.clear()

func _photo_plaster() -> StandardMaterial3D:
    if photo_materials.has("plaster"):return photo_materials.plaster
    var material := StandardMaterial3D.new()
    material.resource_name = "CityLimePlaster"
    material.albedo_texture = load("res://assets/production/interiors/materials/lime_plaster/albedo.jpg")
    material.albedo_color = Color(.84,.81,.72)
    material.roughness = 1.0
    material.normal_texture = load("res://assets/production/interiors/materials/lime_plaster/normal.png")
    material.normal_scale = .35
    material.normal_enabled = int(SettingsManager.get_value("graphics","quality_preset"))>=2
    material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
    if material.normal_enabled:material.roughness_texture=load("res://assets/production/interiors/materials/lime_plaster/orm.png")
    material.uv1_triplanar = true
    material.uv1_world_triplanar = true
    material.uv1_scale = Vector3.ONE * .5
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    photo_materials.plaster = material
    return material

func _city_material(original: Material) -> Material:
    if not original is StandardMaterial3D:return original
    var role := original.resource_name
    if role=="Plaster":return _photo_plaster()
    if role=="Timber":return load("res://assets/production/exteriors/family_home/Timber.tres")
    if role=="Stone":return load("res://assets/production/exteriors/family_home/Stone.tres")
    if role=="RoofTiles":
        if photo_materials.has("clay"):return photo_materials.clay
        var clay:=StandardMaterial3D.new()
        clay.resource_name="CityClayRoof"
        clay.albedo_texture=load("res://assets/production/architecture/townhouse/clay_albedo.png")
        clay.albedo_color=Color(.9,.85,.8)
        clay.roughness_texture=load("res://assets/production/architecture/townhouse/clay_orm.png")
        clay.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
        clay.roughness=1.0
        clay.normal_texture=load("res://assets/production/architecture/townhouse/clay_normal.png")
        clay.normal_enabled=int(SettingsManager.get_value("graphics","quality_preset"))>=2
        clay.normal_scale=.25
        clay.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
        photo_materials.clay=clay
        return clay
    if role == "MI_Plaster":return _photo_plaster()
    if role == "MI_WoodTrim":return load("res://assets/production/exteriors/family_home/Timber.tres")
    if role not in ["MI_RoundTiles","MI_Brick"]:return original
    if photo_materials.has(role):return photo_materials[role]
    var material := original.duplicate() as StandardMaterial3D
    material.albedo_color = Color(.72,.65,.57) if role=="MI_RoundTiles" else Color(.82,.80,.72)
    material.roughness = .94
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    photo_materials[role] = material
    return material

func _timber(house: Transform3D,a:Vector3,b:Vector3,thickness:float=1.0) -> void:
    _add_mesh(COURT.mesh("TimberBeam"),house*COURT.beam(a,b,thickness),180.0)
    detail_counts.timber += 1

func _add_townhouse_details(house:Transform3D,footprint:Vector2,stories:int,count_x:int,step_x:float) -> void:
    var half := footprint*.5
    for story in range(stories):
        var y := float(story)*3.12
        for side:float in [-1.0,1.0]:
            var z := side*(half.y+.09)
            _timber(house,Vector3(-half.x,y+3.04,z),Vector3(half.x,y+3.04,z),.9)
            if story>0:_timber(house,Vector3(-half.x,y+.08,z),Vector3(half.x,y+.08,z),1.05)
            for index in range(count_x+1):
                if index%2!=0 and index!=count_x:continue
                var x := -half.x+index*step_x
                _timber(house,Vector3(x,y+.05,z),Vector3(x,y+3.04,z),.8)
            _timber(house,Vector3(-half.x,y+2.38,z),Vector3(-half.x+.5,y+3.04,z),.65)
            _timber(house,Vector3(half.x,y+2.38,z),Vector3(half.x-.5,y+3.04,z),.65)
        for side:float in [-1.0,1.0]:
            var x := side*(half.x+.09)
            _timber(house,Vector3(x,y+3.04,-half.y),Vector3(x,y+3.04,half.y),.9)
            for z:float in [-half.y,0,half.y]:_timber(house,Vector3(x,y+.05,z),Vector3(x,y+3.04,z),.8)
        for index in range(count_x):
            if index%2!=0 or (story==0 and index==count_x/2):continue
            var x := -half.x+(index+.5)*step_x
            var point := Vector3(x,y+.72,half.y+.27)
            _add_mesh(COURT.mesh("WindowPlanter"),house*Transform3D(Basis.from_scale(Vector3(.85,1,1)),point),180.0)
            detail_counts.window_boxes += 1
            for offset:float in [-.42,0,.42]:
                _add_mesh(COURT.mesh("MeadowFlowers"),house*Transform3D(Basis.from_scale(Vector3.ONE*.8),point+Vector3(offset,.26,0)),180.0)
                detail_counts.flowers += 1

static func apply_surface_quality(level:int) -> void:
    for key:String in ["plaster","clay"]:
        if not photo_materials.has(key):continue
        var material:StandardMaterial3D=photo_materials[key]
        material.normal_enabled=level>=2
        material.roughness_texture=load("res://assets/production/interiors/materials/lime_plaster/orm.png" if key=="plaster" else "res://assets/production/architecture/townhouse/clay_orm.png") if level>=2 else null
