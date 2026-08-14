extends Node3D

@export var display_name: String = "Мира"

func interact(_player: Node) -> void:
    match GameState.quest_stage:
        0:
            GameState.start_quest()
        1:
            GameState.confirm_gathering()
        2:
            GameState.notify("Создайте строительный набор клавишей C, затем поставьте убежище клавишей B.")
        3:
            GameState.complete_intro_quest()
        4:
            GameState.notify("Мира: Осмотритесь вокруг. Это только начало.")
        _:
            GameState.notify("%s сейчас ничего не просит." % display_name)
