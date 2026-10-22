extends RefCounted

static var cached_clips: Dictionary = {}

# Bake once into the actor's private library. No per-frame IK or cloth solver.
static func prepare(visual: Node3D) -> void:
    var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var animator: AnimationPlayer = visual.get("animation_player")
    var base := animator.get_animation("Idle")
    var key := base.get_instance_id()
    if cached_clips.has(key):
        animator.get_animation_library("").add_animation("WorkStanding", cached_clips[key])
        return
    var original := {}
    for bone in range(skeleton.get_bone_count()):
        original[bone] = skeleton.get_bone_pose_rotation(bone)
    for name: String in ["WorkStanding"]:
        var clip := Animation.new()
        clip.length = 2.4
        clip.loop_mode = Animation.LOOP_LINEAR
        # Freeze the supported Idle lower body, retaining every transform track.
        # Copying a cropped Idle loop leaves keys outside the new loop boundary.
        for source in range(base.get_track_count()):
            var type := base.track_get_type(source)
            var track := clip.add_track(type)
            clip.track_set_path(track, base.track_get_path(source))
            assert(type in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D])
            if type == Animation.TYPE_POSITION_3D:
                var value := base.position_track_interpolate(source, 0)
                clip.position_track_insert_key(track, 0, value)
                clip.position_track_insert_key(track, clip.length, value)
            elif type == Animation.TYPE_ROTATION_3D:
                var value := base.rotation_track_interpolate(source, 0)
                clip.rotation_track_insert_key(track, 0, value)
                clip.rotation_track_insert_key(track, clip.length, value)
            else:
                var value := base.scale_track_interpolate(source, 0)
                clip.scale_track_insert_key(track, 0, value)
                clip.scale_track_insert_key(track, clip.length, value)
        var root := animator.get_node(animator.root_node)
        # Idle fingers hang loosely. Work with open fingers over the surface,
        # using the native anatomical bind, rather than folding through it.
        for bone in range(skeleton.get_bone_count()):
            var part := skeleton.get_bone_name(bone)
            if not "Hand" in part or not part.right(1).is_valid_int(): continue
            var path := NodePath(String(root.get_path_to(skeleton)) + ":" + part)
            var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
            if track >= 0: clip.remove_track(track)
            track = clip.add_track(Animation.TYPE_ROTATION_3D)
            clip.track_set_path(track, path)
            clip.rotation_track_insert_key(track, 0, Quaternion.IDENTITY)
            clip.rotation_track_insert_key(track, clip.length, Quaternion.IDENTITY)
        var changed: Array[int] = []
        for part: String in ["Spine1", "Spine2", "Neck", "Head", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand"]:
            var bone := skeleton.find_bone(part)
            changed.append(bone)
            var path := NodePath(String(root.get_path_to(skeleton)) + ":" + part)
            var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
            if track >= 0: clip.remove_track(track)
            track = clip.add_track(Animation.TYPE_ROTATION_3D)
            clip.track_set_path(track, path)
        for phase in range(5):
            var motion: float = [0.0, 1.0, 0.0, -1.0, 0.0][phase]
            for bone: int in original:
                skeleton.set_bone_pose_rotation(bone, original[bone])
            skeleton.force_update_all_bone_transforms()
            var lean := 0.10
            for part: String in ["Spine1", "Spine2"]:
                visual.call("_rotate_actor_bone", skeleton, part, Vector3.RIGHT, -lean * 0.5)
            visual.call("_rotate_actor_bone", skeleton, "Neck", Vector3.RIGHT, -0.18)
            visual.call("_rotate_actor_bone", skeleton, "Head", Vector3.RIGHT, -0.56)
            for side: String in ["Left", "Right"]:
                var sign := -1.0 if side == "Left" else 1.0
                var shoulder: Vector3 = visual.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(side + "Arm")).origin))
                var target := Vector3(sign * 0.13, shoulder.y - 0.42, -0.30)
                if side == "Right":
                    target.z += motion * 0.045
                    target.y += motion * 0.018
                _reach(visual, skeleton, side, target, Vector3(sign, -0.4, 0.1))
                visual.call("_orient_hand_axes", skeleton, side, Vector3(0, -0.10, -1).normalized(), Vector3(-sign, 0, 0))
            for bone: int in changed:
                var path := NodePath(String(root.get_path_to(skeleton)) + ":" + skeleton.get_bone_name(bone))
                clip.rotation_track_insert_key(clip.find_track(path, Animation.TYPE_ROTATION_3D), phase * 0.6, skeleton.get_bone_pose_rotation(bone))
        animator.get_animation_library("").add_animation(name, clip)
        cached_clips[key] = clip
    for bone: int in original:
        skeleton.set_bone_pose_rotation(bone, original[bone])
    skeleton.force_update_all_bone_transforms()

static func _reach(visual: Node3D, skeleton: Skeleton3D, side: String, target: Vector3, pole: Vector3) -> void:
    var upper := skeleton.find_bone(side + "Arm")
    var elbow := skeleton.find_bone(side + "ForeArm")
    var wrist := skeleton.find_bone(side + "Hand")
    var shoulder := skeleton.get_bone_global_pose(upper).origin
    var joint := skeleton.get_bone_global_pose(elbow).origin
    var hand := skeleton.get_bone_global_pose(wrist).origin
    var destination := skeleton.to_local(visual.to_global(target))
    var a := shoulder.distance_to(joint)
    var b := joint.distance_to(hand)
    var direction := (destination - shoulder).normalized()
    # Keep a visible elbow bend even at the far end of the working stroke.
    var distance := clampf(shoulder.distance_to(destination), absf(a-b) + 0.001, sqrt(a*a+b*b+2*a*b*cos(deg_to_rad(32))))
    destination = shoulder + direction * distance
    var pole_direction := skeleton.global_basis.inverse() * visual.global_basis * pole
    var bend := (pole_direction - direction * pole_direction.dot(direction)).normalized()
    var along := (a*a-b*b+distance*distance)/(2*distance)
    var knee := shoulder + direction * along + bend * sqrt(maxf(0, a*a-along*along))
    var to_actor := visual.global_basis.inverse() * skeleton.global_basis
    visual.call("_align_sitting_bone", skeleton, side + "Arm", side + "ForeArm", to_actor * (knee-shoulder))
    joint = skeleton.get_bone_global_pose(elbow).origin
    visual.call("_align_sitting_bone", skeleton, side + "ForeArm", side + "Hand", to_actor * (destination-joint))
