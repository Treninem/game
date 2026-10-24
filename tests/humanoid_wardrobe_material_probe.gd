extends RefCounted

# Independent material contract for the new UV atlases. Legacy shirt checks
# remain in their existing tests; these maps must never resolve to that atlas.
func check(material: StandardMaterial3D, sex: String, label: String, source_albedo: Texture2D) -> Array[String]:
    var failures: Array[String] = []
    if label=="OutfitLining":
        if material.albedo_texture==null or material.albedo_texture!=source_albedo:
            failures.append("Fitted lining lost its authored cloth diffuse")
        if material.normal_enabled or material.ao_enabled:
            failures.append("Lining reuses a baked normal/AO atlas from another surface")
        if material.roughness<.9 or material.texture_filter!=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC:
            failures.append("Lining lost matte anisotropic filtering")
        if material.albedo_texture!=null and not material.albedo_texture.get_image().has_mipmaps():
            failures.append("Lining diffuse has no physical mip chain")
        return failures
    if label not in ["VikingTunic", "VikingPants", "VikingBoots"]:
        failures.append("Unknown wardrobe material: " + label)
        return failures
    var stem := "res://assets/production/characters/realistic/wardrobe/%s-%s" % [sex, label.to_lower()]
    if material.albedo_texture == null or material.albedo_texture != source_albedo:
        failures.append("Wardrobe loses its authored diffuse atlas: " + label)
    if not material.normal_enabled or material.normal_texture == null or material.normal_texture.resource_path != stem + "-normal.png":
        failures.append("Wardrobe uses missing or unrelated normal atlas: " + label)
    if not material.ao_enabled or material.ao_texture == null or material.ao_texture.resource_path != stem + "-ao.png":
        failures.append("Wardrobe uses missing or unrelated AO atlas: " + label)
    if material.roughness < 0.8 or material.ao_light_affect > 0.25 or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC:
        failures.append("Wardrobe loses matte filtering/occlusion contract: " + label)
    for texture: Texture2D in [material.albedo_texture, material.normal_texture, material.ao_texture]:
        if texture == null:
            continue
        var image := texture.get_image()
        if image == null or not image.has_mipmaps():
            failures.append("Wardrobe texture has no physical mip chain: " + label)
    return failures
