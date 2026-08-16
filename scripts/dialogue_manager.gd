extends Node

signal dialogue_opened(speaker: String, text: String, options: Array)
signal dialogue_closed

var is_open := false
var speaker := ""
var text := ""
var options: Array = []

func open_dialogue(p_speaker: String, p_text: String, p_options: Array = []) -> void:
    speaker = p_speaker
    text = p_text
    options = p_options.duplicate(true)
    is_open = true
    dialogue_opened.emit(speaker, text, options)

func close_dialogue() -> void:
    if not is_open:
        return
    is_open = false
    speaker = ""
    text = ""
    options = []
    dialogue_closed.emit()

func choose(index: int) -> void:
    if not is_open or index < 0 or index >= options.size():
        return
    var option = options[index]
    if typeof(option) != TYPE_DICTIONARY:
        close_dialogue()
        return
    var action := String(option.get("action", "close"))
    match action:
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
