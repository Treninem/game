extends RefCounted

# Read the GPU's own morphed/skinned vertex positions. No CPU deformation or
# contact function is used to produce these measurements. RGB stores base-192
# fixed-point values, avoiding the renderer's low-color toe. All three axes
# occupy separate pages in ONE rendered frame, not three different poses.
var viewport: SubViewport
var instance: MeshInstance3D
var material: ShaderMaterial
var materials: Array[ShaderMaterial] = []
var instances: Array[MeshInstance3D] = []
var source_ref: WeakRef
var points_count := 0
var dimensions := Vector2i.ZERO
var decode_linear := false
var flip_x := false
var flip_y := false
var vertex_material_ref: WeakRef
var measurement_code := ""
var render_instances: Array[RID] = []
var raw_mesh := RID()
var skin_reference: SkinReference
var raw_owner: ArrayMesh

func setup(parent: Node, source: MeshInstance3D = null, surface := 0, canary_points := PackedVector3Array()) -> void:
    viewport=SubViewport.new()
    viewport.own_world_3d=true
    viewport.transparent_bg=false
    viewport.msaa_3d=Viewport.MSAA_DISABLED
    viewport.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
    parent.add_child(viewport)
    var mesh:=ArrayMesh.new()
    var arrays:=[]
    var shapes:=[]
    var flags:=0
    if source!=null:
        # Preserve the actual packed vertex/TBN/skin/morph bytes. Decoding and
        # rebuilding an ArrayMesh can quantize its tangent frame a second time.
        var packed:=RenderingServer.mesh_get_surface(source.mesh.get_rid(),surface)
        var original:=packed.duplicate(true)
        points_count=int(packed.vertex_count)
        packed.primitive=RenderingServer.PRIMITIVE_POINTS
        packed.format=int(packed.format)&~RenderingServer.ARRAY_FORMAT_INDEX
        packed.index_count=0;packed.index_data=PackedByteArray();packed.lods=[];packed.erase("material")
        print("RAW_GPU_SURFACE original_format=",original.format," point_format=",packed.format," vertices=",points_count," shapes=",source.get_blend_shape_count()," original_primitive=",original.primitive," data_bytes=",packed.blend_shape_data.size())
        # 4.7.1's GDScript mesh_create_from_surfaces wrapper drops its shape
        # count argument. ArrayMesh owns a correctly initialized RID instead.
        raw_owner=ArrayMesh.new()
        for i in range(source.get_blend_shape_count()):raw_owner.add_blend_shape((source.mesh as ArrayMesh).get_blend_shape_name(i))
        raw_mesh=raw_owner.get_rid()
        assert(RenderingServer.mesh_get_blend_shape_count(raw_mesh)==source.get_blend_shape_count())
        RenderingServer.mesh_add_surface(raw_mesh,packed)
        RenderingServer.mesh_set_blend_shape_mode(raw_mesh,RenderingServer.mesh_get_blend_shape_mode(source.mesh.get_rid()))
        var copied:=RenderingServer.mesh_get_surface(raw_mesh,0)
        for field:String in ["vertex_data","attribute_data","skin_data","blend_shape_data"]:
            assert(copied.get(field,PackedByteArray())==original.get(field,PackedByteArray()),"Packed GPU attribute bytes changed: "+field)
        skin_reference=source.get_skin_reference();assert(skin_reference!=null)
        source_ref=weakref(source)
    else:
        points_count=canary_points.size()
        arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=canary_points
    dimensions=Vector2i(128,ceili(points_count*3/128.0))
    viewport.size=dimensions
    if source==null:
        mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS,arrays,shapes,{},flags)
        instance=MeshInstance3D.new();instance.mesh=mesh;instance.extra_cull_margin=4;viewport.add_child(instance)
    var shader:=Shader.new()
    shader.code="""shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform ivec2 grid_size;
uniform int points_count;
uniform int coordinate = 0;
uniform bool srgb_decode = false;
uniform bool calibration = false;
varying flat vec3 measured_position;
varying flat vec3 calibration_color;
vec3 to_linear(vec3 color) {
    return mix(pow((color+vec3(0.055))/1.055,vec3(2.4)),color/12.92,lessThanEqual(color,vec3(0.04045)));
}
void vertex() {
    measured_position=VERTEX;
    int n=VERTEX_ID % 192;
    calibration_color=vec3(float(n+64),float((n*17)%192+64),float((n*31)%192+64))/255.0;
    int id=VERTEX_ID+coordinate*points_count;
    int x=id % grid_size.x;
    int y=id / grid_size.x;
    POSITION=vec4((float(x)+0.5)/float(grid_size.x)*2.0-1.0,1.0-(float(y)+0.5)/float(grid_size.y)*2.0,0.0,1.0);
    POINT_SIZE=1.0;
}
void fragment() {
    float value=measured_position[coordinate];
    float packed=round(clamp((value+4.0)/8.0,0.0,1.0)*7077887.0);
    vec3 bytes=(vec3(floor(packed/36864.0),mod(floor(packed/192.0),192.0),mod(packed,192.0))+vec3(64.0))/255.0;
    if(calibration) {bytes=calibration_color;}
    ALBEDO=srgb_decode ? to_linear(bytes) : bytes;
}
"""
    measurement_code=shader.code
    material=ShaderMaterial.new();material.shader=shader
    material.set_shader_parameter("grid_size",dimensions)
    material.set_shader_parameter("points_count",points_count)
    if source==null:
        instance.material_override=material
        materials.append(material);instances.append(instance)
        for axis in [1,2]:
            var copy:=instance.duplicate() as MeshInstance3D
            var copy_material:=material.duplicate() as ShaderMaterial
            copy_material.set_shader_parameter("coordinate",axis);copy.material_override=copy_material;viewport.add_child(copy)
            materials.append(copy_material);instances.append(copy)
    else:
        for axis in range(3):
            var copy_material:ShaderMaterial=material if axis==0 else material.duplicate() as ShaderMaterial
            copy_material.set_shader_parameter("coordinate",axis);materials.append(copy_material)
            var rid:=RenderingServer.instance_create2(raw_mesh,viewport.find_world_3d().scenario)
            RenderingServer.instance_attach_skeleton(rid,skin_reference.get_skeleton())
            RenderingServer.instance_geometry_set_material_override(rid,copy_material.get_rid())
            RenderingServer.instance_set_ignore_culling(rid,true)
            render_instances.append(rid)
        sync_source()
    var camera:=Camera3D.new();viewport.add_child(camera)
    camera.position=Vector3(0,1,4);camera.look_at(Vector3(0,1,0));camera.make_current()
    var environment:=WorldEnvironment.new();environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color.BLACK
    environment.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
    environment.environment.glow_enabled=false
    viewport.add_child(environment)

func _set_parameter(name: String, value: Variant) -> void:
    for item: ShaderMaterial in materials:item.set_shader_parameter(name,value)

func sync_source() -> void:
    if source_ref==null:return
    var source:=source_ref.get_ref() as MeshInstance3D
    assert(is_instance_valid(source))
    for copy: MeshInstance3D in instances:
        copy.global_transform=source.global_transform
        for shape in range(source.get_blend_shape_count()):copy.set_blend_shape_value(shape,source.get_blend_shape_value(shape))
    for rid:RID in render_instances:
        RenderingServer.instance_set_transform(rid,source.global_transform)
        for shape in range(source.get_blend_shape_count()):RenderingServer.instance_set_blend_shape_weight(rid,shape,source.get_blend_shape_value(shape))
    sync_vertex_uniforms()

# Extract balanced, authored function bodies; the contact implementation itself
# is executed by the GPU, never rewritten as a CPU deformation oracle.
func _function_range(code: String, name: String) -> Vector2i:
    var expression:=RegEx.new()
    assert(expression.compile("void\\s+"+name+"\\s*\\(\\s*\\)\\s*\\{")==OK)
    var found:=expression.search(code)
    assert(found!=null,"Capture requires an explicit shader function: "+name)
    var depth:=1;var cursor:=found.get_end()
    while cursor<code.length() and depth>0:
        if code[cursor]=="{":depth+=1
        elif code[cursor]=="}":depth-=1
        cursor+=1
    assert(depth==0,"Unbalanced shader function")
    return Vector2i(found.get_start(),cursor)

func _body(code: String, name: String) -> String:
    var span:=_function_range(code,name)
    var start:=code.find("{",span.x)+1
    return code.substr(start,span.y-start-1)

func use_vertex_material(source: ShaderMaterial) -> void:
    assert(source!=null and source.shader!=null)
    var code:=source.shader.code
    assert(not code.contains("world_vertex_coords") and not code.contains("skip_vertex_transform"),"Unsupported vertex coordinate convention")
    assert(not code.contains("void light"),"Capture supports vertex/fragment shaders only")
    var authored_vertex:=_body(code,"vertex")
    var span:=_function_range(code,"fragment")
    code=code.left(span.x)+code.substr(span.y)
    span=_function_range(code,"vertex")
    code=code.left(span.x)+code.substr(span.y)
    var modes:=RegEx.new();assert(modes.compile("render_mode[^;]*;")==OK)
    code=modes.sub(code,"",true).replace("shader_type spatial;","")
    var measurement_vertex:=_body(measurement_code,"vertex")
    span=_function_range(measurement_code,"vertex")
    var header:=measurement_code.left(span.x)
    var fragment:=measurement_code.substr(span.y)
    var shader:=Shader.new()
    shader.code=header+code+"\nvoid vertex() {\n"+authored_vertex+"\n"+measurement_vertex+"\n}\n"+fragment
    vertex_material_ref=weakref(source)
    for item: ShaderMaterial in materials:item.shader=shader
    sync_vertex_uniforms()

func sync_vertex_uniforms() -> void:
    if vertex_material_ref==null:return
    var source:=vertex_material_ref.get_ref() as ShaderMaterial
    assert(is_instance_valid(source))
    for entry: Dictionary in source.shader.get_shader_uniform_list():
        _set_parameter(entry.name,source.get_shader_parameter(entry.name))

func _read() -> Image:
    viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
    await viewport.get_tree().process_frame
    await RenderingServer.frame_post_draw
    var picture:=viewport.get_texture().get_image()
    picture.convert(Image.FORMAT_RGBA8)
    return picture

func calibrate() -> void:
    assert(points_count>=192)
    _set_parameter("calibration",true)
    var maximum:=255
    for decode:bool in [false,true]:
        _set_parameter("srgb_decode",decode)
        var picture:=await _read()
        for reverse_y:bool in [false,true]:
            for reverse_x:bool in [false,true]:
                maximum=0
                for i in range(192):
                    var x:int=i%dimensions.x;var y:int=i/dimensions.x
                    if reverse_x:x=dimensions.x-1-x
                    if reverse_y:y=dimensions.y-1-y
                    var pixel:=picture.get_pixel(x,y)
                    maximum=maxi(maximum,absi(roundi(pixel.r*255)-i-64))
                    maximum=maxi(maximum,absi(roundi(pixel.g*255)-(i*17)%192-64))
                    maximum=maxi(maximum,absi(roundi(pixel.b*255)-(i*31)%192-64))
                print("GPU_BYTE_CALIBRATION decode=",decode," flip_x=",reverse_x," flip_y=",reverse_y," max_error=",maximum," first=",picture.get_pixel(0,0))
                if maximum==0:
                    decode_linear=decode;flip_x=reverse_x;flip_y=reverse_y
                    break
            if maximum==0:break
        if maximum==0:break
    assert(maximum==0,"GPU byte calibration is not exact; position decoding cannot be trusted")
    _set_parameter("calibration",false)

func capture() -> PackedVector3Array:
    sync_source()
    _set_parameter("srgb_decode",decode_linear)
    var picture:=await _read()
    return _decode_capture(picture)

# Coordinate several real mesh probes on ONE live physics/render frame:
# begin all, await process_frame + frame_post_draw once, then finish all.
func begin_capture() -> void:
    sync_source()
    _set_parameter("srgb_decode",decode_linear)
    viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func finish_capture() -> PackedVector3Array:
    var picture:=viewport.get_texture().get_image()
    picture.convert(Image.FORMAT_RGBA8)
    return _decode_capture(picture)

func _decode_capture(picture: Image) -> PackedVector3Array:
    var points:=PackedVector3Array();points.resize(points_count)
    for axis in range(3):
        for i in range(points_count):
            var id:=i+axis*points_count
            var x:int=id%dimensions.x;var y:int=id/dimensions.x
            if flip_x:x=dimensions.x-1-x
            if flip_y:y=dimensions.y-1-y
            var color:=picture.get_pixel(x,y)
            var packed:=(roundi(color.r*255)-64)*36864+(roundi(color.g*255)-64)*192+roundi(color.b*255)-64
            points[i][axis]=float(packed)/7077887.0*8.0-4.0
    return points

func dispose() -> void:
    for rid:RID in render_instances:RenderingServer.free_rid(rid)
    render_instances.clear()
    if raw_mesh.is_valid():raw_owner=null;raw_mesh=RID()
    skin_reference=null
    viewport.free()
