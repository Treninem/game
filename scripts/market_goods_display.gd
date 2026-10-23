extends Node3D

const ARROW := preload("res://assets/production/weapons/woodland/Arrow.glb")
var merchant:Node
var piles:Array[MultiMeshInstance3D]=[]
var displayed:=-1
var elapsed:=0.0

func _process(delta:float) -> void:
    elapsed+=delta
    if elapsed<.5:return
    elapsed=0.0;refresh()

func build(counter:Node3D,trader:Node) -> void:
    merchant=trader
    var heights:Dictionary={}
    for mesh:MeshInstance3D in counter.find_children("*","MeshInstance3D",true,false):
        var transform:=counter.global_transform.affine_inverse()*mesh.global_transform
        for slot in range(mesh.mesh.get_surface_count()):
            if mesh.mesh.surface_get_material(slot).resource_name!="MI_Trim_Furniture":continue
            var arrays:=mesh.mesh.surface_get_arrays(slot)
            var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
            var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
            for index in range(0,indices.size(),3):
                var a:=transform*positions[indices[index]];var b:=transform*positions[indices[index+1]];var c:=transform*positions[indices[index+2]]
                var y:float=(a.y+b.y+c.y)/3
                if y<.6 or y>1.4 or maxf(a.y,maxf(b.y,c.y))-minf(a.y,minf(b.y,c.y))>.01:continue
                var key:=roundi(y*1000);heights[key]=float(heights.get(key,0))+(b-a).cross(c-a).length()*.5
    var largest:=0.0;var top:=.9
    for key in heights:
        if float(heights[key])>largest:largest=heights[key];top=float(key)/1000.0
    assert(largest>.05,"Market display requires a measured structural countertop")
    counter.add_child(self)
    position.y=top+.018
    var source:=ARROW.instantiate() as Node3D
    var rotation:=Transform3D(Basis(Vector3.RIGHT,-PI*.5)*Basis.from_scale(Vector3.ONE*.55),Vector3.ZERO)
    var bounds:AABB=get_parent().get_parent()._bounds(source,rotation)
    var placement:=rotation
    placement.origin=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
    var parts:Array[Dictionary]=[];_parts(source,Transform3D.IDENTITY,parts);source.free()
    for part:Dictionary in parts:
        var data:=MultiMesh.new();data.transform_format=MultiMesh.TRANSFORM_3D;data.mesh=part.mesh;data.instance_count=60
        for index in range(60):
            var origin:=Vector3((index%6-2.5)*.055,int(index/6)*.018,0)
            data.set_instance_transform(index,Transform3D(Basis.IDENTITY,origin)*placement*part.transform)
        var pile:=MultiMeshInstance3D.new();pile.multimesh=data;pile.visibility_range_end=36;add_child(pile);piles.append(pile)
    set_meta("countertop_y",top)
    refresh()

func _parts(node:Node3D,inherited:Transform3D,result:Array[Dictionary]) -> void:
    var transform:=inherited*node.transform
    if node is MeshInstance3D:result.append({"mesh":node.mesh,"transform":transform})
    for child in node.get_children():
        if child is Node3D:_parts(child,transform,result)

func refresh() -> void:
    if not is_instance_valid(merchant):return
    var stock:Dictionary=merchant._shop_stock()
    var count:=clampi(int(stock.get("arrow",0)),0,60)
    if displayed==count:return
    displayed=count
    for pile:MultiMeshInstance3D in piles:pile.multimesh.visible_instance_count=count
    set_meta("displayed_arrows",count)
