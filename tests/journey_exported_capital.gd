extends SceneTree

# Long opt-in input journey against a frozen PCK. Keep this external harness and
# the input driver out of shipped resources; no test player coordinate writes.
func _initialize() -> void:
    call_deferred("_start_journey")

func _start_journey() -> void:
    if ResourceLoader.exists("res://tests/journey_capital_driver.gd"):
        push_error("Packaged journey unexpectedly sees source-only test resources")
        quit(1)
        return
    var driver_path := OS.get_environment("IMPULS_JOURNEY_DRIVER")
    var driver := load(driver_path) as Script
    if driver == null:
        push_error("External packaged-journey input driver is unavailable")
        quit(1)
        return
    print("PACKAGED_JOURNEY_START args=", OS.get_cmdline_args())
    var pack_path := OS.get_environment("IMPULS_JOURNEY_PACK")
    if not FileAccess.file_exists(pack_path):
        push_error("Packaged journey has no frozen PCK to fingerprint")
        quit(1)
        return
    print("PACKAGED_JOURNEY_PACK path=", pack_path, " sha256=", FileAccess.get_sha256(pack_path))
    root.add_child(driver.new())
    if change_scene_to_file("res://scenes/stage1.tscn") != OK:
        push_error("Packaged journey could not start the shipped world")
        quit(1)
