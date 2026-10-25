extends SceneTree
func _initialize():call_deferred("run")
func run():
    var path = "res://scenes/stage1.tscn"
    var use_sub_threads := not OS.get_cmdline_user_args().has("no-subthreads")
    assert(ResourceLoader.load_threaded_request(path,"PackedScene",use_sub_threads)==OK)
    while ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_IN_PROGRESS: await process_frame
    var scene = ResourceLoader.load_threaded_get(path)
    var stage = scene.instantiate()
    root.add_child(stage)
    current_scene = stage
    for i in range(60):await physics_frame
    current_scene=null
    stage.queue_free()
    for i in range(10):await process_frame
    print("THREAD_PROBE_OK")
    quit()
