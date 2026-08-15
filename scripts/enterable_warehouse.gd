class_name EnterableWarehouse
extends EnterableBuilding

@export var commodity_class := "dry_goods"

func configure_warehouse(size: Vector3, variant: int, label: String, commodity: String) -> void:
    commodity_class = commodity
    configure(size, variant, label)

func _ready() -> void:
    super._ready()
    add_to_group("enterable_warehouse")
    set_meta("commodity_class", commodity_class)
    set_meta("storage_is_physical", true)
    _replace_dwelling_furniture_with_storage()

func _replace_dwelling_furniture_with_storage() -> void:
    var old_furniture := get_node_or_null("InteriorFurniture") as Node3D
    if old_furniture != null:
        remove_child(old_furniture)
        old_furniture.queue_free()

    interior_prop_count = 0
    var storage := Node3D.new()
    storage.name = "WarehouseStorage"
    add_child(storage)

    var inner_half_x := interior_size.x * 0.5
    var inner_half_z := interior_size.z * 0.5
    var floor_y := floor_thickness

    # The center line and the front-door approach remain empty so a person
    # carrying goods can physically enter, turn and reach the back of the room.
    var rack_x := maxf(1.8, inner_half_x - 0.72)
    var rack_depth := minf(3.2, maxf(2.2, interior_size.z * 0.34))
    _add_furniture_box(storage, "StorageRackLeftBack", Vector3(1.10, 2.15, rack_depth), Vector3(-rack_x, floor_y + 1.075, -inner_half_z + rack_depth * 0.55 + 0.3), timber_material)
    _add_furniture_box(storage, "StorageRackRightBack", Vector3(1.10, 2.15, rack_depth), Vector3(rack_x, floor_y + 1.075, -inner_half_z + rack_depth * 0.55 + 0.3), timber_material)
    _add_furniture_box(storage, "StorageRackLeftFront", Vector3(1.10, 2.15, rack_depth), Vector3(-rack_x, floor_y + 1.075, inner_half_z - rack_depth * 0.55 - 0.55), timber_material)
    _add_furniture_box(storage, "StorageRackRightFront", Vector3(1.10, 2.15, rack_depth), Vector3(rack_x, floor_y + 1.075, inner_half_z - rack_depth * 0.55 - 0.55), timber_material)

    var back_z := -inner_half_z + 0.72
    _add_furniture_box(storage, "StorageCrateA", Vector3(1.05, 0.95, 1.05), Vector3(-1.55, floor_y + 0.475, back_z), timber_material)
    _add_furniture_box(storage, "StorageCrateB", Vector3(1.05, 0.95, 1.05), Vector3(1.55, floor_y + 0.475, back_z), timber_material)

    var aisle := Marker3D.new()
    aisle.name = "CentralLoadingAisle"
    aisle.position = Vector3(0.0, floor_y + 0.1, 0.0)
    aisle.set_meta("clear_width", minf(3.0, maxf(2.2, interior_size.x - 3.2)))
    aisle.set_meta("clear_length", maxf(3.0, interior_size.z - 1.8))
    storage.add_child(aisle)
