extends SkeletonModifier3D

# Citizens retain their own authored locomotion, support and furniture poses.
# Only the arm chains pass through the same garment clearance as the player.
var visual: Node3D
var clearance = preload("res://scripts/humanoid_arm_clearance.gd").new()

func _process_modification_with_delta(_delta: float) -> void:
    if is_instance_valid(visual) and is_instance_valid(visual.get("animation_player")):
        clearance.apply(visual, get_skeleton())
