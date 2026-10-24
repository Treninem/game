extends "res://tests/visual_human_street_scale.gd"
func _run()->void:
    var report:Dictionary={"same_physical_scale":true,"manual_play":false}
    await _palette(report)
    assert(report.palette_rendered_at_same_scale==15)
    var palette:=preload("res://scripts/street_surface_palette.gd")
    for index in range(1000):palette.material(index)
    assert(palette.cache.size()==15,"Per-cell street materials grow without a bound")
    var file:=FileAccess.open("user://street-surface-palette.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("STREET_SURFACE_PALETTE_OK ",JSON.stringify(report));quit(0)
