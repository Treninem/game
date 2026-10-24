extends SkeletonModifier3D

# Citizens retain their own authored locomotion, support and furniture poses.
# Upper-body balance precedes the same garment clearance as the player.
var visual: Node3D
var seated_support:RefCounted
var clearance = preload("res://scripts/humanoid_arm_clearance.gd").new()
var motion_response = preload("res://scripts/humanoid_motion_response.gd").new()

func _process_modification_with_delta(_delta: float) -> void:
    if is_instance_valid(visual) and is_instance_valid(visual.get("animation_player")):
        motion_response.apply(visual, get_skeleton(), _delta)
        var actor:=visual.get_parent() as CharacterBody3D
        if actor!=null and String(actor.get_meta("activity","idle"))=="sit":
            if seated_support==null:seated_support=preload("res://scripts/humanoid_grounding.gd").new()
            seated_support.apply(visual,get_skeleton(),_delta)
        clearance.apply(visual, get_skeleton())
