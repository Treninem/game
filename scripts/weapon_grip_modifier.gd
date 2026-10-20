extends SkeletonModifier3D

var visual: Node3D
var last_grip := Transform3D.IDENTITY
var closed_fingers := 0
var gait_time := 0.0
var gait_applied := false
var gait_tracks: Dictionary = {}

func _process_modification_with_delta(_delta: float) -> void:
    if not is_instance_valid(visual):
        closed_fingers = 0
        gait_applied = false
        return
    var skeleton := get_skeleton()
    _moving_legs(skeleton, _delta)
    if not is_instance_valid(visual.held_weapon):
        closed_fingers = 0
        return
    var side := "Left" if visual.held_item == "short_bow" else "Right"
    if visual.held_item == "short_bow":
        var actor := visual.get_parent_node_3d()
        var pivot := actor.get_node_or_null("CameraPivot") as Node3D
        if pivot != null:
            var axis := (skeleton.global_basis.inverse() * actor.global_basis.x).normalized()
            for arm_side: String in ["Left", "Right"]:
                _rotate(skeleton, skeleton.find_bone(arm_side + "Arm"), Basis(axis, pivot.rotation.x))
    for finger: String in ["Index", "Middle", "Ring", "Pinky", "Thumb"]:
        for joint in range(1, 4):
            var bone := skeleton.find_bone(side + "Hand" + finger + str(joint))
            if bone >= 0:
                skeleton.set_bone_pose_rotation(bone, Quaternion.IDENTITY)
    var frame := palm_frame(skeleton, side)
    last_grip = skeleton.global_transform * frame
    closed_fingers = 0
    _close_hand(skeleton, side, frame)
    var drawing: bool = visual.held_item == "short_bow" and visual.animation_player.assigned_animation == "Bow_Attack_Draw"
    var draw_point := Vector3.ZERO
    if drawing:
        for finger: String in ["Index", "Middle", "Ring", "Pinky", "Thumb"]:
            for joint in range(1, 4):
                var bone := skeleton.find_bone("RightHand" + finger + str(joint))
                if bone >= 0:
                    skeleton.set_bone_pose_rotation(bone, Quaternion.IDENTITY)
        var right_frame := palm_frame(skeleton, "Right")
        _close_hand(skeleton, "Right", right_frame)
        var index := skeleton.get_bone_global_pose(skeleton.find_bone("RightHandIndex2")).origin
        var middle := skeleton.get_bone_global_pose(skeleton.find_bone("RightHandMiddle2")).origin
        draw_point = skeleton.to_global((index + middle) * 0.5)
    visual.call("_place_weapon_at_grip", last_grip, draw_point, drawing)

func _moving_legs(skeleton: Skeleton3D, delta: float) -> void:
    gait_applied = false
    var actor := visual.get_parent() as CharacterBody3D
    if actor == null:
        return
    var current: String = visual.animation_player.assigned_animation
    if current in ["Walk", "Run"]:
        gait_time = visual.animation_player.current_animation_position
        return
    var motion := actor.get_real_velocity()
    var speed := Vector2(motion.x, motion.z).length()
    if speed < 0.16 or current not in ["Axe_Chop", "Bow_Attack_Draw", "Bow_Attack_Shoot", "Punch", "Cast_Left", "Cast_Right"]:
        return
    var gait := "Run" if speed > 5.7 else "Walk"
    var clip: Animation = visual.animation_player.get_animation(gait)
    if not gait_tracks.has(gait):
        var tracks := []
        for track in range(clip.get_track_count()):
            var path := clip.track_get_path(track)
            if path.get_subname_count() == 0:
                continue
            var bone_name := String(path.get_subname(0))
            if bone_name not in ["Hips", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
                continue
            tracks.append([track, skeleton.find_bone(bone_name), clip.track_get_type(track)])
        gait_tracks[gait] = tracks
    gait_time = fposmod(gait_time + delta * clampf(speed / ((7.5 if gait == "Run" else 3.8) * visual.scale.x), 0.65, 1.5), clip.length)
    for entry: Array in gait_tracks[gait]:
        if entry[1] < 0:
            continue
        if entry[2] == Animation.TYPE_ROTATION_3D:
            skeleton.set_bone_pose_rotation(entry[1], clip.rotation_track_interpolate(entry[0], gait_time))
        elif entry[2] == Animation.TYPE_POSITION_3D:
            skeleton.set_bone_pose_position(entry[1], clip.position_track_interpolate(entry[0], gait_time))
    gait_applied = true

static func palm_frame(skeleton: Skeleton3D, side: String) -> Transform3D:
    var wrist := skeleton.get_bone_global_pose(skeleton.find_bone(side + "Hand")).origin
    var index := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex1")).origin
    var pinky := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandPinky1")).origin
    var middle := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandMiddle1")).origin
    var ring := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandRing1")).origin
    var knuckles := (index + middle + ring + pinky) * 0.25
    var along := (knuckles - wrist).normalized()
    var across := (index - pinky).normalized()
    var normal := along.cross(across).normalized() * (1.0 if side == "Left" else -1.0)
    across = (across - normal * across.dot(normal)).normalized()
    var basis := Basis(across.cross(normal).normalized(), across, normal).orthonormalized()
    return Transform3D(basis, wrist.lerp(knuckles, 0.9) + normal * 0.021)

func _close_hand(skeleton: Skeleton3D, side: String, frame: Transform3D) -> void:
    var palm_normal := frame.basis.z
    for finger: String in ["Index", "Middle", "Ring", "Pinky"]:
        var first := skeleton.find_bone(side + "Hand" + finger + "1")
        if first < 0:
            continue
        var axis := skeleton.get_bone_global_pose(first).basis.y.normalized().cross(palm_normal).normalized()
        for joint in range(1, 4):
            var bone := skeleton.find_bone(side + "Hand" + finger + str(joint))
            if bone < 0:
                continue
            var angle := deg_to_rad([62.0, 72.0, 38.0][joint - 1])
            # The roll is authored per finger, so bend in palm space instead
            # of assuming the same local X rotation on left/right bones.
            _rotate(skeleton, bone, Basis(axis, angle))
        closed_fingers += 1
    var thumb := skeleton.find_bone(side + "HandThumb1")
    var thumb_next := skeleton.find_bone(side + "HandThumb2")
    if thumb >= 0 and thumb_next >= 0:
        var from := skeleton.get_bone_global_pose(thumb).origin
        var direction := (skeleton.get_bone_global_pose(thumb_next).origin - from).normalized()
        var target := frame.origin + frame.basis.y * 0.015 + palm_normal * 0.008
        _rotate(skeleton, thumb, Basis(Quaternion(direction, (target - from).normalized())))
        closed_fingers += 1

func _rotate(skeleton: Skeleton3D, bone: int, rotation: Basis) -> void:
    var pose := skeleton.get_bone_global_pose(bone)
    var local := skeleton.get_bone_pose_rotation(bone)
    var frame := pose.basis.orthonormalized() * Basis(local).inverse()
    skeleton.set_bone_pose_rotation(bone, ((frame.inverse() * rotation * frame).get_rotation_quaternion() * local).normalized())
