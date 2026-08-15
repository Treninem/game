extends Node3D

const SETTLEMENTS := preload("res://scripts/world_settlements.gd")
const OVERLAY := preload("res://scripts/settlement_road_gate_overlay.gd")

var failed := false

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    print("::error title=Settlement road gates smoke::%s" % message.replace("\n", " "))
    push_error("Settlement road gates smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var overlay := OVERLAY.new() as SettlementRoadGateOverlay
    overlay.name = "RoadGateOverlay"
    add_child(overlay)

    var settlements := SETTLEMENTS.new() as WorldSettlements
    settlements.name = "Settlements"
    add_child(settlements)
    await get_tree().process_frame

    var expected := {
        "border_village_01": 3,
        "border_village_02": 1,
        "first_fortified_town": 3
    }

    for id in expected.keys():
        var root := settlements.materialize_settlement_for_test(id) as Node3D
        if root == null:
            _fail(2, "could not materialize %s" % id)
            return
        await get_tree().process_frame
        var network := overlay.rebuild_settlement(root)
        if network == null:
            _fail(3, "%s did not receive road-aware gate network" % id)
            return
        for _i in range(2):
            await get_tree().physics_frame

        var gate_count := int(network.get_meta("gate_count", 0))
        if gate_count != int(expected[id]):
            _fail(4, "%s expected %d physical road passages, got %d" % [id, int(expected[id]), gate_count])
            return
        if int(root.get_meta("road_gate_count", 0)) != gate_count:
            _fail(5, "%s settlement metadata disagrees with materialized gate count" % id)
            return

        if id == "first_fortified_town":
            if root.get_node_or_null("TownWallFrontLeft") != null or root.get_node_or_null("TownGatePassage") != null:
                _fail(6, "%s still contains legacy single-gate town perimeter" % id)
                return
        else:
            if root.get_node_or_null("FenceFrontLeft") != null or root.get_node_or_null("VillageGatePassage") != null:
                _fail(7, "%s still contains legacy single-gate village fence" % id)
                return

        var physical_segments := 0
        for child in network.get_children():
            if child is StaticBody3D:
                if _has_collision(child as StaticBody3D):
                    physical_segments += 1
        if physical_segments < 4:
            _fail(8, "%s new perimeter is not physically collidable" % id)
            return

        for gate_index in range(gate_count):
            var marker := network.get_node_or_null("RoadGatePassage_%02d" % gate_index) as Marker3D
            if marker == null:
                _fail(9, "%s missing physical passage marker %d" % [id, gate_index])
                return
            if not bool(marker.get_meta("road_connected", false)):
                _fail(10, "%s gate %d is not marked as road-connected" % [id, gate_index])
                return
            var half_width := float(marker.get_meta("half_width", 0.0))
            var minimum_half_width := 6.5 if id == "first_fortified_town" else 4.5
            if half_width < minimum_half_width:
                _fail(11, "%s gate %d is too narrow for its settlement class" % [id, gate_index])
                return

            var approach := network.get_node_or_null("RoadApproach_%02d" % gate_index) as Node3D
            if approach == null:
                _fail(12, "%s gate %d has no visible road approach" % [id, gate_index])
                return
            if not bool(approach.get_meta("extends_outside_perimeter", false)):
                _fail(13, "%s gate %d road does not extend beyond the wall/fence" % [id, gate_index])
                return
            if int(approach.get_meta("patch_count", 0)) < 8:
                _fail(14, "%s gate %d road approach is too short or sparse" % [id, gate_index])
                return
            if _mesh_child_count(approach) < 8:
                _fail(15, "%s gate %d road approach has no materialized road patches" % [id, gate_index])
                return

            if not _gate_center_is_physically_clear(root, network, marker):
                _fail(16, "%s gate %d is still blocked by physical perimeter collision" % [id, gate_index])
                return

        if id == "first_fortified_town":
            for gate_index in range(gate_count):
                if not _has_collision(network.get_node_or_null("GateLintel_%02d" % gate_index) as StaticBody3D):
                    _fail(17, "town road gate %d lacks load-bearing physical arch" % gate_index)
                    return
                if not _has_collision(network.get_node_or_null("Gate_%02d_Leaf_0" % gate_index) as StaticBody3D):
                    _fail(18, "town road gate %d lacks first physical open leaf" % gate_index)
                    return
                if not _has_collision(network.get_node_or_null("Gate_%02d_Leaf_1" % gate_index) as StaticBody3D):
                    _fail(19, "town road gate %d lacks second physical open leaf" % gate_index)
                    return

    print("SETTLEMENT_ROAD_GATE_OVERLAY_SMOKE_OK passages=7 village_junction=3 river_village=1 town_junction=3")
    get_tree().quit(0)

func _has_collision(body: StaticBody3D) -> bool:
    if body == null:
        return false
    for child in body.get_children():
        if child is CollisionShape3D and (child as CollisionShape3D).shape != null:
            return true
    return false

func _mesh_child_count(root: Node3D) -> int:
    var count := 0
    for child in root.get_children():
        if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
            count += 1
    return count

func _gate_center_is_physically_clear(settlement: Node3D, network: Node3D, marker: Marker3D) -> bool:
    var direction2: Vector2 = marker.get_meta("world_direction", Vector2(0, 1))
    direction2 = direction2.normalized()
    var direction := Vector3(direction2.x, 0.0, direction2.y)
    var center := marker.global_position + Vector3.UP * 1.45
    var query := PhysicsRayQueryParameters3D.create(center - direction * 3.0, center + direction * 3.0)
    query.collide_with_bodies = true
    query.collide_with_areas = false
    var excluded: Array[RID] = []
    for child in settlement.get_children():
        if child is CharacterBody3D:
            excluded.append((child as CharacterBody3D).get_rid())
    query.exclude = excluded
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return true
    var collider := hit.get("collider") as Node
    if collider == null:
        return true
    return not network.is_ancestor_of(collider)
