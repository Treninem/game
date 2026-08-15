class_name EnterableWarehouse
extends EnterableBuilding

@export var commodity_class := "dry_goods"

var physical_storage_fixture_count := 0
var physical_storage_volume_m3 := 0.0

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
    physical_storage_fixture_count = 0
    physical_storage_volume_m3 = 0.0

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
    var rack_size := Vector3(1.10, 2.15, rack_depth)
    _add_storage_fixture(storage, "StorageRackLeftBack", rack_size, Vector3(-rack_x, floor_y + 1.075, -inner_half_z + rack_depth * 0.55 + 0.3), 0.62)
    _add_storage_fixture(storage, "StorageRackRightBack", rack_size, Vector3(rack_x, floor_y + 1.075, -inner_half_z + rack_depth * 0.55 + 0.3), 0.62)
    _add_storage_fixture(storage, "StorageRackLeftFront", rack_size, Vector3(-rack_x, floor_y + 1.075, inner_half_z - rack_depth * 0.55 - 0.55), 0.62)
    _add_storage_fixture(storage, "StorageRackRightFront", rack_size, Vector3(rack_x, floor_y + 1.075, inner_half_z - rack_depth * 0.55 - 0.55), 0.62)

    var back_z := -inner_half_z + 0.72
    var crate_size := Vector3(1.05, 0.95, 1.05)
    _add_storage_fixture(storage, "StorageCrateA", crate_size, Vector3(-1.55, floor_y + 0.475, back_z), 0.80)
    _add_storage_fixture(storage, "StorageCrateB", crate_size, Vector3(1.55, floor_y + 0.475, back_z), 0.80)

    var aisle := Marker3D.new()
    aisle.name = "CentralLoadingAisle"
    aisle.position = Vector3(0.0, floor_y + 0.1, 0.0)
    aisle.set_meta("clear_width", minf(3.0, maxf(2.2, interior_size.x - 3.2)))
    aisle.set_meta("clear_length", maxf(3.0, interior_size.z - 1.8))
    storage.add_child(aisle)

    # Capacity is an outcome of the physical interior, not a design-time magic
    # number. Future inventory/logistics systems can consume this metadata while
    # remaining bounded by the fixtures that actually exist in the room.
    storage.set_meta("physical_fixture_count", physical_storage_fixture_count)
    storage.set_meta("usable_storage_volume_m3", physical_storage_volume_m3)
    set_meta("physical_storage_fixture_count", physical_storage_fixture_count)
    set_meta("usable_storage_volume_m3", physical_storage_volume_m3)

func _add_storage_fixture(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, usable_fraction: float) -> StaticBody3D:
    var fixture := _add_furniture_box(parent, node_name, size, pos, timber_material)
    var gross_volume := size.x * size.y * size.z
    var usable_volume := gross_volume * clampf(usable_fraction, 0.0, 1.0)
    fixture.set_meta("gross_volume_m3", gross_volume)
    fixture.set_meta("usable_storage_volume_m3", usable_volume)
    fixture.set_meta("physical_storage_fixture", true)
    physical_storage_fixture_count += 1
    physical_storage_volume_m3 += usable_volume
    return fixture

func storage_fixture_count() -> int:
    return physical_storage_fixture_count

func storage_volume_m3() -> float:
    return physical_storage_volume_m3
