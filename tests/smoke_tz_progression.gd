extends Node

const CAPITAL := preload("res://scripts/capital_data.gd")
const REALM_RUNTIME := preload("res://scripts/realm_runtime.gd")

var failed := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    push_error("TZ progression smoke failed: %s" % message)
    get_tree().quit(code)

func _check(condition: bool, code: int, message: String) -> bool:
    if condition:
        return true
    _fail(code, message)
    return false

func _run_test() -> void:
    GameState.reset_new_game()
    ProgressionSystem.reset_for_new_game()
    GameState.coins = 50000

    var expected_ranks := ["H", "G", "F", "E", "D", "C", "B", "A", "S", "SS", "SSS", "SSS+"]
    if not _check(ProgressionSystem.RANKS == expected_ranks, 2, "rank ladder H..SSS+ is incomplete"):
        return
    ProgressionSystem.add_xp(13000)
    if not _check(ProgressionSystem.rank_name() == "SSS+", 3, "XP progression does not reach SSS+"):
        return
    var medal := ProgressionSystem.medallion()
    if not _check(int(medal.get("level", 0)) > 1 and String(medal.get("rank", "")) == "SSS+", 4, "medallion is detached from rank/level progression"):
        return

    if not _check(ProgressionSystem.register_party_member("companion", "Лира", "B"), 5, "party member registration failed"):
        return
    if not _check(ProgressionSystem.set_party_deputy("companion"), 6, "party deputy assignment failed"):
        return
    var party := ProgressionSystem.party()
    if not _check(Array(party.get("members", [])).size() == 2 and String(party.get("deputy", "")) == "companion", 7, "party leader/deputy/member state is invalid"):
        return

    if not _check(ProgressionSystem.create_guild("Тестовая гильдия"), 8, "guild creation failed"):
        return
    var denied_war := ProgressionSystem.request_guild_war("Без согласия", false)
    if not _check(not bool(denied_war.get("ok", true)) and String(denied_war.get("reason", "")) == "mutual_consent_required", 9, "guild war can start without mutual consent"):
        return
    if not _check(bool(ProgressionSystem.request_guild_war("Соперник A", true).get("ok", false)), 10, "consensual guild war did not start"):
        return
    var war_result := ProgressionSystem.resolve_guild_war("Соперник A", true, 1000)
    if not _check(int(war_result.get("seized", -1)) == 100, 11, "guild war does not cap seizure at 10 percent"):
        return
    if not _check(Array(war_result.get("territories", [])).size() == 1, 12, "winning a guild war does not capture territory"):
        return
    if not _check(bool(ProgressionSystem.request_guild_war("Соперник B", true).get("ok", false)), 13, "second consensual war did not start"):
        return
    var second_war := ProgressionSystem.resolve_guild_war("Соперник B", true, 2000)
    if not _check(int(second_war.get("seized", -1)) == 0, 14, "treasury can be seized more than once in the same week"):
        return

    var dungeon_start := ProgressionSystem.start_dungeon("H")
    if not _check(bool(dungeon_start.get("ok", false)), 15, "rank H dungeon did not start"):
        return
    var run: Dictionary = dungeon_start.get("run", {})
    var floor_count := int(run.get("floor_count", 0))
    if not _check(floor_count >= 5 and floor_count <= 10, 16, "dungeon floor count is outside 5..10"):
        return
    if not _check(int(run.get("boss_floor", -1)) == floor_count, 17, "dungeon boss is not on the final floor"):
        return
    var hidden := int(run.get("hidden_floor", -1))
    if hidden >= 0 and not _check(hidden >= 2 and hidden < floor_count, 18, "hidden floor is outside legal range"):
        return
    var dungeon_result: Dictionary = {}
    for _i in range(12):
        dungeon_result = ProgressionSystem.dungeon_floor_victory()
        if bool(dungeon_result.get("completed", false)):
            break
    if not _check(bool(dungeon_result.get("completed", false)), 19, "dungeon cannot complete through its floor progression"):
        return
    if not _check(bool(dungeon_result.get("first_clear", false)), 20, "first-clear reward flag is missing"):
        return

    if not _check(ProgressionSystem.buy_inventory_insurance(), 21, "inventory insurance purchase failed"):
        return
    var insured_start := ProgressionSystem.start_dungeon("H")
    if not _check(bool(insured_start.get("ok", false)), 22, "insured dungeon did not start"):
        return
    ProgressionSystem.dungeon_floor_victory()
    var insured_death := ProgressionSystem.fail_dungeon(true)
    if not _check(bool(insured_death.get("insured", false)) and ProgressionSystem.inventory_insurance_charges() == 0, 23, "one-death inventory insurance did not consume exactly one charge"):
        return

    var outside_pos := CAPITAL.CENTER + Vector2(CAPITAL.HALF_EXTENT + CAPITAL.DEFENSE_BELT + 500.0, 0.0)
    var normal_plot := ProgressionSystem.purchase_plot("normal", outside_pos)
    if not _check(bool(normal_plot.get("ok", false)) and int(Dictionary(normal_plot.get("plot", {})).get("size", 0)) == 32, 24, "normal plot is not 32x32 outside the capital"):
        return
    ProgressionSystem.set_vip_enabled(true)
    var vip_plot := ProgressionSystem.purchase_plot("vip", CAPITAL.CENTER + Vector2(700.0, 700.0))
    if not _check(bool(vip_plot.get("ok", false)) and int(Dictionary(vip_plot.get("plot", {})).get("size", 0)) == 96, 25, "VIP plot is not 96x96 inside the capital"):
        return
    var guild_plot := ProgressionSystem.purchase_plot("guild", outside_pos + Vector2(0.0, 300.0))
    if not _check(bool(guild_plot.get("ok", false)) and int(Dictionary(guild_plot.get("plot", {})).get("size", 0)) == 128, 26, "guild plot is not 128x128 outside the capital"):
        return
    if not _check(not bool(ProgressionSystem.purchase_plot("normal", CAPITAL.CENTER).get("ok", false)), 27, "ordinary players can buy plots inside the protected capital"):
        return
    var vip_id := String(Dictionary(vip_plot.get("plot", {})).get("id", ""))
    var normal_id := String(Dictionary(normal_plot.get("plot", {})).get("id", ""))
    if not _check(ProgressionSystem.plot_build_allowed(vip_id, "house", true), 28, "creative build is unavailable on VIP plot"):
        return
    if not _check(not ProgressionSystem.plot_build_allowed(normal_id, "house", true), 29, "creative build leaks onto ordinary plot"):
        return
    if not _check(not ProgressionSystem.plot_build_allowed(vip_id, "chest", true) and not ProgressionSystem.plot_build_allowed(vip_id, "rare_block", true), 30, "creative restrictions allow transfer/storage exploits"):
        return

    if not _check(ProgressionSystem.toggle_vip_flight(), 31, "VIP flight cannot be enabled outside combat"):
        return
    ProgressionSystem.set_combat_active(true)
    if not _check(not bool(ProgressionSystem.vip_status().get("flight", true)), 32, "VIP flight remains active in combat"):
        return
    ProgressionSystem.set_combat_active(false)
    if not _check(bool(ProgressionSystem.start_dungeon("H").get("ok", false)), 33, "dungeon could not start for VIP restriction test"):
        return
    if not _check(not ProgressionSystem.toggle_vip_flight(), 34, "VIP flight can be enabled inside dungeon"):
        return
    ProgressionSystem.fail_dungeon(false)

    var event_data := ProgressionSystem.active_event()
    if not _check(not event_data.is_empty(), 35, "world event rotation has no active event"):
        return
    if not _check(ProgressionSystem.claim_event_reward(), 36, "event reward could not be claimed"):
        return
    if not _check(not ProgressionSystem.claim_event_reward(), 37, "event reward can be claimed twice in one event day"):
        return

    var mini_catalog := ProgressionSystem.minigame_catalog()
    if not _check(mini_catalog.size() >= 3, 38, "mandatory minigame catalog is incomplete"):
        return
    for mini in mini_catalog:
        var mini_data: Dictionary = mini
        var result := ProgressionSystem.finish_minigame(String(mini_data.get("id", "")), int(mini_data.get("target", 0)))
        if not _check(bool(result.get("ok", false)) and bool(result.get("target_reached", false)), 39, "minigame scoring/reward contract failed"):
            return

    if not _check(CAPITAL.gates().size() == 32, 40, "capital does not have exactly 32 gates"):
        return
    if not _check(CAPITAL.gates_are_open(12.0 * 60.0) and not CAPITAL.gates_are_open(22.0 * 60.0), 41, "capital day/night gate schedule is incorrect"):
        return

    var realm_runtime := REALM_RUNTIME.new()
    add_child(realm_runtime)
    var realms := realm_runtime.realm_catalog()
    if not _check(realms.size() >= 2, 42, "altered Nether/End analogue realms are missing"):
        return
    realm_runtime.queue_free()

    var required_biome_names := ["Тропики", "Снежные земли", "Подводный мир", "Тундра", "Северная тайга", "Болота", "Сухие земли", "Степь", "Лес", "Горный хребет"]
    for display_name in required_biome_names:
        var known := false
        for id in ["tropical", "snow", "underwater", "tundra", "taiga", "marsh", "drylands", "steppe", "forest", "mountains"]:
            if WorldData.biome_display_name(id) == display_name:
                known = true
                break
        if not _check(known, 43, "biome catalog is missing %s" % display_name):
            return

    var preserved := ProgressionSystem.snapshot()
    ProgressionSystem.reset_for_new_game()
    ProgressionSystem.load_snapshot(preserved)
    if not _check(ProgressionSystem.rank_name() == "SSS+" and not ProgressionSystem.guild().is_empty(), 44, "progression state is not restorable for save/load"):
        return

    print("TZ_PROGRESSION_SMOKE_OK ranks=12 dungeons=5-10 guilds=mutual-consent+territory plots=32/96/128 vip=restricted insurance=one-death events=minigames realms=2 gates=32 biomes=extended")
    get_tree().quit(0)
