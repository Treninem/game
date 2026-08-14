extends Node

const FLIPBOOK_SCRIPT = preload("res://scripts/vfx_flipbook_3d.gd")
const KENNEY := "res://assets/vfx/third_party/kenney_particle_pack/PNG (Transparent)/"
const ARCANE := "res://assets/vfx/third_party/oga_arcane_magic/01/"

const ELEMENT_TINTS := {
    "arcane": Color(0.58, 0.28, 1.0, 1.0),
    "fire": Color(1.0, 0.34, 0.08, 1.0),
    "frost": Color(0.48, 0.88, 1.0, 1.0),
    "lightning": Color(0.78, 0.90, 1.0, 1.0),
    "poison": Color(0.42, 1.0, 0.30, 1.0),
    "heal": Color(0.48, 1.0, 0.58, 1.0),
    "holy": Color(1.0, 0.88, 0.42, 1.0),
    "dark": Color(0.34, 0.08, 0.52, 1.0),
    "portal": Color(0.55, 0.22, 1.0, 1.0),
    "shield": Color(0.28, 0.68, 1.0, 1.0)
}

func attach_projectile_visual(host: Node3D, element: String, size: float) -> void:
    if host == null:
        return
    var path := _projectile_texture(element)
    if path.is_empty() or not ResourceLoader.exists(path):
        return
    var texture := load(path) as Texture2D
    if texture == null:
        return

    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "CC0ProjectileSprite"
    var quad := QuadMesh.new()
    quad.size = Vector2(size, size)
    mesh_instance.mesh = quad

    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.albedo_texture = texture
    var tint: Color = ELEMENT_TINTS.get(element, Color.WHITE)
    material.albedo_color = tint
    material.emission_enabled = true
    material.emission = Color(tint.r, tint.g, tint.b, 1.0)
    material.emission_energy_multiplier = 2.4
    mesh_instance.material_override = material
    host.add_child(mesh_instance)

func spawn_magic(element: String, position: Vector3, parent: Node = null, strength: float = 1.0) -> Node3D:
    var host := parent if parent != null else get_tree().current_scene
    if host == null:
        return null
    var flipbook = FLIPBOOK_SCRIPT.new()
    host.add_child(flipbook)
    flipbook.global_position = position
    var tint: Color = ELEMENT_TINTS.get(element, Color.WHITE)
    var paths := _effect_frames(element)
    var size := clampf(1.25 * strength, 0.45, 3.2)
    if not flipbook.setup(paths, size, tint, _frame_time(element), 1):
        return null
    return flipbook

func spawn_spell_cast(spell_id: String, position: Vector3, parent: Node = null, strength: float = 1.0) -> Node3D:
    var element := "arcane"
    match spell_id:
        "fireball", "fire_zone": element = "fire"
        "ice_shard", "frost_zone": element = "frost"
        "lightning": element = "lightning"
        "poison_orb": element = "poison"
        "heal": element = "heal"
        "shield": element = "shield"
        "blink": element = "portal"
        "arcane_blast": element = "arcane"
    return spawn_magic(element, position, parent, strength)

func spawn_slash(position: Vector3, parent: Node = null, strength: float = 1.0) -> Node3D:
    var host := parent if parent != null else get_tree().current_scene
    if host == null:
        return null
    var flipbook = FLIPBOOK_SCRIPT.new()
    host.add_child(flipbook)
    flipbook.global_position = position
    var paths: Array[String] = [
        KENNEY + "slash_01.png",
        KENNEY + "slash_02.png",
        KENNEY + "slash_03.png",
        KENNEY + "slash_04.png"
    ]
    if not flipbook.setup(paths, clampf(1.5 * strength, 0.65, 3.0), Color(0.85, 0.93, 1.0, 1.0), 0.045, 1):
        return null
    return flipbook

func spawn_scorch(position: Vector3, parent: Node = null, size: float = 1.4) -> Node3D:
    var host := parent if parent != null else get_tree().current_scene
    if host == null:
        return null
    var root := Node3D.new()
    root.name = "ScorchDecalLite"
    host.add_child(root)
    root.global_position = position + Vector3.UP * 0.025

    var mesh_instance := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(size, size)
    mesh_instance.mesh = quad
    mesh_instance.rotation_degrees.x = -90.0

    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if ResourceLoader.exists(KENNEY + "scorch_02.png"):
        material.albedo_texture = load(KENNEY + "scorch_02.png")
    material.albedo_color = Color(0.22, 0.12, 0.08, 0.72)
    mesh_instance.material_override = material
    root.add_child(mesh_instance)
    var timer := get_tree().create_timer(10.0)
    timer.timeout.connect(func():
        if is_instance_valid(root):
            root.queue_free()
    )
    return root

func _projectile_texture(element: String) -> String:
    match element:
        "fire": return KENNEY + "fire_01.png"
        "frost": return KENNEY + "star_03.png"
        "lightning": return KENNEY + "spark_02.png"
        "poison": return KENNEY + "magic_04.png"
        "heal": return KENNEY + "light_01.png"
        "holy": return KENNEY + "star_05.png"
        "dark": return KENNEY + "magic_05.png"
        "portal": return KENNEY + "twirl_02.png"
        "shield": return KENNEY + "circle_04.png"
        _: return KENNEY + "magic_01.png"

func _effect_frames(element: String) -> Array[String]:
    match element:
        "arcane":
            return [
                ARCANE + "Arcane_Effect_1.png",
                ARCANE + "Arcane_Effect_2.png",
                ARCANE + "Arcane_Effect_3.png",
                ARCANE + "Arcane_Effect_4.png",
                ARCANE + "Arcane_Effect_5.png",
                ARCANE + "Arcane_Effect_6.png",
                ARCANE + "Arcane_Effect_7.png"
            ]
        "fire": return [KENNEY + "flame_01.png", KENNEY + "flame_02.png", KENNEY + "flame_03.png", KENNEY + "flame_04.png"]
        "frost": return [KENNEY + "star_03.png", KENNEY + "star_04.png", KENNEY + "star_06.png", KENNEY + "star_08.png"]
        "lightning": return [KENNEY + "spark_01.png", KENNEY + "spark_02.png", KENNEY + "spark_03.png", KENNEY + "spark_04.png"]
        "poison": return [KENNEY + "magic_03.png", KENNEY + "magic_04.png", KENNEY + "magic_05.png", KENNEY + "twirl_03.png"]
        "heal": return [KENNEY + "light_01.png", KENNEY + "light_02.png", KENNEY + "light_03.png", KENNEY + "star_05.png"]
        "holy": return [KENNEY + "star_05.png", KENNEY + "light_01.png", KENNEY + "star_09.png"]
        "dark": return [KENNEY + "magic_05.png", KENNEY + "twirl_01.png", KENNEY + "magic_03.png"]
        "portal": return [KENNEY + "twirl_01.png", KENNEY + "twirl_02.png", KENNEY + "twirl_03.png", KENNEY + "magic_01.png"]
        "shield": return [KENNEY + "circle_01.png", KENNEY + "circle_02.png", KENNEY + "circle_03.png", KENNEY + "circle_04.png", KENNEY + "circle_05.png"]
        _: return [KENNEY + "magic_01.png", KENNEY + "magic_02.png", KENNEY + "magic_03.png"]

func _frame_time(element: String) -> float:
    match element:
        "lightning": return 0.035
        "fire": return 0.050
        "arcane": return 0.055
        _: return 0.065
