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
        {"proxy":"Table", "model":"RealTableModel"},
        {"proxy":"Bench", "model":"RealBenchModel"},
        {"proxy":"StorageChest", "model":"RealChestModel"}
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
        var expected_pack := "quaternius_fantasy_props_megakit_standard" if proxy_name in ["Bench", "StorageChest"] else "quaternius_furniture_pack"
        if String(model.get_meta("source_pack", "")) != expected_pack:
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

    var bed_model := furniture.get_node("Bed/RealBedModel") as Node3D
    var bed_bounds := decorator._combined_mesh_bounds(bed_model)
    var bed_size := bed_bounds.size * bed_model.scale
    if bed_size.z < 2.0 or bed_size.z <= bed_size.x or bed_size.x > 1.72 + 0.001:
        _fail(21, "bed length does not follow the gameplay sleeping axis: " + str(bed_size))
        return
    var chest := furniture.get_node("StorageChest") as HouseholdFurniture
    var players := chest.get_node("RealChestModel").find_children("*", "AnimationPlayer", true, false)
    if players.is_empty() or not players[0].has_animation("Chest_Open") or not players[0].has_animation("Chest_Close"):
        _fail(18, "authored chest has no real opening/closing animations")
        return
    for prop_name in ["Bed", "Bench"]:
        var prop := furniture.get_node(prop_name) as StaticBody3D
        if not prop.has_meta("rest_support_y") or not is_finite(float(prop.get_meta("rest_support_y"))):
            _fail(19, "authored rest surface was not measured for " + prop_name)
            return
        var expected_y := prop.global_position.y + float(prop.get_meta("rest_support_y"))
        var query := PhysicsRayQueryParameters3D.create(prop.global_position + Vector3.UP * 1.2, Vector3(prop.global_position.x, expected_y - 0.04, prop.global_position.z), 1)
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if hit.get("collider") != prop or absf(Vector3(hit.get("position", Vector3.ZERO)).y - expected_y) > 0.02:
            _fail(20, "physical support floats above or below the authored surface: " + prop_name)
            return
    print("HOUSEHOLD_MEASURED_SUPPORT bed=", furniture.get_node("Bed").get_meta("rest_support_y"), " bench=", furniture.get_node("Bench").get_meta("rest_support_y"))
    var primitive_bed_mesh := furniture.get_node_or_null("Bed/Mesh") as MeshInstance3D
    var primitive_table_mesh := furniture.get_node_or_null("Table/Mesh") as MeshInstance3D
    if primitive_bed_mesh == null or primitive_table_mesh == null:
        _fail(13, "collision proxies no longer retain their fallback geometry nodes")
        return
    if primitive_bed_mesh.visible or primitive_table_mesh.visible:
        _fail(14, "primitive placeholder furniture is still visibly overlapping real models")
        return

    if decorator.real_furniture_model_count() < 4:
        _fail(15, "decorator did not account for both production furniture instances")
        return

    print("SETTLEMENT_INTERIOR_ASSETS_SMOKE_OK production_models=", decorator.real_furniture_model_count(), " physical_props=", building.interior_prop_count)
    get_tree().quit(0)
