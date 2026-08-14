extends Node3D

@export var display_name: String = "Мира"

func interact(_player: Node) -> void:
    match GameState.quest_stage:
        0:
            DialogueManager.open_dialogue(
                display_name,
                "Ты выглядишь так, будто только что добрался сюда. Если собираешься выжить, начни с простого убежища.",
                [
                    {"text": "Что мне нужно сделать?", "action": "start_quest"},
                    {"text": "Сначала осмотрюсь.", "action": "close"}
                ]
            )
        1:
            DialogueManager.open_dialogue(
                display_name,
                "Удалось собрать древесину и камень?",
                [
                    {"text": "Да, проверь материалы.", "action": "confirm_gathering"},
                    {"text": "Пока нет.", "action": "close"}
                ]
            )
        2:
            DialogueManager.open_dialogue(
                display_name,
                "Материалы есть. Теперь открой меню крафта и собери строительный набор, затем установи убежище.",
                [{"text": "Понял.", "action": "close"}]
            )
        3:
            DialogueManager.open_dialogue(
                display_name,
                "Вижу, убежище уже стоит. Хорошая работа.",
                [
                    {"text": "Что дальше?", "action": "complete_intro"},
                    {"text": "Вернусь позже.", "action": "close"}
                ]
            )
        4:
            DialogueManager.open_dialogue(
                display_name,
                "Теперь у тебя есть крыша над головой и инструмент. Исследуй окрестности, собирай припасы и будь осторожен ночью.",
                [{"text": "Хорошо.", "action": "close"}]
            )
        _:
            DialogueManager.open_dialogue(display_name, "Сейчас у меня нет для тебя новых поручений.", [{"text": "До встречи.", "action": "close"}])
