extends RefCounted

# Bounded local A*: goals come from needs/routines, paths from physical geometry.
# No prescribed sequence of furniture, lanes or door-center waypoints.
const CELL := 0.25
var clearance := 0.38
var door_signature := ""
var grid := AStarGrid2D.new()
var home: EnterableBuilding
var ready := false
var routes: Dictionary = {}

func build(building: EnterableBuilding) -> void:
    home = building
    routes.clear()
    door_signature = _door_signature()
    var half := home.interior_size * 0.5
    grid.region = Rect2i(0, 0, int(ceil(home.interior_size.x / CELL)), int(ceil(home.interior_size.z / CELL)))
    grid.cell_size = Vector2.ONE * CELL
    grid.offset = Vector2(-half.x + CELL * 0.5, -half.z + CELL * 0.5)
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    grid.update()
    var obstacles: Array[Dictionary] = []
    for collision: CollisionShape3D in home.find_children("*", "CollisionShape3D", true, false):
        if collision.disabled or collision.shape == null:
            continue
        var door := collision.get_parent() as DoorInteractable
        if door != null and not door.locked and (not door.opened or absf(door.rotation.y - door.target_rotation_y) > 0.01):
            continue
        var box := AABB()
        if collision.shape is BoxShape3D:
            var size := (collision.shape as BoxShape3D).size
            box = AABB(-size * 0.5, size)
            var transform := home.global_transform.affine_inverse() * collision.global_transform
            if door != null and door.locked:
                var closed := door.transform
                closed.basis = Basis(Vector3.UP, door.closed_rotation_y) * Basis.from_scale(door.scale)
                transform = home.global_transform.affine_inverse() * door.get_parent_node_3d().global_transform * closed * collision.transform
            var world_box := transform * box
            if world_box.end.y <= home.floor_thickness + 0.06 or world_box.position.y > home.floor_thickness + 1.85:
                continue
            var flat := Transform2D(Vector2(transform.basis.x.x, transform.basis.x.z), Vector2(transform.basis.z.x, transform.basis.z.z), Vector2(transform.origin.x, transform.origin.z))
            obstacles.append({"frame": flat.affine_inverse(), "low": Vector2(box.position.x, box.position.z), "high": Vector2(box.end.x, box.end.z), "scale": minf(flat.x.length(), flat.y.length())})
            continue
        elif collision.shape is ConcavePolygonShape3D:
            var transform := home.global_transform.affine_inverse() * collision.global_transform
            # Author-cached bounds use the shape's own coordinate frame. Reject
            # overhead geometry before reading thousands of roof triangles.
            # Geometry intersecting actor height keeps the exact triangle path.
            var cached_bounds: Variant = collision.shape.get_meta("navigation_local_bounds") if collision.shape.has_meta("navigation_local_bounds") else null
            if cached_bounds is AABB:
                var local_bounds: AABB = transform * cached_bounds
                if local_bounds.end.y <= home.floor_thickness + 0.06 or local_bounds.position.y > home.floor_thickness + 1.85:
                    continue
            var points := (collision.shape as ConcavePolygonShape3D).get_faces()
            # A merged timber mesh spans the room. Rasterize its real triangles,
            # never its whole-room bounding box, which would seal every path.
            for index in range(0, points.size(), 3):
                var triangle := AABB(transform * points[index], Vector3.ZERO)
                triangle = triangle.expand(transform * points[index + 1]).expand(transform * points[index + 2])
                if triangle.end.y > home.floor_thickness + 0.06 and triangle.position.y < home.floor_thickness + 1.85:
                    obstacles.append({"frame": Transform2D.IDENTITY, "low": Vector2(triangle.position.x, triangle.position.z), "high": Vector2(triangle.end.x, triangle.end.z), "scale": 1.0})
            continue
        else:
            continue
        box = (home.global_transform.affine_inverse() * collision.global_transform) * box
        if box.end.y <= home.floor_thickness + 0.06 or box.position.y > home.floor_thickness + 1.85:
            continue
    for x in range(grid.region.size.x):
        for y in range(grid.region.size.y):
            var id := Vector2i(x, y)
            var p := grid.get_point_position(id)
            var blocked := absf(p.x) > half.x - clearance or absf(p.y) > half.z - clearance
            for obstacle: Dictionary in obstacles:
                var local: Vector2 = obstacle.frame * p
                var closest := Vector2(clampf(local.x, obstacle.low.x, obstacle.high.x), clampf(local.y, obstacle.low.y, obstacle.high.y))
                if local.distance_squared_to(closest) * float(obstacle.scale) * float(obstacle.scale) < clearance * clearance:
                    blocked = true
                    break
            grid.set_point_solid(id, blocked)
    ready = true

func _door_signature() -> String:
    var signature := ""
    for candidate in home.find_children("*", "AnimatableBody3D", true, false):
        var door := candidate as DoorInteractable
        if door != null:
            signature += str(door.locked) + str(door.opened and absf(door.rotation.y - door.target_rotation_y) <= 0.01)
    return signature

func _cell(point: Vector3) -> Vector2i:
    return Vector2i(roundi((point.x - grid.offset.x) / CELL), roundi((point.z - grid.offset.y) / CELL))

func _nearest(id: Vector2i) -> Vector2i:
    var best := Vector2i(-1, -1)
    var distance := INF
    for x in range(id.x - 3, id.x + 4):
        for y in range(id.y - 3, id.y + 4):
            var candidate := Vector2i(x, y)
            if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
                var d := id.distance_squared_to(candidate)
                if d < distance:
                    best = candidate
                    distance = d
    return best

func next_point(from: Vector3, destination: Vector3, actor: Node3D) -> Vector3:
    if not ready or door_signature != _door_signature():
        build(home)
    var start := _nearest(_cell(from))
    if start.x < 0:
        return from
    var dynamic := _block_stationary_people(from, actor, start)
    var finish := _nearest(_cell(destination))
    if finish.x < 0:
        _restore_people(dynamic.cells)
        return from
    var key := actor.get_instance_id()
    var record: Dictionary = routes.get(key, {})
    if record.get("finish", Vector2i(-1, -1)) != finish or not record.get("path", []).has(start) or record.get("people", "") != dynamic.signature:
        record = {"finish": finish, "path": grid.get_id_path(start, finish), "people": dynamic.signature}
        routes[key] = record
    var path: Array[Vector2i] = record.path
    _restore_people(dynamic.cells)
    if path.is_empty():
        return from
    var index := maxi(0, path.find(start))
    if index == path.size() - 1:
        return destination if start == _cell(destination) else Vector3(grid.get_point_position(finish).x, from.y, grid.get_point_position(finish).y)
    var next := grid.get_point_position(path[index + 1])
    # Open only an unlocked door obstructing the chosen near-term path.
    var ahead := grid.get_point_position(path[mini(index + 4, path.size() - 1)])
    var query := PhysicsRayQueryParameters3D.create(home.to_global(from + Vector3.UP), home.to_global(Vector3(ahead.x, from.y + 1, ahead.y)))
    if actor is CollisionObject3D:
        query.exclude = [(actor as CollisionObject3D).get_rid()]
    var hit := home.get_world_3d().direct_space_state.intersect_ray(query)
    var door := hit.get("collider") as DoorInteractable
    if door != null and not door.locked:
        door.set_open(true)
    return Vector3(next.x, from.y, next.y)

func _block_stationary_people(from: Vector3, actor: Node3D, start: Vector2i) -> Dictionary:
    var changed: Array[Vector2i] = []
    var signature := ""
    for other in home.get_tree().get_nodes_in_group("settlement_npc") + home.get_tree().get_nodes_in_group("player"):
        if other == actor or not other is CharacterBody3D:
            continue
        var person := other as CharacterBody3D
        if Vector2(person.velocity.x, person.velocity.z).length() > 0.15:
            continue
        var point := home.to_local(person.global_position)
        if Vector2(point.x - from.x, point.z - from.z).length() > 5.0:
            continue
        var center := _cell(point)
        signature += str(person.get_instance_id()) + str(center)
        var radius := clearance + (0.45 if person.is_in_group("player") else 0.34) + 0.02
        var reach := int(ceil(radius / CELL))
        for x in range(center.x - reach, center.x + reach + 1):
            for y in range(center.y - reach, center.y + reach + 1):
                var id := Vector2i(x, y)
                if id == start or not grid.is_in_boundsv(id) or grid.is_point_solid(id):
                    continue
                if grid.get_point_position(id).distance_to(Vector2(point.x, point.z)) < radius:
                    grid.set_point_solid(id, true)
                    changed.append(id)
    return {"cells": changed, "signature": signature}

func _restore_people(cells: Array) -> void:
    for id: Vector2i in cells:
        grid.set_point_solid(id, false)
