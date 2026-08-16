class_name MenuRuntimeAssets
extends RefCounted

# Kenney UI Pack Adventure button_brown.png (CC0), embedded as PNG bytes so the
# stable build does not depend on an editor import sidecar for this tiny UI asset.
const BUTTON_PNG_B64 := "iVBORw0KGgoAAAANSUhEUgAAADAAAAAYCAMAAACLI47uAAAABGdBTUEAALGPC/xhBQAAAEJQTFRFbUombUonbUslZkQibkonbEomAAAAbEombUwmbEsnbUsmom867NOt+unIelQrnWw4q3U9h10wmWk3tHtBbUsn//HS9emmsQAAAAt0Uk5Tn9+PD09/AK8vv+8o51UPAAAAgElEQVQ4y+2UOxKAIAxE4w8IKh+z3v+qoiOOFdDZ+KpMZl+6LKmhZ8aJHkeNEsz9oMjYZ2EtalhDGs7PchKBKCVm76AJCHkRy/lEAJIgsuxNLCK3sDfyC7/wvbC25ddL6OBrb7NtefLoiOBCJQ/cRnCgdwk0kEpAGa6FpikfZaMO+7RZD0HnG/YAAAAASUVORK5CYII="

static func button_texture() -> Texture2D:
    var bytes := Marshalls.base64_to_raw(BUTTON_PNG_B64)
    var image := Image.new()
    if image.load_png_from_buffer(bytes) != OK:
        push_error("ImPuls menu button texture could not be decoded")
        return null
    return ImageTexture.create_from_image(image)

static func hover_sound() -> AudioStreamWAV:
    return _tone(620.0, 0.035, 0.20)

static func click_sound() -> AudioStreamWAV:
    return _tone(360.0, 0.060, 0.28)

static func _tone(frequency: float, duration: float, gain: float) -> AudioStreamWAV:
    const RATE := 22050
    var frames := maxi(1, roundi(float(RATE) * duration))
    var data := PackedByteArray()
    data.resize(frames * 2)
    for index in range(frames):
        var t := float(index) / float(RATE)
        var phase := TAU * frequency * t
        var envelope := pow(maxf(0.0, 1.0 - float(index) / float(frames)), 3.0)
        # Add a quiet octave to make the tiny signal feel like a physical UI tap.
        var value := (sin(phase) + sin(phase * 2.0) * 0.18) * envelope * gain
        var sample := int(clampf(value, -1.0, 1.0) * 32767.0)
        var unsigned := sample & 0xffff
        data[index * 2] = unsigned & 0xff
        data[index * 2 + 1] = (unsigned >> 8) & 0xff
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = data
    return stream
