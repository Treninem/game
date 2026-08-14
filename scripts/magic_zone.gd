extends Node3D

var zone_id: String = ""
var element: String = "arcane"
var radius := 3.0
var duration := 5.0
var tick_interval := 0.75
var damage_per_tick := 0.0
var status_name: String = ""
var status_duration := 0.0
var caster: Node3D
var elapsed := 0.0
var tick_elapsed := 0.0
var pulse_elapsed := 0.0
var sprite_pulse_elapsed := 0.0

func setup(data: Dictionary, source: Node3D) -> void:
    zone_id = String(data.get("id", "magic_zone"))
    element = String(data.get("element", "arcane"))
    radius = float(data.get("radius", 3.0))
    duration = float(data.get("duration", 5.0))
    tick_interval = float(data.get("tick_interval", 0.75))
    damage_per_tick = float(data.get("damage_per_tick", 0.0))
    status_name = String(data.get("status", ""))
    status_duration = float(data.get("status_duration", 0.0))
    caster = source
    _build_visual(data)
    VFXLibrary.spawn_magic(element, global_position, get_tree().current_scene, 1.25)
    ThirdPartyVFX.spawn_magic(element, global_position + Vector3.UP * 0.2, get_tree().current_scene, 1.15)
    if element == "fire":
        ThirdPartyVFX.spawn_scorch(global_position, get_tree().current_scene, radius * 1.25)

func _physics_process(delta: float) -> void:
    elapsed += delta
    tick_elapsed += delta
    pulse_elapsed += delta
    sprite_pulse_elapsed += delta
    if elapsed >= duration:
        VFXLibrary.spawn_magic(element, global_position, get_tree().current_scene, 0.60)
        ThirdPartyVFX.spawn_magic(element, global_position + Vector3.UP * 0.2, get_tree().current_scene, 0.65)
        queue_free()
        return

    if pulse_elapsed >= 1.0:
        pulse_elapsed = 0.0
        VFXLibrary.spawn_magic(element, global_position, get_tree().current_scene, 0.40)

    if sprite_pulse_elapsed >= 2.0:
        sprite_pulse_elapsed = 0.0
        ThirdPartyVFX.spawn_magic(element, global_position + Vector3.UP * 0.15, get_tree().current_scene, 0.48)

    if tick_elapsed < tick_interval:
        return
    tick_elapsed = 0.0
    for hostile in get_tree().get_nodes_in_group("hostile"):
        if not is_instance_valid(hostile) or not (hostile is Node3D):
            continue
        var body := hostile as Node3D
        if body.global_position.distance_to(global_position) > radius:
            continue
        if damage_per_tick > 0.0 and body.has_method("take_damage"):
            body.take_damage(damage_per_tick, caster, true)
        if not status_name.is_empty() and body.has_method("apply_status"):
            body.apply_status(status_name, status_duration, caster)

func _build_visual(data: Dictionary) -> void:
    var color: Color = data.get("color", Color(0.45, 0.18, 1.0, 0.45))
    color.a = minf(color.a, 0.48)

    var disk := MeshInstance3D.new()
    disk.name = "ZoneDisk"
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = 0.035
    cylinder.radial_segments = 48
    disk.mesh = cylinder
    disk.position.y = 0.025

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = Color(color.r, color.g, color.b, 1.0)
    material.emission_energy_multiplier = 1.6
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    disk.material_override = material
    add_child(disk)
