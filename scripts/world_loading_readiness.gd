extends RefCounted

const VISUAL_RADIUS: int = 2
const PHYSICS_RADIUS: int = 1
const SETTLEMENT_LOAD_RADIUS: float = 980.0

const CRITICAL_CHECKS := [
    "save", "spawn", "region", "terrain", "collisions", "gameplay",
    "environment", "camera", "ground"
]

static func snapshot(world: Node, player: CharacterBody3D) -> Dictionary:
    if world == null or player == null or not player.is_inside_tree():
        return _empty("Ожидание игрового мира")

    var pos2 := Vector2(player.global_position.x, player.global_position.z)
    var stream := _stream_state(world.get_node_or_null("World/WorldStreamer"), pos2)
    var settlement := _settlement_state(
        world.get_node_or_null("World/Settlements"),
        world.get_node_or_null("World/SettlementInteriorVisuals"),
        pos2
    )
    var start_region := world.get_node_or_null("World/StartRegion")
    var bootstrap := world.get_node_or_null("Bootstrap")
    var city := world.get_node_or_null("World/CityDistrict")

    var city_ready := false
    if city != null:
        var cells: Variant = city.get("loaded_cells")
        city_ready = cells is Dictionary and not (cells as Dictionary).is_empty()

    var bootstrap_ready: bool = _safe_bool_property(world, "startup_state_ready", false)
    var spawn_ready: bool = WorldData != null and WorldData.inside_world(pos2)
    var region_ready: bool = float(stream.get("visual_ratio", 0.0)) >= 0.999
    var terrain_ready: bool = bool(stream.get("center_terrain", false))
    var collision_ready: bool = float(stream.get("collision_ratio", 0.0)) >= 0.999
    var nature_ready: bool = _safe_int_property(start_region, "real_nature_detail_count", 0) > 0
    var water_ready: bool = _safe_int_property(start_region, "river_segment_count", 0) > 0 and WorldWater != null
    var roads_ready: bool = WorldRoads != null and region_ready
    var items_ready: bool = bool(stream.get("items_ready", false)) or city_ready
    var environment_ready: bool = world.get_node_or_null("World/Sun") is DirectionalLight3D and world.get_node_or_null("World/WorldEnvironmentController") != null and EnvironmentState != null and WeatherVFX != null
    var gameplay_ready: bool = GameState != null and SaveManager != null and InventorySystem != null and DialogueManager != null
    var camera := player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        camera = world.get_node_or_null("World/Player/Camera3D") as Camera3D
    var camera_ready: bool = camera != null and camera.current
    var ground_ready: bool = terrain_ready and collision_ready and _ground_below(player)

    var checks := {
        "save": SaveManager != null and bootstrap != null and bootstrap_ready,
        "spawn": spawn_ready,
        "region": region_ready,
        "terrain": terrain_ready,
        "collisions": collision_ready,
        "water": water_ready,
        "roads": roads_ready,
        "nature": nature_ready,
        "settlements": bool(settlement.get("settlements_ready", false)),
        "buildings": bool(settlement.get("buildings_ready", false)),
        "interiors": bool(settlement.get("interiors_ready", false)),
        "npcs": bool(settlement.get("npcs_ready", false)),
        "items": items_ready,
        "gameplay": gameplay_ready,
        "environment": environment_ready,
        "camera": camera_ready,
        "ground": ground_ready
    }

    var weights := {
        "save":0.06, "spawn":0.08, "region":0.08, "terrain":0.10, "collisions":0.10,
        "water":0.05, "roads":0.04, "nature":0.05, "settlements":0.05, "buildings":0.05,
        "interiors":0.03, "npcs":0.04, "items":0.03, "gameplay":0.05, "environment":0.04,
        "camera":0.03, "ground":0.04
    }
    var ratio := 0.0
    for key: Variant in checks:
        if bool(checks[key]):
            ratio += float(weights.get(key, 0.0))

    var all_ready := true
    for key: String in CRITICAL_CHECKS:
        if not bool(checks.get(key, false)):
            all_ready = false
            break

    var stage: String = _stage_for(checks)
    var detail: String = _detail_for(stage, stream, settlement)
    return {
        "ratio":clampf(ratio, 0.0, 1.0),
        "all_ready":all_ready,
        "stage":stage,
        "detail":detail,
        "checks":checks
    }

static func _safe_bool_property(node: Object, property: StringName, fallback: bool = false) -> bool:
    if node == null or not is_instance_valid(node):
        return fallback
    var value: Variant = node.get(property)
    if value is bool:
        return value
    if value is int or value is float:
        return float(value) != 0.0
    if value is String:
        var text := String(value).strip_edges().to_lower()
        if text == "true" or text == "1":
            return true
        if text == "false" or text == "0":
            return false
    return fallback

static func _safe_int_property(node: Object, property: StringName, fallback: int = 0) -> int:
    if node == null or not is_instance_valid(node):
        return fallback
    var value: Variant = node.get(property)
    return _safe_int_variant(value, fallback)

static func _safe_int_variant(value: Variant, fallback: int = 0) -> int:
    if value == null:
        return fallback
    if value is bool:
        return 1 if value else 0
    if value is int:
        return value
    if value is float:
        return int(value)
    if value is String:
        var text := String(value).strip_edges()
        if text.is_valid_int():
            return text.to_int()
        if text.is_valid_float():
            return int(text.to_float())
    return fallback

static func _stream_state(streamer: Node, pos: Vector2) -> Dictionary:
    var empty := {"visual_ratio":0.0,"collision_ratio":0.0,"center_terrain":false,"items_ready":false,"visual_loaded":0,"visual_required":0,"collision_loaded":0,"collision_required":0}
    if streamer == null or not is_instance_valid(streamer):
        return empty

    var loaded_variant: Variant = streamer.get("loaded_chunks")
    var collisions_variant: Variant = streamer.get("collision_chunks")
    if not (loaded_variant is Dictionary) or not (collisions_variant is Dictionary):
        return empty
    if not streamer.has_method("_world_to_chunk") or not streamer.has_method("_chunk_inside_world"):
        return empty

    var loaded: Dictionary = loaded_variant
    var collisions: Dictionary = collisions_variant
    var center_variant: Variant = streamer.call("_world_to_chunk", pos)
    if not (center_variant is Vector2i):
        return empty
    var center: Vector2i = center_variant

    var visual_required := 0
    var visual_loaded := 0
    var collision_required := 0
    var collision_loaded := 0
    var items := 0
    for x: int in range(center.x - VISUAL_RADIUS, center.x + VISUAL_RADIUS + 1):
        for z: int in range(center.y - VISUAL_RADIUS, center.y + VISUAL_RADIUS + 1):
            var coord := Vector2i(x, z)
            var inside_variant: Variant = streamer.call("_chunk_inside_world", coord)
            if not bool(inside_variant):
                continue
            visual_required += 1
            if loaded.has(coord) and is_instance_valid(loaded.get(coord)):
                visual_loaded += 1
                var chunk := loaded.get(coord) as Node
                if chunk != null and chunk.get_node_or_null("Items") != null:
                    items += 1
            if maxi(abs(coord.x - center.x), abs(coord.y - center.y)) <= PHYSICS_RADIUS:
                collision_required += 1
                if collisions.has(coord) and is_instance_valid(collisions.get(coord)):
                    collision_loaded += 1

    var center_terrain := false
    if loaded.has(center) and is_instance_valid(loaded.get(center)):
        var center_chunk := loaded.get(center) as Node
        center_terrain = center_chunk != null and center_chunk.get_node_or_null("Terrain") != null

    var visual_ratio := float(visual_loaded) / float(visual_required) if visual_required > 0 else 0.0
    var collision_ratio := float(collision_loaded) / float(collision_required) if collision_required > 0 else 0.0
    return {
        "visual_ratio":clampf(visual_ratio, 0.0, 1.0),
        "collision_ratio":clampf(collision_ratio, 0.0, 1.0),
        "center_terrain":center_terrain,
        "items_ready":visual_required > 0 and items >= visual_required,
        "visual_loaded":visual_loaded,
        "visual_required":visual_required,
        "collision_loaded":collision_loaded,
        "collision_required":collision_required
    }

static func _settlement_state(settlements: Node, interiors: Node, pos: Vector2) -> Dictionary:
    var empty := {"settlements_ready":false,"buildings_ready":false,"interiors_ready":false,"npcs_ready":false,"loaded":0,"expected":0}
    if settlements == null or not is_instance_valid(settlements):
        return empty

    var specs_variant: Variant = settlements.call("settlement_specs") if settlements.has_method("settlement_specs") else []
    if not (specs_variant is Array):
        return empty
    var specs: Array = specs_variant
    var expected := 0
    for variant: Variant in specs:
        if variant is Dictionary:
            var spec: Dictionary = variant
            var center_value: Variant = spec.get("center", Vector2.ZERO)
            if center_value is Vector2 and pos.distance_to(center_value) <= SETTLEMENT_LOAD_RADIUS:
                expected += 1

    var loaded_value: Variant = settlements.call("loaded_settlement_count") if settlements.has_method("loaded_settlement_count") else 0
    var loaded := _safe_int_variant(loaded_value, 0)
    var settlements_ready := expected <= 0 or loaded >= expected
    var buildings_ready := expected <= 0 or (settlements_ready and _safe_int_property(settlements, "materialized_buildings", 0) > 0)
    var npcs_ready := expected <= 0 or (settlements_ready and _safe_int_property(settlements, "materialized_npcs", 0) > 0)
    var enterable_count := settlements.get_tree().get_nodes_in_group("enterable_building").size()
    var interiors_ready := enterable_count <= 0 or (interiors != null and _safe_int_property(interiors, "decorated_buildings", 0) > 0)
    return {"settlements_ready":settlements_ready,"buildings_ready":buildings_ready,"interiors_ready":interiors_ready,"npcs_ready":npcs_ready,"loaded":loaded,"expected":expected}

static func _ground_below(player: CharacterBody3D) -> bool:
    if player == null or not is_instance_valid(player) or player.get_world_3d() == null:
        return false
    var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
    if space == null:
        return false
    var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 2.0, player.global_position + Vector3.DOWN * 4.0)
    query.exclude = [player.get_rid()]
    query.collision_mask = 1
    return not space.intersect_ray(query).is_empty()

static func _stage_for(checks: Dictionary) -> String:
    var stages: Array[Array] = [
        ["save", "Подготовка сохранения"], ["spawn", "Определение точки появления"],
        ["region", "Загрузка стартовой области"], ["terrain", "Создание ландшафта"],
        ["collisions", "Подготовка физики и коллизий"], ["water", "Загрузка рек и воды"],
        ["roads", "Загрузка дорог"], ["nature", "Загрузка растительности"],
        ["settlements", "Загрузка поселений"], ["buildings", "Загрузка зданий"],
        ["interiors", "Загрузка интерьеров"], ["npcs", "Подготовка NPC"],
        ["items", "Подготовка предметов мира"], ["gameplay", "Квесты и инвентарь"],
        ["environment", "Погода, время и освещение"], ["camera", "Подготовка камеры"],
        ["ground", "Проверка земли под игроком"]
    ]
    for pair: Array in stages:
        var key := String(pair[0])
        if not bool(checks.get(key, false)):
            return String(pair[1])
    return "Финальная проверка стартовой области"

static func _detail_for(stage: String, stream: Dictionary, settlement: Dictionary) -> String:
    if stage == "Загрузка стартовой области":
        return "Видимые чанки: %d из %d" % [int(stream.get("visual_loaded",0)), int(stream.get("visual_required",0))]
    if stage == "Подготовка физики и коллизий":
        return "Физические чанки: %d из %d" % [int(stream.get("collision_loaded",0)), int(stream.get("collision_required",0))]
    if stage in ["Загрузка поселений","Загрузка зданий","Загрузка интерьеров","Подготовка NPC"]:
        return "Поселения рядом: %d из %d" % [int(settlement.get("loaded",0)), int(settlement.get("expected",0))]
    return "Основные системы готовы; детали мира продолжают загружаться в фоне"

static func _empty(stage: String) -> Dictionary:
    return {"ratio":0.0,"all_ready":false,"stage":stage,"detail":"Подготовка узлов игрового мира","checks":{}}
