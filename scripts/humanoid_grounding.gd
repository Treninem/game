extends RefCounted

# Player-only visual support. The CharacterBody collider remains authoritative.
# Samples come from the existing skinned boot mesh, not an ankle-height guess.
var boot: MeshInstance3D
var samples := {"Left": [], "Right": []}
var bindings := {}
var root_offset := 0.0
var had_support := false
var last_origin := Vector3.INF
var last_cost_usec := 0
var contacts := {}
var cached_shape_weights := []
var landing_compression := 0.0
var pose_points := {}

func apply(visual: Node3D, skeleton: Skeleton3D, delta: float) -> void:
    var started := Time.get_ticks_usec()
    pose_points.clear()
    contacts.clear()
    landing_compression = 0.0
    var actor := visual.get_parent() as CharacterBody3D
    if actor == null or actor.has_meta("preview_animation") or not actor.is_on_floor() or String(actor.get_meta("activity", "idle")) in ["sit", "sleep"]:
        root_offset = 0.0
        had_support = false
        return
    if last_origin.is_finite() and last_origin.distance_to(actor.global_position) > 2.0:
        root_offset = 0.0
        had_support = false
    last_origin = actor.global_position
    if not is_instance_valid(boot):
        _cache_samples(visual, skeleton)
    if not is_instance_valid(boot) or samples.Left.is_empty() or samples.Right.is_empty():
        return
    _refresh_morph_vertices()
    var lows := {"Left": _lowest(skeleton, "Left"), "Right": _lowest(skeleton, "Right")}
    var hits := {}
    for side: String in ["Left", "Right"]:
        var point: Vector3 = lows[side]
        var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.35, point + Vector3.DOWN * 0.55, actor.collision_mask, [actor.get_rid()])
        var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty() and Vector3(hit.normal).dot(Vector3.UP) >= cos(actor.floor_max_angle):
            hits[side] = hit
        else:
            # The lowest vertex can be outside a ledge while the heel or toe
            # still rests on it. Probe actual skinned sole extrema, bounded
            # to four extra rays and only when the primary ray misses.
            for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
                var edge := _lowest(skeleton, side, Vector3.UP + direction * 0.5)
                var edge_query := PhysicsRayQueryParameters3D.create(edge + Vector3.UP * 0.35, edge + Vector3.DOWN * 0.55, actor.collision_mask, [actor.get_rid()])
                var edge_hit := actor.get_world_3d().direct_space_state.intersect_ray(edge_query)
                if not edge_hit.is_empty() and Vector3(edge_hit.normal).dot(Vector3.UP) >= cos(actor.floor_max_angle):
                    hits[side] = edge_hit
                    break
    var support := "Left" if (lows.Left as Vector3).y <= (lows.Right as Vector3).y else "Right"
    # A swinging foot over an edge cannot invalidate the other foot's support.
    if not hits.has(support) and not hits.is_empty():
        support = "Right" if support == "Left" else "Left"
    if not hits.has(support):
        root_offset = 0.0
        had_support = false
        return
    var contact_weights := {}
    var foot_bases := {}
    # Predict the tilted sole before choosing pelvis height. Otherwise a
    # straight standing leg cannot reach the floor after its foot is tilted.
    var target := INF
    for side: String in ["Left", "Right"]:
        if not hits.has(side):
            continue
        var height := Vector3(lows[side]).y - Vector3(lows[support]).y
        var contact := 1.0 - smoothstep(0.04 * visual.scale.x, 0.14 * visual.scale.x, height)
        var low := _lowest(skeleton, side, hits[side].normal)
        if _vertical_gap(low, hits[side]) < 0.003:
            contact = 1.0
        contact_weights[side] = contact
        var foot := skeleton.find_bone(side + "Foot")
        var basis := skeleton.global_basis.orthonormalized() * skeleton.get_bone_global_pose(foot).basis.orthonormalized()
        var tilt := Quaternion.IDENTITY.slerp(Quaternion(Vector3.UP, Vector3(hits[side].normal)), contact)
        foot_bases[side] = Basis(tilt) * basis
        if Vector3(hits[side].normal).dot(Vector3.UP) < 0.99999:
            _restore_foot_basis(skeleton, foot, foot_bases[side])
        if contact > 0.5:
            var point := _lowest(skeleton, side, hits[side].normal)
            target = minf(target, 0.004 - _vertical_gap(point, hits[side]))
    if not is_finite(target):
        root_offset = 0.0
        had_support = false
        return
    target = clampf(target, -0.30, 0.18)
    # New support must fit on its very first rendered frame. Lowering the
    # pelvis must not lag behind a planted leg's finite extension either.
    var smoothed := lerpf(root_offset, target, 1.0 - exp(-18.0 * maxf(delta, 0.0)))
    root_offset = minf(smoothed, target) if had_support else target
    had_support = true
    var compression := 0.0
    var elapsed: Variant = actor.get("landing_elapsed")
    if elapsed != null and float(elapsed) > 0.0:
        var phase := clampf(1.0 - float(elapsed) / 0.24, 0.0, 1.0)
        compression = sin(PI * phase) * 0.10 * float(actor.get("landing_strength")) * visual.scale.x
    landing_compression = compression
    var hip := skeleton.find_bone("Hips")
    skeleton.set_bone_pose_position(hip, skeleton.get_bone_pose_position(hip) + skeleton.global_basis.inverse() * Vector3.UP * (root_offset - compression))
    skeleton.force_update_all_bone_transforms()
    pose_points.clear()
    for side: String in ["Left", "Right"]:
        if not hits.has(side) or float(contact_weights.get(side, 0.0)) <= 0.001:
            continue
        var contact: float = contact_weights[side]
        var foot := skeleton.find_bone(side + "Foot")
        for iteration in range(2):
            var low := _lowest(skeleton, side, hits[side].normal)
            var adjustment := clampf((0.004 - _vertical_gap(low, hits[side])) * contact, -0.16, 0.20)
            if absf(adjustment) < 0.0005:
                break
            var ankle := skeleton.to_global(skeleton.get_bone_global_pose(foot).origin)
            _solve_leg(visual, skeleton, side, ankle + Vector3.UP * adjustment)
            _restore_foot_basis(skeleton, foot, foot_bases[side])
        contacts[side] = {"gap": _vertical_gap(_lowest(skeleton, side, hits[side].normal), hits[side]), "weight": contact}
    # Pelvis support and landing compression can push the other, swinging foot
    # into an uphill face. Its old hit/stance weight was sampled before that
    # translation (and may be absent). Check both final skinned soles anew;
    # lift only penetrations, retaining the authored swing and foot rotation.
    for side: String in ["Left", "Right"]:
        _clear_swing_foot(visual, skeleton, actor, side)
    last_cost_usec = Time.get_ticks_usec() - started

func _cache_samples(visual: Node3D, skeleton: Skeleton3D) -> void:
    boot = visual.find_child("Boots", true, false) as MeshInstance3D
    if boot == null or boot.skin == null or not boot.mesh is ArrayMesh:
        return
    samples = {"Left": [], "Right": []}
    bindings.clear()
    cached_shape_weights.clear()
    for slot in range(boot.skin.get_bind_count()):
        var bone := boot.skin.get_bind_bone(slot)
        if not boot.skin.get_bind_name(slot).is_empty():
            bone = skeleton.find_bone(boot.skin.get_bind_name(slot))
        if bone >= 0:
            bindings[slot] = [bone, boot.skin.get_bind_pose(slot)]
    for surface in range(boot.mesh.get_surface_count()):
        var arrays := boot.mesh.surface_get_arrays(surface)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
        var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
        var shapes: Array = (boot.mesh as ArrayMesh).surface_get_blend_shape_arrays(surface)
        var count := bones.size() / vertices.size()
        var bins := {"Left": {}, "Right": {}}
        for vertex in range(vertices.size()):
            var influences := []
            var side := ""
            var largest := 0.0
            for joint in range(count):
                var weight := weights[vertex * count + joint]
                var slot := bones[vertex * count + joint]
                if weight <= 0.0 or not bindings.has(slot):
                    continue
                influences.append([slot, weight])
                if weight > largest:
                    largest = weight
                    side = "Left" if String(skeleton.get_bone_name(bindings[slot][0])).begins_with("Left") else "Right"
            if side.is_empty():
                continue
            # A bounded grid retains heel/toe/sole edges through foot roll.
            var cell := Vector2i(floori(vertices[vertex].x / 0.025), floori(vertices[vertex].z / 0.045))
            if bins[side].has(cell) and Vector3(bins[side][cell][0]).y <= vertices[vertex].y:
                continue
            var shape_points := []
            for shape: Array in shapes:
                shape_points.append((shape[Mesh.ARRAY_VERTEX] as PackedVector3Array)[vertex])
            bins[side][cell] = [vertices[vertex], influences, shape_points, vertices[vertex]]
        for side: String in ["Left", "Right"]:
            samples[side].append_array(bins[side].values())

func _refresh_morph_vertices() -> void:
    var weights := []
    for shape in range(boot.get_blend_shape_count()):
        weights.append(boot.get_blend_shape_value(shape))
    if weights == cached_shape_weights:
        return
    cached_shape_weights = weights
    for side: String in ["Left", "Right"]:
        for sample: Array in samples[side]:
            var vertex: Vector3 = sample[0]
            for shape in range(weights.size()):
                if is_zero_approx(float(weights[shape])):
                    continue
                var point: Vector3 = sample[2][shape]
                if (boot.mesh as ArrayMesh).blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED:
                    point -= sample[0]
                vertex += point * float(weights[shape])
            sample[3] = vertex

func _vertical_gap(point: Vector3, hit: Dictionary) -> float:
    return (point - Vector3(hit.position)).dot(hit.normal) / maxf(0.01, Vector3(hit.normal).y)

func _lowest(skeleton: Skeleton3D, side: String, normal := Vector3.UP) -> Vector3:
    var low := Vector3(0, INF, 0)
    var score := INF
    for point: Vector3 in _skinned_points(skeleton, side):
        if point.dot(normal) < score:
            low = point
            score = point.dot(normal)
    return low

func _skinned_points(skeleton: Skeleton3D, side: String) -> PackedVector3Array:
    if pose_points.has(side):
        return pose_points[side]
    # One deformation per unchanged leg pose. Different sole directions and
    # fallback/contact rays reuse it; every bone/root mutation invalidates it.
    var points := PackedVector3Array()
    var transforms := {}
    var world := skeleton.global_transform
    for sample: Array in samples[side]:
        var vertex: Vector3 = sample[3]
        var point := Vector3.ZERO
        for influence: Array in sample[1]:
            var slot: int = influence[0]
            if not transforms.has(slot):
                transforms[slot] = skeleton.get_bone_global_pose(bindings[slot][0]) * (bindings[slot][1] as Transform3D)
            point += ((transforms[slot] as Transform3D) * vertex) * float(influence[1])
        points.append(world * point)
    pose_points[side] = points
    return points

func _solve_leg(visual: Node3D, skeleton: Skeleton3D, side: String, world_goal: Vector3) -> void:
    pose_points.erase(side)
    var upper := skeleton.find_bone(side + "UpLeg")
    var knee := skeleton.find_bone(side + "Leg")
    var foot := skeleton.find_bone(side + "Foot")
    var hip := skeleton.get_bone_global_pose(upper).origin
    var joint := skeleton.get_bone_global_pose(knee).origin
    var ankle := skeleton.get_bone_global_pose(foot).origin
    var goal := skeleton.to_local(world_goal)
    var a := hip.distance_to(joint)
    var b := joint.distance_to(ankle)
    var direction := (goal - hip).normalized()
    var distance := clampf(hip.distance_to(goal), absf(a - b) + 0.001, a + b - 0.001)
    goal = hip + direction * distance
    var pole := skeleton.global_basis.inverse() * visual.global_basis * Vector3(0, 0, -1)
    var bend := (pole - direction * pole.dot(direction)).normalized()
    var along := (a * a - b * b + distance * distance) / (2.0 * distance)
    var joint_goal := hip + direction * along + bend * sqrt(maxf(0.0, a * a - along * along))
    var to_visual := visual.global_basis.inverse() * skeleton.global_basis
    visual.call("_align_sitting_bone", skeleton, side + "UpLeg", side + "Leg", to_visual * (joint_goal - hip))
    joint = skeleton.get_bone_global_pose(knee).origin
    visual.call("_align_sitting_bone", skeleton, side + "Leg", side + "Foot", to_visual * (goal - joint))

func _restore_foot_basis(skeleton: Skeleton3D, foot: int, world_basis: Basis) -> void:
    pose_points.erase(String(skeleton.get_bone_name(foot)).trim_suffix("Foot"))
    var local := skeleton.get_bone_pose_rotation(foot)
    var frame := skeleton.get_bone_global_pose(foot).basis.orthonormalized() * Basis(local).inverse()
    var goal := skeleton.global_basis.orthonormalized().inverse() * world_basis
    skeleton.set_bone_pose_rotation(foot, (frame.inverse() * goal).get_rotation_quaternion())
    skeleton.force_update_all_bone_transforms()

func _clear_swing_foot(visual: Node3D, skeleton: Skeleton3D, actor: CharacterBody3D, side: String) -> void:
    var normal := actor.get_floor_normal()
    if normal.length_squared() < 0.5:
        normal = Vector3.UP
    var point := _lowest(skeleton, side, normal)
    var reach := 0.45 * visual.scale.x
    var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * reach, point + Vector3.DOWN * 0.06, actor.collision_mask, [actor.get_rid()])
    var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP) < cos(actor.floor_max_angle):
        return
    var gap := _vertical_gap(_lowest(skeleton, side, hit.normal), hit)
    if gap >= 0.002:
        return
    var foot := skeleton.find_bone(side + "Foot")
    var basis := skeleton.global_basis.orthonormalized() * skeleton.get_bone_global_pose(foot).basis.orthonormalized()
    var lifted := 0.0
    for iteration in range(2):
        var adjustment := clampf(0.004 - gap, 0.0, 0.22 * visual.scale.x)
        if adjustment < 0.0005:
            break
        var ankle := skeleton.to_global(skeleton.get_bone_global_pose(foot).origin)
        _solve_leg(visual, skeleton, side, ankle + Vector3.UP * adjustment)
        _restore_foot_basis(skeleton, foot, basis)
        lifted += adjustment
        gap = _vertical_gap(_lowest(skeleton, side, hit.normal), hit)
    var contact: Dictionary = contacts.get(side, {"weight": 0.0})
    contact["gap"] = gap
    contact["clearance_lift"] = lifted
    contacts[side] = contact
