class_name EmbeddedUITexture
extends RefCounted

static func load_webp_parts(prefix: String, part_count: int) -> Texture2D:
    var encoded := ""
    for index in range(part_count):
        var path := "%s.%02d.txt" % [prefix, index]
        if not FileAccess.file_exists(path):
            push_error("Embedded UI texture part missing: %s" % path)
            return null
        var file := FileAccess.open(path, FileAccess.READ)
        if file == null:
            push_error("Embedded UI texture part cannot be opened: %s" % path)
            return null
        encoded += file.get_as_text().strip_edges()
    var bytes := Marshalls.base64_to_raw(encoded)
    if bytes.is_empty():
        push_error("Embedded UI texture data is empty: %s" % prefix)
        return null
    var image := Image.new()
    var err := image.load_webp_from_buffer(bytes)
    if err != OK:
        push_error("Embedded UI WebP decode failed: %s" % err)
        return null
    return ImageTexture.create_from_image(image)
