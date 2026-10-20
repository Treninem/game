extends Node3D

const GRIP := preload("res://scripts/weapon_grip_modifier.gd")
const GRIP_POINTS := {"starter_axe": Vector3(-0.09865, -0.18, 0), "stone_knife": Vector3(0.0006, -0.12, 0), "short_bow": Vector3(-0.070708, 0, 0)}

const APPEARANCE := preload("res://scripts/character_appearance.gd")
const GARMENT_NORMAL := preload("res://assets/production/characters/realistic/details/garment_normal.png")
const GARMENT_AO := preload("res://assets/production/characters/realistic/details/garment_ao.png")
const SHOE_ALBEDO := preload("res://assets/production/characters/realistic/details/shoes_albedo.png")
const HAIR_SHADER := preload("res://assets/shaders/characters/hair_tint.gdshader")
const EYE_TEXTURES := [preload("res://assets/production/characters/realistic/eyes/brown_eye.png"), preload("res://assets/production/characters/realistic/eyes/blue_eye.png"), preload("res://assets/production/characters/realistic/eyes/green_eye.png"), preload("res://assets/production/characters/realistic/eyes/grey_eye.png"), preload("res://assets/production/characters/realistic/eyes/lightblue_eye.png")]
const HUMANS := {"male": preload("res://assets/production/characters/realistic/male.glb"), "female": preload("res://assets/production/characters/realistic/female.glb")}
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

@export var appearance_profile: Dictionary = {}
var current_profile: Dictionary = {}
var appearance_revision := -1
var model: Node3D
var animation_player: AnimationPlayer
var standing_hip_height := 0.95
var measured_speed := 0.0
var active_animation := ""
var last_position := Vector3.ZERO
var weapon_socket: BoneAttachment3D
var held_weapon: Node3D
var held_item := ""
var grip_modifier: SkeletonModifier3D
var bow_cords: Array[MeshInstance3D] = []
var nocked_arrow: Node3D
var last_draw_point := Vector3.ZERO

func _ready() -> void:
    var profile: Variant = appearance_profile
    if get_parent().name == "Player":
        profile = GameState.get_world_value("player_appearance", {})
    elif profile.is_empty():
        profile = APPEARANCE.preset(palette_variant % 5)
    apply_appearance(profile)

func apply_appearance(value: Variant) -> void:
    var profile := APPEARANCE.normalized(value)
    scale = Vector3.ONE * body_scale * (float(profile.height_cm) / APPEARANCE.DEFAULT_HEIGHT_CM)
    var actor := get_parent_node_3d()
    if actor.name == "Player" and actor.has_method("apply_character_dimensions"):
        actor.call("apply_character_dimensions", float(profile.height_cm))
    if is_instance_valid(model) and profile.sex == current_profile.get("sex", ""):
        current_profile = profile
        _style_model()
        return
    if is_instance_valid(model):
        model.free()
    weapon_socket = null
    held_weapon = null
    held_item = ""
    bow_cords.clear()
    nocked_arrow = null
    active_animation = ""
    current_profile = profile
    model = (HUMANS[profile.sex] as PackedScene).instantiate() as Node3D
    model.name = "HumanModel"
    model.rotation.y = PI
    add_child(model)
    _style_model()
    var players := model.find_children("*", "AnimationPlayer", true, false)
    if not players.is_empty():
        animation_player = players[0] as AnimationPlayer
        # Generated poses belong to this actor. Replacing a shared library
        # while another streamed actor is aiming would interrupt its clip.
        var local_library := animation_player.get_animation_library("").duplicate() as AnimationLibrary
        animation_player.remove_animation_library("")
        animation_player.add_animation_library("", local_library)
        for key in animation_player.get_animation_list():
            var animation := animation_player.get_animation(key)
            if String(key) in ["Idle", "Walk", "Run", "Working"]:
                animation.loop_mode = Animation.LOOP_LINEAR
        _play("Idle", 1.0)
        animation_player.advance(0.0)
        _prepare_airborne_pose(model)
        _prepare_sitting_pose(model)
        _prepare_bow_poses(model)
        _prepare_axe_pose(model)
        _prepare_cast_poses(model)
    last_position = get_parent_node_3d().global_position
    if get_parent().name == "Player" or get_parent().has_meta("preview_animation"):
        var skeletons := model.find_children("*", "Skeleton3D", true, false)
        if not skeletons.is_empty():
            weapon_socket = BoneAttachment3D.new()
            weapon_socket.name = "WeaponSocket"
            weapon_socket.bone_name = "RightHand"
            skeletons[0].add_child(weapon_socket)
            grip_modifier = GRIP.new()
            grip_modifier.name = "WeaponGrip"
            grip_modifier.set("visual", self)
            skeletons[0].add_child(grip_modifier)
            if get_parent().name == "Player" and not InventorySystem.equipment_changed.is_connected(_refresh_weapon):
                InventorySystem.equipment_changed.connect(_refresh_weapon)
            _refresh_weapon()

func _style_model() -> void:
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        if String(mesh.name).begins_with("HairShort"):
            mesh.visible = int(current_profile.hair) == 0
        elif String(mesh.name).begins_with("HairPonytail"):
            mesh.visible = int(current_profile.hair) == 1
        for key: String in APPEARANCE.SHAPES:
            var index := mesh.find_blend_shape_by_name(key)
            if index >= 0:
                mesh.set_blend_shape_value(index, float(current_profile[key]))
        for surface in range(mesh.mesh.get_surface_count()):
            var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
            if source == null:
                continue
            var eye_index := int(current_profile.eye_color) if String(source.resource_name).begins_with("EyesHuman") else 0
            var key := "%d:%d:%d:%d:%d" % [source.get_instance_id(), current_profile.skin, current_profile.hair_color, current_profile.cloth, eye_index]
            if not palette_materials.has(key):
                if String(source.resource_name).begins_with("HairHuman") or String(source.resource_name).begins_with("BrowsHuman"):
                    var hair := ShaderMaterial.new()
                    hair.shader = HAIR_SHADER
                    hair.set_shader_parameter("hair_texture", source.albedo_texture)
                    hair.set_shader_parameter("hair_color", APPEARANCE.HAIR[int(current_profile.hair_color)])
                    palette_materials[key] = hair
                    mesh.set_surface_override_material(surface, hair)
                    continue
                var material := source.duplicate() as StandardMaterial3D
                var label := String(source.resource_name)
                material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
                if label.begins_with("SkinHuman"):
                    material.albedo_color = APPEARANCE.SKINS[int(current_profile.skin)]
                    material.roughness = 0.64
                elif label.begins_with("ClothTunic") or label.begins_with("ClothTrousers"):
                    # Reuse the garment's authored UV-aligned folds, not a tiled
                    # replacement. The source diffuse depicts denim, so retain
                    # the fantasy palette while using its neutral AO/normal.
                    material.albedo_color = APPEARANCE.CLOTH[int(current_profile.cloth)].lightened(0.18) if label.begins_with("ClothTunic") else Color(0.24, 0.21, 0.17)
                    material.albedo_texture = GARMENT_AO
                    material.normal_enabled = true
                    material.normal_texture = GARMENT_NORMAL
                    material.normal_scale = 0.65
                    material.ao_enabled = true
                    material.ao_texture = GARMENT_AO
                    material.ao_light_affect = 0.25
                    material.roughness = 0.9
                elif label.begins_with("LeatherBoots"):
                    material.albedo_texture = SHOE_ALBEDO
                    material.albedo_color = Color(0.72, 0.62, 0.50)
                    material.roughness = 0.73
                elif label.begins_with("EyesHuman"):
                    material.albedo_texture = EYE_TEXTURES[int(current_profile.eye_color)]
                    material.roughness = 0.22
                    material.metallic_specular = 0.65
                palette_materials[key] = material
            mesh.set_surface_override_material(surface, palette_materials[key])

func _refresh_weapon() -> void:
    if weapon_socket == null:
        return
    held_item = String(get_parent().get_meta("preview_item", "")) if get_parent().has_meta("preview_animation") else InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    bow_cords.clear()
    nocked_arrow = null
    if held_weapon != null:
        held_weapon.free()
        held_weapon = null
    if not WEAPONS.has(held_item):
        (weapon_socket.get_parent() as Skeleton3D).advance(0.0)
        return
    weapon_socket.bone_name = "LeftHand" if held_item == "short_bow" else "RightHand"
    # Keep the asset's normalization transform intact. Compensate the human
    # skeleton's imported scale so a 65 cm axe stays 65 cm in the world.
    held_weapon = Node3D.new()
    held_weapon.name = "EquippedWeapon"
    held_weapon.set_meta("item_id", held_item)
    weapon_socket.add_child(held_weapon)
    held_weapon.top_level = true
    held_weapon.scale = Vector3.ONE
    var weapon_model := (WEAPONS[held_item] as PackedScene).instantiate() as Node3D
    held_weapon.add_child(weapon_model)
    weapon_model.position -= GRIP_POINTS[held_item]
    if held_item == "short_bow":
        _prepare_bow_cord(weapon_model)
    var skeleton := weapon_socket.get_parent() as Skeleton3D
    var initial_grip := skeleton.global_transform * GRIP.palm_frame(skeleton, "Left" if held_item == "short_bow" else "Right")
    _place_weapon_at_grip(initial_grip)
    grip_modifier.set("last_grip", initial_grip)
    skeleton.advance(0.0)

func _place_weapon_at_grip(grip: Transform3D, draw_point: Vector3 = Vector3.ZERO, drawing: bool = false) -> void:
    if not is_instance_valid(held_weapon):
        return
    var frame := grip.basis.orthonormalized()
    if held_item == "starter_axe":
        frame = frame * Basis(Vector3.UP, PI)
    if held_item == "short_bow":
        var body := get_parent_node_3d()
        var aim := body.global_basis.orthonormalized()
        var pivot := body.get_node_or_null("CameraPivot") as Node3D
        if pivot != null:
            aim = aim * Basis(Vector3.RIGHT, pivot.rotation.x)
        frame = aim * Basis(Vector3.UP, -PI * 0.5)
    held_weapon.global_transform = Transform3D(frame, grip.origin)
    if held_item == "short_bow" and bow_cords.size() == 2:
        var top := held_weapon.to_global(Vector3(0.2055, 0.5157, 0))
        var bottom := held_weapon.to_global(Vector3(0.2055, -0.5157, 0))
        last_draw_point = draw_point if drawing else held_weapon.to_global(Vector3(0.2055, 0, 0))
        _cord_between(bow_cords[0], top, last_draw_point)
        _cord_between(bow_cords[1], last_draw_point, bottom)
        if is_instance_valid(nocked_arrow):
            nocked_arrow.visible = drawing
            var actor := get_parent_node_3d()
            var aim_basis := actor.global_basis.orthonormalized()
            var pivot := actor.get_node_or_null("CameraPivot") as Node3D
            if pivot != null:
                aim_basis = aim_basis * Basis(Vector3.RIGHT, pivot.rotation.x)
            var aim := -aim_basis.z
            nocked_arrow.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, aim)), last_draw_point + aim * 0.35)


func _prepare_bow_cord(weapon_model: Node3D) -> void:
    # This authored bow has its original straight cord in a thin isolated strip.
    # Replace only that strip; keep the original wood, UVs and material surfaces.
    for instance: MeshInstance3D in weapon_model.find_children("*", "MeshInstance3D", true, false):
        var source := instance.mesh as ArrayMesh
        if source == null:
            continue
        var cleaned := ArrayMesh.new()
        for surface in range(source.get_surface_count()):
            var arrays := source.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            var kept := PackedInt32Array()
            for i in range(0, indices.size(), 3):
                var cord := true
                for j in range(3):
                    var point := vertices[indices[i + j]]
                    cord = cord and point.x > 0.35 and absf(point.y) < 0.006 and absf(point.z) < 0.94
                if not cord:
                    kept.append_array(indices.slice(i, i + 3))
            if kept.is_empty():
                continue
            arrays[Mesh.ARRAY_INDEX] = kept
            var new_surface := cleaned.get_surface_count()
            cleaned.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
            cleaned.surface_set_material(new_surface, source.surface_get_material(surface))
        instance.mesh = cleaned
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.73, 0.68, 0.56)
    material.roughness = 0.85
    for i in range(2):
        var cord := MeshInstance3D.new()
        cord.name = "BowCord%d" % i
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.0013
        cylinder.bottom_radius = 0.0013
        cylinder.height = 1.0
        cylinder.radial_segments = 6
        cord.mesh = cylinder
        cord.material_override = material
        cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        held_weapon.add_child(cord)
        bow_cords.append(cord)
    nocked_arrow = Node3D.new()
    nocked_arrow.add_child(preload("res://assets/production/weapons/woodland/Arrow.glb").instantiate())
    nocked_arrow.name = "NockedArrow"
    held_weapon.add_child(nocked_arrow)
    nocked_arrow.top_level = true
    nocked_arrow.visible = false

func _cord_between(cord: MeshInstance3D, a: Vector3, b: Vector3) -> void:
    var distance := a.distance_to(b)
    if distance < 0.001:
        cord.visible = false
        return
    cord.visible = true
    cord.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, (b - a).normalized())).scaled(Vector3(1, distance, 1)), (a + b) * 0.5)

func arrow_release_point() -> Vector3:
    return last_draw_point

func _process(delta: float) -> void:
    if get_parent().name == "Player" and appearance_revision != GameState.state_revision:
        appearance_revision = GameState.state_revision
        rotation.y = 0.0
        measured_speed = 0.0
        apply_appearance(GameState.get_world_value("player_appearance", {}))
    if get_parent().has_meta("preview_animation"):
        if animation_player != null and not animation_player.is_playing():
            active_animation = ""
        _play(String(get_parent().get_meta("preview_animation")), 1.0)
        return
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
    _update_locomotion_facing(body, physical_motion, delta)
    measured_speed = lerpf(measured_speed, speed, minf(1.0, delta * 12.0))
    if String(body.get_meta("activity", "idle")) == "sit":
        _play("Sitting", 1.0)
    elif String(body.get_meta("activity", "idle")) == "sleep":
        _play("Idle", 0.35)
    elif not body.is_on_floor():
        _play("Airborne", 1.0)
    elif body.name == "Player" and float(body.get("cast_elapsed")) > 0.0:
        _play("Cast_Right" if held_item == "short_bow" else "Cast_Left", 1.0)
    elif body.name == "Player" and float(body.get("attack_elapsed")) > 0.0:
        var stroke := "Axe_Chop" if held_item == "starter_axe" else "Punch"
        if held_item == "short_bow":
            _play("Bow_Attack_Draw" if float(body.get("pending_bow_elapsed")) > 0 else "Bow_Attack_Shoot", 1.8 if float(body.get("pending_bow_elapsed")) > 0 else 1.0)
        else:
            _play(stroke, 1.8 if held_item == "starter_axe" else 1.0)
    elif body.is_in_group("hostile") and float(body.get("attack_elapsed")) > float(body.get("attack_interval")) - 0.55:
        _play("Punch", 1.0)
    elif measured_speed > 5.7:
        _play("Run", clampf(measured_speed / (7.5 * scale.x), 0.75, 1.35))
    elif measured_speed > 0.16:
        _play("Walk", clampf(measured_speed / (3.8 * scale.x), 0.65, 1.5))
    elif String(body.get_meta("activity", "idle")) == "work":
        _play("Working" if animation_player.has_animation("Working") else "PickUp", 0.8)
    else:
        _play("Idle", 1.0)

func _update_locomotion_facing(body: CharacterBody3D, motion: Vector3, delta: float) -> void:
    if body.name != "Player":
        return
    # Camera/input yaw belongs to the physical actor. Turn only the visual so
    # lateral/backward travel does not play a forward gait across the ground.
    # Attacks must face the same direction as their actual ray/projectile.
    if float(body.get("attack_elapsed")) > 0.0 or float(body.get("cast_elapsed")) > 0.0:
        rotation.y = 0.0
        return
    if not body.is_on_floor() or String(body.get_meta("activity", "idle")) in ["sit", "sleep"]:
        return
    motion.y = 0.0
    if motion.length_squared() < 0.0256:
        return
    var local_motion := body.global_basis.inverse() * motion
    var target_yaw := atan2(-local_motion.x, -local_motion.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-14.0 * maxf(delta, 0.0)))

func _play(key: String, rate: float) -> void:
    if animation_player == null or not animation_player.has_animation(key):
        return
    animation_player.speed_scale = rate
    if active_animation != key or (key in ["Working", "PickUp"] and not animation_player.is_playing()):
        var previous := active_animation
        active_animation = key
        # A bow releases after 0.22 s. A long locomotion crossfade used most
        # of that preparation time and left the weapon below the aim line.
        animation_player.play(key, 0.06 if key in ["Bow_Attack_Draw", "Bow_Attack_Shoot", "Cast_Left", "Cast_Right"] else 0.18)
        if key in ["Walk", "Run"] and previous in ["Axe_Chop", "Bow_Attack_Draw", "Bow_Attack_Shoot", "Punch", "Cast_Left", "Cast_Right"] and is_instance_valid(grip_modifier):
            animation_player.seek(fposmod(float(grip_modifier.get("gait_time")), animation_player.get_animation(key).length), true)

func begin_axe_stroke() -> void:
    if animation_player != null and animation_player.has_animation("Axe_Chop"):
        active_animation = "Axe_Chop"
        animation_player.speed_scale = 1.8
        animation_player.play("Axe_Chop", 0.06)
        animation_player.seek(0.0, true)

func play_death() -> void:
    _play("Death", 1.0)
    set_process(false)

func _prepare_cast_poses(human: Node3D) -> void:
    var skeleton := human.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var root := animation_player.get_node(animation_player.root_node)
    for side: String in ["Left", "Right"]:
        var clip := animation_player.get_animation("Idle").duplicate() as Animation
        clip.length = 0.45
        clip.loop_mode = Animation.LOOP_NONE
        var original := {}
        for suffix: String in ["Arm", "ForeArm", "Hand"]:
            var bone := skeleton.find_bone(side + suffix)
            original[bone] = skeleton.get_bone_pose_rotation(bone)
        # Reach with the free arm; the weapon arm keeps its existing grip.
        _align_sitting_bone(skeleton, side + "Arm", side + "ForeArm", Vector3(-0.25 if side == "Left" else 0.25, -0.12, -1))
        _align_sitting_bone(skeleton, side + "ForeArm", side + "Hand", Vector3(0, 0.18, -1))
        for bone: int in original:
            var path := NodePath(String(root.get_path_to(skeleton)) + ":" + skeleton.get_bone_name(bone))
            var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
            if track >= 0:
                clip.remove_track(track)
            track = clip.add_track(Animation.TYPE_ROTATION_3D)
            clip.track_set_path(track, path)
            clip.rotation_track_insert_key(track, 0.0, original[bone])
            clip.rotation_track_insert_key(track, 0.12, skeleton.get_bone_pose_rotation(bone))
            clip.rotation_track_insert_key(track, 0.26, skeleton.get_bone_pose_rotation(bone))
            clip.rotation_track_insert_key(track, 0.45, original[bone])
        for bone: int in original:
            skeleton.set_bone_pose_rotation(bone, original[bone])
        skeleton.force_update_all_bone_transforms()
        # A shortened Idle copy changes interpolation at its old loop boundary.
        # Keep the occupied arm at the same relaxed pose throughout the gesture.
        var other := "Right" if side == "Left" else "Left"
        for suffix: String in ["Arm", "ForeArm", "Hand"]:
            var bone := skeleton.find_bone(other + suffix)
            var path := NodePath(String(root.get_path_to(skeleton)) + ":" + skeleton.get_bone_name(bone))
            var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
            if track >= 0:
                clip.remove_track(track)
            track = clip.add_track(Animation.TYPE_ROTATION_3D)
            clip.track_set_path(track, path)
            var relaxed := skeleton.get_bone_pose_rotation(bone)
            clip.rotation_track_insert_key(track, 0.0, relaxed)
            clip.rotation_track_insert_key(track, 0.45, relaxed)
        animation_player.get_animation_library("").add_animation("Cast_" + side, clip)

func _prepare_bow_poses(human: Node3D) -> void:
    var skeleton := human.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var original := {}
    for side: String in ["Left", "Right"]:
        for suffix: String in ["Arm", "ForeArm", "Hand"]:
            var bone := skeleton.find_bone(side + suffix)
            if bone >= 0:
                original[bone] = skeleton.get_bone_pose_rotation(bone)
    # Aim in actor space: left arm toward the target, right elbow outward.
    # Source bow clips use a different shoulder frame; copying their absolute
    # rotations onto this rig folds the hands behind the actor's back.
    _align_sitting_bone(skeleton, "LeftArm", "LeftForeArm", Vector3(-0.10, 0.10, -1))
    _align_sitting_bone(skeleton, "LeftForeArm", "LeftHand", Vector3(-0.03, 0, -1))
    _align_sitting_bone(skeleton, "RightArm", "RightForeArm", Vector3(0.9, 0.2, 0.15))
    _align_sitting_bone(skeleton, "RightForeArm", "RightHand", Vector3(-0.65, 0.15, -0.75))
    _orient_bow_hand(skeleton, "Left")
    var bow_grip := to_local(skeleton.global_transform * GRIP.palm_frame(skeleton, "Left").origin)
    _solve_right_arm(skeleton, bow_grip + Vector3(0.02, 0.015, 0.62))
    _orient_bow_hand(skeleton, "Right")
    var drawn := {}
    for bone: int in original:
        drawn[bone] = skeleton.get_bone_pose_rotation(bone)
    var root := animation_player.get_node(animation_player.root_node)
    for key: String in ["Bow_Attack_Draw", "Bow_Attack_Shoot"]:
        var clip := animation_player.get_animation("Idle").duplicate() as Animation
        clip.length = 0.8 if key == "Bow_Attack_Draw" else 0.5
        clip.loop_mode = Animation.LOOP_NONE
        for bone: int in original:
            var path := NodePath(String(root.get_path_to(skeleton)) + ":" + skeleton.get_bone_name(bone))
            var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
            if track >= 0:
                clip.remove_track(track)
            track = clip.add_track(Animation.TYPE_ROTATION_3D)
            clip.track_set_path(track, path)
            if key == "Bow_Attack_Draw":
                clip.rotation_track_insert_key(track, 0.0, original[bone])
                clip.rotation_track_insert_key(track, 0.24, drawn[bone])
                clip.rotation_track_insert_key(track, 0.8, drawn[bone])
            else:
                clip.rotation_track_insert_key(track, 0.0, drawn[bone])
                clip.rotation_track_insert_key(track, 0.12, drawn[bone])
                clip.rotation_track_insert_key(track, 0.5, original[bone])
        var library := animation_player.get_animation_library("")
        library.remove_animation(key)
        library.add_animation(key, clip)
    for bone: int in original:
        skeleton.set_bone_pose_rotation(bone, original[bone])
    skeleton.force_update_all_bone_transforms()

func _solve_right_arm(skeleton: Skeleton3D, target: Vector3) -> void:
    var upper := skeleton.find_bone("RightArm")
    var elbow := skeleton.find_bone("RightForeArm")
    var wrist := skeleton.find_bone("RightHand")
    var shoulder := skeleton.get_bone_global_pose(upper).origin
    var joint := skeleton.get_bone_global_pose(elbow).origin
    var hand := skeleton.get_bone_global_pose(wrist).origin
    var destination := skeleton.global_transform.affine_inverse() * to_global(target)
    var a := shoulder.distance_to(joint)
    var b := joint.distance_to(hand)
    var direction := (destination - shoulder).normalized()
    var distance := clampf(shoulder.distance_to(destination), absf(a - b) + 0.001, a + b - 0.001)
    var pole := skeleton.global_basis.inverse() * global_basis * Vector3(0.65, 0.10, 0.45)
    var bend := (pole - direction * pole.dot(direction)).normalized()
    var along := (a * a - b * b + distance * distance) / (2.0 * distance)
    var knee := shoulder + direction * along + bend * sqrt(maxf(0, a * a - along * along))
    var to_actor := global_basis.inverse() * skeleton.global_basis
    _align_sitting_bone(skeleton, "RightArm", "RightForeArm", to_actor * (knee - shoulder))
    joint = skeleton.get_bone_global_pose(elbow).origin
    _align_sitting_bone(skeleton, "RightForeArm", "RightHand", to_actor * (destination - joint))

func _orient_bow_hand(skeleton: Skeleton3D, side: String) -> void:
    _orient_hand_axes(skeleton, side, Vector3.FORWARD, Vector3.UP)

func _orient_hand_axes(skeleton: Skeleton3D, side: String, finger_axis: Vector3, handle_axis: Vector3) -> void:
    var hand := skeleton.find_bone(side + "Hand")
    var wrist := skeleton.get_bone_global_pose(hand).origin
    var index := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandIndex1")).origin
    var pinky := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandPinky1")).origin
    var middle := skeleton.get_bone_global_pose(skeleton.find_bone(side + "HandMiddle1")).origin
    var along := (middle - wrist).normalized()
    var across := (index - pinky).normalized()
    var current := Basis(across, along, across.cross(along)).orthonormalized()
    var actor_frame := skeleton.global_basis.inverse() * global_basis
    var desired := Basis(actor_frame * handle_axis, actor_frame * finger_axis, actor_frame * handle_axis.cross(finger_axis)).orthonormalized()
    var pose := skeleton.get_bone_global_pose(hand)
    var local := skeleton.get_bone_pose_rotation(hand)
    var frame := pose.basis.orthonormalized() * Basis(local).inverse()
    var rotation := desired * current.inverse()
    skeleton.set_bone_pose_rotation(hand, ((frame.inverse() * rotation * frame).get_rotation_quaternion() * local).normalized())
    skeleton.force_update_all_bone_transforms()

func _prepare_axe_pose(human: Node3D) -> void:
    var skeleton := human.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    var original := {}
    for suffix: String in ["Arm", "ForeArm", "Hand"]:
        var bone := skeleton.find_bone("Right" + suffix)
        original[bone] = skeleton.get_bone_pose_rotation(bone)
    var poses: Array[Dictionary] = [original]
    for pose in [
        [Vector3(0.2, 1.97, 0.06), Vector3(0, -1, 1).normalized(), Vector3(0, 1, 1).normalized()],
        [Vector3(0.10, 1.30, -0.65), Vector3(0, -1, -1).normalized(), Vector3(0, 1, -1).normalized()],
        [Vector3(0.05, 1.0, -0.35), Vector3(0, -1, 0.3).normalized(), Vector3(0, -0.3, -1).normalized()]
    ]:
        _solve_right_arm(skeleton, pose[0])
        _orient_hand_axes(skeleton, "Right", pose[1], pose[2])
        var sample := {}
        for bone: int in original:
            sample[bone] = skeleton.get_bone_pose_rotation(bone)
        poses.append(sample)
    poses.append(original)
    var clip := animation_player.get_animation("Idle").duplicate() as Animation
    clip.length = 0.99
    clip.loop_mode = Animation.LOOP_NONE
    var root := animation_player.get_node(animation_player.root_node)
    for bone: int in original:
        var path := NodePath(String(root.get_path_to(skeleton)) + ":" + skeleton.get_bone_name(bone))
        var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
        if track >= 0:
            clip.remove_track(track)
        track = clip.add_track(Animation.TYPE_ROTATION_3D)
        clip.track_set_path(track, path)
        for index in range(poses.size()):
            # Player rate 1.8 places contact at 0.22 s, matching damage.
            clip.rotation_track_insert_key(track, [0.0, 0.22, 0.396, 0.57, 0.99][index], poses[index][bone])
    for bone: int in original:
        skeleton.set_bone_pose_rotation(bone, original[bone])
    skeleton.force_update_all_bone_transforms()
    var library := animation_player.get_animation_library("")
    library.remove_animation("Axe_Chop")
    library.add_animation("Axe_Chop", clip)

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
    var original := {}
    for side: String in ["Left", "Right"]:
        for suffix: String in ["UpLeg", "Leg", "Foot", "Arm", "ForeArm"]:
            var bone := skeleton.find_bone(side + suffix)
            if bone >= 0:
                original[bone] = skeleton.get_bone_pose_rotation(bone)
        _align_sitting_bone(skeleton, side + "UpLeg", side + "Leg", Vector3(0, -1, -0.35))
        _align_sitting_bone(skeleton, side + "Leg", side + "Foot", Vector3(0, -1, 0.2))
        _align_sitting_bone(skeleton, side + "Foot", side + "ToeBase", Vector3(0, -0.15, -1))
        _align_sitting_bone(skeleton, side + "Arm", side + "ForeArm", Vector3(0.12 if side == "Left" else -0.12, -1, 0.1))
        _align_sitting_bone(skeleton, side + "ForeArm", side + "Hand", Vector3(0, -1, -0.2))
    for bone: int in original:
        var path := NodePath(skeleton_path + ":" + skeleton.get_bone_name(bone))
        var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
        if track >= 0:
            clip.remove_track(track)
        track = clip.add_track(Animation.TYPE_ROTATION_3D)
        clip.track_set_path(track, path)
        clip.rotation_track_insert_key(track, 0.0, original[bone])
        clip.rotation_track_insert_key(track, 0.16, skeleton.get_bone_pose_rotation(bone))
    for bone: int in original:
        skeleton.set_bone_pose_rotation(bone, original[bone])
    skeleton.force_update_all_bone_transforms()
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
