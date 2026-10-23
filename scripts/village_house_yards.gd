extends RefCounted

const KIT := preload("res://scripts/cottage_yard_assets.gd")
const PATHS := preload("res://scripts/terrain_paths.gd")
const PLANNER := preload("res://scripts/settlement_paths.gd")
const BERRY := preload("res://scripts/garden_berry.gd")
const DOOR := preload("res://scripts/door_interactable.gd")
const FURNITURE := preload("res://scripts/household_furniture.gd")
const NATURE := preload("res://scripts/production_nature.gd")
const GRASS := preload("res://assets/production/nature/meadow/MeadowGrass.glb")

static func build(village: Node3D) -> void:
    var houses: Array[Node3D] = []
    for child in village.get_children():
        if child is EnterableBuilding:houses.append(child)
    var plots: Array[Dictionary] = []
    for i in range(houses.size()):
        var home := houses[i]
        if home.has_node("GardenYard"):continue
        var half: Vector2 = home.get("footprint")*0.5
        var size := Vector2(6,5)
        var selected: Variant = null
        for offset in [Vector2(0,-half.y-7.5),Vector2(-half.x-4.3,-1),Vector2(half.x+4.3,-1),Vector2(-half.x-4.3,half.y+0.5),Vector2(half.x+4.3,half.y+0.5)]:
            var polygon := PATHS.rectangle(home,offset,size+Vector2.ONE*1.0)
            if _clear(village,home,polygon,houses,plots):
                selected = offset
                break
        if selected==null:continue
        var yard := Node3D.new()
        yard.name = "GardenYard"
        home.add_child(yard)
        var offset: Vector2 = selected
        var polygon := PATHS.rectangle(home,offset,size)
        var record := {"home":home,"yard":yard,"offset":offset,"size":size,"polygon":polygon}
        plots.append(record)
        _furnish(village,home,yard,offset,size,i)
    # Routes are designed only after all plot bounds are known, so one garden's
    # approach cannot be drawn through the next garden's closed fence.
    var wet_cells: Dictionary = {}
    for plot in plots:_connect(village,plot,houses,plots,wet_cells)
    village.set_meta("house_yard_count",plots.size())

static func _clear(village: Node3D,home: Node3D,polygon: PackedVector2Array,houses: Array[Node3D],plots: Array[Dictionary]) -> bool:
    for point in polygon:
        var local := village.to_local(Vector3(point.x,0,point.y))
        if absf(local.x)>75 or absf(local.z)>65 or not WorldData.water_kind_at(point).is_empty():return false
    for other in houses:
        if not Geometry2D.intersect_polygons(polygon,PATHS.rectangle(other,Vector2.ZERO,other.get("footprint")+Vector2.ONE*1.2)).is_empty():return false
    for path: Node3D in village.get_tree().get_nodes_in_group("terrain_path_surface"):
        if not village.is_ancestor_of(path):continue
        for footprint: PackedVector2Array in path.get_meta("path_polygons",[]):
            if not Geometry2D.intersect_polygons(polygon,footprint).is_empty():return false
    for other in plots:
        if not Geometry2D.intersect_polygons(polygon,other.polygon).is_empty():return false
    return true

static func _ground(home: Node3D,p: Vector2) -> Vector3:
    var world := home.to_global(Vector3(p.x,0,p.y))
    return Vector3(p.x,WorldData.elevation_at(Vector2(world.x,world.z))-home.global_position.y,p.y)

static func _furnish(village: Node3D,home: Node3D,yard: Node3D,offset: Vector2,size: Vector2,index: int) -> void:
    yard.set_meta("plot_offset",offset)
    yard.set_meta("plot_size",size)
    yard.set_meta("house_id",home.name)
    var marker := Marker3D.new()
    marker.name = "GardenMapFootprint"
    marker.position = _ground(home,offset)
    marker.set_meta("map_footprint",size)
    marker.add_to_group("map_fixture")
    yard.add_child(marker)
    var polygons: Array[PackedVector2Array] = [PATHS.rectangle(home,offset,size)]
    PATHS.add(yard,"CultivatedGround",polygons,"soil",0.006)
    var fences: Array[Transform3D] = []
    var half := size*0.5
    for segment in [
        [Vector2(-half.x,-half.y),Vector2(half.x,-half.y)],
        [Vector2(-half.x,-half.y),Vector2(-half.x,half.y)],
        [Vector2(half.x,-half.y),Vector2(half.x,half.y)],
        [Vector2(-half.x,half.y),Vector2(-1.1,half.y)],
        [Vector2(1.1,half.y),Vector2(half.x,half.y)]]:
        _fence(home,yard,offset+segment[0],offset+segment[1],fences)
    KIT.batch(yard,"GardenFence",fences,160)
    var gate := DOOR.new()
    gate.name = "GardenGate"
    gate.position = _ground(home,offset+Vector2(-1.1,half.y))
    gate.configure("Калитка",-1,true)
    gate.persistence_key = "door:garden:%s:%s" % [village.get_meta("settlement_id"),home.name]
    var model := MeshInstance3D.new()
    model.name = "FenceGateModel"
    model.mesh = KIT.mesh("GardenFence")
    model.position.x = 1.0
    model.visibility_range_end = 160
    gate.add_child(model)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(2,1.05,0.14)
    shape.shape = box
    shape.position = Vector3(1,0.525,0)
    gate.add_child(shape)
    yard.add_child(gate)
    yard.set_meta("gate_approach",offset+Vector2(0,half.y+3.0))
    var flower_transforms: Array[Transform3D] = []
    var rng := RandomNumberGenerator.new()
    rng.seed = 261022+index*71
    for i in range(14):
        var p := offset+Vector2(rng.randf_range(-2.5,2.5),rng.randf_range(-1.9,-1.4) if index%3!=2 else rng.randf_range(0.5,1.3))
        flower_transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*rng.randf_range(0.7,1.05)),_ground(home,p)))
    KIT.batch(yard,"MeadowFlowers",flower_transforms,48,false)
    var grass_transforms: Array[Transform3D] = []
    for i in range(24):
        var side := -1.0 if i%2==0 else 1.0
        var p := offset+Vector2(side*rng.randf_range(2.35,2.65),rng.randf_range(-2.1,2.0))
        grass_transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*rng.randf_range(0.55,0.8)),_ground(home,p)))
    NATURE.add_model_batches(yard,grass_transforms,GRASS,58,false)
    var bushes := [Vector2(-1.7,-0.5),Vector2(1.7,-0.5)] if index%3!=2 else [Vector2(-2.1,-0.4)]
    for i in range(bushes.size()):
        var plant := BERRY.new()
        plant.name = "Berry_%d" % i
        plant.persistent_id = "%s:%s:%d" % [village.get_meta("settlement_id"),home.name,i]
        plant.position = _ground(home,offset+bushes[i])
        yard.add_child(plant)
    if index%3==2:_store(home,yard,offset+Vector2(0,-0.7))

static func _fence(home: Node3D,yard: Node3D,a: Vector2,b: Vector2,transforms: Array[Transform3D]) -> void:
    var count := ceili(a.distance_to(b)/2.0)
    for i in range(count):
        var start := a.lerp(b,float(i)/count)
        var finish := a.lerp(b,float(i+1)/count)
        var direction := Vector3(finish.x-start.x,0,finish.y-start.y).normalized()
        var length := start.distance_to(finish)
        var center := _ground(home,(start+finish)*0.5)
        center.y = minf(_ground(home,start).y,_ground(home,finish).y)-0.025
        var basis := Basis(direction,Vector3.UP,direction.cross(Vector3.UP))
        transforms.append(Transform3D(basis.scaled(Vector3(length*0.5,1,1)),center))
        KIT.collision(yard,"Fence",Transform3D(basis,center+Vector3.UP*0.525),Vector3(length,1.05,0.14))

static func _store(home: Node3D,yard: Node3D,p: Vector2) -> void:
    var ground := _ground(home,p)
    for x in [-1.45,1.45]:
        for z in [-.9,.9]:ground.y=minf(ground.y,_ground(home,p+Vector2(x,z)).y)
    var stores: Array[Transform3D] = [Transform3D(Basis.IDENTITY,ground)]
    KIT.batch(yard,"TimberStore",stores,160)
    KIT.collision(yard,"StoreRoof",Transform3D(Basis(Vector3.RIGHT,-atan(.35/2.45)),ground+Vector3.UP*2.55),Vector3(3.4,.09,2.45))
    for x in [-1.45,1.45]:
        for z in [-.9,.9]:KIT.collision(yard,"StorePost",Transform3D(Basis.IDENTITY,ground+Vector3(x,1.25,z)),Vector3(.14,2.5,.14))
    var chest := FURNITURE.new()
    chest.name = "GardenChest"
    chest.position = _ground(home,p+Vector2(0,-.35))+Vector3.UP*.34
    # Its grandparent remains the actual home, preserving HouseholdFurniture's
    # identity and ownership contract without a separate storage implementation.
    yard.add_child(chest)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.35,.68,.72)
    shape.shape = box
    chest.add_child(shape)
    var visual := (load("res://assets/production/medieval/capital_square/Chest_Wood.gltf") as PackedScene).instantiate() as Node3D
    visual.name = "RealChestModel"
    chest.add_child(visual)
    var bounds := AABB()
    var measured := false
    for mesh: MeshInstance3D in visual.find_children("*","MeshInstance3D",true,false):
        var b: AABB = (visual.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
        for surface in range(mesh.mesh.get_surface_count()):
            var material := mesh.get_active_material(surface)
            if material!=null and "Furniture" in material.resource_name:mesh.set_surface_override_material(surface,KIT.material("Timber"))
        bounds = bounds.merge(b) if measured else b
        measured = true
    var factor := minf(1.35/bounds.size.x,minf(.68/bounds.size.y,.72/bounds.size.z))
    visual.scale = Vector3.ONE*factor
    visual.position = Vector3(-bounds.get_center().x*factor,-.34-bounds.position.y*factor,-bounds.get_center().z*factor)

static func _connect(village: Node3D,plot: Dictionary,houses: Array[Node3D],plots: Array[Dictionary],wet_cells: Dictionary) -> void:
    var yard: Node3D = plot.yard
    var home: Node3D = plot.home
    var point := home.to_global(Vector3(plot.offset.x,0,plot.offset.y+plot.size.y*0.5+3.0))
    var local := village.to_local(point)
    var destination := Vector2(local.x,local.z)
    var path_node := village.get_node("HomeAccess_"+String(home.name))
    var home_path: PackedVector2Array = path_node.get_meta("local_path")
    var grid := PLANNER._grid(village,houses,1.0,wet_cells)
    for other in plots:
        var inflated := Geometry2D.offset_polygon(other.polygon,0.65)
        var polygon: PackedVector2Array = inflated[0]
        # Rasterize only a small conservative rectangle around this one parcel.
        var local_polygon := PackedVector2Array()
        for p in polygon:
            var v := village.to_local(Vector3(p.x,0,p.y))
            local_polygon.append(Vector2(v.x,v.z))
        var rect := Rect2(local_polygon[0],Vector2.ZERO)
        for p in local_polygon:rect=rect.expand(p)
        for z in range(floori(rect.position.y-0.7),ceili(rect.end.y+0.7)+1):
            for x in range(floori(rect.position.x-0.7),ceili(rect.end.x+0.7)+1):
                if grid.region.has_point(Vector2i(x,z)) and Geometry2D.is_point_in_polygon(Vector2(x,z),local_polygon):grid.set_point_solid(Vector2i(x,z))
    var nearest := Vector2.ZERO
    var distance := INF
    for p in home_path:
        var id := Vector2i(p.round())
        if not grid.region.has_point(id) or grid.is_point_solid(id):continue
        if p.distance_squared_to(destination)<distance:
            nearest=p
            distance=p.distance_squared_to(destination)
    assert(is_finite(distance),"No walkable street node for garden: "+String(home.name))
    var path := grid.get_point_path(Vector2i(nearest.round()),Vector2i(destination.round()))
    assert(not path.is_empty(),"New garden has no clear access: "+String(home.name))
    path.append(destination)
    yard.set_meta("access_path",path)
    var footprints: Array[PackedVector2Array] = []
    PLANNER._append_path(village,footprints,path,1.5)
    # The routing goal stays clear of the open gate sweep, but the visible soil
    # continues through the actual 2.2m opening into the cultivated ground.
    var inside_world := home.to_global(Vector3(plot.offset.x,0,plot.offset.y+plot.size.y*0.5-0.15))
    var inside := village.to_local(inside_world)
    var entrance := PackedVector2Array([destination,Vector2(inside.x,inside.z)])
    PLANNER._append_path(village,footprints,entrance,1.5)
    PATHS.add(yard,"GardenAccess",footprints,"soil",0.010)
