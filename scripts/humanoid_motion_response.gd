extends RefCounted

# A small additive balance pass on the existing human rig. Physics, authored
# limb cycles and the subsequent sole/weapon solvers remain authoritative.
var pitch := 0.0
var roll := 0.0
var head_yaw := 0.0
var shoulder_lift := 0.0
var last_physics_frame := -1
var last_velocity := Vector3.ZERO
var last_position := Vector3.INF
var last_forward := Vector3.FORWARD
var acceleration := Vector3.ZERO
var turn_rate := 0.0
var sampled := false
var bones: Dictionary = {}
var skeleton_id := 0
var last_cost_usec := 0
var last_delta := 0.0

func reset() -> void:
    pitch = 0.0
    roll = 0.0
    head_yaw = 0.0
    shoulder_lift = 0.0
    acceleration = Vector3.ZERO
    turn_rate = 0.0
    sampled = false
    last_physics_frame = -1
    last_position = Vector3.INF

func apply(visual: Node3D, skeleton: Skeleton3D, delta: float) -> void:
    var started := Time.get_ticks_usec()
    last_delta = delta
    var actor := visual.get_parent() as CharacterBody3D
    if actor == null or not actor.is_inside_tree() or not visual.is_inside_tree() or not is_instance_valid(visual.get("animation_player")):
        reset()
        return
    var animator: AnimationPlayer = visual.get("animation_player")
    var clip := String(animator.assigned_animation)
    if String(actor.get_meta("activity", "idle")) in ["sit", "sleep"] or clip in ["Sitting", "Death"]:
        reset()
        return
    if actor.name == "Player" and bool(actor.get("ground_guard_active")):
        reset()
        return
    if skeleton_id != skeleton.get_instance_id():
        skeleton_id = skeleton.get_instance_id()
        bones.clear()
        for name: String in ["Spine1", "Spine2", "Neck", "Head", "LeftShoulder", "RightShoulder"]:
            bones[name] = skeleton.find_bone(name)
        reset()
    var preview := actor.has_meta("preview_animation")
    var velocity := actor.get_real_velocity()
    velocity.y = 0.0
    if preview:
        # The editor has no physical displacement. Keep the authored gait and
        # do not invent acceleration when its turntable is dragged.
        acceleration = Vector3.ZERO
        turn_rate = 0.0
    else:
        _sample_physics(actor, visual, velocity)
    var frame := visual.global_basis.orthonormalized()
    var local_acceleration := frame.inverse() * acceleration
    var landing := 0.0
    if actor.name == "Player":
        var elapsed: Variant = actor.get("landing_elapsed")
        if elapsed != null and float(elapsed) > 0.0:
            landing = sin(PI * clampf(1.0 - float(elapsed) / 0.24, 0.0, 1.0)) * float(actor.get("landing_strength"))
    var action := clip in ["Axe_Chop", "Bow_Attack_Draw", "Bow_Attack_Shoot", "Punch", "Cast_Left", "Cast_Right"]
    var movement_weight := 0.25 if action else 1.0
    var grounded := preview or actor.is_on_floor()
    var target_pitch := local_acceleration.z * 0.006 * movement_weight if grounded else 0.0
    var target_roll := -local_acceleration.x * 0.006 * movement_weight if grounded else 0.0
    target_pitch = clampf(target_pitch - landing * 0.10, -0.14, 0.12)
    target_roll = clampf(target_roll, -0.10, 0.10)
    var target_yaw := clampf(-turn_rate * 0.022, -0.12, 0.12) if not action and grounded else 0.0
    var target_lift := landing * 0.035
    # Exponential response keeps equal wall-time behavior at 30/60/120 Hz.
    # A bounded delta prevents a stalled frame from producing a large snap.
    var blend := 1.0 - exp(-15.0 * clampf(delta, 0.0, 0.10))
    pitch = lerpf(pitch, target_pitch, blend)
    roll = lerpf(roll, target_roll, blend)
    head_yaw = lerpf(head_yaw, target_yaw, blend)
    shoulder_lift = lerpf(shoulder_lift, target_lift, blend)
    var right := (skeleton.global_basis.inverse() * frame.x).normalized()
    var up := (skeleton.global_basis.inverse() * frame.y).normalized()
    var back := (skeleton.global_basis.inverse() * frame.z).normalized()
    _rotate(skeleton, "Spine1", right, pitch * 0.55)
    _rotate(skeleton, "Spine1", back, roll * 0.55)
    _rotate(skeleton, "Spine2", right, pitch * 0.45)
    _rotate(skeleton, "Spine2", back, roll * 0.45)
    # Keep the gaze calmer than the torso while preserving the authored head.
    for name: String in ["Neck", "Head"]:
        _rotate(skeleton, name, right, -pitch * 0.25)
        _rotate(skeleton, name, back, -roll * 0.25)
        _rotate(skeleton, name, up, head_yaw * 0.5)
    _rotate(skeleton, "LeftShoulder", back, -shoulder_lift)
    _rotate(skeleton, "RightShoulder", back, shoulder_lift)
    last_cost_usec = Time.get_ticks_usec() - started

func _sample_physics(actor: CharacterBody3D, visual: Node3D, velocity: Vector3) -> void:
    var current_frame := Engine.get_physics_frames()
    if current_frame == last_physics_frame:
        return
    var frames := current_frame - last_physics_frame
    var seconds := float(frames) / float(Engine.physics_ticks_per_second)
    var forward := -visual.global_basis.z.normalized()
    var teleported := sampled and last_position.distance_to(actor.global_position) > maxf(0.5, minf(seconds, 8.0 / Engine.physics_ticks_per_second) * 24.0)
    if sampled and frames > 0 and frames <= 8 and not teleported:
        acceleration = (velocity - last_velocity) / seconds
        acceleration.y = 0.0
        acceleration = acceleration.limit_length(28.0)
        turn_rate = clampf(last_forward.signed_angle_to(forward, Vector3.UP) / seconds, -6.0, 6.0)
    else:
        acceleration = Vector3.ZERO
        turn_rate = 0.0
        # A pause invalidates the velocity derivative, not the displayed pose.
        # Ease it out on resume; only a relocation discards the old balance.
        if teleported:
            pitch = 0.0
            roll = 0.0
            head_yaw = 0.0
            shoulder_lift = 0.0
    sampled = true
    last_velocity = velocity
    last_position = actor.global_position
    last_forward = forward
    last_physics_frame = current_frame

func _rotate(skeleton: Skeleton3D, name: String, axis: Vector3, angle: float) -> void:
    var bone: int = bones.get(name, -1)
    if bone < 0 or absf(angle) < 0.00001:
        return
    var local := skeleton.get_bone_pose_rotation(bone)
    var frame := skeleton.get_bone_global_pose(bone).basis.orthonormalized() * Basis(local).inverse()
    skeleton.set_bone_pose_rotation(bone, ((frame.inverse() * Basis(axis, angle) * frame).get_rotation_quaternion() * local).normalized())
