extends Node3D

# Physical partitions preserve existing furniture identities and save contents.
# Room routing is also used by residents when leaving home for work.
var home: EnterableBuilding
var dividing_x := -0.85
var split_z := 0.0
var kitchen_x := 1.45
var kitchen_z := 1.65
var room_doors: Array[DoorInteractable] = []
var bedroom_doors: Array[float] = []
var kitchen_door_z := 2.65
var room_lights: Array[OmniLight3D] = []
var light_elapsed := 0.0
var navigators: Dictionary = {}

func build(building: EnterableBuilding) -> void:
    home = building
    var half := home.interior_size * 0.5
    split_z = -half.z + 2.95 + float(home.wall_variant % 3 - 1) * 0.12
    bedroom_doors = [-half.z + 1.45, minf(0.35, split_z + 1.5)]
    kitchen_z = 2.1 if home.footprint.y >= 9.5 else 1.25
    kitchen_door_z = (kitchen_z + half.z) * 0.5
    _wall_with_doors(dividing_x, -half.z, half.z, bedroom_doors, true)
    _panel(Vector3((dividing_x - half.x) * 0.5, home.floor_thickness, split_z), dividing_x + half.x, 0, home.interior_size.y)
    _wall_with_doors(kitchen_x, kitchen_z, half.z, [kitchen_door_z], false)
    _panel(Vector3((kitchen_x + half.x) * 0.5, home.floor_thickness, kitchen_z), half.x - kitchen_x, 0, home.interior_size.y)
    home.room_count = 4 # two private/living rooms, common hall/dining, kitchen
    set_meta("layout_profile", "two_sleeping_rooms" if home.has_node("InteriorFurniture/BedSecond") else "single_bedroom_and_sitting_room")
    for point: Vector3 in [Vector3(-half.x + 0.10, 2.25, bedroom_doors[0]), Vector3(-half.x + 0.10, 2.25, bedroom_doors[1] + 1.0), Vector3(1.7, 2.25, half.z - 0.10)]:
        _lamp(point)

func _lamp(point: Vector3) -> void:
    var model := home._interior_scene("res://assets/production/medieval/capital_square/Lantern_Wall.gltf").instantiate() as Node3D
    add_child(model)
    var bounds := AABB()
    var measured := false
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        var part: AABB = (model.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
        bounds = bounds.merge(part) if measured else part
        measured = true
    var factor := 0.3 / bounds.size.y
    model.rotation.y = PI * 0.5 if point.x < 0 else PI
    model.scale = Vector3.ONE * factor
    model.position = point - model.basis * Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
    var light := OmniLight3D.new()
    light.position = point + Vector3(0.15, 0.1, -0.15)
    light.light_color = Color(1.0, 0.76, 0.48)
    light.light_energy = 0.85
    light.omni_range = 3.8
    light.shadow_enabled = false
    add_child(light)
    room_lights.append(light)

func _process(delta: float) -> void:
    light_elapsed += delta
    if light_elapsed < 0.5:
        return
    light_elapsed = 0.0
    var player := get_tree().get_first_node_in_group("player") as Node3D
    var nearby := player == null or global_position.distance_squared_to(player.global_position) < 400.0
    for light: OmniLight3D in room_lights:
        light.visible = nearby

func _panel(point: Vector3, width: float, yaw: float, height: float) -> void:
    if width < 0.01 or height < 0.01:
        return
    var body := StaticBody3D.new()
    body.position = point
    body.rotation.y = yaw
    add_child(body)
    var model := home._interior_scene("res://assets/production/interiors/architecture/HousePartition.glb").instantiate() as Node3D
    body.add_child(model)
    model.scale = Vector3(width, height / 2.86, 1)
    for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
        for index in range(mesh.mesh.get_surface_count()):
            var material := mesh.get_active_material(index)
            mesh.set_surface_override_material(index, home.timber_material if "Timber" in material.resource_name else home.wall_materials[home.wall_variant % home.wall_materials.size()])
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(width, height, 0.16)
    collision.shape = shape
    collision.position.y = height * 0.5
    body.add_child(collision)

func _wall_with_doors(x: float, low: float, high: float, centers: Array, private_side: bool) -> void:
    var cursor := low
    for center: float in centers:
        var start := center - 0.65
        _panel(Vector3(x, home.floor_thickness, (cursor + start) * 0.5), start - cursor, PI * 0.5, home.interior_size.y)
        _panel(Vector3(x, home.floor_thickness + 2.3, center), 1.3, PI * 0.5, home.interior_size.y - 2.3)
        var door := DoorInteractable.new()
        door.name = "RoomDoor%d" % room_doors.size()
        door.position = Vector3(x, home.floor_thickness, center + (0.65 if private_side else -0.65))
        door.rotation.y = PI * 0.5 if private_side else -PI * 0.5
        door.configure("Кухня" if not private_side else "Комната", 1, true)
        var p := home.global_position
        door.persistence_key = "door:rooms:%d:%d:%d:%s" % [roundi(p.x * 100), roundi(p.y * 100), roundi(p.z * 100), door.name]
        var visual := home.DOOR_SCENE.instantiate() as Node3D
        visual.scale = Vector3(1.3 / 1.116, 2.3 / 2.118, 1)
        door.add_child(visual)
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(1.3, 2.3, 0.12)
        collision.shape = shape
        collision.position = Vector3(0.65, 1.15, 0)
        door.add_child(collision)
        add_child(door)
        room_doors.append(door)
        cursor = center + 0.65
    _panel(Vector3(x, home.floor_thickness, (cursor + high) * 0.5), high - cursor, PI * 0.5, home.interior_size.y)

func waypoint(from: Vector3, destination: Vector3, actor: Node3D) -> Vector3:
    var key := "player" if actor.is_in_group("player") else "resident"
    if not navigators.has(key):
        var navigator = load("res://scripts/house_navigation.gd").new()
        navigator.clearance = 0.48 if key == "player" else 0.38
        navigator.build(home)
        navigators[key] = navigator
    return navigators[key].next_point(from, destination, actor)

func invalidate_navigation() -> void:
    navigators.clear()
