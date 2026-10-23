extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(240).timeout.connect(func(): push_error("CONTOUR_REVIEW timeout"); quit(1))
    root.size = Vector2i(1280, 720)
    root.scaling_3d_scale = 1.0
    root.msaa_3d = Viewport.MSAA_4X
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35, -25, 0)
    light.light_energy = 0.85
    world.add_child(light)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20, 150, 0)
    fill.light_energy = 0.20
    world.add_child(fill)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(0.19, 0.22, 0.25)
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color.WHITE
    env.environment.ambient_light_energy = 0.32
    world.add_child(env)
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.make_current()
    var rows: Array = []
    for sex: String in ["male", "female"]:
        for family: String in ["integrated"]:
            var actor := CharacterBody3D.new()
            actor.set_meta("preview_animation", "Idle")
            world.add_child(actor)
            var path := "res://scripts/humanoid_visual.gd"
            var visual := load(path).new() as Node3D
            visual.set("appearance_profile", {"sex":sex})
            actor.add_child(visual)
            visual.set_process(false)
            var far := visual.find_children("HumanBodyFar", "MeshInstance3D", true, false)
            if not far.is_empty(): far[0].visible = false
            var animation: AnimationPlayer = visual.get("animation_player")
            var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
            var cpu := preload("res://tests/humanoid_clothed_skin_probe.gd").new()
            cpu.cache(visual, skeleton)
            var state := {"capture":false,"points":PackedVector3Array()}
            var grip: Node = visual.get("grip_modifier")
            grip.modification_processed.connect(func():
                if state.capture:
                    state.capture=false
                    state.points=cpu.snapshot(skeleton))
            var gpu := preload("res://tests/gpu_skinned_vertex_probe.gd").new()
            gpu.setup(root,cpu.body,0)
            await gpu.calibrate()
            for view: String in ["face-front", "face-angle", "face-side", "hand-walk", "bow", "axe"]:
                actor.process_mode=Node.PROCESS_MODE_INHERIT
                var clip := "Walk" if view == "hand-walk" else ("Bow_Attack_Draw" if view == "bow" else ("Axe_Chop" if view == "axe" else "Idle"))
                actor.set_meta("preview_item", "short_bow" if view == "bow" else ("starter_axe" if view == "axe" else ""))
                visual.call("_refresh_weapon")
                animation.play(clip, 0)
                animation.seek(animation.get_animation(clip).length * 0.4, true)
                animation.pause()
                state.capture=view in ["hand-walk","bow","axe"]
                skeleton.advance(0)
                await process_frame
                var gpu_error := -1.0
                var gpu_count := 0
                if view in ["hand-walk","bow","axe"]:
                    assert(not state.capture,"Final skeleton modifier did not publish the pose")
                    actor.process_mode=Node.PROCESS_MODE_DISABLED
                    var measured := await gpu.capture()
                    assert(measured.size()==state.points.size())
                    gpu_error=0.0
                    gpu_count=measured.size()
                    for i in range(measured.size()): gpu_error=maxf(gpu_error,cpu.body.to_global(measured[i]).distance_to(state.points[i]))
                    assert(gpu_error<0.0001,"Eight-weight GPU body differs from its final morphed skeleton")
                    print("CONTOUR_GPU_SAMPLE ",sex," ",clip," vertices=",gpu_count," maximum_error_m=",gpu_error)
                var head := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin) + Vector3.UP * 0.10
                var target := head
                camera.fov = 30
                var offset := Vector3(0, 0, -0.78)
                if view == "face-angle": offset = Vector3(0.49, 0.015, -0.64)
                if view == "face-side": offset = Vector3(0.78, 0, 0)
                if view == "hand-walk":
                    target = skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightHand")).origin) + Vector3.DOWN * 0.07
                    offset = Vector3(0.28, 0.02, -0.45)
                    camera.fov = 35
                if view in ["bow", "axe"]:
                    target = skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin) + Vector3.UP * 0.25
                    offset = Vector3(1.3, 0.35, -2.5)
                    camera.fov = 38
                camera.position = target + offset
                camera.look_at(target)
                await RenderingServer.frame_post_draw
                var file := "user://contour-%s-%s-%s.png" % [family, sex, view]
                assert(root.get_texture().get_image().save_png(file) == OK)
                rows.append({"family":family,"sex":sex,"view":view,"clip":clip,"file":file,"camera":str(camera.transform),"automated":true,"gpu_vertices":gpu_count,"gpu_error_m":gpu_error})
                print("CONTOUR_FRAME ", JSON.stringify(rows.back()))
            if family == "integrated":
                var lod = visual.get("detail_lod")
                for height: float in [160.0, 195.0]:
                    var profile := {"sex":sex,"height_cm":height}
                    for key: String in load("res://scripts/character_appearance.gd").SHAPES: profile[key] = -0.5 if height == 160.0 else 0.5
                    visual.call("apply_appearance", profile)
                    var near := visual.find_child("HumanBody", true, false) as MeshInstance3D
                    var distant := visual.find_child("HumanBodyFar", true, false) as MeshInstance3D
                    var na := near.mesh.surface_get_arrays(0)
                    var fa := distant.mesh.surface_get_arrays(0)
                    assert(na[Mesh.ARRAY_BONES].size() == na[Mesh.ARRAY_VERTEX].size() * 8)
                    assert(fa[Mesh.ARRAY_BONES].size() == fa[Mesh.ARRAY_VERTEX].size() * 4)
                    for key: String in load("res://scripts/character_appearance.gd").SHAPES:
                        assert(is_equal_approx(near.get_blend_shape_value(near.find_blend_shape_by_name(key)), profile[key]))
                        assert(is_equal_approx(distant.get_blend_shape_value(distant.find_blend_shape_by_name(key)), profile[key]))
                    var expected := [true, true, false, false, false, true]
                    var distances := [6.0, 8.0, 9.2, 8.0, 7.2, 6.8]
                    for i in range(distances.size()):
                        camera.position = visual.global_position + Vector3.UP * visual.global_basis.get_scale().y * 0.95 + Vector3.FORWARD * distances[i]
                        lod.update(0.2)
                        assert(near.visible == expected[i] and distant.visible == not expected[i], "LOD hole, overlap or lost hysteresis")
                    var appearance = load("res://scripts/character_appearance.gd")
                    assert(appearance.save_look(profile) == OK)
                    assert(appearance.load_look() == appearance.normalized(profile))
                    print("CONTOUR_LOD_PROFILE_OK ",sex," height=",height," checks=6 weights=8/4 morphs=9 disk_roundtrip=true")
                    actor.process_mode=Node.PROCESS_MODE_INHERIT
                    actor.set_meta("preview_item", "")
                    visual.call("_refresh_weapon")
                    animation.play("Idle",0)
                    animation.seek(0.4,true)
                    animation.pause()
                    state.capture=true
                    skeleton.advance(0)
                    await process_frame
                    assert(not state.capture)
                    actor.process_mode=Node.PROCESS_MODE_DISABLED
                    var measured := await gpu.capture()
                    var error := 0.0
                    assert(measured.size()==state.points.size())
                    for i in range(measured.size()): error=maxf(error,cpu.body.to_global(measured[i]).distance_to(state.points[i]))
                    assert(error<0.0001,"Combined nine-morph extreme differs on the GPU")
                    var head := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin) + Vector3.UP * 0.10 * visual.scale.y
                    camera.position=head+Vector3(0.49,0.015,-0.64)*visual.scale.y
                    camera.fov=35
                    camera.look_at(head)
                    lod.update(0.2)
                    assert(near.visible and not distant.visible)
                    await RenderingServer.frame_post_draw
                    var file := "user://contour-extreme-%s-%d.png" % [sex,int(height)]
                    assert(root.get_texture().get_image().save_png(file)==OK)
                    rows.append({"sex":sex,"view":"combined_extreme","height_cm":height,"morph_value":profile.Build,"file":file,"gpu_vertices":measured.size(),"gpu_error_m":error,"automated":true})
                    print("CONTOUR_GPU_EXTREME ",JSON.stringify(rows.back()))
                actor.process_mode=Node.PROCESS_MODE_INHERIT
                visual.call("play_death")
                for distance: float in [9.3,6.5]:
                    camera.position=visual.global_position+Vector3.UP*visual.scale.y*0.95+Vector3.FORWARD*distance
                    await create_timer(0.16).timeout
                    assert(not visual.is_processing() and animation.assigned_animation == "Death", "Distance selection restarted the dead actor's animation driver")
                    var near := visual.find_child("HumanBody",true,false) as MeshInstance3D
                    var distant := visual.find_child("HumanBodyFar",true,false) as MeshInstance3D
                    assert(near.visible == (distance<7.0) and distant.visible == (distance>9.0), "Stopped animation driver froze corpse distance detail")
                print("CONTOUR_CORPSE_LOD_OK ",sex," animation_driver_stopped=true distance_checks=2")
            gpu.dispose()
            actor.free()
    var creator := load("res://scenes/character_creator.tscn").instantiate() as Control
    root.add_child(creator)
    await process_frame
    for preset: int in [0,5]:
        creator.call("select_preset",preset)
        creator.set("zoom",0.95)
        creator.set("camera_height",1.68)
        creator.call("_camera")
        await process_frame
        await RenderingServer.frame_post_draw
        var file := "user://contour-creator-%d.png" % preset
        assert(root.get_texture().get_image().save_png(file)==OK)
        rows.append({"view":"actual_creator","preset":preset,"file":file,"automated":true})
    creator.free()
    var report := FileAccess.open("user://contour-review.json", FileAccess.WRITE)
    report.store_string(JSON.stringify(rows,"  "))
    print("CONTOUR_REVIEW_OK frames=",rows.size())
    quit(0)
