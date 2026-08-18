extends SceneTree

const READINESS := preload("res://scripts/world_loading_readiness.gd")

func _initialize() -> void:
    var integer_cases := [
        [null, 7],
        [true, 1],
        [false, 0],
        [42, 42],
        [3.9, 3],
        ["12", 12],
        ["2.5", 2],
        ["not-a-number", 7],
        [[], 7],
        [{"value": 12}, 7]
    ]
    for case: Array in integer_cases:
        var actual := READINESS._safe_int_variant(case[0], case[1])
        if actual != case[1]:
            push_error("safe int conversion failed: value=%s expected=%s actual=%s" % [case[0], case[1], actual])
            quit(2)
            return

    var ratio_cases := [
        [null, 0.0],
        [true, 1.0],
        [false, 0.0],
        [0.5, 0.5],
        [-4.0, 0.0],
        [4.0, 1.0],
        ["0.25", 0.25],
        ["invalid", 0.0],
        [INF, 0.0],
        [NAN, 0.0]
    ]
    for case: Array in ratio_cases:
        var actual := READINESS._safe_ratio(case[0], 0.0)
        if absf(actual - float(case[1])) > 0.0001:
            push_error("safe ratio conversion failed: value=%s expected=%s actual=%s" % [case[0], case[1], actual])
            quit(3)
            return

    print("WORLD_LOADING_READINESS_TEST_PASS")
    quit(0)
