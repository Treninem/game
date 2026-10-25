extends SpotLight3D

# The wall/backplate shields the room-facing lantern; one perspective shadow
# covers the occupied space. A short, shadowless warm bounce keeps the fixture
# and its mounting wall lit, without six whole-room cubemap shadow views.
var bounce: OmniLight3D

func _init() -> void:
    rotation_degrees = Vector3(-15, 180, 0)
    spot_angle = 82.0
    spot_angle_attenuation = 0.25
    light_specular = 0.5
    shadow_normal_bias = 1.0

func _ready() -> void:
    bounce = OmniLight3D.new()
    bounce.name = "LanternBounce"
    bounce.omni_range = 1.65
    bounce.light_specular = 0.0
    bounce.shadow_enabled = false
    add_child(bounce)
    _process(0.0)

func _process(_delta: float) -> void:
    if is_instance_valid(bounce):
        bounce.light_color = light_color
        bounce.light_energy = light_energy * 0.8
        bounce.light_cull_mask = light_cull_mask
