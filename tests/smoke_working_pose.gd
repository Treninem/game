extends Node3D

func _ready() -> void: call_deferred("_run")

func _point(visual: Node3D, skeleton: Skeleton3D, name: String) -> Vector3:
    return visual.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(name)).origin))

func _run() -> void:
    get_tree().create_timer(70).timeout.connect(func():push_error("WORKING_POSE timeout");get_tree().quit(1))
    var samples := 0
    var clips := {}
    for sex: String in ["male", "female"]:
        for build: float in [0, -.5, .5]:
            var actor := CharacterBody3D.new()
            actor.set_meta("preview_animation", "Idle")
            add_child(actor)
            var visual := load("res://scripts/humanoid_visual.gd").new() as Node3D
            visual.set("appearance_profile", {"sex":sex,"Build":build})
            actor.add_child(visual)
            visual.set_process(false)
            var animator: AnimationPlayer=visual.get("animation_player")
            assert(animator.has_animation("Working") and animator.has_animation("WorkStanding"),"Ground work must remain available beside standing work")
            var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
            var clip := animator.get_animation("WorkStanding")
            if clips.has(sex):assert(clips[sex]==clip,"Same rig needlessly rebakes a work clip for every streamed resident")
            clips[sex]=clip
            assert(clip.loop_mode==Animation.LOOP_LINEAR and is_equal_approx(clip.length,2.4))
            for track in range(clip.get_track_count()):
                assert(is_equal_approx(clip.track_get_key_time(track,0),0) and is_equal_approx(clip.track_get_key_time(track,clip.track_get_key_count(track)-1),clip.length),"Work loop contains a cropped source boundary")
                var first: Variant=clip.track_get_key_value(track,0)
                var last: Variant=clip.track_get_key_value(track,clip.track_get_key_count(track)-1)
                if first is Quaternion: assert(first.angle_to(last)<.001,"Work loop snaps at its end")
                elif first is Vector3: assert(first.distance_to(last)<.0001)
            var anchors := {}
            var first_hand := Vector3.ZERO
            var hand_span := 0.0
            var state := {"capture":false,"done":false}
            visual.get("grip_modifier").modification_processed.connect(func():
                if not state.capture:return
                state.capture=false;state.done=true)
            for sample in range(33):
                animator.play("WorkStanding",0)
                animator.seek(clip.length*sample/32.0,true)
                animator.pause()
                state.capture=true;state.done=false
                skeleton.advance(0)
                await get_tree().process_frame
                assert(state.done,"Missing final work pose")
                for name: String in ["Hips","LeftFoot","RightFoot","LeftToeBase","RightToeBase"]:
                    var point := _point(visual,skeleton,name)
                    if sample==0:anchors[name]=point
                    assert(point.distance_to(anchors[name])<.001,"Standing work moves support or kneels")
                var head := skeleton.find_bone("Head")
                var rest_forward := skeleton.global_basis.inverse()*visual.global_basis*Vector3.FORWARD
                var head_delta := skeleton.get_bone_global_pose(head).basis*skeleton.get_bone_global_rest(head).basis.inverse()
                var gaze := (visual.global_basis.inverse()*skeleton.global_basis*head_delta*rest_forward).normalized()
                var target := (_point(visual,skeleton,"LeftHand")+_point(visual,skeleton,"RightHand"))*.5
                var toward := (target-_point(visual,skeleton,"Head")).normalized()
                assert(gaze.angle_to(toward)<deg_to_rad(25),"Worker looks past the bench instead of toward the hand task")
                for side: String in ["Left","Right"]:
                    var shoulder := _point(visual,skeleton,side+"Arm")
                    var elbow := _point(visual,skeleton,side+"ForeArm")
                    var hand := _point(visual,skeleton,side+"Hand")
                    var bend := rad_to_deg((elbow-shoulder).angle_to(hand-elbow))
                    assert(bend>=31 and bend<150,"Working elbow is locked or reversed")
                    assert(hand.y>.90 and hand.y<1.18 and hand.z<-.12 and hand.z>-.5,"Working hand misses the bench-height envelope")
                    var along := (_point(visual,skeleton,side+"HandMiddle1")-hand).normalized()
                    var across := (_point(visual,skeleton,side+"HandIndex1")-_point(visual,skeleton,side+"HandPinky1")).normalized()
                    var palm := across.cross(along).normalized()*(1 if side=="Right" else -1)
                    assert(palm.y<-.65,"Worker presents palms upward instead of working over the surface")
                    if side=="Right":
                        if sample==0:first_hand=hand
                        hand_span=maxf(hand_span,hand.distance_to(first_hand))
                samples+=1
            assert(hand_span>.025,"Work animation is only a stationary pose")
            print("WORKING_POSE_BODY_OK sex=",sex," build=",build," hand_span_m=",hand_span)
            actor.free()
    print("WORKING_POSE_OK final_poses=",samples," bodies=2 builds=3 supported_feet=true open_palms=true gaze=hand_task legacy_ground_work_retained=true")
    get_tree().quit(0)
