extends Node3D

const BUILDING_SCRIPT := preload("res://scripts/enterable_building.gd")
const DECORATOR_SCRIPT := preload("res://scripts/settlement_interior_visuals.gd")

var failed := false

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    var clean := message.replace("\r", " ").replace("\n", " ")
    print("::error title=Settlement interior asset smoke::%s" % clean)
    push_error("Settlement interior asset smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    if not ResourceLoader.exists("res://assets/production/interiors/quaternius_furniture/Bed.fbx"):
        _fail(2, "production Quaternius Bed asset is missing")
        return
    if not ResourceLoader.exists("res://assets/production/interiors/quaternius_furniture/Table.fbx"):
        _fail(3, "production Quaternius Table asset is missing")
        return

    var decorator := DECORATOR_SCRIPT.new() as SettlementInteriorVisuals
    decorator.name = "SettlementInteriorVisuals"
    add_child(decorator)

    var building := BUILDING_SCRIPT.new() as EnterableBuilding
    building.name = "FurnitureIntegrationHouse"
    building.configure(Vector3(10.0, 3.4, 9.0), 1, "Дом проверки мебели")
    add_child(building)

    for _i in range(6):
        await get_tree().physics_frame

    if not decorator.decorate_building(building):
        _fail(4, "decorator could not upgrade a valid enterable building")
        return
    if not building.get_meta("real_furniture_visuals", false):
        _fail(5, "building was not marked as upgraded with real furniture")
        return

    var furniture := building.get_node_or_null("InteriorFurniture") as Node3D
    if furniture == null:
        _fail(6, "building lost its physical furniture root")
        return

    var checks := [
        {"proxy":"Bed", "model":"RealBedModel"},
        {"proxy":"Table", "model":"RealTableModel"}
    ]
    for check in checks:
        var proxy_name := String(check.get("proxy", ""))
        var model_name := String(check.get("model", ""))
        var proxy := furniture.get_node_or_null(proxy_name) as StaticBody3D
        if proxy == null:
            _fail(7, "%s physical proxy disappeared after visual upgrade" % proxy_name)
            return
        var collision := proxy.get_node_or_null("Collision") as CollisionShape3D
        if collision == null or collision.shape == null:
            _fail(8, "%s real model replaced or removed load-bearing collision" % proxy_name)
            return
        var model := proxy.get_node_or_null(model_name) as Node3D
        if model == null:
            _fail(9, "%s does not contain its production Quaternius model" % proxy_name)
            return
        if String(model.get_meta("source_pack", "")) != "quaternius_furniture_pack":
            _fail(10, "%s model lacks verified source-pack metadata" % proxy_name)
            return
        if String(model.get_meta("license", "")) != "CC0":
            _fail(11, "%s model lacks CC0 integration metadata" % proxy_name)
            return
        var visible_meshes := 0
        for candidate in model.find_children("*", "MeshInstance3D", true, false):
            var mesh_instance := candidate as MeshInstance3D
            if mesh_instance != null and mesh_instance.mesh != null and mesh_instance.visible:
                visible_meshes += 1
        if visible_meshes < 1:
            _fail(12, "%s production model has no visible imported mesh" % proxy_name)
            return

    var primitive_bed_mesh := furniture.get_node_or_null("Bed/Mesh") as MeshInstance3D
    var primitive_table_mesh := furniture.get_node_or_null("Table/Mesh") as MeshInstance3D
    if primitive_bed_mesh == null or primitive_table_mesh == null:
        _fail(13, "collision proxies no longer retain their fallback geometry nodes")
        return
    if primitive_bed_mesh.visible or primitive_table_mesh.visible:
        _fail(14, "primitive placeholder furniture is still visibly overlapping real models")
        return

    if decorator.real_furniture_model_count() < 2:
        _fail(15, "decorator did not account for both production furniture instances")
        return

    print("SETTLEMENT_INTERIOR_ASSETS_SMOKE_OK production_models=", decorator.real_furniture_model_count(), " physical_props=", building.interior_prop_count)
    get_tree().quit(0)
