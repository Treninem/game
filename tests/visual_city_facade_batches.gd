extends SceneTree

var world:Node3D
var snapshots:Dictionary={}
var comparisons:Array=[]

func _initialize() -> void:call_deferred("_run")

func _render(parent:Node3D,other:Node3D,label:String) -> Image:
    other.visible=false;parent.visible=true
    for frame in range(3):await process_frame;await RenderingServer.frame_post_draw
    var image:=root.get_texture().get_image()
    assert(image!=null and image.get_width()==1280 and image.get_height()==720)
    assert(image.save_png("user://city-batches-"+label+".png")==OK)
    return image

func _difference(a:Image,b:Image) -> Dictionary:
    a=a.duplicate();b=b.duplicate();a.resize(320,180,Image.INTERPOLATE_LANCZOS);b.resize(320,180,Image.INTERPOLATE_LANCZOS)
    a.convert(Image.FORMAT_RGB8);b.convert(Image.FORMAT_RGB8)
    var aa:=a.get_data();var bb:=b.get_data();var sum:=0.0;var gross:=0
    for index in range(0,aa.size(),3):
        var largest:=0
        for channel in range(3):
            var delta:=absi(int(aa[index+channel])-int(bb[index+channel]));sum+=delta;largest=maxi(largest,delta)
        if largest>64:gross+=1
    return {"mean_rgb_error":sum/aa.size()/255.0,"gross_pixel_fraction":float(gross)/(320*180)}

func _fingerprint(mesh:Mesh) -> Array:
    var result:Array=[]
    for slot in range(mesh.get_surface_count()):
        var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(var_to_bytes(mesh.surface_get_arrays(slot)))
        result.append([digest.finish().hex_encode(),mesh.surface_get_material(slot).get_instance_id()])
    return result

func _run() -> void:
    create_timer(180).timeout.connect(func():push_error("CITY_FACADE_BATCHES timeout");quit(1))
    assert(DisplayServer.get_name()!="headless","Actual rendered facade preservation requires a graphical renderer")
    root.size=Vector2i(1280,720)
    world=Node3D.new();root.add_child(world);current_scene=world
    var anchor:=Vector3(13500,0,-7000)
    var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.28,.35,.42);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color(.8,.85,.9);environment.environment.ambient_light_energy=.4;world.add_child(environment)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-30,0);world.add_child(sun)
    var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2.ONE*220;ground.mesh=plane;ground.position=anchor;var material:=StandardMaterial3D.new();material.albedo_color=Color(.35,.33,.29);ground.material_override=material;world.add_child(ground)
    var baseline:=Node3D.new();baseline.position=anchor;world.add_child(baseline)
    var candidate:=Node3D.new();candidate.position=anchor;world.add_child(candidate)
    var facade:RefCounted=load("res://scripts/modular_city_facades.gd").new()
    var lots:Array[Vector3]=[]
    for side:float in [-1.0,1.0]:
        for z:float in [14.0,25.0,36.0,47.0,58.0]:lots.append(Vector3(side*25,-side*PI*.5,z))
        for z:float in [-57.0,-36.0,-15.0]:lots.append(Vector3(side*66,-side*PI*.5,z))
    for x:float in [-31.0,31.0]:lots.append(Vector3(x,0,-61))
    for x:float in [-44.0,-20.0,20.0,44.0]:lots.append(Vector3(x,PI,73))
    for index in range(lots.size()):
        var lot:=lots[index];facade.add_house(Vector3(lot.x,0,lot.z),lot.y,Vector2(9.5,12),3 if index%3==0 else 2,false,true)
    assert(lots.size()==22)
    var expected:Dictionary={};var houses:=0
    for group:Dictionary in facade.groups.values():
        var mesh:Mesh=group.mesh;var key:=mesh.get_instance_id()
        snapshots[key]=_fingerprint(mesh)
        expected[key]={"mesh":mesh,"transforms":group.transforms.duplicate(),"range_end":group.range_end}
        if mesh.get_meta("authored_city_house",false):houses+=group.transforms.size()
        # Independent reference: render the unpartitioned original instance list.
        var data:=MultiMesh.new();data.transform_format=MultiMesh.TRANSFORM_3D;data.mesh=mesh;data.instance_count=group.transforms.size()
        for index in range(data.instance_count):data.set_instance_transform(index,group.transforms[index])
        var node:=MultiMeshInstance3D.new();node.multimesh=data;node.visibility_range_end=float(group.range_end);baseline.add_child(node)
    assert(houses==22)
    facade.finish(candidate)
    var actual:Dictionary={};var house_batches:=0
    for batch:MultiMeshInstance3D in candidate.find_children("*","MultiMeshInstance3D",true,false):
        var data:=batch.multimesh;var key:=data.mesh.get_instance_id()
        assert(expected.has(key) and data.mesh==expected[key].mesh,"Partitioning replaced a shared source mesh")
        assert(_fingerprint(data.mesh)==snapshots[key],"Partitioning changed geometry UVs normals or material references")
        assert(is_equal_approx(batch.visibility_range_end,float(expected[key].range_end)))
        assert(batch.transform==Transform3D.IDENTITY)
        if not actual.has(key):actual[key]=[]
        for index in range(data.instance_count):actual[key].append(data.get_instance_transform(index))
        if data.mesh.get_meta("authored_city_house",false):
            house_batches+=1
            for i in range(data.instance_count):
                for j in range(i):assert(data.get_instance_transform(i).origin.distance_to(data.get_instance_transform(j).origin)<23,"Unrelated distant houses still share one oversized culling bound")
    assert(house_batches>2 and actual.size()==expected.size())
    for key in expected:
        var remaining:Array=actual[key].duplicate()
        assert(remaining.size()==expected[key].transforms.size(),"A house or detail was duplicated or lost")
        for transform:Transform3D in expected[key].transforms:
            var found:=-1
            for index in range(remaining.size()):
                if transform.is_equal_approx(remaining[index]):found=index;break
            assert(found>=0,"A source instance transform changed")
            remaining.remove_at(found)
        assert(remaining.is_empty())
    var camera:=Camera3D.new();world.add_child(camera);camera.fov=72;camera.make_current()
    for quality in range(4):
        root.get_node("SettingsManager").set_quality_preset(quality);facade.apply_surface_quality(quality)
        for view in range(3):
            camera.position=anchor+([Vector3(-5,2.3,-1),Vector3(-15,3,32),Vector3(0,12,-42)][view] as Vector3)
            camera.look_at(anchor+([Vector3(-22,3.1,32),Vector3(-25,4.3,42),Vector3(0,4,33)][view] as Vector3))
            var before:Image=await _render(baseline,candidate,"%d-%d-before"%[quality,view])
            var after:Image=await _render(candidate,baseline,"%d-%d-after"%[quality,view])
            var delta:=_difference(before,after);delta.quality=quality;delta.view=view;comparisons.append(delta)
            print("CITY_BATCH_RENDER_PAIR ",JSON.stringify(delta))
            assert(float(delta.mean_rgb_error)<.005 and float(delta.gross_pixel_fraction)<.005,"Rendered partitioned townhouses diverge from their unchanged reference layout")
    var report:={"houses":houses,"house_batches":house_batches,"source_meshes":snapshots.size(),"unchanged_geometry_uv_normal_material_arrays":true,"all_instance_transforms_conserved":true,"quality_levels":4,"actual_render_pairs":comparisons}
    var file:=FileAccess.open("user://city-facade-batches.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("CITY_FACADE_BATCHES_OK houses=22 shared_geometry=true transforms=conserved quality_levels=4 rendered_pairs=12")
    world.free();quit(0)
