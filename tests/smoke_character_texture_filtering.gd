extends Node

const VISUAL := preload("res://scripts/humanoid_visual.gd")
var failures: Array[String] = []
var checked: Dictionary = {}

func _ready() -> void:
    call_deferred("_run")

func _check_texture(texture: Texture2D, label: String) -> void:
    if texture == null:
        failures.append("Missing texture: " + label)
        return
    if checked.has(texture.get_instance_id()):
        return
    checked[texture.get_instance_id()] = true
    var image := texture.get_image()
    if image == null or not image.has_mipmaps():
        failures.append("Actual character texture lacks mip levels: " + label)

func _run() -> void:
    _check_texture(VISUAL.GARMENT_NORMAL, "garment normal")
    _check_texture(VISUAL.GARMENT_AO, "garment AO")
    _check_texture(VISUAL.SHOE_ALBEDO, "shoe albedo")
    for texture: Texture2D in VISUAL.EYE_TEXTURES:
        _check_texture(texture, texture.resource_path)
    if failures.is_empty():
        for preset in [0, 5]:
            var actor := CharacterBody3D.new()
            actor.set_meta("preview_animation", "Idle")
            add_child(actor)
            var visual := VISUAL.new()
            visual.appearance_profile = preload("res://scripts/character_appearance.gd").preset(preset)
            actor.add_child(visual)
            for mesh: MeshInstance3D in visual.model.find_children("*", "MeshInstance3D", true, false):
                for surface in range(mesh.mesh.get_surface_count()):
                    var material := mesh.get_active_material(surface)
                    if material is StandardMaterial3D:
                        if String(material.resource_name).begins_with("Viking"):
                            var authored := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
                            failures.append_array(preload("res://tests/humanoid_wardrobe_material_probe.gd").new().check(material, String(visual.current_profile.sex), String(material.resource_name), authored.albedo_texture))
                            _check_texture(material.albedo_texture, "wardrobe diffuse")
                            _check_texture(material.ao_texture, "wardrobe AO")
                        elif material.resource_name=="OutfitLining":
                            var authored := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
                            failures.append_array(preload("res://tests/humanoid_wardrobe_material_probe.gd").new().check(material,String(visual.current_profile.sex),String(material.resource_name),authored.albedo_texture))
                            _check_texture(material.albedo_texture,"lining cloth diffuse")
                        elif String(mesh.name) == "Clothing":
                            if material.albedo_texture != null or not material.ao_enabled or material.ao_texture != VISUAL.GARMENT_AO:
                                failures.append("Garment AO is painted into base color or loses actual occlusion")
                            if not material.normal_enabled or material.normal_texture != VISUAL.GARMENT_NORMAL or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC:
                                failures.append("Garment loses authored normals or anisotropic filtering")
                            _check_texture(material.ao_texture, "actual garment AO")
                        else:
                            _check_texture(material.albedo_texture, String(mesh.name))
                        if material.normal_enabled:
                            _check_texture(material.normal_texture, "actual garment normal")
                    elif material is ShaderMaterial:
                        if String(mesh.name) == "Eyes":
                            if material.shader != VISUAL.EYE_SHADER: failures.append("Unexpected eye shader")
                            _check_texture(material.get_shader_parameter("eye_texture"), "actual eye atlas")
                        else:
                            _check_texture(material.get_shader_parameter("hair_texture"), String(mesh.name))
            actor.queue_free()
            await get_tree().process_frame
    for failure in failures:
        push_error(failure)
    if failures.is_empty():
        print("CHARACTER_TEXTURE_FILTERING_OK bodies=2 textures=", checked.size(), " mip_levels=physical")
    get_tree().quit(0 if failures.is_empty() else 1)
