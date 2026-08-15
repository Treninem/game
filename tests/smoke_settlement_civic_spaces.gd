extends Node3D

const SETTLEMENTS_SCRIPT := preload("res://scripts/world_settlements.gd")
const CIVIC_SCRIPT := preload("res://scripts/settlement_civic_spaces.gd")

var failed := false

func _ready() -> void:
    call_deferred("_run_test")

func _fail(code: int, message: String) -> void:
    if failed:
        return
    failed = true
    print("::error title=Settlement civic spaces smoke::%s" % message.replace("\n", " "))
    push_error("Settlement civic spaces smoke failed: %s" % message)
    get_tree().quit(code)

func _run_test() -> void:
    var settlements := SETTLEMENTS_SCRIPT.new() as WorldSettlements
    settlements.name = "Settlements"
    add_child(settlements)

    var civic := CIVIC_SCRIPT.new() as SettlementCivicSpaces
    civic.name = "SettlementCivicSpaces"
    add_child(civic)
    await get_tree().process_frame

    var town := settlements.materialize_settlement_for_test("first_fortified_town")
    if town == null:
        _fail(2, "fortified town could not be materialized")
        return
    if not civic.decorate_settlement(town):
        _fail(3, "fortified town could not receive a civic interior")
        return

    var hall := town.get_node_or_null("Enterable_14") as EnterableBuilding
    if hall == null:
        _fail(4, "main town building is missing")
        return
    if hall.front_door == null or hall.door_count < 1:
        _fail(5, "civic hall is not physically enterable")
        return
    if not bool(hall.get_meta("physical_council_venue", false)):
        _fail(6, "main building is not classified as a physical council venue")
        return
    if hall.get_node_or_null("InteriorFurniture") != null:
        _fail(7, "civic hall retained dwelling furniture")
        return

    var chamber := hall.get_node_or_null("CouncilChamber") as Node3D
    if chamber == null:
        _fail(8, "civic hall has no council chamber")
        return
    if int(chamber.get_meta("assembly_capacity", 0)) < 16:
        _fail(9, "council chamber capacity is too small for settlement representatives")
        return

    var aisle := chamber.get_node_or_null("EntranceAisle") as Marker3D
    if aisle == null or float(aisle.get_meta("clear_width", 0.0)) < 2.2:
        _fail(10, "council chamber lacks a usable entrance aisle")
        return
    if not bool(aisle.get_meta("connects_front_door_to_chamber", false)):
        _fail(11, "entrance aisle is not connected conceptually to the front door")
        return

    var assembly := chamber.get_node_or_null("AssemblyArea") as Marker3D
    if assembly == null:
        _fail(12, "council chamber lacks a physical assembly area")
        return
    if int(assembly.get_meta("standing_capacity", 0)) + int(assembly.get_meta("seated_capacity", 0)) < 16:
        _fail(13, "assembly capacity metadata is inconsistent")
        return

    var physical_fixture_count := 0
    for child in chamber.get_children():
        if child is StaticBody3D:
            var collision := child.get_node_or_null("Collision") as CollisionShape3D
            if collision != null and collision.shape != null:
                physical_fixture_count += 1
    if physical_fixture_count < 10:
        _fail(14, "council chamber has fewer than ten collidable fixtures")
        return

    if chamber.get_node_or_null("CouncilTable") == null:
        _fail(15, "council table is missing")
        return
    if chamber.get_node_or_null("ClerkDesk") == null or chamber.get_node_or_null("CharterChest") == null:
        _fail(16, "civic record-keeping fixtures are missing")
        return
    if chamber.get_node_or_null("CharterWritingSurface") == null:
        _fail(17, "civic hall lacks a visible writing surface for physical charters")
        return

    var sources: Array = hall.get_meta("canonical_story_sources", [])
    if not sources.has("story/main_story/09_CITY_TO_REALM.md") or not sources.has("story/dialogues/09_FOUNDING_COUNCIL.md"):
        _fail(18, "civic hall lost canonical story provenance")
        return

    var village := settlements.materialize_settlement_for_test("border_village_01")
    if village == null:
        _fail(19, "village could not be materialized")
        return
    if civic.decorate_settlement(village):
        _fail(20, "village was incorrectly converted into the fortified-town civic hall")
        return

    if civic.civic_hall_count() != 1:
        _fail(21, "civic hall counter disagrees with materialized world")
        return

    print("SETTLEMENT_CIVIC_SPACES_SMOKE_OK fixtures=", physical_fixture_count, " halls=", civic.civic_hall_count())
    get_tree().quit(0)
