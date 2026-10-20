extends Node

signal dialogue_opened(speaker: String, text: String, options: Array)
signal dialogue_closed

var is_open := false
var speaker := ""
var text := ""
var options: Array = []
var dialogue_revision := 0

func open_dialogue(p_speaker: String, p_text: String, p_options: Array = []) -> void:
    dialogue_revision += 1
    speaker = p_speaker
    text = p_text
    options = p_options.duplicate(true)
    is_open = true
    dialogue_opened.emit(speaker, text, options)

func close_dialogue() -> void:
    if not is_open:
        return
    is_open = false
    dialogue_revision += 1
    speaker = ""
    text = ""
    options = []
    dialogue_closed.emit()

func choose(index: int, quantity: int = -1, expected_revision: int = -1) -> void:
    if not is_open or index < 0 or index >= options.size() or (expected_revision != -1 and expected_revision != dialogue_revision):
        return
    var option = options[index]
    if typeof(option) != TYPE_DICTIONARY:
        close_dialogue()
        return
    var action := String(option.get("action", "close"))
    if quantity != -1 and (action != "furniture_transfer" or not option.has("quantity_max") or quantity < 1 or quantity > int(option.quantity_max)):
        GameState.notify("Укажите количество в доступном диапазоне.")
        return
    match action:
        "furniture_transfer":
            var furniture := instance_from_id(int(option.get("furniture", 0))) as Node
            var actor := get_tree().get_first_node_in_group("player") as Node3D
            if is_instance_valid(furniture) and furniture.is_inside_tree() and furniture.has_method("transfer"):
                var amount := quantity if quantity != -1 else int(option.get("amount", 1))
                if not furniture.call("transfer", actor, String(option.get("item", "")), bool(option.get("deposit", false)), amount):
                    GameState.notify("Перенос недоступен: проверьте запас, место в сундуке и доступ к нему.")
                furniture.call("open_storage", actor)
            else:
                close_dialogue()
        "merchant_trade":
            var merchant := instance_from_id(int(option.get("merchant", 0))) as Node
            if is_instance_valid(merchant) and merchant.is_inside_tree() and merchant.has_method("complete_trade"):
                merchant.call("complete_trade", String(option.get("item", "")), bool(option.get("sell", false)))
            else:
                close_dialogue()
        "start_quest":
            GameState.start_quest()
            open_dialogue("Мира", "Хорошо. Принеси мне 8 единиц древесины и 4 камня. Эти материалы нужны для первого убежища.", [{"text": "Я вернусь с материалами.", "action": "close"}])
        "confirm_gathering":
            if GameState.confirm_gathering():
                open_dialogue("Мира", "Отлично. Теперь собери строительный набор. Рецепт уже доступен в меню крафта.", [{"text": "Понял.", "action": "close"}])
            else:
                open_dialogue("Мира", "Материалов пока не хватает. Проверь журнал задания — там указано точное количество.", [{"text": "Продолжу поиски.", "action": "close"}])
        "complete_intro":
            if GameState.complete_intro_quest():
                open_dialogue("Мира", "Убежище готово. Возьми этот топор. Южные ворота Люменграда уже рядом — там найдёшь работу и новых людей.", [{"text": "Отправляюсь в город.", "action": "close"}])
            else:
                close_dialogue()
        "start_city_quest":
            if CityQuestSystem.start_city_quest():
                open_dialogue("Радан", "Материалы нужны крепкие: 6 камня и 4 древесины. Вернёшься — сразу пущу их на ремонт ворот.", [{"text": "Сделаю.", "action": "close"}])
            else:
                close_dialogue()
        "complete_city_quest":
            if CityQuestSystem.complete_city_quest():
                open_dialogue("Радан", "Вот это дело. Скобы и подпорки подготовлю сам. Держи оплату — 35 монет. Стража запомнит, кто помог Южному кварталу.", [{"text": "Рад помочь.", "action": "close"}])
            else:
                open_dialogue("Радан", "Материалов не хватает. Нужно 6 камня и 4 древесины.", [{"text": "Вернусь позже.", "action": "close"}])
        _:
            close_dialogue()
