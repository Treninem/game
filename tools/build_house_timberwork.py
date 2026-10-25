"""Blender-authored room timber kit for the user's 2026-10-21 house concept.

Default envelope 12 x 10 x 3.2m, +Z front. Existing house collision remains
authoritative; exposed beams receive their own triangle collision in Godot.
"""
from pathlib import Path
import bpy
import math

ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
material = bpy.data.materials.new('Timber')
material.diffuse_color = (0.3, 0.2, 0.11, 1)
members = []

def beam(name, dimensions, position, angle=0):
    x, y, z = position
    sx, sy, sz = dimensions
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -z, y))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (sx, sz, sy)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    modifier = obj.modifiers.new('Dressed timber edges', 'BEVEL')
    modifier.width = 0.012
    modifier.segments = 2
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    axis = max(range(3), key=lambda a: obj.dimensions[a])
    for polygon in obj.data.polygons:
        other = next(a for a in range(3) if a != axis and abs(polygon.normal[a]) < 0.5)
        for loop in polygon.loop_indices:
            co = obj.data.vertices[obj.data.loops[loop].vertex_index].co
            axes = [a for a in range(3) if a != axis] if abs(polygon.normal[axis]) > 0.7 else [other, axis]
            obj.data.uv_layers.active.data[loop].uv = (co[axes[0]] * 0.5, co[axes[1]] * 0.5)
    obj.rotation_euler.y = math.radians(angle)
    members.append(obj)

for x in (-5.55, 5.55):
    for z in (-4.55, 4.55):
        beam('CornerPost', (0.18, 2.85, 0.18), (x, 1.605, z))
        beam('KneeBrace', (0.12, 0.85, 0.13), (x - math.copysign(0.30, x), 2.60, z), math.copysign(45, x))
for z in (-3.0, 0.0, 3.0):
    beam('CeilingTie', (11.45, 0.17, 0.18), (0, 2.955, z))
for z in (-4.59, 4.59):
    beam('WallPlate', (11.25, 0.15, 0.12), (0, 2.88, z))
for x in (-5.59, 5.59):
    beam('WallPlate', (0.12, 0.15, 9.20), (x, 2.88, 0))
bpy.ops.object.select_all(action='DESELECT')
for obj in members:
    obj.select_set(True)
bpy.context.view_layer.objects.active = members[0]
bpy.ops.object.join()
bpy.context.object.name = 'RoomTimberwork'
bpy.context.scene.cursor.location = (0, 0, 0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
output = ROOT / 'assets/production/interiors/architecture/RoomTimberwork.glb'
output.parent.mkdir(parents=True, exist_ok=True)
work = ROOT / 'assets/source/interiors'
work.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.ops.wm.save_as_mainfile(filepath=str(work / 'RoomTimberwork.blend'))
bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', export_yup=True)
print('HOUSE_TIMBERWORK_BUILT', output)
