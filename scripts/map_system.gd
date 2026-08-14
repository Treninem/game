extends Node

signal explored_changed

const CELL_SIZE := 6.0
const REVEAL_RADIUS := 2
const WORLD_MIN := Vector2(-120.0, -120.0)
const WORLD_MAX := Vector2(120.0, 90.0)
const STATE_KEY := "map_explored"

var player: Node3D
var last_cell := Vector2i(999999, 999999)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(_delta: float) -> void:
    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node3D
        if player == null:
            return
    var cell := world_to_cell(Vector2(player.global_position.x, player.global_position.z))
    if cell != last_cell:
        last_cell = cell
        reveal_around(cell)

func world_to_cell(world_pos: Vector2) -> Vector2i:
    return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))

func cell_to_world_center(cell: Vector2i) -> Vector2:
    return Vector2((float(cell.x) + 0.5) * CELL_SIZE, (float(cell.y) + 0.5) * CELL_SIZE)

func reveal_around(center: Vector2i, radius: int = REVEAL_RADIUS) -> void:
    var explored := _explored_dictionary()
    var changed := false
    for x in range(center.x - radius, center.x + radius + 1):
        for y in range(center.y - radius, center.y + radius + 1):
            var cell := Vector2i(x, y)
            var world := cell_to_world_center(cell)
            if world.x < WORLD_MIN.x or world.x > WORLD_MAX.x or world.y < WORLD_MIN.y or world.y > WORLD_MAX.y:
                continue
            if Vector2(x - center.x, y - center.y).length() > float(radius) + 0.35:
                continue
            var key := _cell_key(cell)
            if not explored.has(key):
                explored[key] = true
                changed = true
    if changed:
        GameState.set_world_value(STATE_KEY, explored)
        explored_changed.emit()

func is_cell_explored(cell: Vector2i) -> bool:
    return _explored_dictionary().has(_cell_key(cell))

func is_world_explored(world_pos: Vector2) -> bool:
    return is_cell_explored(world_to_cell(world_pos))

func explored_cells() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for key in _explored_dictionary().keys():
        var parts := String(key).split(":")
        if parts.size() == 2:
            result.append(Vector2i(int(parts[0]), int(parts[1])))
    return result

func explored_percent() -> float:
    var columns := int(ceil((WORLD_MAX.x - WORLD_MIN.x) / CELL_SIZE))
    var rows := int(ceil((WORLD_MAX.y - WORLD_MIN.y) / CELL_SIZE))
    var total := maxi(1, columns * rows)
    return clampf(float(_explored_dictionary().size()) / float(total) * 100.0, 0.0, 100.0)

func _explored_dictionary() -> Dictionary:
    var saved = GameState.get_world_value(STATE_KEY, {})
    if typeof(saved) == TYPE_DICTIONARY:
        return saved
    return {}

func _cell_key(cell: Vector2i) -> String:
    return "%d:%d" % [cell.x, cell.y]
