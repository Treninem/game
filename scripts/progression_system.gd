extends Node

signal progression_changed
signal dungeon_requested(run: Dictionary)
signal dungeon_exit_requested(result: Dictionary)
signal vip_flight_changed(active: bool)
signal event_changed(event_data: Dictionary)

const STATE_KEY := "impuls_progression_v1"
const RANKS := PackedStringArray(["H", "G", "F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "SSS+"])
const RANK_XP := PackedInt32Array([0, 120, 300, 600, 1050, 1700, 2550, 3650, 5100, 7000, 9500, 12500])
const MAX_LEVEL := 100
const INACTIVITY_RELEASE_DAYS := 60
const WEEK_SECONDS := 7 * 24 * 60 * 60
const VIP_FLIGHT_COST_PER_MINUTE := 2
const NORMAL_PLOT_SIZE := 32
const VIP_PLOT_SIZE := 96
const GUILD_PLOT_SIZE := 128
const NORMAL_PLOT_PRICE := 250
const VIP_PLOT_PRICE := 1800
const GUILD_PLOT_PRICE := 3500
const INSURANCE_PRICE := 180
const DUNGEON_MIN_FLOORS := 5
const DUNGEON_MAX_FLOORS := 10

const DUNGEONS := {
    "H": {"name": "Заброшенные катакомбы", "reward_coins": 80, "reward_xp": 90, "difficulty": 1.0},
    "G": {"name": "Пещеры шёпота", "reward_coins": 120, "reward_xp": 130, "difficulty": 1.2},
    "F": {"name": "Затонувший храм", "reward_coins": 175, "reward_xp": 185, "difficulty": 1.45},
    "E": {"name": "Башня пепла", "reward_coins": 250, "reward_xp": 255, "difficulty": 1.75},
    "D": {"name": "Крепость бездны", "reward_coins": 350, "reward_xp": 345, "difficulty": 2.1},
    "C": {"name": "Лабиринт стражей", "reward_coins": 480, "reward_xp": 460, "difficulty": 2.5},
    "B": {"name": "Гробница титана", "reward_coins": 650, "reward_xp": 600, "difficulty": 3.0},
    "A": {"name": "Разлом лунного света", "reward_coins": 900, "reward_xp": 790, "difficulty": 3.6},
    "S": {"name": "Чёрная цитадель", "reward_coins": 1250, "reward_xp": 1050, "difficulty": 4.4},
    "SS": {"name": "Обитель древних", "reward_coins": 1750, "reward_xp": 1400, "difficulty": 5.3},
    "SSS": {"name": "Сердце миров", "reward_coins": 2500, "reward_xp": 1900, "difficulty": 6.5},
    "SSS+": {"name": "Нулевая бездна", "reward_coins": 4000, "reward_xp": 2800, "difficulty": 8.0}
}

const EVENTS := [
    {"id": "night_siege", "name": "Ночная осада", "description": "Защитите санитарный пояс столицы от усиленной волны существ.", "reward_coins": 180},
    {"id": "merchant_fair", "name": "Ярмарка гильдий", "description": "Торговцы и ремесленники снижают цены на услуги и награждают за заказы.", "reward_coins": 120},
    {"id": "rift_hunt", "name": "Охота на разломы", "description": "Закройте нестабильные разломы до появления элитных существ.", "reward_coins": 220},
    {"id": "arena_week", "name": "Неделя арены", "description": "Серия боевых испытаний с рейтингом и повышенной наградой.", "reward_coins": 260}
]

const MINIGAMES := {
    "arena_trial": {"name": "Испытание арены", "target": 1000, "reward_coins": 90},
    "courier_race": {"name": "Гонка курьеров", "target": 750, "reward_coins": 75},
    "rune_puzzle": {"name": "Рунная головоломка", "target": 650, "reward_coins": 70}
}

var _flight_cost_accumulator := 0.0
var _last_event_id := ""

func _ready() -> void:
    _ensure_state()

func _process(delta: float) -> void:
    _advance_time(delta)
    _advance_vip_flight(delta)
    _release_inactive_plots()
    _refresh_event()

func _default_state() -> Dictionary:
    return {
        "player_name": "Странник",
        "rank_index": 0,
        "level": 1,
        "xp": 0,
        "tasks_completed": 0,
        "dungeons_completed": 0,
        "dungeon_first_clears": {},
        "party": {
            "registered": true,
            "leader": "player",
            "deputy": "",
            "members": [{"id": "player", "name": "Странник", "rank_index": 0}]
        },
        "guild": {},
        "guild_wars": {},
        "plots": [],
        "vip": {
            "enabled": false,
            "flight": false,
            "creative": false,
            "flight_currency": 120
        },
        "insurance_charges": 0,
        "combat_active": false,
        "in_dungeon": false,
        "dungeon_run": {},
        "dungeon_history": [],
        "event_day": 0,
        "elapsed_world_minutes": 0.0,
        "active_event": {},
        "event_claimed_day": -1,
        "minigame_records": {},
        "creative_inventory": {},
        "territories": [],
        "last_world_tick_unix": int(Time.get_unix_time_from_system())
    }

func _ensure_state() -> Dictionary:
    var state_value = GameState.get_world_value(STATE_KEY, null)
    var state: Dictionary
    if typeof(state_value) != TYPE_DICTIONARY:
        state = _default_state()
        GameState.set_world_value(STATE_KEY, state)
        return state
    state = state_value
    var defaults := _default_state()
    for key in defaults:
        if not state.has(key):
            state[key] = defaults[key]
    _normalize_party(state)
    _normalize_vip(state)
    GameState.set_world_value(STATE_KEY, state)
    return state

func reset_for_new_game() -> void:
    GameState.set_world_value(STATE_KEY, _default_state())
    _flight_cost_accumulator = 0.0
    _last_event_id = ""
    _refresh_event(true)
    progression_changed.emit()

func snapshot() -> Dictionary:
    return _ensure_state().duplicate(true)

func load_snapshot(data: Dictionary) -> void:
    var merged := _default_state()
    for key in data:
        merged[key] = data[key]
    GameState.set_world_value(STATE_KEY, merged)
    _ensure_state()
    progression_changed.emit()

func rank_name(index: int = -1) -> String:
    var state := _ensure_state()
    var use_index := int(state.get("rank_index", 0)) if index < 0 else index
    return RANKS[clampi(use_index, 0, RANKS.size() - 1)]

func rank_index(rank_id: String) -> int:
    return RANKS.find(rank_id)

func level() -> int:
    return int(_ensure_state().get("level", 1))

func xp() -> int:
    return int(_ensure_state().get("xp", 0))

func add_xp(amount: int) -> void:
    if amount <= 0:
        return
    var state := _ensure_state()
    state["xp"] = maxi(0, int(state.get("xp", 0)) + amount)
    state["level"] = clampi(1 + int(state["xp"]) / 180, 1, MAX_LEVEL)
    var new_rank := int(state.get("rank_index", 0))
    for i in range(RANK_XP.size()):
        if int(state["xp"]) >= RANK_XP[i]:
            new_rank = i
    if new_rank > int(state.get("rank_index", 0)):
        state["rank_index"] = new_rank
        GameState.notify("Новый ранг: %s." % rank_name(new_rank))
    _sync_player_party_rank(state)
    _commit(state)

func medallion() -> Dictionary:
    var state := _ensure_state()
    var guild: Dictionary = state.get("guild", {})
    return {
        "name": String(state.get("player_name", "Странник")),
        "rank": rank_name(),
        "level": int(state.get("level", 1)),
        "xp": int(state.get("xp", 0)),
        "tasks": int(state.get("tasks_completed", 0)),
        "dungeons": int(state.get("dungeons_completed", 0)),
        "guild": String(guild.get("name", "Нет гильдии"))
    }

func set_player_name(value: String) -> bool:
    var clean := value.strip_edges().substr(0, 32)
    if clean.is_empty():
        return false
    var state := _ensure_state()
    state["player_name"] = clean
    var party: Dictionary = state.get("party", {})
    var members: Array = party.get("members", [])
    for member in members:
        if member is Dictionary and String(member.get("id", "")) == "player":
            member["name"] = clean
    party["members"] = members
    state["party"] = party
    _commit(state)
    return true

func party() -> Dictionary:
    return _ensure_state().get("party", {}).duplicate(true)

func party_average_rank_index() -> float:
    var members: Array = party().get("members", [])
    if members.is_empty():
        return float(rank_index(rank_name()))
    var total := 0.0
    for member in members:
        if member is Dictionary:
            total += float(member.get("rank_index", 0))
    return total / maxf(1.0, float(members.size()))

func register_party_member(member_id: String, member_name: String, member_rank: String) -> bool:
    var id := member_id.strip_edges()
    var ridx := rank_index(member_rank)
    if id.is_empty() or ridx < 0:
        return false
    var state := _ensure_state()
    var party_state: Dictionary = state.get("party", {})
    var members: Array = party_state.get("members", [])
    for member in members:
        if member is Dictionary and String(member.get("id", "")) == id:
            return false
    members.append({"id": id, "name": member_name.substr(0, 32), "rank_index": ridx})
    party_state["members"] = members
    state["party"] = party_state
    _commit(state)
    return true

func remove_party_member(member_id: String) -> bool:
    if member_id == "player":
        return false
    var state := _ensure_state()
    var party_state: Dictionary = state.get("party", {})
    var members: Array = party_state.get("members", [])
    for i in range(members.size() - 1, -1, -1):
        var member = members[i]
        if member is Dictionary and String(member.get("id", "")) == member_id:
            members.remove_at(i)
            if String(party_state.get("deputy", "")) == member_id:
                party_state["deputy"] = ""
            party_state["members"] = members
            state["party"] = party_state
            _commit(state)
            return true
    return false

func set_party_deputy(member_id: String) -> bool:
    var state := _ensure_state()
    var party_state: Dictionary = state.get("party", {})
    if member_id.is_empty():
        party_state["deputy"] = ""
        state["party"] = party_state
        _commit(state)
        return true
    for member in party_state.get("members", []):
        if member is Dictionary and String(member.get("id", "")) == member_id and member_id != "player":
            party_state["deputy"] = member_id
            state["party"] = party_state
            _commit(state)
            return true
    return false

func guild() -> Dictionary:
    return _ensure_state().get("guild", {}).duplicate(true)

func create_guild(name: String) -> bool:
    var clean := name.strip_edges().substr(0, 40)
    if clean.is_empty():
        return false
    var state := _ensure_state()
    if not Dictionary(state.get("guild", {})).is_empty():
        return false
    if GameState.coins < 500:
        GameState.notify("Для регистрации гильдии требуется 500 монет.")
        return false
    GameState.coins -= 500
    state["guild"] = {
        "name": clean,
        "leader": "player",
        "deputy": "",
        "members": ["player"],
        "treasury": 0,
        "rating": 1000,
        "territories": [],
        "war_wins": 0,
        "war_losses": 0
    }
    _commit(state)
    GameState.notify("Гильдия «%s» зарегистрирована." % clean)
    return true

func disband_guild() -> bool:
    var state := _ensure_state()
    var guild_state: Dictionary = state.get("guild", {})
    if guild_state.is_empty() or String(guild_state.get("leader", "")) != "player":
        return false
    state["guild"] = {}
    state["guild_wars"] = {}
    _commit(state)
    return true

func guild_deposit(amount: int) -> bool:
    if amount <= 0 or GameState.coins < amount:
        return false
    var state := _ensure_state()
    var guild_state: Dictionary = state.get("guild", {})
    if guild_state.is_empty():
        return false
    GameState.coins -= amount
    guild_state["treasury"] = int(guild_state.get("treasury", 0)) + amount
    state["guild"] = guild_state
    _commit(state)
    return true

func request_guild_war(opponent_name: String, opponent_consents: bool) -> Dictionary:
    var state := _ensure_state()
    var guild_state: Dictionary = state.get("guild", {})
    if guild_state.is_empty():
        return {"ok": false, "reason": "no_guild"}
    var opponent := opponent_name.strip_edges().substr(0, 40)
    if opponent.is_empty():
        return {"ok": false, "reason": "invalid_opponent"}
    if not opponent_consents:
        return {"ok": false, "reason": "mutual_consent_required"}
    var wars: Dictionary = state.get("guild_wars", {})
    wars[opponent] = {
        "opponent": opponent,
        "status": "active",
        "started_unix": int(Time.get_unix_time_from_system()),
        "last_treasury_seizure_week": -1,
        "arena_score": 0,
        "territory_score": 0
    }
    state["guild_wars"] = wars
    _commit(state)
    return {"ok": true, "opponent": opponent}

func resolve_guild_war(opponent_name: String, player_won: bool, opponent_treasury: int = 0) -> Dictionary:
    var state := _ensure_state()
    var wars: Dictionary = state.get("guild_wars", {})
    if not wars.has(opponent_name):
        return {"ok": false, "reason": "war_not_active"}
    var war: Dictionary = wars[opponent_name]
    if String(war.get("status", "")) != "active":
        return {"ok": false, "reason": "war_not_active"}
    var guild_state: Dictionary = state.get("guild", {})
    var seized := 0
    var week := int(int(Time.get_unix_time_from_system()) / WEEK_SECONDS)
    if player_won:
        guild_state["war_wins"] = int(guild_state.get("war_wins", 0)) + 1
        guild_state["rating"] = int(guild_state.get("rating", 1000)) + 35
        if int(war.get("last_treasury_seizure_week", -1)) != week:
            seized = maxi(0, int(floor(float(maxi(0, opponent_treasury)) * 0.10)))
            guild_state["treasury"] = int(guild_state.get("treasury", 0)) + seized
            war["last_treasury_seizure_week"] = week
    else:
        guild_state["war_losses"] = int(guild_state.get("war_losses", 0)) + 1
        guild_state["rating"] = maxi(0, int(guild_state.get("rating", 1000)) - 25)
    war["status"] = "finished"
    war["winner"] = String(guild_state.get("name", "player")) if player_won else opponent_name
    wars[opponent_name] = war
    state["guild_wars"] = wars
    state["guild"] = guild_state
    _commit(state)
    return {"ok": true, "seized": seized, "rating": int(guild_state.get("rating", 1000))}

func dungeon_catalog() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var player_rank := int(_ensure_state().get("rank_index", 0))
    for i in range(RANKS.size()):
        var rank_id := RANKS[i]
        var definition: Dictionary = DUNGEONS[rank_id]
        result.append({
            "rank": rank_id,
            "name": String(definition.get("name", rank_id)),
            "reward_coins": int(definition.get("reward_coins", 0)),
            "reward_xp": int(definition.get("reward_xp", 0)),
            "difficulty": float(definition.get("difficulty", 1.0)),
            "available": i <= player_rank + 1
        })
    return result

func dungeon_warning(rank_id: String) -> String:
    var idx := rank_index(rank_id)
    if idx < 0:
        return "Неизвестный ранг подземелья."
    var average := party_average_rank_index()
    if float(idx) > average + 1.0:
        return "Опасность критическая: средний ранг группы значительно ниже ранга подземелья."
    if float(idx) > average:
        return "Подземелье выше среднего ранга группы. Вход разрешён, но риск повышен."
    return "Состав группы соответствует рекомендуемому рангу."

func start_dungeon(rank_id: String) -> Dictionary:
    var idx := rank_index(rank_id)
    if idx < 0:
        return {"ok": false, "reason": "unknown_rank"}
    var state := _ensure_state()
    if bool(state.get("in_dungeon", false)):
        return {"ok": false, "reason": "already_inside"}
    if idx > int(state.get("rank_index", 0)) + 1:
        return {"ok": false, "reason": "rank_locked"}
    var definition: Dictionary = DUNGEONS[rank_id]
    var seed := int(Time.get_unix_time_from_system()) ^ (idx * 7919) ^ (int(state.get("dungeons_completed", 0)) * 104729)
    var floor_count := DUNGEON_MIN_FLOORS + posmod(seed, DUNGEON_MAX_FLOORS - DUNGEON_MIN_FLOORS + 1)
    var hidden_floor := -1
    if posmod(seed, 4) == 0:
        hidden_floor = clampi(2 + posmod(int(seed / 7), maxi(1, floor_count - 3)), 2, floor_count - 1)
    var run := {
        "id": "%s-%d" % [rank_id, int(Time.get_unix_time_from_system())],
        "rank": rank_id,
        "name": String(definition.get("name", rank_id)),
        "floor_count": floor_count,
        "current_floor": 1,
        "hidden_floor": hidden_floor,
        "hidden_discovered": false,
        "boss_floor": floor_count,
        "earned_coins": 0,
        "earned_xp": 0,
        "started_unix": int(Time.get_unix_time_from_system()),
        "difficulty": float(definition.get("difficulty", 1.0)),
        "warning": dungeon_warning(rank_id)
    }
    state["dungeon_run"] = run
    state["in_dungeon"] = true
    state["combat_active"] = false
    var vip: Dictionary = state.get("vip", {})
    vip["flight"] = false
    vip["creative"] = false
    state["vip"] = vip
    _commit(state)
    vip_flight_changed.emit(false)
    dungeon_requested.emit(run.duplicate(true))
    return {"ok": true, "run": run.duplicate(true)}

func dungeon_run() -> Dictionary:
    return _ensure_state().get("dungeon_run", {}).duplicate(true)

func dungeon_floor_victory() -> Dictionary:
    var state := _ensure_state()
    if not bool(state.get("in_dungeon", false)):
        return {"ok": false, "reason": "not_inside"}
    var run: Dictionary = state.get("dungeon_run", {})
    var floor_index := int(run.get("current_floor", 1))
    var floor_count := int(run.get("floor_count", 5))
    var definition: Dictionary = DUNGEONS.get(String(run.get("rank", "H")), DUNGEONS["H"])
    var floor_reward_coins := maxi(5, int(definition.get("reward_coins", 80)) / maxi(1, floor_count))
    var floor_reward_xp := maxi(8, int(definition.get("reward_xp", 90)) / maxi(1, floor_count))
    run["earned_coins"] = int(run.get("earned_coins", 0)) + floor_reward_coins
    run["earned_xp"] = int(run.get("earned_xp", 0)) + floor_reward_xp
    if floor_index == int(run.get("hidden_floor", -1)):
        run["hidden_discovered"] = true
        run["earned_coins"] = int(run.get("earned_coins", 0)) + floor_reward_coins * 2
        run["earned_xp"] = int(run.get("earned_xp", 0)) + floor_reward_xp
    if floor_index >= floor_count:
        state["dungeon_run"] = run
        _commit(state)
        return complete_dungeon()
    run["current_floor"] = floor_index + 1
    state["dungeon_run"] = run
    _commit(state)
    return {"ok": true, "completed": false, "run": run.duplicate(true)}

func complete_dungeon() -> Dictionary:
    var state := _ensure_state()
    if not bool(state.get("in_dungeon", false)):
        return {"ok": false, "reason": "not_inside"}
    var run: Dictionary = state.get("dungeon_run", {})
    var rank_id := String(run.get("rank", "H"))
    var definition: Dictionary = DUNGEONS.get(rank_id, DUNGEONS["H"])
    var first_clears: Dictionary = state.get("dungeon_first_clears", {})
    var first_clear := not bool(first_clears.get(rank_id, false))
    var base_coins := int(definition.get("reward_coins", 80))
    var base_xp := int(definition.get("reward_xp", 90))
    var coins_reward := int(run.get("earned_coins", 0)) + base_coins
    var xp_reward := int(run.get("earned_xp", 0)) + base_xp
    if first_clear:
        coins_reward += int(round(float(base_coins) * 0.75))
        xp_reward += int(round(float(base_xp) * 0.50))
        first_clears[rank_id] = true
    GameState.coins += coins_reward
    state["dungeon_first_clears"] = first_clears
    state["dungeons_completed"] = int(state.get("dungeons_completed", 0)) + 1
    state["tasks_completed"] = int(state.get("tasks_completed", 0)) + 1
    state["in_dungeon"] = false
    state["combat_active"] = false
    var history: Array = state.get("dungeon_history", [])
    history.append({"rank": rank_id, "won": true, "coins": coins_reward, "xp": xp_reward, "first_clear": first_clear})
    while history.size() > 40:
        history.pop_front()
    state["dungeon_history"] = history
    state["dungeon_run"] = {}
    _commit(state)
    add_xp(xp_reward)
    var result := {"ok": true, "completed": true, "coins": coins_reward, "xp": xp_reward, "first_clear": first_clear}
    dungeon_exit_requested.emit(result.duplicate(true))
    GameState.notify("Подземелье пройдено: +%d монет, +%d опыта." % [coins_reward, xp_reward])
    return result

func fail_dungeon(death: bool = true) -> Dictionary:
    var state := _ensure_state()
    if not bool(state.get("in_dungeon", false)):
        return {"ok": false, "reason": "not_inside"}
    var run: Dictionary = state.get("dungeon_run", {})
    var retained_ratio := 0.50 if death else 0.70
    var retained_coins := int(floor(float(int(run.get("earned_coins", 0))) * retained_ratio))
    var retained_xp := int(floor(float(int(run.get("earned_xp", 0))) * retained_ratio))
    var insured := false
    if death and int(state.get("insurance_charges", 0)) > 0:
        state["insurance_charges"] = int(state.get("insurance_charges", 0)) - 1
        retained_coins = int(run.get("earned_coins", 0))
        retained_xp = int(run.get("earned_xp", 0))
        insured = true
    GameState.coins += retained_coins
    var history: Array = state.get("dungeon_history", [])
    history.append({"rank": String(run.get("rank", "H")), "won": false, "coins": retained_coins, "xp": retained_xp, "insured": insured})
    while history.size() > 40:
        history.pop_front()
    state["dungeon_history"] = history
    state["in_dungeon"] = false
    state["combat_active"] = false
    state["dungeon_run"] = {}
    _commit(state)
    add_xp(retained_xp)
    var result := {"ok": true, "completed": false, "coins": retained_coins, "xp": retained_xp, "insured": insured}
    dungeon_exit_requested.emit(result.duplicate(true))
    return result

func buy_inventory_insurance() -> bool:
    var state := _ensure_state()
    if GameState.coins < INSURANCE_PRICE:
        return false
    GameState.coins -= INSURANCE_PRICE
    state["insurance_charges"] = int(state.get("insurance_charges", 0)) + 1
    _commit(state)
    return true

func inventory_insurance_charges() -> int:
    return int(_ensure_state().get("insurance_charges", 0))

func purchase_plot(plot_type: String, position: Vector2 = Vector2.ZERO) -> Dictionary:
    var kind := plot_type.to_lower()
    var state := _ensure_state()
    var vip: Dictionary = state.get("vip", {})
    var guild_state: Dictionary = state.get("guild", {})
    var size := NORMAL_PLOT_SIZE
    var price := NORMAL_PLOT_PRICE
    if kind == "vip":
        if not bool(vip.get("enabled", false)):
            return {"ok": false, "reason": "vip_required"}
        size = VIP_PLOT_SIZE
        price = VIP_PLOT_PRICE
    elif kind == "guild":
        if guild_state.is_empty():
            return {"ok": false, "reason": "guild_required"}
        size = GUILD_PLOT_SIZE
        price = GUILD_PLOT_PRICE
    elif kind != "normal":
        return {"ok": false, "reason": "unknown_plot_type"}
    if GameState.coins < price:
        return {"ok": false, "reason": "insufficient_funds"}
    GameState.coins -= price
    var plots: Array = state.get("plots", [])
    var plot_id := "plot-%d-%d" % [int(Time.get_unix_time_from_system()), plots.size()]
    var plot := {
        "id": plot_id,
        "type": kind,
        "size": size,
        "position": [position.x, position.y],
        "parcels": 1,
        "last_active_unix": int(Time.get_unix_time_from_system()),
        "owner": String(guild_state.get("name", "player")) if kind == "guild" else "player"
    }
    plots.append(plot)
    state["plots"] = plots
    _commit(state)
    return {"ok": true, "plot": plot.duplicate(true)}

func expand_plot(plot_id: String) -> bool:
    var state := _ensure_state()
    var plots: Array = state.get("plots", [])
    for plot in plots:
        if plot is Dictionary and String(plot.get("id", "")) == plot_id:
            var kind := String(plot.get("type", "normal"))
            var base_price := NORMAL_PLOT_PRICE
            if kind == "vip":
                base_price = VIP_PLOT_PRICE
            elif kind == "guild":
                base_price = GUILD_PLOT_PRICE
            var price := maxi(50, int(round(float(base_price) * 0.65)))
            if GameState.coins < price:
                return false
            GameState.coins -= price
            plot["parcels"] = int(plot.get("parcels", 1)) + 1
            plot["last_active_unix"] = int(Time.get_unix_time_from_system())
            state["plots"] = plots
            _commit(state)
            return true
    return false

func sell_plot(plot_id: String) -> bool:
    var state := _ensure_state()
    var plots: Array = state.get("plots", [])
    for i in range(plots.size() - 1, -1, -1):
        var plot = plots[i]
        if plot is Dictionary and String(plot.get("id", "")) == plot_id:
            var kind := String(plot.get("type", "normal"))
            var original_price := NORMAL_PLOT_PRICE
            if kind == "vip":
                original_price = VIP_PLOT_PRICE
            elif kind == "guild":
                original_price = GUILD_PLOT_PRICE
            var parcels := maxi(1, int(plot.get("parcels", 1)))
            GameState.coins += int(round(float(original_price) * 0.65 * float(parcels)))
            plots.remove_at(i)
            state["plots"] = plots
            _commit(state)
            return true
    return false

func plots() -> Array:
    return _ensure_state().get("plots", []).duplicate(true)

func touch_plot(plot_id: String) -> void:
    var state := _ensure_state()
    var plots: Array = state.get("plots", [])
    for plot in plots:
        if plot is Dictionary and String(plot.get("id", "")) == plot_id:
            plot["last_active_unix"] = int(Time.get_unix_time_from_system())
    state["plots"] = plots
    _commit(state)

func plot_build_allowed(plot_id: String, item_id: String, creative: bool = false) -> bool:
    var state := _ensure_state()
    var selected: Dictionary = {}
    for plot in state.get("plots", []):
        if plot is Dictionary and String(plot.get("id", "")) == plot_id:
            selected = plot
            break
    if selected.is_empty():
        return false
    if creative:
        if String(selected.get("type", "")) != "vip":
            return false
        if item_id in ["chest", "shared_container", "rare_block", "quest_item", "currency_container"]:
            return false
    return true

func set_vip_enabled(active: bool) -> void:
    var state := _ensure_state()
    var vip: Dictionary = state.get("vip", {})
    vip["enabled"] = active
    if not active:
        vip["flight"] = false
        vip["creative"] = false
    state["vip"] = vip
    _commit(state)
    vip_flight_changed.emit(bool(vip.get("flight", false)))

func vip_status() -> Dictionary:
    return _ensure_state().get("vip", {}).duplicate(true)

func add_vip_flight_currency(amount: int) -> void:
    if amount <= 0:
        return
    var state := _ensure_state()
    var vip: Dictionary = state.get("vip", {})
    vip["flight_currency"] = int(vip.get("flight_currency", 0)) + amount
    state["vip"] = vip
    _commit(state)

func toggle_vip_flight() -> bool:
    var state := _ensure_state()
    var vip: Dictionary = state.get("vip", {})
    if not bool(vip.get("enabled", false)) or bool(state.get("combat_active", false)) or bool(state.get("in_dungeon", false)):
        vip["flight"] = false
        state["vip"] = vip
        _commit(state)
        vip_flight_changed.emit(false)
        return false
    if int(vip.get("flight_currency", 0)) <= 0:
        vip["flight"] = false
        state["vip"] = vip
        _commit(state)
        vip_flight_changed.emit(false)
        return false
    vip["flight"] = not bool(vip.get("flight", false))
    state["vip"] = vip
    _commit(state)
    vip_flight_changed.emit(bool(vip.get("flight", false)))
    return bool(vip.get("flight", false))

func set_vip_creative(active: bool) -> bool:
    var state := _ensure_state()
    var vip: Dictionary = state.get("vip", {})
    if active and (not bool(vip.get("enabled", false)) or bool(state.get("combat_active", false)) or bool(state.get("in_dungeon", false))):
        return false
    vip["creative"] = active
    state["vip"] = vip
    _commit(state)
    return true

func set_combat_active(active: bool) -> void:
    var state := _ensure_state()
    state["combat_active"] = active
    if active:
        var vip: Dictionary = state.get("vip", {})
        if bool(vip.get("flight", false)):
            vip["flight"] = false
            state["vip"] = vip
            vip_flight_changed.emit(false)
    _commit(state)

func active_event() -> Dictionary:
    _refresh_event()
    return _ensure_state().get("active_event", {}).duplicate(true)

func claim_event_reward() -> bool:
    var state := _ensure_state()
    var event_data: Dictionary = state.get("active_event", {})
    var day := int(state.get("event_day", 0))
    if event_data.is_empty() or int(state.get("event_claimed_day", -1)) == day:
        return false
    var reward := int(event_data.get("reward_coins", 0))
    GameState.coins += reward
    state["event_claimed_day"] = day
    state["tasks_completed"] = int(state.get("tasks_completed", 0)) + 1
    _commit(state)
    add_xp(maxi(20, reward / 2))
    return true

func minigame_catalog() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var records: Dictionary = _ensure_state().get("minigame_records", {})
    for id in MINIGAMES:
        var definition: Dictionary = MINIGAMES[id]
        rows.append({
            "id": String(id),
            "name": String(definition.get("name", id)),
            "target": int(definition.get("target", 0)),
            "reward_coins": int(definition.get("reward_coins", 0)),
            "record": int(records.get(id, 0))
        })
    return rows

func finish_minigame(minigame_id: String, score: int) -> Dictionary:
    if not MINIGAMES.has(minigame_id) or score < 0:
        return {"ok": false}
    var definition: Dictionary = MINIGAMES[minigame_id]
    var state := _ensure_state()
    var records: Dictionary = state.get("minigame_records", {})
    var old_record := int(records.get(minigame_id, 0))
    var new_record := maxi(old_record, score)
    records[minigame_id] = new_record
    state["minigame_records"] = records
    var reached := score >= int(definition.get("target", 0))
    var reward := int(definition.get("reward_coins", 0)) if reached else int(definition.get("reward_coins", 0)) / 4
    GameState.coins += reward
    if reached:
        state["tasks_completed"] = int(state.get("tasks_completed", 0)) + 1
    _commit(state)
    if reached:
        add_xp(maxi(15, reward / 2))
    return {"ok": true, "reward": reward, "record": new_record, "target_reached": reached}

func _advance_time(delta: float) -> void:
    if delta <= 0.0:
        return
    var state := _ensure_state()
    state["elapsed_world_minutes"] = float(state.get("elapsed_world_minutes", 0.0)) + delta * 4.0
    state["event_day"] = int(floor(float(state.get("elapsed_world_minutes", 0.0)) / 1440.0))
    state["last_world_tick_unix"] = int(Time.get_unix_time_from_system())
    GameState.set_world_value(STATE_KEY, state)

func _advance_vip_flight(delta: float) -> void:
    var state := _ensure_state()
    var vip: Dictionary = state.get("vip", {})
    if not bool(vip.get("flight", false)):
        _flight_cost_accumulator = 0.0
        return
    if bool(state.get("combat_active", false)) or bool(state.get("in_dungeon", false)):
        vip["flight"] = false
        state["vip"] = vip
        _commit(state)
        vip_flight_changed.emit(false)
        return
    _flight_cost_accumulator += maxf(delta, 0.0)
    while _flight_cost_accumulator >= 60.0:
        _flight_cost_accumulator -= 60.0
        var currency := int(vip.get("flight_currency", 0))
        if currency < VIP_FLIGHT_COST_PER_MINUTE:
            vip["flight"] = false
            state["vip"] = vip
            _commit(state)
            vip_flight_changed.emit(false)
            GameState.notify("Полёт отключён: закончилась валюта полёта.")
            return
        vip["flight_currency"] = currency - VIP_FLIGHT_COST_PER_MINUTE
    state["vip"] = vip
    GameState.set_world_value(STATE_KEY, state)

func _release_inactive_plots() -> void:
    var state := _ensure_state()
    var plots: Array = state.get("plots", [])
    if plots.is_empty():
        return
    var now := int(Time.get_unix_time_from_system())
    var limit := INACTIVITY_RELEASE_DAYS * 24 * 60 * 60
    var changed := false
    for i in range(plots.size() - 1, -1, -1):
        var plot = plots[i]
        if plot is Dictionary and now - int(plot.get("last_active_unix", now)) >= limit:
            plots.remove_at(i)
            changed = true
    if changed:
        state["plots"] = plots
        _commit(state)

func _refresh_event(force: bool = false) -> void:
    var state := _ensure_state()
    var day := int(state.get("event_day", 0))
    var index := posmod(day, EVENTS.size())
    var event_data: Dictionary = EVENTS[index].duplicate(true)
    event_data["day"] = day
    var id := String(event_data.get("id", ""))
    if force or id != String(Dictionary(state.get("active_event", {})).get("id", "")):
        state["active_event"] = event_data
        _commit(state)
        if id != _last_event_id:
            _last_event_id = id
            event_changed.emit(event_data.duplicate(true))

func _normalize_party(state: Dictionary) -> void:
    var party_state: Dictionary = state.get("party", {})
    var members: Array = party_state.get("members", [])
    var found_player := false
    for member in members:
        if member is Dictionary and String(member.get("id", "")) == "player":
            found_player = true
            member["rank_index"] = int(state.get("rank_index", 0))
            member["name"] = String(state.get("player_name", "Странник"))
    if not found_player:
        members.push_front({"id": "player", "name": String(state.get("player_name", "Странник")), "rank_index": int(state.get("rank_index", 0))})
    party_state["registered"] = true
    party_state["leader"] = "player"
    party_state["members"] = members
    if not party_state.has("deputy"):
        party_state["deputy"] = ""
    state["party"] = party_state

func _normalize_vip(state: Dictionary) -> void:
    var vip: Dictionary = state.get("vip", {})
    var defaults: Dictionary = _default_state().get("vip", {})
    for key in defaults:
        if not vip.has(key):
            vip[key] = defaults[key]
    state["vip"] = vip

func _sync_player_party_rank(state: Dictionary) -> void:
    var party_state: Dictionary = state.get("party", {})
    var members: Array = party_state.get("members", [])
    for member in members:
        if member is Dictionary and String(member.get("id", "")) == "player":
            member["rank_index"] = int(state.get("rank_index", 0))
            member["name"] = String(state.get("player_name", "Странник"))
    party_state["members"] = members
    state["party"] = party_state

func _commit(state: Dictionary) -> void:
    GameState.set_world_value(STATE_KEY, state)
    progression_changed.emit()
