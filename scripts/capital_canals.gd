extends Node3D

const DATA:=preload("res://scripts/capital_canal_data.gd")
const CAPITAL:=preload("res://scripts/capital_data.gd")
const PATHS:=preload("res://scripts/terrain_paths.gd")
const KIT:=preload("res://assets/production/architecture/capital_canal/CapitalCanalKit.glb")
const NATURE:=preload("res://scripts/production_nature.gd")
const PARK_TREES:Array[PackedScene]=[preload("res://assets/production/nature/temperate/TemperateTree_LOD.glb"),preload("res://assets/production/nature/temperate/TemperateTree_Broad.glb")]
const MEADOW:=preload("res://assets/production/nature/meadow/MeadowGrass.glb")
static var tree_factors:Dictionary={}
static var parts:Dictionary={}
static var shapes:Dictionary={}
static var stone:StandardMaterial3D
static var paving:StandardMaterial3D
static var liquid:ShaderMaterial
var lamps:Array[OmniLight3D]=[]
var elapsed:=1.

static func _prepare() -> void:
    if not parts.is_empty():return
    var source:=KIT.instantiate()
    stone=StandardMaterial3D.new();stone.resource_name="CanalDressedStone"
    stone.albedo_texture=preload("res://assets/production/materials/ground/lichen_rock.jpg")
    stone.albedo_color=Color(.52,.53,.50);stone.roughness=.94
    stone.normal_texture=preload("res://assets/production/architecture/city_street/stone_normal.png");stone.normal_scale=.35
    stone.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    paving=PATHS.material("paving")
    for node:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
        var mesh:=node.mesh.duplicate() as ArrayMesh
        for slot in range(mesh.get_surface_count()):mesh.surface_set_material(slot,paving if node.name=="DeckAndApproaches" else stone)
        parts[String(node.name)]={"mesh":mesh,"transform":node.transform}
    source.free()
    assert(parts.size()==5 and parts.has("QuayWall6m"))
    liquid=ShaderMaterial.new();liquid.shader=preload("res://assets/shaders/environment/ice_surface.gdshader")
    liquid.set_shader_parameter("water_color",Color(.055,.20,.23,.88));liquid.set_shader_parameter("wave_strength",.004)
    apply_quality();sync_water()
    if not SettingsManager.settings_changed.is_connected(apply_quality):SettingsManager.settings_changed.connect(apply_quality)

static func apply_quality() -> void:
    if stone!=null:stone.normal_enabled=int(SettingsManager.get_value("graphics","quality_preset"))>=2

static func sync_water() -> void:
    if liquid!=null:EnvironmentState.apply_environment_material(liquid)

static func water_chunk(chunk:Node3D,size:float) -> void:
    var origin:=Vector2(chunk.global_position.x,chunk.global_position.z)
    var bounds:=Rect2(origin,Vector2.ONE*size)
    if not DATA.affects_rect(bounds) or chunk.has_node("CapitalCanalWater"):return
    _prepare()
    var intersections:=Geometry2D.intersect_polygons(DATA.water_polygon(),PackedVector2Array([bounds.position,bounds.position+Vector2(size,0),bounds.end,bounds.position+Vector2(0,size)]))
    var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var triangles:=0
    for polygon:PackedVector2Array in intersections:
        var local_polygon:=PackedVector2Array()
        for point:Vector2 in polygon:local_polygon.append(point-origin)
        var indices:=Geometry2D.triangulate_polygon(local_polygon)
        for index in indices:
            var point:=polygon[index]-origin;tool.set_normal(Vector3.UP);tool.set_uv(point*.1);tool.add_vertex(Vector3(point.x,DATA.WATER_LEVEL,point.y))
        triangles+=indices.size()/3
    if triangles==0:return
    var water:=MeshInstance3D.new();water.name="CapitalCanalWater";water.mesh=tool.commit();water.material_override=liquid
    water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;water.visibility_range_end=size*3.5
    water.set_meta("continuous_water",true);water.set_meta("water_kind","river");chunk.add_child(water)

static func _owner(point:Vector2) -> Vector2i:
    var local:=point-CAPITAL.CENTER
    return Vector2i(floori((local.x+80)/160),floori((local.y+80)/160))

static func _visual(body:Node3D,key:String) -> MeshInstance3D:
    var node:=MeshInstance3D.new();node.name=key;node.mesh=parts[key].mesh;node.transform=parts[key].transform
    node.visibility_range_end=420;body.add_child(node)
    return node

static func bridge(parent:Node3D,center:Vector2) -> StaticBody3D:
    _prepare()
    var body:=StaticBody3D.new();body.name="CapitalCanalBridge_%d"%roundi(center.y-CAPITAL.CENTER.y)
    body.position=parent.to_local(Vector3(center.x,0,center.y));parent.add_child(body)
    body.add_to_group("map_fixture");body.set_meta("map_footprint",Vector2(96,16));body.set_meta("surface_type","stone")
    var reference:ConcavePolygonShape3D=shapes.get("bridge")
    var faces:=PackedVector3Array()
    for key:String in ["DeckAndApproaches","MeasuredArchVaults","PiersAndSpandrels","ParapetsAndCaps"]:
        var visual:=_visual(body,key)
        if reference==null:
            for point:Vector3 in visual.mesh.get_faces():faces.append(visual.transform*point)
    if reference==null:
        reference=ConcavePolygonShape3D.new();reference.set_faces(faces);reference.backface_collision=true;shapes.bridge=reference
    var shape:=CollisionShape3D.new();shape.shape=reference;body.add_child(shape)
    body.set_meta("measured_bridge_collision",true)
    return body

static func city_cell(root:Node3D,city:Node3D) -> void:
    _prepare()
    var bounds:=Rect2(Vector2(root.global_position.x,root.global_position.z)-Vector2.ONE*80,Vector2.ONE*160)
    var center:=Vector2(root.global_position.x,root.global_position.z)
    var footprints:Array[PackedVector2Array]=[PATHS.strip(center-Vector2(80,0),center+Vector2(80,0),14),PATHS.strip(center-Vector2(0,80),center+Vector2(0,80),14)]
    for side:float in [-1,1]:
        footprints.append(PATHS.strip(DATA.CENTER+Vector2(side*26,-320),DATA.CENTER+Vector2(side*26,320),8))
    var home_center:Vector2=DATA.bridges()[1]
    footprints.append(PATHS.strip(home_center+Vector2(-45,-23),home_center+Vector2(-49.5,0),3))
    footprints.append(PATHS.strip(home_center+Vector2(49.5,0),home_center+Vector2(55,-20),3))
    footprints.append(PackedVector2Array([home_center+Vector2(51,-34),home_center+Vector2(73,-34),home_center+Vector2(73,-18),home_center+Vector2(51,-18)]))
    var dry:Array[PackedVector2Array]=[]
    var rectangle:=PackedVector2Array([bounds.position,bounds.position+Vector2(160,0),bounds.end,bounds.position+Vector2(0,160)])
    for footprint:PackedVector2Array in footprints:
        for piece:PackedVector2Array in Geometry2D.intersect_polygons(footprint,rectangle):
            for polygon:PackedVector2Array in Geometry2D.clip_polygons(piece,DATA.water_polygon()):dry.append(polygon)
    # The same four-metre terrain triangles own rendering and physics. No flat
    # district box covers the excavated basin or floats above its approaches.
    PATHS.add(root,"CanalDistrictPaving",dry,"paving")
    var cell:=_owner(Vector2(root.global_position.x,root.global_position.z))
    for bridge_center:Vector2 in DATA.bridges():
        if _owner(bridge_center)==cell:bridge(root,bridge_center)
    if _owner(home_center)==cell:
        var household:Node3D=load("res://scripts/canal_household.gd").new();household.name="CanalHousehold";household.position=root.to_local(Vector3(home_center.x,0,home_center.y));root.add_child(household)
    var details:Node3D=load("res://scripts/capital_canals.gd").new();details.name="CanalBankDetails";root.add_child(details)
    var transforms:Array[Transform3D]=[]
    for side:float in [-1,1]:
        for index in range(100):
            var point:=DATA.CENTER+Vector2(side*19.5,-297+index*6)
            if _owner(point)!=cell:continue
            var opening:=false
            for crossing_center:Vector2 in DATA.bridges():
                if absf(point.y-crossing_center.y)<12:opening=true
            if opening:continue
            transforms.append(Transform3D(Basis(Vector3.UP,PI*.5),details.to_local(Vector3(point.x,0,point.y))))
    if not transforms.is_empty():
        var mesh:=MultiMesh.new();mesh.transform_format=MultiMesh.TRANSFORM_3D;mesh.mesh=parts.QuayWall6m.mesh;mesh.instance_count=transforms.size()
        var physical:=StaticBody3D.new();physical.name="MeasuredCanalBank";physical.set_meta("surface_type","stone");details.add_child(physical)
        var reference:Shape3D=shapes.get("quay")
        if reference==null:reference=parts.QuayWall6m.mesh.create_trimesh_shape();shapes.quay=reference
        for index in range(transforms.size()):
            var transform:Transform3D=transforms[index]*Transform3D(parts.QuayWall6m.transform)
            mesh.set_instance_transform(index,transform)
            var collision:=CollisionShape3D.new();collision.shape=reference;collision.transform=transform;physical.add_child(collision)
        var batch:=MultiMeshInstance3D.new();batch.name="QuayMasonry";batch.multimesh=mesh;batch.visibility_range_end=300;details.add_child(batch)
    details.set_meta("quay_modules",transforms.size())
    _bank_lamps(details,cell)
    _park(root,center)

static func _bounds(node:Node3D,inherited:Transform3D=Transform3D.IDENTITY) -> AABB:
    var transform:=inherited*node.transform
    var result:=AABB()
    var found:=node is MeshInstance3D
    if found:result=transform*(node as MeshInstance3D).get_aabb()
    for child in node.get_children():
        if not child is Node3D:continue
        var part:=_bounds(child,transform)
        if part.size.length_squared()==0:continue
        result=result.merge(part) if found else part;found=true
    return result

static func _bank_lamps(parent:Node3D,cell:Vector2i) -> void:
    var street:=preload("res://scripts/capital_streetscape.gd");street._prepare()
    if not shapes.has("post"):shapes.post=street.parts.LanternPost.mesh.create_trimesh_shape()
    for side:float in [-1,1]:
        for index in range(4):
            var point:=DATA.CENTER+Vector2(side*27.7,-240+160*index)
            if _owner(point)!=cell:continue
            var post:=StaticBody3D.new();post.name="CanalLampPost"
            post.position=parent.to_local(Vector3(point.x,WorldData.elevation_at(point)+PATHS.LIFT,point.y));post.rotation.y=PI if side>0 else 0;parent.add_child(post)
            var visual:=MeshInstance3D.new();visual.mesh=street.parts.LanternPost.mesh;visual.transform=street.parts.LanternPost.transform;post.add_child(visual)
            var collision:=CollisionShape3D.new();collision.shape=shapes.post;collision.transform=visual.transform;post.add_child(collision)
            var lantern:Node3D=preload("res://assets/production/medieval/capital_square/Lantern_Wall.gltf").instantiate()
            var bounds:=_bounds(lantern);var scale:=.42/bounds.size.y
            lantern.scale*=scale;lantern.position=street.lantern_anchor-Vector3.UP*.42-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*scale;post.add_child(lantern)
            var lamp:=OmniLight3D.new();lamp.name="CanalLanternLight";lamp.position=street.lantern_anchor-Vector3.UP*.20
            lamp.light_color=Color(1,.76,.49);lamp.light_energy=.9;lamp.omni_range=5.5;lamp.shadow_enabled=false;post.add_child(lamp);parent.lamps.append(lamp)

static func _garden_clear(point:Vector2,center:Vector2) -> bool:
    var local:=point-center
    if absf(local.x)<9 or absf(local.y)<9 or DATA.distance_to_channel(point)<21:return false
    if absf(absf(point.x-DATA.CENTER.x)-26)<6:return false
    var home:=DATA.bridges()[1]
    var relative:=point-home
    if relative.x>-56 and relative.x<-35 and relative.y>-39 and relative.y<4:return false
    if relative.x>48 and relative.x<78 and relative.y>-38 and relative.y<5:return false
    # Original neighbouring lot envelopes are kept clear; no grass or trunk
    # may grow through their existing physical houses while the rest streams in.
    if DATA.distance_to_channel(point)>=48 and (absf(absf(local.x)-28)<13 or absf(absf(local.x)-52)<13) and (absf(absf(local.y)-28)<13 or absf(absf(local.y)-52)<13):return false
    return true

static func _park(parent:Node3D,center:Vector2) -> void:
    var park:=Node3D.new();park.name="CanalPark";park.add_to_group("capital_canal_park");park.set_meta("surface_bounds",Rect2(center-Vector2.ONE*80,Vector2.ONE*160));parent.add_child(park);parent=park
    var grass:Array[Transform3D]=[]
    var rng:=RandomNumberGenerator.new();rng.seed=917319+roundi(center.x)*17+roundi(center.y)*31
    for index in range(6000):
        var point:=center+Vector2(rng.randf_range(-79,79),rng.randf_range(-79,79))
        if not _garden_clear(point,center):continue
        var scale:=rng.randf_range(.65,1.15)
        grass.append(Transform3D(Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*scale),parent.to_local(Vector3(point.x,WorldData.elevation_at(point),point.y))))
    if not grass.is_empty():NATURE.add_model_batches(parent,grass,MEADOW,68)
    park.set_meta("authored_grass_instances",grass.size())
    var tree_lists:Array[Array]=[[],[]]
    var cell:=_owner(center)
    for side:float in [-1,1]:
        for index in range(15):
            var point:=DATA.CENTER+Vector2(side*36,-270+index*40)
            if _owner(point)!=cell or not _garden_clear(point,center):continue
            var variant:=index%2
            var scene:PackedScene=PARK_TREES[variant]
            if not tree_factors.has(variant):
                var source:=scene.instantiate();var vertices:Array[Vector3]=[];NATURE._collect_vertices(source,Transform3D.IDENTITY,vertices);source.free()
                var bottom:=INF;var top:=-INF
                for vertex:Vector3 in vertices:bottom=minf(bottom,vertex.y);top=maxf(top,vertex.y)
                tree_factors[variant]={"factor":8./(top-bottom),"bottom":bottom,"radius":NATURE.trunk_radius(scene)}
            var info:Dictionary=tree_factors[variant];var scale:float=info.factor*(.9+.05*(index%4))
            var transform:=Transform3D(Basis(Vector3.UP,index*.73).scaled(Vector3.ONE*scale),parent.to_local(Vector3(point.x,WorldData.elevation_at(point)-info.bottom*scale,point.y)))
            tree_lists[variant].append(transform)
            var tree:=StaticBody3D.new();tree.name="CanalParkTree";tree.transform=transform;tree.add_to_group("map_tree");tree.set_meta("map_footprint",Vector2.ONE*7);parent.add_child(tree)
            var shape:=CollisionShape3D.new();var cylinder:=CylinderShape3D.new();cylinder.height=2.5;cylinder.radius=info.radius;shape.shape=cylinder;shape.position.y=info.bottom+1.25;tree.add_child(shape)
    for variant in range(2):
        var list:Array[Transform3D]=[];list.assign(tree_lists[variant])
        if not list.is_empty():NATURE.add_model_batches(parent,list,PARK_TREES[variant],320)

func _process(delta:float) -> void:
    elapsed+=delta
    if elapsed<1:return
    elapsed=0
    var hour:=fmod(GameState.world_minutes/60.,24.)
    var player:=get_tree().get_first_node_in_group("player") as Node3D
    for lamp:OmniLight3D in lamps:
        lamp.visible=(hour>=17.5 or hour<7) and int(SettingsManager.get_value("graphics","quality_preset"))>=1 and (player==null or lamp.global_position.distance_squared_to(player.global_position)<14400)
