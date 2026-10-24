extends Node

const CONTROLLER = preload("res://scripts/world_environment_controller.gd")

func _ready() -> void:
    var world := Node3D.new()
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    world.add_child(sun)
    var controller = CONTROLLER.new()
    world.add_child(controller)
    controller.set_process(false)
    var failures: Array[String] = []
    for boundary in [360.0, 1080.0, 1440.0]:
        controller.set_time_of_day(boundary - 0.01)
        var previous_basis := sun.basis
        var previous_color := sun.light_color
        var previous_energy := sun.light_energy
        controller.set_time_of_day(boundary + 0.01)
        if previous_basis.x.distance_to(sun.basis.x) > 0.001 or previous_basis.y.distance_to(sun.basis.y) > 0.001:
            failures.append("Solar direction jumps at minute %s" % boundary)
        if (Vector3(previous_color.r, previous_color.g, previous_color.b).distance_to(Vector3(sun.light_color.r, sun.light_color.g, sun.light_color.b))) > 0.001 or absf(previous_energy - sun.light_energy) > 0.001:
            failures.append("Solar illumination jumps at minute %s" % boundary)
    controller.set_time_of_day(720.0)
    var noon_energy := sun.light_energy
    controller.set_time_of_day(0.0)
    if noon_energy < 1.0 or sun.light_energy > 0.001:
        failures.append("Sun must illuminate noon and turn off below the horizon")
    if controller.environment.ambient_light_energy < 0.3:
        failures.append("Night lost readable ambient fill")
    controller.set_time_of_day(-60.0)
    var wrapped := sun.basis
    controller.set_time_of_day(1380.0)
    if wrapped.y.distance_to(sun.basis.y) > 0.001:
        failures.append("Negative time does not wrap to the same solar orbit")
    world.queue_free()
    await get_tree().process_frame
    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        get_tree().quit(1)
        return
    print("WORLD_LIGHTING_SMOKE_OK")
    get_tree().quit()
