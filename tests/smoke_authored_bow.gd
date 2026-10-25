extends SceneTree

const CATALOG = preload("res://scripts/weapon_model_catalog.gd")
var samples: Array = []
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _require(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)

func _surface_distance(part: MeshInstance3D, target: Vector3) -> float:
    # Independent complete imported vertex scan at the actual applied weight;
    # never read the rig's cached nearest vertex/displacement or tip helpers.
    var best := INF
    var mesh := part.mesh as ArrayMesh
    for surface in range(mesh.get_surface_count()):
        var base: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
        var shapes := mesh.surface_get_blend_shape_arrays(surface)
        for vertex in range(base.size()):
            var point := base[vertex]
            for shape in range(shapes.size()):
                var offset: Vector3 = shapes[shape][Mesh.ARRAY_VERTEX][vertex]
                if mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED:
                    offset -= base[vertex]
                point += offset * part.get_blend_shape_value(shape)
            best = minf(best, part.to_global(point).distance_to(target))
    return best

func _run() -> void:
    create_timer(90).timeout.connect(func():push_error("AUTHORED_BOW timeout");quit(1))
    for image_path: String in ["cedar.png", "leather.png"]:
        var texture := load("res://assets/production/weapons/settler_equipment/" + image_path) as Texture2D
        _require(texture != null and texture.get_image().has_mipmaps(), "Weapon texture lacks mip levels")
    var before: Dictionary = root.get_node("GameState").call("snapshot")
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var rest_model := CATALOG.SCENES.short_bow.instantiate() as Node3D
    world.add_child(rest_model)
    var checked := 0
    for sex: int in [0, 5]:
        for stature: float in [160.0, 180.0, 195.0, 200.0]:
            var actor := CharacterBody3D.new()
            actor.set_meta("preview_animation", "Idle")
            actor.set_meta("preview_item", "short_bow")
            world.add_child(actor)
            actor.position = Vector3(3, 1, -4)
            actor.rotation.y = 0.73
            var pivot := Node3D.new()
            pivot.name = "CameraPivot"
            actor.add_child(pivot)
            var visual = load("res://scripts/humanoid_visual.gd").new()
            visual.appearance_profile = preload("res://scripts/character_appearance.gd").preset(sex)
            visual.appearance_profile.height_cm = stature
            actor.add_child(visual)
            visual.set_process(false)
            var skeleton := visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
            var model := visual.get("held_weapon").get_child(0) as Node3D
            var limb := model.find_child("ContinuousTaperedLimbs", true, false) as MeshInstance3D
            var top := model.find_child("HornNockTop", true, false) as MeshInstance3D
            var bottom := model.find_child("HornNockBottom", true, false) as MeshInstance3D
            var rest_limb := rest_model.find_child("ContinuousTaperedLimbs", true, false) as MeshInstance3D
            _require(limb.mesh == rest_limb.mesh and limb.get_blend_shape_count() == 1, "Imported bow morph buffers replaced")
            _require(not (model.find_child("RestCord", true, false) as MeshInstance3D).visible, "Double rest/drawn cord")
            for pitch: float in [-0.55, 0.0, 0.55]:
                pivot.rotation.x = pitch
                for time: float in [0.0, 0.12, 0.396, 0.6, 0.75]:
                    visual.animation_player.play("Bow_Attack_Draw", 0)
                    visual.animation_player.seek(time, true)
                    visual.animation_player.pause()
                    skeleton.advance(0)
                    await process_frame
                    var cords: Array = visual.bow_cords
                    var upper: Vector3 = (cords[0] as Node3D).to_global(Vector3(0, -.5, 0))
                    var lower: Vector3 = (cords[1] as Node3D).to_global(Vector3(0, .5, 0))
                    var top_gap := _surface_distance(top, upper)
                    var bottom_gap := _surface_distance(bottom, lower)
                    _require(top_gap < .004 and bottom_gap < .004, "Cord detaches from actual morphed horn")
                    var seat := visual.nocked_arrow.find_child("ArrowNockSeat", true, false) as Node3D
                    _require(seat.global_position.distance_to(visual.last_draw_point) < .0001, "Fingers miss arrow string seat")
                    var aim := -(actor.global_basis * Basis(Vector3.RIGHT, pitch)).z
                    var projectile = load("res://scripts/weapon_projectile.gd").new()
                    world.add_child(projectile)
                    projectile.set_physics_process(false)
                    projectile.global_position = visual.arrow_release_point()
                    projectile.setup(actor, aim)
                    var maximum_jump := 0.0
                    for part: MeshInstance3D in visual.nocked_arrow.find_children("*", "MeshInstance3D", true, false):
                        var flight_part := projectile.find_child(String(part.name), true, false) as MeshInstance3D
                        _require(flight_part != null and flight_part.mesh == part.mesh, "Release changes arrow geometry")
                        if flight_part == null:continue
                        var bounds := part.mesh.get_aabb()
                        for corner in range(8):
                            var point := bounds.get_endpoint(corner)
                            maximum_jump = maxf(maximum_jump, part.to_global(point).distance_to(flight_part.to_global(point)))
                    _require(maximum_jump < .0001, "Arrow jumps or rolls at release")
                    _require(is_zero_approx(rest_limb.get_blend_shape_value(0)), "Held bow changes shared inventory/rest instance")
                    samples.append({"body":sex,"height_cm":stature,"pitch":pitch,"time":time,"top_gap_m":top_gap,"bottom_gap_m":bottom_gap,"release_jump_m":maximum_jump,"flex":limb.get_blend_shape_value(0)})
                    projectile.free()
                    checked += 1
            visual.animation_player.play("Idle", 0)
            visual.animation_player.seek(0, true)
            visual.animation_player.pause()
            skeleton.advance(0)
            await process_frame
            _require(is_zero_approx(limb.get_blend_shape_value(0)) and not visual.nocked_arrow.visible, "Cancelled draw retains flex or arrow")
            actor.free()
            await process_frame
    _require(root.get_node("GameState").call("snapshot") == before, "Visual audit mutated game state")
    var report := {"poses":checked,"samples":samples,"failures":failures,"manual_play":false,"actual_imported_morphs":true,"whole_art_accepted":false}
    var file := FileAccess.open("user://authored-bow.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    for message in failures:push_error(message)
    print("AUTHORED_BOW_RESULT poses=", checked, " failures=", failures.size())
    world.free()
    quit(0 if failures.is_empty() else 1)
