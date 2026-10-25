extends Node3D

const GRIP := preload("res://scripts/weapon_grip_modifier.gd")
const DETAIL_LOD := preload("res://scripts/humanoid_detail_lod.gd")
const BOW_DRAW_RATE := 3.0
const GRIP_POINTS := {"starter_axe": Vector3(-0.09865, -0.18, 0), "stone_knife": Vector3(0.0006, -0.12, 0), "short_bow": Vector3(-0.070708, 0, 0)}

const APPEARANCE := preload("res://scripts/character_appearance.gd")
const GARMENT_NORMAL := preload("res://assets/production/characters/realistic/details/garment_normal.png")
const GARMENT_AO := preload("res://assets/production/characters/realistic/details/garment_ao.png")
const SHOE_ALBEDO := preload("res://assets/production/characters/realistic/details/shoes_albedo.png")
const EYE_SHADER := preload("res://assets/shaders/characters/human_iris.gdshader")
const TUNIC_RESPONSE := preload("res://assets/production/characters/realistic/wardrobe/tunic-metal-roughness.png")
const HAIR_SHADER := preload("res://assets/shaders/characters/hair_strands.gdshader")
const EYE_TEXTURES := [preload("res://assets/production/characters/realistic/eyes/brown_eye.png"), preload("res://assets/production/characters/realistic/eyes/blue_eye.png"), preload("res://assets/production/characters/realistic/eyes/green_eye.png"), preload("res://assets/production/characters/realistic/eyes/grey_eye.png"), preload("res://assets/production/characters/realistic/eyes/lightblue_eye.png")]
const HUMAN_PATHS := {"male": "res://assets/production/characters/realistic_contours/male.glb", "female": "res://assets/production/characters/realistic_contours/female.glb"}
static var human_scenes: Dictionary = {}
const PALETTES := [null, preload("res://assets/production/characters/citizen/citizen_dark.png"), preload("res://assets/production/characters/citizen/citizen_light.png")]
static var palette_materials: Dictionary = {}
const MODEL_CATALOG = preload("res://scripts/weapon_model_catalog.gd")
const WEAPONS = MODEL_CATALOG.SCENES

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
var bow_rig = preload("res://scripts/bow_visual_rig.gd").new()
var bow_cords: Array[MeshInstance3D] = []
var nocked_arrow: Node3D
var last_draw_point := Vector3.ZERO
var draw_point_in_actor := Vector3.ZERO
var has_draw_point := false
var detail_lod: DETAIL_LOD

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
    var actor := (get_parent() as Node3D)
    if actor.has_method("apply_character_dimensions"):
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
    has_draw_point = false
    bow_cords.clear()
    nocked_arrow = null
    active_animation = ""
    current_profile = profile
    # Loading a script or discarding a streamed scene before _ready does not
    # need both dense bodies. Retain each selected scene for subsequent actors.
    if not human_scenes.has(profile.sex):
        human_scenes[profile.sex] = load(HUMAN_PATHS[profile.sex])
    model = (human_scenes[profile.sex] as PackedScene).instantiate() as Node3D
    model.name = "HumanModel"
    model.rotation.y = PI
    add_child(model)
    _style_model()
    var players := model.find_children("*", "AnimationPlayer", true, false)
    if not players.is_empty():
        animation_player = players[0] as AnimationPlayer
        if actor.name == "Player":
            # Short combat windows are counted by the controller's physics
            # ticks. Sampling the player's clips on those same ticks keeps
            # a draw visible before release even when a render is very late.
            # Citizen and preview animation budgets remain render-driven.
            animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
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
        preload("res://scripts/humanoid_work_poses.gd").prepare(self)
    last_position = (get_parent() as Node3D).global_position
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
    else:
        var skeletons := model.find_children("*", "Skeleton3D", true, false)
        if not skeletons.is_empty():
            var clothing_modifier := preload("res://scripts/humanoid_arm_clearance_modifier.gd").new()
            clothing_modifier.name = "ClothingClearance"
            clothing_modifier.set("visual", self)
            skeletons[0].add_child(clothing_modifier)

func _style_model() -> void:
    # Instantiated-but-discarded streamed scenes never reach _ready. Allocate
    # the node only when it can immediately become this visual's owned child.
    if not is_instance_valid(detail_lod):
        detail_lod = DETAIL_LOD.new()
        detail_lod.name = "HumanDetailLOD"
        add_child(detail_lod)
    detail_lod.configure(self)
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
            var key := _material_palette_key(source)
            if not palette_materials.has(key):
                if String(source.resource_name).begins_with("HairHuman") or String(source.resource_name).begins_with("BrowsHuman"):
                    var hair := ShaderMaterial.new()
                    hair.shader = HAIR_SHADER
                    hair.set_shader_parameter("hair_texture", source.albedo_texture)
                    hair.set_shader_parameter("hair_color", APPEARANCE.HAIR[int(current_profile.hair_color)])
                    hair.set_shader_parameter("eyebrows", String(source.resource_name).begins_with("BrowsHuman"))
                    palette_materials[key] = hair
                    mesh.set_surface_override_material(surface, hair)
                    continue
                if String(source.resource_name).begins_with("EyesHuman"):
                    var eyes := ShaderMaterial.new()
                    eyes.shader = EYE_SHADER
                    eyes.set_shader_parameter("eye_texture", EYE_TEXTURES[int(current_profile.eye_color)])
                    eyes.set_shader_parameter("brown_iris", int(current_profile.eye_color) == 0)
                    palette_materials[key] = eyes
                    mesh.set_surface_override_material(surface, eyes)
                    continue
                var material := source.duplicate() as StandardMaterial3D
                var label := String(source.resource_name)
                material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
                if label.begins_with("SkinHuman"):
                    material.albedo_color = APPEARANCE.SKINS[int(current_profile.skin)]
                    material.roughness = 0.64
                    material.metallic_specular = 0.32
                elif label.begins_with("Viking"):
                    var stem := "res://assets/production/characters/realistic/wardrobe/%s-%s" % [current_profile.sex, label.to_lower()]
                    material.normal_enabled = true
                    material.normal_texture = load(stem + "-normal.png")
                    material.normal_scale = 0.65
                    material.ao_enabled = true
                    material.ao_texture = load(stem + "-ao.png")
                    material.ao_light_affect = 0.2
                    material.roughness = 0.9 if label == "VikingTunic" else 0.86
                    if label == "VikingTunic":
                        material.metallic = 1.0
                        material.metallic_texture = TUNIC_RESPONSE
                        material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
                        material.roughness = 1.0
                        material.roughness_texture = TUNIC_RESPONSE
                        material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
                        material.albedo_color = APPEARANCE.CLOTH[int(current_profile.cloth)].lightened(0.65)
                elif label.begins_with("ClothTunic") or label.begins_with("ClothTrousers"):
                    # Reuse the garment's authored UV-aligned folds, not a tiled
                    # replacement. The source diffuse depicts denim, so retain
                    # the fantasy palette while using its neutral AO/normal.
                    # AO belongs to occlusion, not base color: multiplying it
                    # into both makes moving sleeves retain painted black pits.
                    material.albedo_color = APPEARANCE.CLOTH[int(current_profile.cloth)].lightened(0.18) if label.begins_with("ClothTunic") else Color(0.24, 0.21, 0.17)
                    material.albedo_texture = null
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
                palette_materials[key] = material
            mesh.set_surface_override_material(surface, palette_materials[key])

func _material_palette_key(source: StandardMaterial3D) -> String:
    # A morph, hairstyle or unrelated pigment does not create a new material.
    # Keep each actor's selected pigment independent without multiplying the
    # same source by every combination of skin, hair, cloth and eye choices.
    var label := String(source.resource_name)
    var choice := 0
    if label.begins_with("SkinHuman"):
        choice = int(current_profile.skin)
    elif label.begins_with("HairHuman") or label.begins_with("BrowsHuman"):
        choice = int(current_profile.hair_color)
    elif label.begins_with("EyesHuman"):
        choice = int(current_profile.eye_color)
    elif label == "VikingTunic" or label.begins_with("ClothTunic"):
        choice = int(current_profile.cloth)
    return "%d:%d" % [source.get_instance_id(), choice]

func _refresh_weapon() -> void:
    if weapon_socket == null:
        return
    held_item = String(get_parent().get_meta("preview_item", "")) if get_parent().has_meta("preview_animation") else InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON)
    bow_cords.clear()
    has_draw_point = false
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
        var body := (get_parent() as Node3D)
        var aim := body.global_basis.orthonormalized()
        var pivot := body.get_node_or_null("CameraPivot") as Node3D
        if pivot != null:
            aim = aim * Basis(Vector3.RIGHT, pivot.rotation.x)
        frame = aim * Basis(Vector3.UP, -PI * 0.5)
    held_weapon.global_transform = Transform3D(frame, grip.origin)
    if held_item == "short_bow" and bow_cords.size() == 2:
        bow_rig.apply_draw(draw_point, drawing)
        var top: Vector3 = bow_rig.top_world()
        var bottom: Vector3 = bow_rig.bottom_world()
        last_draw_point = draw_point if drawing else held_weapon.to_global(Vector3(0.2055, 0, 0))
        # Several physical ticks can occur before the next rendered rig pose.
        # Keep the last corrected hand point attached to the moving actor,
        # rather than firing from its previous world-space position mid-jump.
        draw_point_in_actor = (get_parent() as Node3D).to_local(last_draw_point)
        has_draw_point = true
        _cord_between(bow_cords[0], top, last_draw_point)
        _cord_between(bow_cords[1], last_draw_point, bottom)
        if is_instance_valid(nocked_arrow):
            nocked_arrow.visible = drawing
            var actor := (get_parent() as Node3D)
            var aim_basis := actor.global_basis.orthonormalized()
            var pivot := actor.get_node_or_null("CameraPivot") as Node3D
            if pivot != null:
                aim_basis = aim_basis * Basis(Vector3.RIGHT, pivot.rotation.x)
            var aim := -aim_basis.z
            nocked_arrow.global_transform = Transform3D(MODEL_CATALOG.flight_basis(aim) * Basis(Vector3.RIGHT, -PI * 0.5), last_draw_point - aim * MODEL_CATALOG.ARROW_NOCK_Y)


func _prepare_bow_cord(weapon_model: Node3D) -> void:
    bow_rig.bind_model(weapon_model)
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
    nocked_arrow.add_child(MODEL_CATALOG.ARROW.instantiate())
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
    # Scale the cylinder along its LOCAL shaft before rotating it. Basis.scaled
    # stretches world axes, so angled strings miss their endpoints by centimetres.
    cord.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, (b - a).normalized())) * Basis.from_scale(Vector3(1, distance, 1)), (a + b) * 0.5)

func arrow_release_point() -> Vector3:
    if not has_draw_point or held_item != "short_bow":
        return Vector3.INF
    return (get_parent() as Node3D).to_global(draw_point_in_actor)

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
    elif body.name == "Player" and float(body.get("cast_elapsed")) > 0.0:
        _play("Cast_Right" if held_item == "short_bow" else "Cast_Left", 1.0)
    elif body.name == "Player" and float(body.get("attack_elapsed")) > 0.0:
        var stroke := "Axe_Chop" if held_item == "starter_axe" else "Punch"
        if held_item == "short_bow":
            _play("Bow_Attack_Draw" if float(body.get("pending_bow_elapsed")) > 0 else "Bow_Attack_Shoot", BOW_DRAW_RATE if float(body.get("pending_bow_elapsed")) > 0 else 1.0)
        else:
            # Complete the jab and recovery within the real attack window.
            # At rate 1 the 1.04 s source punch was cut off after 0.55 s.
            var rate := 1.8 if held_item == "starter_axe" else animation_player.get_animation(stroke).length / maxf(0.1, float(body.get("attack_cooldown")))
            _play(stroke, rate)
    elif not body.is_on_floor():
        _play("Airborne", 1.0)
        animation_player.seek(airborne_sample_time(body), true)
    elif body.is_in_group("hostile") and float(body.get("attack_elapsed")) > float(body.get("attack_interval")) - 0.55:
        _play("Punch", 1.0)
    elif measured_speed > 0.16:
        var gait := gait_for_speed(measured_speed)
        _play(gait, gait_rate(gait, measured_speed))
    elif String(body.get_meta("activity", "idle")) == "work":
        var work_pose := String(body.get_meta("work_pose", "Working"))
        _play(work_pose, 1.0 if work_pose == "WorkStanding" else 0.8)
    else:
        _play("Idle", 1.0)

# Reference stance speeds measured on the actual in-place human clips.
# This matches the stride to motion; it is not full terrain foot locking.
func airborne_sample_time(body: CharacterBody3D) -> float:
    # A render clock cannot tell rising, apex and descent apart. Drive the
    # airborne pose from physical vertical velocity, including a ledge fall.
    var launch: Variant = body.get("jump_velocity")
    var speed := maxf(1.0, float(launch) if launch != null else 5.5)
    return clampf((speed - body.velocity.y) / (2.0 * speed), 0.0, 1.0) * animation_player.get_animation("Airborne").length

func _gait_reference_speed(gait: String) -> float:
    if String(current_profile.get("sex", "male")) == "female":
        return 5.46 if gait == "Run" else 1.77
    return 5.93 if gait == "Run" else 1.82

func gait_for_speed(speed: float) -> String:
    return "Run" if speed > _gait_reference_speed("Walk") * scale.x * 1.5 else "Walk"

func gait_rate(gait: String, speed: float) -> float:
    return clampf(speed / (_gait_reference_speed(gait) * scale.x), 0.05, 2.0)

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
        var gait_phase := -1.0
        if key in ["Walk", "Run"] and previous in ["Walk", "Run"]:
            var previous_clip := animation_player.get_animation(previous)
            if previous_clip.length > 0.0:
                gait_phase = fposmod(animation_player.current_animation_position / previous_clip.length, 1.0)
        active_animation = key
        # A bow releases after 0.22 s. A long locomotion crossfade used most
        # of that preparation time and left the weapon below the aim line.
        animation_player.play(key, 0.06 if key in ["Bow_Attack_Draw", "Bow_Attack_Shoot", "Cast_Left", "Cast_Right", "Punch"] else 0.18)
        # Preserve the foot cycle across sprint changes: restarting at frame
        # zero swaps the support leg and produces a visible kick/crossfade.
        if gait_phase >= 0.0:
            animation_player.seek(gait_phase * animation_player.get_animation(key).length, true)
        elif key in ["Walk", "Run"] and previous in ["Airborne", "Axe_Chop", "Bow_Attack_Draw", "Bow_Attack_Shoot", "Punch", "Cast_Left", "Cast_Right"] and is_instance_valid(grip_modifier):
            animation_player.seek(float(grip_modifier.call("gait_phase")) * animation_player.get_animation(key).length, true)

func begin_axe_stroke() -> void:
    _begin_action_pose("Axe_Chop", 1.8)

func begin_bow_draw() -> void:
    # Reach authored tension at 0.08 s, then hold it through the existing
    # 0.22 s physical preparation. The hold spans a full eight-tick catch-up
    # render, instead of disappearing between two slow frames.
    _begin_action_pose("Bow_Attack_Draw", BOW_DRAW_RATE)

func begin_bow_release() -> void:
    _begin_action_pose("Bow_Attack_Shoot", 1.0)

func begin_punch_stroke(duration: float) -> void:
    if animation_player != null and animation_player.has_animation("Punch"):
        _begin_action_pose("Punch", animation_player.get_animation("Punch").length / maxf(0.1, duration))

func begin_cast_pose(right_hand: bool) -> void:
    _begin_action_pose("Cast_Right" if right_hand else "Cast_Left", 1.0)

func _begin_action_pose(key: String, rate: float) -> void:
    # Accept the transition with the actual input/physics event, before the
    # animation mixer's next update. Starting it from _process was one render
    # late and could spend most of a short draw/release showing the old pose.
    if animation_player != null and animation_player.has_animation(key):
        active_animation = key
        animation_player.speed_scale = rate
        if animation_player.assigned_animation == key:
            # A second accepted stroke may arrive before an Idle render.
            # Reset playback while retaining the visible pose in that case.
            animation_player.stop(true)
        animation_player.play(key, 0.06)
        # play() already starts a new clip at zero. Even seek(..., false)
        # processes a just-started clip at delta zero internally, which can
        # keep the old blend visible until a short physical draw has ended.

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
    for name: String in ["Spine1", "Spine2", "Head"]:
        var bone := skeleton.find_bone(name)
        original[bone] = skeleton.get_bone_pose_rotation(bone)
    # An archer stands side-on. Keeping both shoulders square to the aim line
    # forces a short forearm either through the chest or above the face.
    _rotate_actor_bone(skeleton, "Spine1", Vector3.UP, -0.55)
    _rotate_actor_bone(skeleton, "Spine2", Vector3.UP, -0.55)
    _rotate_actor_bone(skeleton, "Head", Vector3.UP, 1.10)
    _align_sitting_bone(skeleton, "LeftArm", "LeftForeArm", Vector3(0.35, 0.10, -1))
    _align_sitting_bone(skeleton, "LeftForeArm", "LeftHand", Vector3(0.35, 0, -1))
    # Raise outside the right side of the chest before drawing toward the face.
    # Directly blending from the hanging arm can sweep through the torso.
    _align_sitting_bone(skeleton, "RightArm", "RightForeArm", Vector3(0.85, -0.10, -0.4))
    _align_sitting_bone(skeleton, "RightForeArm", "RightHand", Vector3(0, 0.55, -0.85))
    _orient_bow_hand(skeleton, "Left")
    _orient_bow_hand(skeleton, "Right")
    var raised := {}
    for bone: int in original:
        raised[bone] = skeleton.get_bone_pose_rotation(bone)
    var neck := to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Neck")).origin))
    # Anchor at the right cheek, not behind the left-side bow grip. The old
    # offset pulled the right wrist across the chest and its elbow behind it.
    _solve_right_arm(skeleton, Vector3(0.10, neck.y + 0.025, neck.z - 0.10), Vector3(1, -0.25, 0.3))
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
                clip.rotation_track_insert_key(track, 0.10, raised[bone])
                clip.rotation_track_insert_key(track, 0.24, drawn[bone])
                clip.rotation_track_insert_key(track, 0.8, drawn[bone])
            else:
                clip.rotation_track_insert_key(track, 0.0, drawn[bone])
                clip.rotation_track_insert_key(track, 0.12, drawn[bone])
                clip.rotation_track_insert_key(track, 0.28, raised[bone])
                clip.rotation_track_insert_key(track, 0.5, original[bone])
        var library := animation_player.get_animation_library("")
        library.remove_animation(key)
        library.add_animation(key, clip)
    for bone: int in original:
        skeleton.set_bone_pose_rotation(bone, original[bone])
    skeleton.force_update_all_bone_transforms()

func _rotate_actor_bone(skeleton: Skeleton3D, name: String, axis: Vector3, angle: float) -> void:
    var bone := skeleton.find_bone(name)
    var pose := skeleton.get_bone_global_pose(bone)
    var local := skeleton.get_bone_pose_rotation(bone)
    var frame := pose.basis.orthonormalized() * Basis(local).inverse()
    var skeleton_axis := (skeleton.global_basis.inverse() * global_basis * axis).normalized()
    var rotation := frame.inverse() * Basis(skeleton_axis, angle) * frame
    skeleton.set_bone_pose_rotation(bone, (rotation.get_rotation_quaternion() * local).normalized())
    skeleton.force_update_all_bone_transforms()

func _solve_right_arm(skeleton: Skeleton3D, target: Vector3, pole_direction := Vector3(0.65, 0.10, 0.45), minimum_bend_degrees := 0.0) -> void:
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
    var maximum_reach := a + b - 0.001
    if minimum_bend_degrees > 0.0:
        maximum_reach = sqrt(a * a + b * b + 2.0 * a * b * cos(deg_to_rad(minimum_bend_degrees)))
    var distance := clampf(shoulder.distance_to(destination), absf(a - b) + 0.001, maximum_reach)
    if minimum_bend_degrees > 0.0:
        destination = shoulder + direction * distance
    var pole := skeleton.global_basis.inverse() * global_basis * pole_direction
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
    for name: String in ["Spine1", "Spine2"]:
        var bone := skeleton.find_bone(name)
        original[bone] = skeleton.get_bone_pose_rotation(bone)
    var shoulder := to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightArm")).origin))
    var poses: Array[Dictionary] = [original]
    for pose in [
        [shoulder + Vector3(0.08, 0.24, 0.10), Vector3(0, -1, 1).normalized(), Vector3(0, 1, 1).normalized(), 0.22, 0.05],
        [Vector3(0.10, 1.30, -0.65), Vector3(0, -1, -1).normalized(), Vector3(0, 1, -1).normalized(), -0.12, -0.18],
        [Vector3(0.05, 1.0, -0.35), Vector3(0, -1, 0.3).normalized(), Vector3(0, -0.3, -1).normalized(), -0.18, -0.08]
    ]:
        # Reset the torso before each authored key; rotations must not accumulate.
        for name: String in ["Spine1", "Spine2"]:
            skeleton.set_bone_pose_rotation(skeleton.find_bone(name), original[skeleton.find_bone(name)])
        skeleton.force_update_all_bone_transforms()
        for name: String in ["Spine1", "Spine2"]:
            _rotate_actor_bone(skeleton, name, Vector3.UP, float(pose[3]) * 0.5)
            _rotate_actor_bone(skeleton, name, Vector3.RIGHT, float(pose[4]) * 0.5)
        _solve_right_arm(skeleton, pose[0], Vector3(0.35, -0.80, 0.20), 35.0)
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

func constrain_axe_elbow(skeleton: Skeleton3D) -> void:
    var time := animation_player.current_animation_position
    var window := clampf(minf(time / 0.12, (0.99 - time) / 0.24), 0.0, 1.0)
    var minimum := 35.0 * smoothstep(0.0, 1.0, window)
    var shoulder := skeleton.get_bone_global_pose(skeleton.find_bone("RightArm")).origin
    var elbow := skeleton.get_bone_global_pose(skeleton.find_bone("RightForeArm")).origin
    var hand := skeleton.find_bone("RightHand")
    var wrist := skeleton.get_bone_global_pose(hand).origin
    if rad_to_deg((elbow - shoulder).angle_to(wrist - elbow)) + 0.1 >= minimum:
        return
    # Quaternion interpolation can straighten a valid pair of IK key poses.
    # Project only those intermediate poses back into the elbow's bend limit.
    var orientation := skeleton.get_bone_global_pose(hand).basis.orthonormalized()
    _solve_right_arm(skeleton, to_local(skeleton.to_global(wrist)), Vector3(0.35, -0.80, 0.20), minimum)
    var local := skeleton.get_bone_pose_rotation(hand)
    var frame := skeleton.get_bone_global_pose(hand).basis.orthonormalized() * Basis(local).inverse()
    skeleton.set_bone_pose_rotation(hand, (frame.inverse() * orientation).get_rotation_quaternion())
    skeleton.force_update_all_bone_transforms()

func _prepare_airborne_pose(model: Node3D) -> void:
    if animation_player.has_animation("Airborne"):
        return
    var skeletons := model.find_children("*", "Skeleton3D", true, false)
    if skeletons.is_empty():
        return
    var skeleton := skeletons[0] as Skeleton3D
    var clip := animation_player.get_animation("Idle").duplicate() as Animation
    clip.length = 0.8
    clip.loop_mode = Animation.LOOP_NONE
    var root := animation_player.get_node(animation_player.root_node)
    var skeleton_path := String(root.get_path_to(skeleton))
    var original := {}
    for side: String in ["Left", "Right"]:
        for suffix: String in ["UpLeg", "Leg", "Foot", "Arm", "ForeArm"]:
            var bone := skeleton.find_bone(side + suffix)
            if bone >= 0:
                original[bone] = skeleton.get_bone_pose_rotation(bone)
    for name: String in ["Spine1", "Spine2"]:
        var bone := skeleton.find_bone(name)
        original[bone] = skeleton.get_bone_pose_rotation(bone)
    var poses: Array[Dictionary] = []
    # Rising: gather the legs. Apex: tuck. Descent: extend for contact.
    # The clip is sampled by velocity; it does not loop while falling.
    for phase in [[-0.45, 0.7, -0.4, -0.25, -0.08], [-0.9, 1.1, -0.35, -0.45, -0.12], [-0.18, 0.12, -0.2, -0.65, -0.04]]:
        for bone: int in original:
            skeleton.set_bone_pose_rotation(bone, original[bone])
        skeleton.force_update_all_bone_transforms()
        for name: String in ["Spine1", "Spine2"]:
            _rotate_actor_bone(skeleton, name, Vector3.RIGHT, float(phase[4]) * 0.5)
        for side: String in ["Left", "Right"]:
            _align_sitting_bone(skeleton, side + "UpLeg", side + "Leg", Vector3(0, -1, phase[0]))
            _align_sitting_bone(skeleton, side + "Leg", side + "Foot", Vector3(0, -1, phase[1]))
            _align_sitting_bone(skeleton, side + "Foot", side + "ToeBase", Vector3(0, 0, -1))
            _align_sitting_bone(skeleton, side + "Arm", side + "ForeArm", Vector3(-0.3 if side == "Left" else 0.3, -0.75, phase[2]))
            _align_sitting_bone(skeleton, side + "ForeArm", side + "Hand", Vector3(0, phase[3], -1))
        var pose := {}
        for bone: int in original:
            pose[bone] = skeleton.get_bone_pose_rotation(bone)
        poses.append(pose)
    for bone: int in original:
        var path := NodePath(skeleton_path + ":" + skeleton.get_bone_name(bone))
        var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
        if track >= 0:
            clip.remove_track(track)
        track = clip.add_track(Animation.TYPE_ROTATION_3D)
        clip.track_set_path(track, path)
        for phase in range(3):
            clip.rotation_track_insert_key(track, phase * 0.4, poses[phase][bone])
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
