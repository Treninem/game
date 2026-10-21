"""Editable timber-and-plaster partition module, Godot metres, +Z front."""
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
materials = {}
for label, color in [('Plaster', (.66, .58, .44, 1)), ('Timber', (.25, .16, .08, 1))]:
    mat = bpy.data.materials.new(label)
    mat.diffuse_color = color
    materials[label] = mat
parts = []
def piece(name, size, center, material):
    x, y, z = center
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -z, y))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(materials[material])
    bevel = obj.modifiers.new('Worn edges', 'BEVEL')
    bevel.width = .006
    bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    parts.append(obj)
piece('Lime plaster infill', (.9, 2.72, .12), (0, 1.43, 0), 'Plaster')
for x in [-.465, .465]:
    piece('Oak post', (.07, 2.86, .16), (x, 1.43, 0), 'Timber')
for y in [.035, 2.825]:
    piece('Oak rail', (1, .07, .16), (0, y, 0), 'Timber')
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
bpy.context.object.name = 'PartitionPanel'
bpy.context.scene.cursor.location = (0, 0, 0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'assets/source/interiors/HousePartition.blend'))
bpy.ops.export_scene.gltf(filepath=str(root / 'assets/production/interiors/architecture/HousePartition.glb'), export_format='GLB', export_yup=True)
print('HOUSE_PARTITION_BUILT')
