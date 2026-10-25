extends "res://tests/journey_capital_driver.gd"

# Opt-in ordinary movement from the real forest spawn, not a relocated fixture.
func _ready() -> void:
    points = [Vector2(10,385),Vector2(90,365),Vector2(250,294),Vector2(650,120),Vector2(1553,-368)]
    super._ready()

func _finish(success: bool, reason: String) -> void:
    started = false
    Input.action_release("move_forward")
    Input.action_release("sprint")
    if success:
        reason = "Village approach reached on foot"
        success = SaveManager.save_game(player,4)
    var proof := {"success":success,"reason":reason,"distance_m":distance,
        "simulated_seconds":elapsed,"position_assignments":0,"save_slot":4,
        "engine_time_scale":Engine.time_scale,"physics_step":1.0/60.0}
    var file := FileAccess.open("user://village_journey.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(proof,"  "))
    if success: print("VILLAGE_JOURNEY_OK ",JSON.stringify(proof))
    else: push_error("Village journey failed: "+reason)
    get_tree().quit(0 if success else 1)
