"""Project-authored rectangular house window. Run with Blender --background --python.

Existing city-pack windows include entire rounded wall modules; this assembly fits
the existing rectangular physical openings without replacing their collision shell.
Godot dimensions are metres, local +Z faces the room. No external asset downloads.
"""
import bpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
wood = bpy.data.materials.new('Timber')
wood.diffuse_color = (0.32, 0.20, 0.11, 1)
pieces = []

def timber(name, size, position):
    x, y, z = position
    sx, sy, sz = size
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -z, y))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (sx, sz, sy)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(wood)
    bevel = obj.modifiers.new('Soft worn edges', 'BEVEL')
    bevel.width = min(0.012, min(size) * 0.15)
    bevel.segments = 2
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    # Preserve real dimensions in the grain, and run grain along each member.
    axis = max(range(3), key=lambda a: obj.dimensions[a])
    for polygon in obj.data.polygons:
        other = next(a for a in range(3) if a != axis and abs(polygon.normal[a]) < 0.5)
        for loop_index in polygon.loop_indices:
            co = obj.data.vertices[obj.data.loops[loop_index].vertex_index].co
            axes = [a for a in range(3) if a != axis] if abs(polygon.normal[axis]) > 0.7 else [other, axis]
            obj.data.uv_layers.active.data[loop_index].uv = (co[axes[0]] * 0.5, co[axes[1]] * 0.5)
    pieces.append(obj)

for x in (-0.675, 0.675):
    timber('Jamb', (0.09, 1.24, 0.34), (x, 0, 0))
for y in (-0.575, 0.575):
    timber('Rail', (1.35, 0.09, 0.34), (0, y, 0))
timber('Mullion', (0.042, 1.06, 0.075), (0, 0, 0.025))
timber('Transom', (1.26, 0.042, 0.075), (0, 0, 0.025))
timber('Sill', (1.60, 0.075, 0.52), (0, -0.63, 0.10))
timber('Apron', (1.40, 0.09, 0.055), (0, -0.70, 0.165))
bpy.ops.object.select_all(action='DESELECT')
for obj in pieces:
    obj.select_set(True)
bpy.context.view_layer.objects.active = pieces[0]
bpy.ops.object.join()
bpy.context.object.name = 'TimberFrame'
bpy.context.scene.cursor.location = (0, 0, 0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
mesh = bpy.data.meshes.new('SinglePane')
mesh.from_pydata([(-0.63, 0, -0.53), (0.63, 0, -0.53), (0.63, 0, 0.53), (-0.63, 0, 0.53)], [], [(0, 1, 2, 3)])
pane = bpy.data.objects.new('Glass', mesh)
bpy.context.collection.objects.link(pane)
output = ROOT / 'assets/production/interiors/architecture/TimberWindow.glb'
output.parent.mkdir(parents=True, exist_ok=True)
work = ROOT / 'assets/source/interiors'
work.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.ops.wm.save_as_mainfile(filepath=str(work / 'TimberWindow.blend'))
bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', export_yup=True)
print('INTERIOR_WINDOW_BUILT', output)
