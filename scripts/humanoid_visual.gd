extends Node3D

const HUMAN: PackedScene = preload("res://assets/production/characters/citizen/citizen.glb")
const PALETTES := [null, preload("res://assets/production/characters/citizen/citizen_dark.png"), preload("res://assets/production/characters/citizen/citizen_light.png")]
static var palette_materials: Dictionary = {}
const WEAPONS := {
    "starter_axe": preload("res://assets/production/weapons/woodland/Axe_small.glb"),
    "stone_knife": preload("res://assets/production/weapons/woodland/Dagger.glb"),
    "short_bow": preload("res://assets/production/weapons/woodland/Bow_Wooden.glb")
}

@export var skin_color := Color(0.72, 0.55, 0.42)
@export var primary_color := Color(0.11, 0.18, 0.28)
@export var secondary_color := Color(0.22, 0.34, 0.44)
@export var accent_color := Color(0.36, 0.78, 0.92)
@export var hair_color := Color(0.10, 0.07, 0.05)
@export var body_scale := 1.0
@export var has_hood := false
@export var has_apron := false
@export var has_guard_armor := false
@export var palette_variant := 0

var animation_player: AnimationPlayer
var standing_hip_height := 0.95
var measured_speed := 0.0
var active_animation := ""
var last_position := Vector3.ZERO
var weapon_socket: BoneAttachment3D
var held_weapon: Node3D
var held_item := ""

func _ready() -> void:
    scale = Vector3.ONE * body_scale
    var model := HUMAN.instantiate() as Node3D
    model.name = "HumanModel"
    model.rotation.y = PI
    add_child(model)
    if get_parent().name != "Player":
        for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
            for surface in range(mesh.mesh.get_surface_count()):
                var material := mesh.get_active_material(surface) as StandardMaterial3D
                if material == null:
                    continue
                var cloth := String(material.resource_name).begins_with("Cloth")
                var skin := material.resource_name == "SkinHuman"
                if not cloth and not skin and (material.albedo_texture == null or palette_variant == 0):
                    continue
                var key := "%d:%d:%s:%s" % [material.get_instance_id(), palette_variant % PALETTES.size(), primary_color.to_html(), secondary_color.to_html()]
                if not palette_materials.has(key):
                    var variant := material.duplicate() as StandardMaterial3D
                    if cloth:
                        variant.albedo_color = primary_color if material.resource_name == "ClothTunic" else secondary_color.darkened(0.30)
                    elif skin:
                        variant.albedo_color = [Color(0.62, 0.43, 0.32), Color(0.32, 0.18, 0.12), Color(0.80, 0.61, 0.47)][palette_variant % 3]
                    else:
                        variant.albedo_texture = PALETTES[palette_variant % PALETTES.size()]
                    palette_materials[key] = variant
                mesh.set_surface_override_material(surface, palette_materials[key])
    var players := model.find_children("*", "AnimationPlayer", true, false)
    if not players.is_empty():
        animation_player = players[0] as AnimationPlayer
        for key in animation_player.get_animation_list():
            var animation := animation_player.get_animation(key)
            if String(key) in ["Idle", "Walk", "Run"]:
                animation.loop_mode = Animation.LOOP_LINEAR
        _play("Idle", 1.0)
        animation_player.advance(0.0)
        _prepare_airborne_pose(model)
        _prepare_sitting_pose(model)
    last_position = get_parent_node_3d().global_position
    if get_parent().name == "Player":
        var skeletons := model.find_children("*", "Skeleton3D", true, false)
        if not skeletons.is_empty():
            weapon_socket = BoneAttachment3D.new()
            weapon_socket.name = "WeaponSocket"
            weapon_socket.bone_name = "RightHand"
            skeletons[0].add_child(weapon_socket)
            skeletons[0].connect("skeleton_updated", _update_bow_transform)
            InventorySystem.equipment_changed.connect(_refresh_weapon)
            _refresh_weapon()

func _refresh_weapon() -> void:
    if weapon_socket == null:
        return
    held_item = InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    if held_weapon != null:
        held_weapon.free()
        held_weapon = null
    if not WEAPONS.has(held_item):
        return
    weapon_socket.bone_name = "LeftHand" if held_item == "short_bow" else "RightHand"
    # Keep the asset's normalization transform intact. Compensate the human
    # skeleton's imported scale so a 65 cm axe stays 65 cm in the world.
    held_weapon = Node3D.new()
    held_weapon.name = "EquippedWeapon"
    held_weapon.set_meta("item_id", held_item)
    weapon_socket.add_child(held_weapon)
    held_weapon.position = Vector3(0.0, 0.10, 0.0)
    held_weapon.scale = Vector3.ONE / weapon_socket.global_basis.get_scale()
    var model := (WEAPONS[held_item] as PackedScene).instantiate() as Node3D
    held_weapon.add_child(model)
    if held_item == "short_bow":
        held_weapon.top_level = true
        held_weapon.scale = Vector3.ONE
        _update_bow_transform()
    else:
        model.position.y += 0.18

func _process(delta: float) -> void:
    var body := get_parent() as CharacterBody3D
    if body == null or animation_player == null:
        return
    if body.name == "Player" and held_item != InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON):
        _refresh_weapon()
    last_position = body.global_position
    # Physics can tick several times (or not at all) between rendered frames.
    # Render-frame displacement produced false Run/Idle switches while walking.
    # The last resolved slide velocity also stays zero when pushing into a wall.
    var physical_motion := body.get_real_velocity()
    var speed := Vector2(physical_motion.x, physical_motion.z).length()
    measured_speed = lerpf(measured_speed, speed, minf(1.0, delta * 12.0))
    if String(body.get_meta("activity", "idle")) == "sit":
        _play("Sitting", 1.0)
    elif String(body.get_meta("activity", "idle")) == "sleep":
        _play("Idle", 0.35)
    elif not body.is_on_floor():
        _play("Airborne", 1.0)
    elif body.name == "Player" and float(body.get("cast_elapsed")) > 0.0:
        _play("Punch", 1.0)
    elif body.name == "Player" and float(body.get("attack_elapsed")) > 0.0:
        var stroke := "Axe_Chop" if held_item == "starter_axe" else "Punch"
        _play("Bow_Attack_Shoot" if held_item == "short_bow" else stroke, 1.8 if held_item == "starter_axe" else 1.0)
    elif body.is_in_group("hostile") and float(body.get("attack_elapsed")) > float(body.get("attack_interval")) - 0.55:
        _play("Punch", 1.0)
    elif measured_speed > 5.7:
        _play("Run", clampf(measured_speed / 7.5, 0.75, 1.35))
    elif measured_speed > 0.16:
        _play("Walk", clampf(measured_speed / 3.8, 0.65, 1.5))
    elif String(body.get_meta("activity", "idle")) == "work":
        _play("Working" if animation_player.has_animation("Working") else "PickUp", 0.8)
    else:
        _play("Idle", 1.0)
    _update_bow_transform()

func _update_bow_transform() -> void:
    if held_item != "short_bow" or not is_instance_valid(held_weapon):
        return
    var body := get_parent_node_3d()
    var aim := body.global_basis.orthonormalized()
    var pivot := body.get_node_or_null("CameraPivot") as Node3D
    if pivot != null:
        aim = aim * Basis(Vector3.RIGHT, pivot.rotation.x)
    # The authored bow is tall along Y and its arrow points along -X.
    # Keep that plane aligned with the aim instead of inheriting wrist roll.
    held_weapon.global_transform = Transform3D(aim * Basis(Vector3.UP, -PI * 0.5), weapon_socket.global_transform * Vector3(0, 0.10, 0))

func _play(key: String, rate: float) -> void:
    if animation_player == null or not animation_player.has_animation(key):
        return
    animation_player.speed_scale = rate
    if active_animation != key or (key in ["Working", "PickUp"] and not animation_player.is_playing()):
        active_animation = key
        animation_player.play(key, 0.18)

func begin_axe_stroke() -> void:
    if animation_player != null and animation_player.has_animation("Axe_Chop"):
        active_animation = "Axe_Chop"
        animation_player.speed_scale = 1.8
        animation_player.play("Axe_Chop", 0.06)
        animation_player.seek(0.0, true)

func play_death() -> void:
    _play("Death", 1.0)
    set_process(false)

func _prepare_airborne_pose(model: Node3D) -> void:
    if animation_player.has_animation("Airborne"):
        return
    var skeletons := model.find_children("*", "Skeleton3D", true, false)
    if skeletons.is_empty():
        return
    var skeleton := skeletons[0] as Skeleton3D
    var clip := animation_player.get_animation("Idle").duplicate() as Animation
    clip.length = 0.22
    clip.loop_mode = Animation.LOOP_NONE
    var root := animation_player.get_node(animation_player.root_node)
    var skeleton_path := String(root.get_path_to(skeleton))
    for bone_name: String in ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftArm", "RightArm"]:
        var bone := skeleton.find_bone(bone_name)
        var path := NodePath(skeleton_path + ":" + bone_name)
        var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
        if track >= 0:
            clip.remove_track(track)
        track = clip.add_track(Animation.TYPE_ROTATION_3D)
        clip.track_set_path(track, path)
        var base := skeleton.get_bone_pose_rotation(bone)
        var angle := -0.42 if bone_name.ends_with("UpLeg") else (0.78 if bone_name.ends_with("Leg") else -0.20)
        clip.rotation_track_insert_key(track, 0.0, base)
        clip.rotation_track_insert_key(track, 0.16, base * Quaternion(Vector3.RIGHT, angle))
    animation_player.get_animation_library("").add_animation("Airborne", clip)

func _prepare_sitting_pose(model: Node3D) -> void:
    var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var hip := skeleton.find_bone("Hips")
    if hip >= 0:
        standing_hip_height = to_local(skeleton.global_transform * skeleton.get_bone_global_pose(hip).origin).y
    if animation_player.has_animation("Sitting"):
        return
    var clip := animation_player.get_animation("Idle").duplicate() as Animation
    clip.length = 1.0
    clip.loop_mode = Animation.LOOP_LINEAR
    var root := animation_player.get_node(animation_player.root_node)
    var original := {}
    for side: String in ["Left", "Right"]:
        for suffix: String in ["UpLeg", "Leg", "Foot"]:
            var bone := skeleton.find_bone(side + suffix)
            if bone >= 0:
                original[bone] = skeleton.get_bone_pose_rotation(bone)
        _align_sitting_bone(skeleton, side + "UpLeg", side + "Leg", Vector3.FORWARD)
        _align_sitting_bone(skeleton, side + "Leg", side + "Foot", Vector3.DOWN)
        _align_sitting_bone(skeleton, side + "Foot", side + "ToeBase", Vector3.FORWARD)
    for bone: int in original:
        var path := NodePath(String(root.get_path_to(skeleton)) + ":" + skeleton.get_bone_name(bone))
        var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
        if track >= 0:
            clip.remove_track(track)
        track = clip.add_track(Animation.TYPE_ROTATION_3D)
        clip.track_set_path(track, path)
        clip.rotation_track_insert_key(track, 0, skeleton.get_bone_pose_rotation(bone))
    for bone: int in original:
        skeleton.set_bone_pose_rotation(bone, original[bone])
    skeleton.force_update_all_bone_transforms()
    animation_player.get_animation_library("").add_animation("Sitting", clip)

func _align_sitting_bone(skeleton: Skeleton3D, bone_name: String, child_name: String, direction: Vector3) -> void:
    var bone := skeleton.find_bone(bone_name)
    var child := skeleton.find_bone(child_name)
    if bone < 0 or child < 0:
        return
    skeleton.force_update_all_bone_transforms()
    var pose := skeleton.get_bone_global_pose(bone)
    var current := (skeleton.get_bone_global_pose(child).origin - pose.origin).normalized()
    var desired := (skeleton.global_basis.inverse() * global_basis * direction).normalized()
    # Imported bone axes and roll differ from the actor axes. Solve in skeleton
    # space, then convert the alignment into the actual animated local frame.
    var rotation := skeleton.get_bone_pose_rotation(bone)
    var frame := pose.basis.orthonormalized() * Basis(rotation).inverse()
    var alignment := Basis(Quaternion(current, desired))
    var local_alignment := frame.inverse() * alignment * frame
    skeleton.set_bone_pose_rotation(bone, (local_alignment.get_rotation_quaternion() * rotation).normalized())
    skeleton.force_update_all_bone_transforms()
