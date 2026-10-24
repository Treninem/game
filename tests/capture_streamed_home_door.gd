extends "res://tests/audit_streamed_home_door.gd"

var review_camera: Camera3D
var captures: Dictionary = {}
var capture_busy := false

func _initialize() -> void:
    super._initialize()
    process_frame.connect(_observe_rendered_crossing)

func _run() -> void:
    await super._run()
    # The original household diagnostic owns success/failure. Never convert
    # its failed assertions into a visual success; only add stricter evidence.
    for phase: String in ["entry", "exit"]:
        if not captures.has(phase) or not FileAccess.file_exists("user://door-" + phase + ".png"):
            push_error("Missing actually rendered household doorway phase: " + phase)
            quit(1)
    var output := FileAccess.open("user://home-door-rendered.json", FileAccess.WRITE)
    output.store_string(JSON.stringify({"controlled_diagnostic_lighting": true,
        "actual_production_home_and_people": true, "manual_play": false,
        "full_world_visual_acceptance": false, "captures": captures}, "  "))
    output.close()

func _observe_rendered_crossing() -> void:
    if DisplayServer.get_name() == "headless" or capture_busy or not is_instance_valid(home):
        return
    if not is_instance_valid(review_camera):
        root.size = Vector2i(1280, 720)
        var environment := WorldEnvironment.new()
        var lighting := Environment.new()
        lighting.background_mode = Environment.BG_COLOR
        lighting.background_color = Color(.13, .15, .18)
        lighting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        lighting.ambient_light_color = Color(.75, .79, .85)
        lighting.ambient_light_energy = .7
        environment.environment = lighting
        fixture.add_child(environment)
        var sun := DirectionalLight3D.new()
        sun.rotation_degrees = Vector3(-45, -30, 0)
        sun.light_energy = .9
        fixture.add_child(sun)
        review_camera = Camera3D.new()
        review_camera.fov = 58
        fixture.add_child(review_camera)
        review_camera.global_position = home.global_position + Vector3(4.8, 2.2, 9.5)
        review_camera.look_at(home.global_position + Vector3(0, 1.2, 5.2), Vector3.UP)
        review_camera.make_current()
    var phase := "entry" if root.get_node("GameState").world_minutes >= 21 * 60 else "exit"
    if captures.has(phase):
        return
    var actor := artisan if phase == "entry" else trader
    if not is_instance_valid(actor) or not actor.home_crossing:
        return
    var point := home.to_local(actor.global_position)
    if point.z < 4.7 or point.z > 5.5:
        return
    capture_busy = true
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png("user://door-" + phase + ".png")
    if result != OK:
        push_error("Could not save actual rendered doorway frame")
        quit(1)
        return
    captures[phase] = {"home_local": home.to_local(actor.global_position),
        "activity": actor.activity, "grounded": actor.is_on_floor(),
        "door_open": home.front_door.opened, "file": "door-" + phase + ".png"}
    capture_busy = false
