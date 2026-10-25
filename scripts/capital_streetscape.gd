extends RefCounted

const KIT:=preload("res://assets/production/architecture/city_street/CityStreetKit.glb")
const NATURE:=preload("res://scripts/production_nature.gd")
const COURT:=preload("res://scripts/cottage_yard_assets.gd")
const BUSH:=preload("res://assets/production/nature/temperate/TemperateBush.glb")
static var parts:Dictionary={}
static var materials:Dictionary={}
static var lantern_anchor:=Vector3.ZERO

static func _prepare() -> void:
    if not parts.is_empty():return
    var source:=KIT.instantiate()
    var marker:=source.find_child("LanternAnchor",true,false) as Node3D
    assert(marker!=null,"Blender street kit lost its lantern support marker")
    lantern_anchor=marker.position
    var stone:=StandardMaterial3D.new()
    stone.resource_name="CityCutStone"
    stone.albedo_texture=preload("res://assets/production/architecture/city_street/stone_albedo.png")
    stone.normal_texture=preload("res://assets/production/architecture/city_street/stone_normal.png")
    stone.normal_scale=.45;stone.roughness=.91
    stone.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    stone.albedo_color=Color(.69,.67,.62)
    var paving:=stone.duplicate() as StandardMaterial3D
    paving.albedo_color=Color(.72,.70,.66)
    materials={"stone":stone,"paving":paving}
    for part:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
        var mesh:=part.mesh.duplicate() as ArrayMesh
        for slot in range(mesh.get_surface_count()):
            var original:=part.get_active_material(slot)
            if original.resource_name=="StreetStone":mesh.surface_set_material(slot,paving if part.name=="PavingPanel" else stone)
        parts[String(part.name)]={"mesh":mesh,"transform":part.transform}
    source.free()
    assert(parts.size()==3 and parts.has("PavingPanel") and parts.has("StonePlanter") and parts.has("LanternPost"))
    apply_quality()
    if not SettingsManager.settings_changed.is_connected(apply_quality):SettingsManager.settings_changed.connect(apply_quality)

static func apply_quality() -> void:
    var high:=int(SettingsManager.get_value("graphics","quality_preset"))>=2
    for key:String in ["stone","paving"]:
        if not materials.has(key):continue
        var material:StandardMaterial3D=materials[key]
        material.normal_enabled=high
        material.roughness_texture=preload("res://assets/production/architecture/city_street/stone_orm.png") if high else null
        material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN

static func _batch(parent:Node3D,key:String,transforms:Array[Transform3D]) -> MultiMeshInstance3D:
    var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D
    multimesh.mesh=parts[key].mesh;multimesh.instance_count=transforms.size()
    for index in range(transforms.size()):multimesh.set_instance_transform(index,transforms[index]*Transform3D(parts[key].transform))
    var node:=MultiMeshInstance3D.new();node.name=key;node.multimesh=multimesh;node.visibility_range_end=180;parent.add_child(node)
    return node

static func build(square:Node3D) -> void:
    _prepare()
    var street:=Node3D.new();street.name="CapitalStreetscape";square.add_child(street)
    var paving:Array[Transform3D]=[]
    var panel_shape:=ConvexPolygonShape3D.new();var points:=PackedVector3Array()
    for extent:float in [1.5,1.4]:
        for x:float in [-extent,extent]:
            for z:float in [-extent,extent]:points.append(Vector3(x,0 if extent>1.45 else .039,z))
    panel_shape.points=points
    var physical:=StaticBody3D.new();physical.name="MeasuredWalkablePaving";street.add_child(physical)
    for side:float in [-1,1]:
        for z:float in [9.0,12.0,15.0,18.0,21.0,24.0,27.0,30.0,33.0,36.0,39.0,42.0,45.0,48.0,51.0,54.0,57.0,60.0]:
            # Two paved promenades border the open 14m cardinal street. Preserve
            # the existing tree beds rather than burying their soil under slabs.
            var point:=Vector3(side*16.8,0,z)
            if absf(z-14)<3.7 or absf(z-44)<3.7:continue
            point.y=square._ground_y(point)
            var transform:=Transform3D(Basis.IDENTITY,point);paving.append(transform)
            var collision:=CollisionShape3D.new();collision.shape=panel_shape;collision.transform=transform;physical.add_child(collision)
    _batch(street,"PavingPanel",paving)
    var plants:Array[Transform3D]=[]
    var flowers:Array[Transform3D]=[]
    var planter_shape:Shape3D=parts.StonePlanter.mesh.create_trimesh_shape()
    for side:float in [-1,1]:
        for z:float in [24,39,55]:
            var point:=Vector3(side*8.35,square._ground_y(Vector3(side*8.35,0,z)),z)
            var body:=StaticBody3D.new();body.name="PlantedStoneTrough_%d_%d"%[int(side),int(z)];body.position=point
            body.add_to_group("map_fixture");body.set_meta("map_footprint",Vector2(1.7,1.25));street.add_child(body)
            var visual:=MeshInstance3D.new();visual.mesh=parts.StonePlanter.mesh;visual.transform=parts.StonePlanter.transform;body.add_child(visual)
            # Exact hollow planter wall/soil geometry, not an invisible solid box.
            var collision:=CollisionShape3D.new();collision.shape=planter_shape;collision.transform=visual.transform;body.add_child(collision)
            var shrub:Node3D=square._place(BUSH,"MarketTroughShrub",Vector3(point.x,0,point.z),.60,side*z*.13,false)
            shrub.position=point+Vector3(0,.34,0);NATURE.prepare(shrub)
            for x:float in [-.48,.48]:flowers.append(Transform3D(Basis.from_scale(Vector3.ONE*.70),point+Vector3(x,.34,.14)))
            plants.append(Transform3D(Basis.IDENTITY,point))
    COURT.batch(street,"MeadowFlowers",flowers,100,false)
    var posts:Array[Transform3D]=[]
    var post_shape:Shape3D=parts.LanternPost.mesh.create_trimesh_shape()
    for side:float in [-1,1]:
        for z:float in [25,58]:
            var point:=Vector3(side*17.8,0,z);point.y=square._ground_y(point)+.039
            var transform:=Transform3D(Basis(Vector3.UP,PI if side>0 else 0),point)
            posts.append(transform)
            var body:=StaticBody3D.new();body.name="StreetLanternPost_%d_%d"%[int(side),int(z)];body.transform=transform;street.add_child(body)
            var collision:=CollisionShape3D.new();collision.shape=post_shape;collision.transform=parts.LanternPost.transform;body.add_child(collision)
            var lantern:Node3D=square._prop("Lantern_Wall",Vector3.ZERO,.42,PI if side>0 else 0,false)
            lantern.name="StreetPostLantern";lantern.position=transform*(lantern_anchor-Vector3.UP*.42)
            var light:=OmniLight3D.new();light.name="StreetPostLight_%d_%d"%[int(side),int(z)];light.position=lantern.position+Vector3.UP*.22
            light.light_color=Color(1,.76,.49);light.light_energy=.9;light.omni_range=5.5;light.shadow_enabled=false;light.set_meta("medium_only",true)
            square.add_child(light);square.lamps.append(light)
    _batch(street,"LanternPost",posts)
    street.set_meta("measured_street_details",{"paving_panels":paving.size(),"planters":plants.size(),"lantern_posts":posts.size(),"flowers":flowers.size(),"central_clear_width_m":14.0,"panel_ramp_rise_m":.039,"panel_ramp_run_m":.1})
