extends RefCounted

# Metres per individual stone/brick, rather than an image stretched over a road.
# All photographs already exist in the shared CC0 production ground family.
const TYPES: Array[Dictionary]=[
 {"id":"small_setts","name":"Мелкая серая брусчатка","unit":Vector2(.16,.12),"layout":0,"tint":Color(.66,.66,.63)},
 {"id":"large_setts","name":"Крупная брусчатка","unit":Vector2(.32,.24),"layout":0,"tint":Color(.70,.69,.64)},
 {"id":"diagonal_setts","name":"Диагональная брусчатка","unit":Vector2(.24,.16),"layout":2,"tint":Color(.62,.64,.64)},
 {"id":"granite_rows","name":"Гранитные ряды","unit":Vector2(.24,.12),"layout":1,"tint":Color(.57,.60,.62)},
 {"id":"sandstone_rows","name":"Песчаник","unit":Vector2(.48,.24),"layout":0,"tint":Color(.78,.68,.52)},
 {"id":"limestone_flags","name":"Известняковые плиты","unit":Vector2(.80,.48),"layout":0,"tint":Color(.79,.77,.68)},
 {"id":"slate_flags","name":"Сланцевые плиты","unit":Vector2(.64,.32),"layout":0,"tint":Color(.45,.49,.52)},
 {"id":"brick_bond","name":"Кирпич в перевязку","unit":Vector2(.24,.12),"layout":0,"tint":Color(.73,.44,.32)},
 {"id":"basket_bond","name":"Паркетная кирпичная кладка","unit":Vector2(.24,.12),"layout":3,"tint":Color(.68,.50,.37)},
 {"id":"rounded_cobbles","name":"Окатанный булыжник","unit":Vector2(.24,.24),"layout":4,"tint":Color(.64,.61,.54)},
 {"id":"square_flags","name":"Квадратные плиты двора","unit":Vector2(.48,.48),"layout":1,"tint":Color(.73,.72,.67)},
 {"id":"edge_setts","name":"Поперечная укладка узких камней","unit":Vector2(.12,.32),"layout":1,"tint":Color(.61,.60,.56)},
 {"id":"gravel_lane","name":"Гравийная дорожка","unit":Vector2.ONE,"layout":5,"tint":Color(.83,.77,.66),"photo":"road_gravel.png"},
 {"id":"earth_lane","name":"Утоптанный грунт","unit":Vector2.ONE,"layout":5,"tint":Color(.90,.82,.68),"photo":"road_soil.png"},
 {"id":"gravel_soil_mix","name":"Гравий с землёй","unit":Vector2.ONE,"layout":6,"tint":Color(.82,.76,.64),"photo":"road_gravel.png"}
]
static var cache:Dictionary={}
static func material(index:int)->ShaderMaterial:
    index=posmod(index,TYPES.size())
    if cache.has(index):return cache[index]
    var spec:Dictionary=TYPES[index]
    var result:=ShaderMaterial.new();result.resource_name=String(spec.id)
    result.shader=preload("res://assets/shaders/environment/street_paving.gdshader")
    result.set_shader_parameter("stone_texture",load("res://assets/production/materials/ground/"+String(spec.get("photo","lichen_rock.jpg"))))
    if index==14:result.set_shader_parameter("blend_texture",load("res://assets/production/materials/ground/road_soil.png"))
    result.set_shader_parameter("unit_m",spec.unit);result.set_shader_parameter("layout",spec.layout)
    result.set_shader_parameter("pigment",spec.tint);result.set_shader_parameter("grain_scale",3.0 if index>=12 else 1.7)
    result.set_shader_parameter("joint_m",.008 if index<10 else .012)
    cache[index]=result;return result
static func index_for(cell:Vector2i,offset:int=0)->int:
    return posmod(cell.x*7+cell.y*11+offset,TYPES.size())
