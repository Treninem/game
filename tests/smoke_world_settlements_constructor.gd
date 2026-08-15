extends Node

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")

func _ready() -> void:
    print("WORLD_SETTLEMENTS_CTOR_STAGE script metadata")
    print("WORLD_SETTLEMENTS_CTOR base_type=", SETTLEMENTS_SCRIPT.get_instance_base_type(), " can_instantiate=", SETTLEMENTS_SCRIPT.can_instantiate())
    if not SETTLEMENTS_SCRIPT.can_instantiate():
        _fail(71, "world_settlements.gd reports can_instantiate=false")
        return

    print("WORLD_SETTLEMENTS_CTOR_STAGE bare Node3D")
    var bare := Node3D.new()
    if bare == null:
        _fail(72, "Node3D.new() unexpectedly failed")
        return

    print("WORLD_SETTLEMENTS_CTOR_STAGE set_script")
    bare.set_script(SETTLEMENTS_SCRIPT)
    print("WORLD_SETTLEMENTS_CTOR_STAGE set_script returned")
    if bare.get_script() != SETTLEMENTS_SCRIPT:
        bare.free()
        _fail(73, "Node3D.set_script() did not attach world_settlements.gd")
        return
    if not bare.has_method("settlement_specs"):
        bare.free()
        _fail(74, "attached settlement script has no settlement_specs method")
        return

    print("WORLD_SETTLEMENTS_CTOR_STAGE set_script probe passed")
    bare.free()

    print("WORLD_SETTLEMENTS_CTOR_STAGE script.new")
    var direct = SETTLEMENTS_SCRIPT.new()
    print("WORLD_SETTLEMENTS_CTOR_STAGE script.new returned")
    if direct == null or not direct is Node3D:
        _fail(75, "GDScript.new() did not return a Node3D")
        return
    direct.free()

    print("WORLD_SETTLEMENTS_CONSTRUCTOR_SMOKE_OK")
    get_tree().quit(0)

func _fail(code: int, message: String) -> void:
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=World settlements constructor::%s" % clean)
    push_error(message)
    get_tree().quit(code)
