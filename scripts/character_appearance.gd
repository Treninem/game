extends RefCounted

const VERSION := 1
const MIN_HEIGHT_CM := 160.0
const MAX_HEIGHT_CM := 200.0
const DEFAULT_HEIGHT_CM := 180.0
const SHAPES := ["HeadSize", "FaceWidth", "FaceHeight", "FaceDepth", "Nose", "NoseWidth", "NoseHeight", "Jaw", "Build"]
const SKINS := [Color(1, 0.97, 0.94), Color(0.85, 0.73, 0.62), Color(0.62, 0.45, 0.33)]
const HAIR := [Color(0.65, 0.48, 0.33), Color(0.24, 0.15, 0.10), Color(0.86, 0.72, 0.45), Color(0.58, 0.24, 0.11), Color(0.68, 0.67, 0.61)]
const CLOTH := [Color(0.34, 0.26, 0.14), Color(0.16, 0.24, 0.17), Color(0.19, 0.22, 0.29), Color(0.36, 0.17, 0.12), Color(0.39, 0.36, 0.29)]

static func preset(index: int) -> Dictionary:
    index = clampi(index, 0, 9)
    var variation := index % 5
    return {"version": VERSION, "name": "Странница" if index >= 5 else "Странник", "sex": "female" if index >= 5 else "male", "preset": index, "hair": 1 if index >= 5 else 0, "hair_color": variation, "skin": variation % 3, "cloth": variation, "eye_color": 0, "height_cm": DEFAULT_HEIGHT_CM, "FaceWidth": [-0.25, 0.18, 0.38, -0.12, 0.05][variation], "Nose": [-0.20, 0.35, -0.05, 0.18, 0.42][variation], "Jaw": [-0.20, 0.35, 0.10, -0.35, 0.40][variation], "Build": [-0.20, 0.12, 0.40, -0.35, 0.05][variation], "HeadSize": 0.0, "FaceHeight": 0.0, "FaceDepth": 0.0, "NoseWidth": 0.0, "NoseHeight": 0.0}

static func normalized(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_DICTIONARY:
        return preset(0)
    var result := preset(5 if value.get("sex") == "female" else 0)
    var text := String(value.get("name", result.name)) if typeof(value.get("name", "")) == TYPE_STRING else String(result.name)
    result.name = text.strip_edges().replace("\n", " ").replace("\r", " ").left(32)
    if String(result.name).is_empty():
        result.name = "Странница" if result.sex == "female" else "Странник"
    result["eye_color"] = 0
    for key in ["preset", "hair", "hair_color", "skin", "cloth", "eye_color"]:
        var number = value.get(key, result[key])
        if typeof(number) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(number)):
            result[key] = clampi(int(number), 0, {"preset": 9, "hair": 1, "hair_color": 4, "skin": 2, "cloth": 4, "eye_color": 4}[key])
    for key in SHAPES:
        var number = value.get(key, result[key])
        if typeof(number) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(number)):
            result[key] = clampf(float(number), -0.5, 0.5)
    var height_value = value.get("height_cm", DEFAULT_HEIGHT_CM)
    if typeof(height_value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(height_value)):
        result.height_cm = clampf(float(height_value), MIN_HEIGHT_CM, MAX_HEIGHT_CM)
    return result

static func save_look(profile: Dictionary) -> Error:
    var config := ConfigFile.new()
    config.set_value("appearance", "profile", normalized(profile))
    return config.save("user://character_look.cfg")

static func load_look() -> Dictionary:
    var config := ConfigFile.new()
    if config.load("user://character_look.cfg") != OK:
        return {}
    return normalized(config.get_value("appearance", "profile", {}))
