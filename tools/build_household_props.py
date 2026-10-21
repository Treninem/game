"""Normalize reviewed CC0 B46 household props in Blender, retaining authored UVs.

One geometry-only GLB shares the existing production trim textures at runtime.
The editable blend keeps the normalized meshes; no repeated embedded images.
"""
from pathlib import Path
import bpy
import json
import shutil
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/staging/sourcechat_b46/models/quaternius_fantasy_props_megakit_standard/Exports/glTF'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
sizes = {'Mug': (0.13, 0.16, 0.13), 'Table_Plate': (0.27, 0.035, 0.27),
         'Book_Stack_1': (0.38, 0.17, 0.25), 'Bookcase_2': (1.05, 1.75, 0.42),
         'Cabinet': (1.35, 1.9, 0.55), 'Workbench_Drawers': (1.65, 0.9, 0.65),
         'Pot_1': (0.3, 0.25, 0.3), 'FarmCrate_Apple': (0.65, 0.5, 0.5),
         'Bag': (0.45, 0.6, 0.4), 'Peg_Rack': (0.9, 0.3, 0.2),
         'SmallBottles_1': (0.36, 0.25, 0.22), 'Nightstand_Shelf': (0.55, 0.65, 0.42)}
sizes.update({'Shelf_Small_Bottles': (1.3, .65, .32), 'Table_Knife': (.04,.025,.22),
              'Table_Spoon': (.045,.025,.20), 'CandleStick_Triple': (.3,.35,.22),
              'Vase_4': (.25,.4,.25), 'Barrel': (.64,.85,.64), 'Shelf_Simple': (1.3,.35,.32)})
for name, target in sizes.items():
    # Source glTF refers to sibling texture names, while the physical pack keeps
    # them in Textures/. This export deliberately shares Godot's existing maps.
    temporary = ROOT / 'build/asset_work/household-imports'
    temporary.mkdir(parents=True, exist_ok=True)
    data = json.loads((SOURCE / (name + '.gltf')).read_text())
    data.pop('images', None)
    data.pop('textures', None)
    for entry in data.get('buffers', []):
        shutil.copy2(SOURCE / entry['uri'], temporary / entry['uri'])
    for entry in data.get('materials', []):
        for key in ('normalTexture', 'occlusionTexture', 'emissiveTexture'):
            entry.pop(key, None)
        pbr = entry.get('pbrMetallicRoughness', {})
        pbr.pop('baseColorTexture', None)
        pbr.pop('metallicRoughnessTexture', None)
    (temporary / (name + '.gltf')).write_text(json.dumps(data))
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(temporary / (name + '.gltf')))
    imported = set(bpy.data.objects) - before
    meshes = [obj for obj in imported if obj.type == 'MESH']
    hierarchy = [obj for obj in imported if obj.type != 'MESH']
    assert meshes, name
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        transform = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = transform
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    model = bpy.context.object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    points = [v.co.copy() for v in model.data.vertices]
    low = Vector(tuple(min(p[a] for p in points) for a in range(3)))
    high = Vector(tuple(max(p[a] for p in points) for a in range(3)))
    extent = high - low
    if name in ('Table_Knife', 'Table_Spoon') and extent.x > extent.y:
        for vertex in model.data.vertices:
            x, y = vertex.co.x, vertex.co.y
            vertex.co.x, vertex.co.y = -y, x
        points = [v.co.copy() for v in model.data.vertices]
        low = Vector(tuple(min(p[a] for p in points) for a in range(3)))
        high = Vector(tuple(max(p[a] for p in points) for a in range(3)))
        extent = high - low
    # Blender Z up; Godot Y up.
    limit = Vector((target[0], target[2], target[1]))
    factor = min(limit[a] / extent[a] for a in range(3) if extent[a] > 1e-6)
    center = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
    for vertex in model.data.vertices:
        vertex.co = (vertex.co - center) * factor
    model.name = name
    # Remove only unused import hierarchy nodes; preserve the joined geometry.
    for obj in hierarchy:
        if obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    # A tiny bevel gives the larger case legible edges without changing its size.
    if name == 'Bookcase_2':
        bevel = model.modifiers.new('Dressed shelf edges', 'BEVEL')
        bevel.width = 0.003
        bevel.segments = 2
        bevel.limit_method = 'ANGLE'
        bpy.ops.object.modifier_apply(modifier=bevel.name)
# Retain imported colour-attribute nodes so authored vertex colours survive.
source_dir = ROOT / 'assets/source/interiors'
source_dir.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.file_preview_type = 'NONE'
bpy.ops.wm.save_as_mainfile(filepath=str(source_dir / 'HouseholdProps.blend'))
output = ROOT / 'assets/production/interiors/architecture/HouseholdProps.glb'
bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', export_yup=True)
# Small cloth objects do not justify another full 2K material family in memory.
cloth_dir = ROOT / 'assets/production/interiors/materials'
for suffix in ('BaseColor', 'Normal', 'ORM'):
    source = SOURCE.parents[1] / 'Textures' / ('T_Trim_Cloth_' + suffix + '.png')
    image = bpy.data.images.load(str(source), check_existing=False)
    image.scale(512, 512)
    image.filepath_raw = str(cloth_dir / ('household_cloth_' + suffix + '.png'))
    image.file_format = 'PNG'
    image.save()
    bpy.data.images.remove(image)
print('HOUSEHOLD_PROPS_BUILT', output)
