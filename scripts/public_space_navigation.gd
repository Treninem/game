extends Node3D

# Goals belong to routines/needs. This bounded grid is measured from live solid
# geometry; no resident is assigned a patrol or a pre-authored walking route.
const CELL:=0.75
const LOW:=Vector2(-38,-25)
const HIGH:=Vector2(38,55)
var lower_bound:=LOW
var upper_bound:=HIGH
var graph:=AStar2D.new()
var building_links:=false
var grid:=AStarGrid2D.new()
var grid_ready:=false
var probe:=PhysicsShapeQueryParameters3D.new()
var anchor_probe:=PhysicsShapeQueryParameters3D.new()
var cursor:=0
var routes:Dictionary={}

func _enter_tree() -> void:
    # WorldLoading reparents the prepared world. _ready runs only once, while
    # _exit_tree disconnects this listener; reconnect on every actual entry.
    if not get_tree().node_added.is_connected(_on_node_added):get_tree().node_added.connect(_on_node_added)
    call_deferred("_exclude_people")
    call_deferred("_watch_existing_geometry")

func _ready() -> void:
    grid.region=Rect2i(0,0,ceili((upper_bound.x-lower_bound.x)/CELL),ceili((upper_bound.y-lower_bound.y)/CELL))
    grid.cell_size=Vector2.ONE*CELL;grid.offset=lower_bound+Vector2.ONE*CELL*.5
    grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
    var capsule:=CapsuleShape3D.new();capsule.radius=.36;capsule.height=1.7
    probe.shape=capsule;probe.collision_mask=1
    var body:=CapsuleShape3D.new();body.radius=.34;body.height=1.8
    anchor_probe.shape=body;anchor_probe.collision_mask=1


func _watch_existing_geometry() -> void:
    for shape:CollisionShape3D in get_tree().root.find_children("*","CollisionShape3D",true,false):
        _consider_geometry(weakref(shape))

func _on_node_added(node:Node) -> void:
    if node is CollisionShape3D:
        var reference:WeakRef=weakref(node)
        # A short-lived collider can appear and disappear in one idle frame
        # while several physics ticks run. Watch it now when initialized; keep
        # the deferred pass for shapes/poses filled in after add_child().
        _consider_geometry(reference)
        call_deferred("_consider_geometry",reference)

func _consider_geometry(reference:WeakRef) -> void:
    var shape:=reference.get_ref() as CollisionShape3D
    if not is_instance_valid(shape) or not shape.is_inside_tree() or shape.shape==null:return
    var body:=shape.get_parent() as StaticBody3D
    if body==null:return
    var point:=to_local(shape.global_position)
    if point.x<lower_bound.x-4 or point.x>upper_bound.x+4 or point.z<lower_bound.y-4 or point.z>upper_bound.y+4:return
    if not body.tree_exiting.is_connected(invalidate):body.tree_exiting.connect(invalidate)
    invalidate()

func invalidate() -> void:
    if not is_inside_tree():return
    grid_ready=false;cursor=0;building_links=false;graph.clear();routes.clear();set_physics_process(true)

func _exit_tree() -> void:
    if get_tree().node_added.is_connected(_on_node_added):get_tree().node_added.disconnect(_on_node_added)

func _exclude_people() -> void:
    var ignored:Array[RID]=[]
    for person in get_tree().get_nodes_in_group("settlement_npc")+get_tree().get_nodes_in_group("player"):
        if person is CollisionObject3D:ignored.append(person.get_rid())
    probe.exclude=ignored
    anchor_probe.exclude=ignored

func _physics_process(_delta:float) -> void:
    if grid_ready:return
    _exclude_people()
    var started:=Time.get_ticks_usec()
    for sample in range(96):
        if cursor>=grid.region.size.x*grid.region.size.y:
            if not building_links:building_links=true;cursor=0;return
            grid_ready=true;set_physics_process(false);return
        var id:=Vector2i(cursor%grid.region.size.x,int(cursor/grid.region.size.x))
        if building_links:
            if graph.has_point(_index(id)):
                for offset:Vector2i in [Vector2i.LEFT,Vector2i.UP,Vector2i(-1,-1),Vector2i(1,-1)]:
                    var neighbor:=id+offset
                    if not grid.is_in_boundsv(neighbor) or not graph.has_point(_index(neighbor)):continue
                    if offset.x!=0 and offset.y!=0 and (grid.is_point_solid(id+Vector2i(offset.x,0)) or grid.is_point_solid(id+Vector2i(0,offset.y))):continue
                    graph.connect_points(_index(id),_index(neighbor))
            cursor+=1
            if Time.get_ticks_usec()-started>=1800:break
            continue
        var point:=grid.get_point_position(id)
        var world:=to_global(Vector3(point.x,0,point.y))
        var point_xz:=Vector2(world.x,world.z)
        var canal:=preload("res://scripts/capital_canal_data.gd")
        var bridge:=canal.bridge_at(point_xz)
        var forbidden_water:=canal.wet_at(point_xz) and is_inf(bridge.x)
        world.y=(canal.deck_height(point_xz.x-bridge.x) if not is_inf(bridge.x) else WorldData.elevation_at(point_xz))+1.0
        probe.transform=Transform3D(Basis.IDENTITY,world)
        grid.set_point_solid(id,forbidden_water or not get_world_3d().direct_space_state.intersect_shape(probe,1).is_empty())
        if not grid.is_point_solid(id):graph.add_point(_index(id),point)
        cursor+=1
        if Time.get_ticks_usec()-started>=1800:break

func _index(cell:Vector2i) -> int:
    return cell.y*grid.region.size.x+cell.x

func _path(from:Vector2i,to:Vector2i) -> Array[Vector2i]:
    var path:Array[Vector2i]=[]
    if not graph.has_point(_index(from)) or not graph.has_point(_index(to)):return path
    for index:int in graph.get_id_path(_index(from),_index(to)):
        path.append(Vector2i(index%grid.region.size.x,int(index/grid.region.size.x)))
    return path

func _cell(point:Vector3) -> Vector2i:
    return Vector2i(roundi((point.x-grid.offset.x)/CELL),roundi((point.z-grid.offset.y)/CELL))

func _surface_height(world:Vector2) -> float:
    var canal:=preload("res://scripts/capital_canal_data.gd")
    var bridge:=canal.bridge_at(world)
    return canal.deck_height(world.x-bridge.x) if not is_inf(bridge.x) else WorldData.elevation_at(world)

func _connection_clear(from_world:Vector3,to_world:Vector3) -> bool:
    # Endpoints can be free on different levels (bank/deck). A person must
    # have continuous walkable support between them, not jump through a rail.
    var from_xz:=Vector2(from_world.x,from_world.z)
    var to_xz:=Vector2(to_world.x,to_world.z)
    var distance:=from_xz.distance_to(to_xz)
    var steps:=maxi(1,ceili(distance/.20))
    var previous:=from_world.y
    for index in range(steps+1):
        var point:=from_xz.lerp(to_xz,float(index)/steps)
        var height:=_surface_height(point)
        if absf(height-previous)>.10+(distance/steps)*tan(deg_to_rad(48)):return false
        previous=height
    var destination:=Vector3(to_world.x,_surface_height(to_xz)+.02,to_world.z)
    # Lift the standing capsule by12cm only for the obstacle sweep. Otherwise
    # an initial floor touch makes cast_motion ignore the whole joined bridge.
    # The support samples above independently reject steps/drops and steepness.
    anchor_probe.transform=Transform3D(Basis.IDENTITY,from_world+Vector3.UP*1.02)
    anchor_probe.motion=destination-from_world
    var result:=get_world_3d().direct_space_state.cast_motion(anchor_probe)
    return result.size()==2 and result[0]>=.99999

func _nearest(id:Vector2i,from_world:Vector3=Vector3.INF) -> Vector2i:
    if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
        var preferred:=grid.get_point_position(id)
        if is_inf(from_world.x) or _connection_clear(from_world,to_global(Vector3(preferred.x,0,preferred.y))):return id
    var candidates:Array[Vector2i]=[]
    var center:=Vector2i(clampi(id.x,0,grid.region.size.x-1),clampi(id.y,0,grid.region.size.y-1))
    for x in range(center.x-3,center.x+4):
        for y in range(center.y-3,center.y+4):
            var candidate:=Vector2i(x,y)
            if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):candidates.append(candidate)
    candidates.sort_custom(func(a:Vector2i,b:Vector2i)->bool:return id.distance_squared_to(a)<id.distance_squared_to(b))
    for candidate:Vector2i in candidates:
        if is_inf(from_world.x):return candidate
        var point:=grid.get_point_position(candidate)
        if _connection_clear(from_world,to_global(Vector3(point.x,0,point.y))):return candidate
    return Vector2i(-1,-1)

func can_reach(from:Vector3,destination:Vector3) -> bool:
    if not grid_ready:return false
    _exclude_people()
    var a:=_nearest(_cell(to_local(from)),from);var b:=_nearest(_cell(to_local(destination)))
    return a.x>=0 and b.x>=0 and not _path(a,b).is_empty()

func contains(world:Vector3) -> bool:
    var point:=to_local(world)
    return point.x>=lower_bound.x and point.x<=upper_bound.x and point.z>=lower_bound.y and point.z<=upper_bound.y

func _arrival_point(from_world:Vector3,destination:Vector3,radius:float) -> Vector3:
    if _connection_clear(from_world,destination):return destination
    # Furniture goals already have a physical interaction radius. Their exact
    # authoring point can lie under a table edge even though that radius is
    # reachable. Stop inside the same existing volume, never through furniture.
    if radius>0:
        var away:=from_world-destination;away.y=0
        var edge:=destination+away.normalized()*radius*.9
        if _connection_clear(from_world,edge):return edge
    return Vector3.INF

func next_point(from_world:Vector3,destination_world:Vector3,actor:Node3D,arrival_radius:float=0.) -> Vector3:
    if not grid_ready:return from_world
    var from:=to_local(from_world);var destination:=to_local(destination_world)
    _exclude_people()
    var start:=_nearest(_cell(from),from_world);var finish:=_nearest(_cell(destination))
    if start.x<0 or finish.x<0:return from_world
    var anchor:=grid.get_point_position(start)
    if start!=_cell(from):
        # Reach the validated anchor before following its path; otherwise a
        # virtual start across the wall can skip the only safe corner point.
        return to_global(Vector3(anchor.x,from.y,anchor.y))
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
                    grid.set_point_solid(id,true);graph.set_point_disabled(_index(id),true);changed.append(id)
    var record:Dictionary=routes.get(actor.get_instance_id(),{})
    if record.get("finish",Vector2i(-1,-1))!=finish or not record.get("path",[]).has(start) or record.get("people","")!=signature:
        record={"finish":finish,"path":_path(start,finish),"people":signature};routes[actor.get_instance_id()]=record
    for id:Vector2i in changed:
        grid.set_point_solid(id,false);graph.set_point_disabled(_index(id),false)
    var path:Array[Vector2i]=record.path
    if path.is_empty():return from_world
    if start==finish:
        var arrival:=_arrival_point(from_world,destination_world,arrival_radius)
        return arrival if not is_inf(arrival.x) else to_global(Vector3(anchor.x,from.y,anchor.y))
    var next:=grid.get_point_position(path[mini(maxi(0,path.find(start))+1,path.size()-1)])
    var point:=to_global(Vector3(next.x,from.y,next.y))
    if _connection_clear(from_world,point):return point
    var anchor_world:=to_global(Vector3(anchor.x,from.y,anchor.y))
    # Grid endpoints can straddle a thin pillar. Keep the free nodes and remove
    # only the measured blocked edge, so A* can find another way around it.
    # Geometry invalidation rebuilds these links when a real obstacle changes.
    if Vector2(from.x-anchor.x,from.z-anchor.y).length()<.06 and not _connection_clear(anchor_world,point):
        var next_id:Vector2i=path[mini(maxi(0,path.find(start))+1,path.size()-1)]
        graph.disconnect_points(_index(start),_index(next_id));routes.clear()
    return anchor_world
