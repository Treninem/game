extends CanvasLayer

# Lightweight screen-space feedback shared by combat, falls, explosions, storms
# and environment transitions. It deliberately avoids heavy post-processing so
# GL Compatibility remains safe.

var environment_rect: ColorRect
var flash_rect: ColorRect
var shake_strength := 0.0
var shake_time := 0.0
var shake_duration := 0.0
var active_camera: Camera3D
var base_h_offset := 0.0
var base_v_offset := 0.0
var environment_tween: Tween

func _ready() -> void:
    layer = 95

    environment_rect = ColorRect.new()
    environment_rect.name = "EnvironmentTint"
    environment_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    environment_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    environment_rect.color = Color(0.06, 0.30, 0.42, 0.0)
    add_child(environment_rect)

    flash_rect = ColorRect.new()
    flash_rect.name = "ScreenFlash"
    flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
    add_child(flash_rect)

    if not EnvironmentState.underwater_changed.is_connected(_on_underwater_changed):
        EnvironmentState.underwater_changed.connect(_on_underwater_changed)
    _set_underwater_tint(EnvironmentState.is_underwater, false)
    set_process(true)

func _process(delta: float) -> void:
    if shake_time <= 0.0:
        _restore_camera_offset()
        return

    shake_time = maxf(0.0, shake_time - delta)
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    if active_camera != camera:
        _restore_camera_offset()
        active_camera = camera
        base_h_offset = camera.h_offset
        base_v_offset = camera.v_offset

    var fade := clampf(shake_time / maxf(shake_duration, 0.001), 0.0, 1.0)
    var amplitude := shake_strength * fade
    camera.h_offset = base_h_offset + randf_range(-amplitude, amplitude)
    camera.v_offset = base_v_offset + randf_range(-amplitude, amplitude)
    if shake_time <= 0.0:
        _restore_camera_offset()

func flash(color: Color, alpha: float = 0.20, duration: float = 0.18) -> void:
    if flash_rect == null:
        return
    var c := Color(color.r, color.g, color.b, clampf(alpha, 0.0, 0.85))
    flash_rect.color = c
    var tween := create_tween()
    tween.tween_property(flash_rect, "color", Color(color.r, color.g, color.b, 0.0), maxf(duration, 0.04))

func shake(strength: float = 0.04, duration: float = 0.18) -> void:
    shake_strength = maxf(shake_strength, clampf(strength, 0.002, 0.28))
    shake_time = maxf(shake_time, maxf(duration, 0.04))
    shake_duration = maxf(shake_duration, shake_time)

func damage_feedback(amount: float) -> void:
    var severity := clampf(amount / 45.0, 0.15, 1.0)
    flash(Color(0.82, 0.06, 0.035, 1.0), 0.10 + severity * 0.20, 0.16 + severity * 0.08)
    shake(0.018 + severity * 0.055, 0.10 + severity * 0.12)

func landing_feedback(fall_speed: float) -> void:
    if fall_speed < 4.0:
        return
    var severity := clampf((fall_speed - 4.0) / 11.0, 0.12, 1.0)
    shake(0.010 + severity * 0.045, 0.10 + severity * 0.10)

func explosion_feedback(world_position: Vector3, strength: float = 1.0) -> void:
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var distance := camera.global_position.distance_to(world_position)
    var attenuation := clampf(1.0 - distance / maxf(12.0 + strength * 18.0, 1.0), 0.0, 1.0)
    if attenuation <= 0.0:
        return
    var power := clampf(strength * attenuation, 0.1, 2.0)
    shake(0.025 + power * 0.055, 0.13 + power * 0.12)
    flash(Color(1.0, 0.58, 0.20, 1.0), 0.04 + power * 0.08, 0.10)

func lightning_flash(strength: float = 1.0) -> void:
    var s := clampf(strength, 0.15, 1.5)
    flash(Color(0.82, 0.90, 1.0, 1.0), 0.12 + 0.20 * s, 0.12)
    shake(0.006 + 0.012 * s, 0.10)

func _on_underwater_changed(value: bool) -> void:
    _set_underwater_tint(value, true)
    if value:
        flash(Color(0.30, 0.70, 0.90, 1.0), 0.14, 0.20)
    else:
        flash(Color(0.72, 0.90, 1.0, 1.0), 0.10, 0.16)

func _set_underwater_tint(value: bool, animate: bool) -> void:
    if environment_rect == null:
        return
    var target := Color(0.035, 0.28, 0.42, 0.18 if value else 0.0)
    if environment_tween != null and environment_tween.is_valid():
        environment_tween.kill()
    if not animate:
        environment_rect.color = target
        return
    environment_tween = create_tween()
    environment_tween.tween_property(environment_rect, "color", target, 0.28 if value else 0.20)

func _restore_camera_offset() -> void:
    if active_camera != null and is_instance_valid(active_camera):
        active_camera.h_offset = base_h_offset
        active_camera.v_offset = base_v_offset
    active_camera = null
    base_h_offset = 0.0
    base_v_offset = 0.0
    shake_strength = 0.0
    shake_duration = 0.0
