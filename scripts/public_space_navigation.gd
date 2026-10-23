extends Node3D

# Goals belong to routines/needs. This bounded grid is measured from live solid
# geometry; no resident is assigned a patrol or a pre-authored walking route.
const CELL:=0.75
const LOW:=Vector2(-38,-25)
const HIGH:=Vector2(38,55)
var grid:=AStarGrid2D.new()
var grid_ready:=false
var probe:=PhysicsShapeQueryParameters3D.new()
var cursor:=0
var routes:Dictionary={}

func _ready() -> void:
    grid.region=Rect2i(0,0,ceili((HIGH.x-LOW.x)/CELL),ceili((HIGH.y-LOW.y)/CELL))
    grid.cell_size=Vector2.ONE*CELL;grid.offset=LOW+Vector2.ONE*CELL*.5
    grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
    var capsule:=CapsuleShape3D.new();capsule.radius=.36;capsule.height=1.7
    probe.shape=capsule;probe.collision_mask=1
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_exclude_people")
    call_deferred("_watch_existing_geometry")

func _watch_existing_geometry() -> void:
    for shape:CollisionShape3D in get_tree().root.find_children("*","CollisionShape3D",true,false):
        _consider_geometry(weakref(shape))

func _on_node_added(node:Node) -> void:
    if node is CollisionShape3D:call_deferred("_consider_geometry",weakref(node))

func _consider_geometry(reference:WeakRef) -> void:
    var shape:=reference.get_ref() as CollisionShape3D
    if not is_instance_valid(shape) or not shape.is_inside_tree() or shape.shape==null:return
    var body:=shape.get_parent() as StaticBody3D
    if body==null:return
    var point:=to_local(shape.global_position)
    if point.x<LOW.x-4 or point.x>HIGH.x+4 or point.z<LOW.y-4 or point.z>HIGH.y+4:return
    if not body.tree_exiting.is_connected(invalidate):body.tree_exiting.connect(invalidate)
    invalidate()

func invalidate() -> void:
    if not is_inside_tree():return
    grid_ready=false;cursor=0;routes.clear();set_physics_process(true)

func _exit_tree() -> void:
    if get_tree().node_added.is_connected(_on_node_added):get_tree().node_added.disconnect(_on_node_added)

func _exclude_people() -> void:
    var ignored:Array[RID]=[]
    for person in get_tree().get_nodes_in_group("settlement_npc")+get_tree().get_nodes_in_group("player"):
        if person is CollisionObject3D:ignored.append(person.get_rid())
    probe.exclude=ignored

func _physics_process(_delta:float) -> void:
    if grid_ready:return
    _exclude_people()
    var started:=Time.get_ticks_usec()
    for sample in range(96):
        if cursor>=grid.region.size.x*grid.region.size.y:
            grid_ready=true;set_physics_process(false);return
        var id:=Vector2i(cursor%grid.region.size.x,int(cursor/grid.region.size.x))
        var point:=grid.get_point_position(id)
        var world:=to_global(Vector3(point.x,0,point.y))
        world.y=WorldData.elevation_at(Vector2(world.x,world.z))+1.0
        probe.transform=Transform3D(Basis.IDENTITY,world)
        grid.set_point_solid(id,not get_world_3d().direct_space_state.intersect_shape(probe,1).is_empty())
        cursor+=1
        if Time.get_ticks_usec()-started>=1800:break

func _cell(point:Vector3) -> Vector2i:
    return Vector2i(roundi((point.x-grid.offset.x)/CELL),roundi((point.z-grid.offset.y)/CELL))

func _nearest(id:Vector2i) -> Vector2i:
    var best:=Vector2i(-1,-1);var distance:=INF
    var center:=Vector2i(clampi(id.x,0,grid.region.size.x-1),clampi(id.y,0,grid.region.size.y-1))
    for x in range(center.x-3,center.x+4):
        for y in range(center.y-3,center.y+4):
            var candidate:=Vector2i(x,y)
            if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate) and id.distance_squared_to(candidate)<distance:
                best=candidate;distance=id.distance_squared_to(candidate)
    return best

func can_reach(from:Vector3,destination:Vector3) -> bool:
    if not grid_ready:return false
    var a:=_nearest(_cell(to_local(from)));var b:=_nearest(_cell(to_local(destination)))
    return a.x>=0 and b.x>=0 and not grid.get_id_path(a,b).is_empty()

func contains(world:Vector3) -> bool:
    var point:=to_local(world)
    return point.x>=LOW.x and point.x<=HIGH.x and point.z>=LOW.y and point.z<=HIGH.y

func next_point(from_world:Vector3,destination_world:Vector3,actor:Node3D) -> Vector3:
    if not grid_ready:return from_world
    var from:=to_local(from_world);var destination:=to_local(destination_world)
    var start:=_nearest(_cell(from));var finish:=_nearest(_cell(destination))
    if start.x<0 or finish.x<0:return from_world
    var changed:Array[Vector2i]=[];var signature:=""
    for person in get_tree().get_nodes_in_group("settlement_npc")+get_tree().get_nodes_in_group("player"):
        if person==actor or not person is CharacterBody3D or Vector2(person.velocity.x,person.velocity.z).length()>.15:continue
        var occupied_position:Vector3=person.global_position
        if person.has_meta("rest_collision_snapshot"):
            var collision:=person.get_node_or_null("CollisionShape3D") as CollisionShape3D
            if collision!=null:occupied_position=collision.global_position
        var point:=to_local(occupied_position)
        if Vector2(point.x-from.x,point.z-from.z).length()>5:continue
        var middle:=_cell(point);signature+=str(person.get_instance_id())+str(middle)
        for x in range(middle.x-2,middle.x+3):
            for y in range(middle.y-2,middle.y+3):
                var id:=Vector2i(x,y)
                if id!=start and grid.is_in_boundsv(id) and not grid.is_point_solid(id) and grid.get_point_position(id).distance_to(Vector2(point.x,point.z))<.76:
                    grid.set_point_solid(id,true);changed.append(id)
    var record:Dictionary=routes.get(actor.get_instance_id(),{})
    if record.get("finish",Vector2i(-1,-1))!=finish or not record.get("path",[]).has(start) or record.get("people","")!=signature:
        record={"finish":finish,"path":grid.get_id_path(start,finish),"people":signature};routes[actor.get_instance_id()]=record
    for id:Vector2i in changed:grid.set_point_solid(id,false)
    var path:Array[Vector2i]=record.path
    if path.is_empty():return from_world
    if start==finish:return destination_world
    var next:=grid.get_point_position(path[mini(maxi(0,path.find(start))+1,path.size()-1)])
    return to_global(Vector3(next.x,from.y,next.y))
