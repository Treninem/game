extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    create_timer(60).timeout.connect(func(): push_error("HUMAN_DETAIL_LIFETIME timeout"); quit(1))
    var human = load("res://scripts/humanoid_visual.gd")
    await process_frame
    await process_frame
    var before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
    # Prove this debug monitor is live; a release build returning zero must
    # not turn the lifecycle regression into a false pass.
    var canary := Node.new()
    await create_timer(1.1).timeout
    var controlled := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
    canary.free()
    await create_timer(1.1).timeout
    assert(controlled==before+1 and int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))==before,"Orphan monitor unavailable or changing unexpectedly")
    # Streamed scenes/editor previews may instantiate an actor and discard it
    # before _ready. Every node allocated by that actor still needs an owner.
    for i in range(32):
        var visual = human.new()
        visual.free()
    await create_timer(1.1).timeout
    var after := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
    print("HUMAN_DETAIL_LIFETIME before=",before," after=",after," detached_actor_cycles=32 canary_verified=true")
    if after!=before:
        push_error("Detached humans leak nodes before entering the scene tree")
        quit(1)
        return
    print("HUMAN_DETAIL_LIFETIME_OK")
    quit(0)
