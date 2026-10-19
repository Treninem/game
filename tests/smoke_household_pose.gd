extends Node3D

func _ready() -> void:
    get_tree().create_timer(15).timeout.connect(func(): get_tree().quit(1))
    call_deferred("_run")

func _run() -> void:
    var body := CharacterBody3D.new()
    body.name = "PoseFixture"
    body.set_meta("activity", "sit")
    add_child(body)
    var visual := preload("res://scripts/humanoid_visual.gd").new()
    visual.name = "Avatar"
    body.add_child(visual)
    await get_tree().process_frame
    visual.animation_player.play("Sitting")
    visual.animation_player.advance(0.5)
    var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    skeleton.force_update_all_bone_transforms()
    for side in ["Left", "Right"]:
        var hip := visual.to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(side + "UpLeg")).origin)
        var knee := visual.to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(side + "Leg")).origin)
        var foot := visual.to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(side + "Foot")).origin)
        print("SITTING_JOINTS ", side, " hip=", hip, " knee=", knee, " foot=", foot)
        assert(knee.z < hip.z - 0.15 and absf(knee.y - hip.y) < 0.2, "Seated thigh does not extend forward horizontally")
        assert(foot.y < knee.y - 0.2 and absf(foot.z - knee.z) < 0.2, "Seated lower leg does not point down")
    print("HOUSEHOLD_POSE_OK knees=forward shins=down")
    get_tree().quit(0)
