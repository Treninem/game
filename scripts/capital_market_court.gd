extends RefCounted

const NATURE := preload("res://scripts/production_nature.gd")
const COURT := preload("res://scripts/cottage_yard_assets.gd")
const FOUNTAIN := preload("res://scripts/market_fountain.gd")
const TREES:Array[PackedScene] = [preload("res://assets/production/nature/temperate/TemperateTree.glb"),preload("res://assets/production/nature/temperate/TemperateTree_Broad.glb")]

static func dress_canopy(node:Node3D,index:int) -> void:
    var palette: Array[Color]=[Color(.65,.60,.46),Color(.23,.33,.34),Color(.4,.44,.29)]
    var texture:=GradientTexture2D.new()
    texture.width=2;texture.height=2;texture.gradient=Gradient.new()
    texture.gradient.colors=PackedColorArray([palette[index%3],palette[index%3]])
    var linen:=ShaderMaterial.new()
    linen.shader=preload("res://assets/shaders/environment/wind_cloth.gdshader")
    linen.set_shader_parameter("albedo_texture",texture)
    linen.set_shader_parameter("roughness",.95)
    EnvironmentState.apply_environment_material(linen)
    linen.set_shader_parameter("wind_strength",.025)
    linen.set_shader_parameter("gust_strength",.01)
    for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
        for slot in range(mesh.mesh.get_surface_count()):
            var original:=mesh.get_active_material(slot)
            if original.resource_name=="MI_Banner":mesh.set_surface_override_material(slot,linen)
            elif original.resource_name=="MI_Trim_Furniture":mesh.set_surface_override_material(slot,preload("res://assets/production/exteriors/family_home/Timber.tres"))

static func build(square:Node3D) -> void:
    var flowers:Array[Transform3D]=[]
    var stone:Array[Transform3D]=[]
    for index in range(4):
        var point:=Vector3(-17 if index<2 else 17,0,14 if index%2==0 else 44)
        var tree:Node3D=square._place(TREES[index%2],"MarketTree",point,8.5+index*.3, index*.9,false)
        NATURE.prepare(tree)
        tree.add_to_group("map_tree")
        tree.set_meta("map_footprint",Vector2(7,7))
        var trunk:=StaticBody3D.new()
        tree.add_child(trunk)
        # Tree visuals are normalized below the unscaled placement body.
        var radius:=NATURE.trunk_radius(TREES[index%2])
        var raw:=TREES[index%2].instantiate()
        var bounds:AABB=square._bounds(raw,Transform3D.IDENTITY)
        raw.free()
        radius *= float(tree.get_meta("authored_height"))/bounds.size.y
        var collision:=CollisionShape3D.new()
        var cylinder:=CylinderShape3D.new()
        cylinder.radius=maxf(.15,radius);cylinder.height=2.4
        collision.shape=cylinder;collision.position.y=1.2;trunk.add_child(collision)
        var soil:=MeshInstance3D.new()
        var disc:=CylinderMesh.new()
        disc.top_radius=2.5;disc.bottom_radius=2.5;disc.height=.06;disc.radial_segments=32
        soil.mesh=disc
        var earth:=StandardMaterial3D.new()
        earth.albedo_texture=preload("res://assets/production/materials/ground/road_soil.png")
        earth.roughness=1;earth.uv1_scale=Vector3.ONE*3;earth.albedo_color=Color(.53,.48,.4)
        soil.material_override=earth;soil.position=tree.position+Vector3.UP*.04;square.add_child(soil)
        for k in range(16):
            var angle:=TAU*k/16.0
            var edge:=tree.position+Vector3(cos(angle)*2.5,.10,sin(angle)*2.5)
            stone.append(Transform3D(Basis(Vector3.UP,-angle)*Basis.from_scale(Vector3(.5,.23,.28)),edge))
            if k%2==0:
                flowers.append(Transform3D(Basis(Vector3.UP,angle),tree.position+Vector3(cos(angle)*1.9,.1,sin(angle)*1.9)))
    COURT.batch(square,"StoneCourse",stone,180)
    COURT.batch(square,"MeadowFlowers",flowers,180,false)
    NATURE.sync_wind()
    var fountain:=FOUNTAIN.new()
    fountain.position=Vector3(-16,square._ground_y(Vector3(-16,0,29)),29)
    square.add_child(fountain)
    for side:float in [-1.0,1.0]:
        for z:float in [18.0,34.0,50.0]:
            square._prop("Barrel_Apples",Vector3(side*12.5,0,z+1.7),.8)
            square._prop("Barrel",Vector3(side*13.3,0,z+1.9),.95)
    var arcade:Node3D=preload("res://scripts/market_structures.gd").build_arcade(square)
    var stock_display:=preload("res://scripts/market_goods_display.gd").new()
    stock_display.name="ActualArrowStock"
    stock_display.build(square.get_node("SquareMarketStall"),square.get_node("SquareTrader"))
    for mount:Node3D in arcade.find_children("LanternMount*","Node3D",true,false):
        var lantern:Node3D=square._prop("Lantern_Wall",Vector3.ZERO,.5,0,false)
        lantern.position=square.to_local(mount.global_position)
        var light:=OmniLight3D.new();light.name="ArcadeLanternLight"
        light.position=lantern.position+Vector3(0,.25,.15)
        light.light_color=Color(1,.74,.45);light.light_energy=1.25;light.omni_range=7.0;light.shadow_enabled=false
        light.set_meta("medium_only",true);square.add_child(light);square.lamps.append(light)
    var navigation:=preload("res://scripts/public_space_navigation.gd").new()
    navigation.name="PublicSpaceNavigation";square.add_child(navigation)
    square.set_meta("market_court",{"trees":4,"flower_clumps":flowers.size(),"goods":12,"fountains":1})
