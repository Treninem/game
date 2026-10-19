"""Repair a physically staged CC0 tree's missing legacy materials and normalize it."""
import bpy, json, struct, shutil, random
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/staging/sourcechat_b44/models/oga_free_vegetation_lod_pack'
BARK=ROOT/'assets/staging/sourcechat_b44/models/quaternius_stylized_nature_megakit_standard/glTF/Bark_NormalTree.png'
DEST=ROOT/'assets/production/nature/temperate';DEST.mkdir(parents=True,exist_ok=True)

def force_cutout(path):
    content=path.read_bytes();length=struct.unpack_from('<I',content,12)[0]
    data=json.loads(content[20:20+length])
    for material in data.get('materials',[]):
        if material.get('name','').startswith('Leaves'):
            material.update(alphaMode='MASK',alphaCutoff=.45,doubleSided=True)
    encoded=json.dumps(data,separators=(',',':')).encode()
    encoded+=b' '*((-len(encoded))%4)
    remainder=content[20+length:]
    total=12+8+len(encoded)+len(remainder)
    path.write_bytes(struct.pack('<4sII',b'glTF',2,total)+struct.pack('<I4s',len(encoded),b'JSON')+encoded+remainder)

def prepare(name,filename,height,leaf_image='branches_small_leaves.png'):
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'free_vegetation_pack.blend'))
    tree=bpy.data.objects[name]
    for obj in list(bpy.data.objects):
        if obj!=tree:
            bpy.data.objects.remove(obj,do_unlink=True)
    for modifier in list(tree.modifiers):
        if modifier.type=='PARTICLE_SYSTEM':
            tree.modifiers.remove(modifier)
    tree.data.materials.clear()
    for name,image_path,leaves in [('Bark_Temperate',BARK,False),('Leaves_Temperate',SOURCE/'textures'/leaf_image,True)]:
        material=bpy.data.materials.new(name);material.use_nodes=True
        bsdf=material.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Roughness'].default_value=.94
        texture=material.node_tree.nodes.new('ShaderNodeTexImage')
        texture.image=bpy.data.images.load(str(image_path))
        material.node_tree.links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
        if leaves:
            material.node_tree.links.new(texture.outputs['Alpha'],bsdf.inputs['Alpha'])
            material.surface_render_method='DITHERED'
            material.use_backface_culling=False
        tree.data.materials.append(material)
    neighbors={vertex.index:set() for vertex in tree.data.vertices}
    for edge in tree.data.edges:
        a,b=edge.vertices;neighbors[a].add(b);neighbors[b].add(a)
    component_size={}
    for vertex in neighbors:
        if vertex in component_size:
            continue
        stack=[vertex];component=set()
        while stack:
            current=stack.pop()
            if current in component:
                continue
            component.add(current);stack.extend(neighbors[current]-component)
        for current in component:
            component_size[current]=len(component)
    leaves=0
    for polygon in tree.data.polygons:
        is_leaf=component_size[polygon.vertices[0]]<=4
        polygon.material_index=1 if is_leaf else 0
        polygon.use_smooth=not is_leaf
        leaves+=int(is_leaf)
    # Retain the authored branch cards, with seeded nearby layers for a fuller
    # living canopy. The lower-detail mesh uses fewer layers of the same cards.
    original=tree.data
    vertices=[vertex.co.copy() for vertex in original.vertices]
    faces=[list(polygon.vertices) for polygon in original.polygons]
    uvs=[[original.uv_layers.active.data[loop].uv.copy() for loop in polygon.loop_indices] for polygon in original.polygons]
    materials=[polygon.material_index for polygon in original.polygons]
    smooth=[polygon.use_smooth for polygon in original.polygons]
    randomizer=random.Random(260819)
    for polygon in original.polygons:
        if polygon.material_index!=1:
            continue
        center=sum((original.vertices[index].co for index in polygon.vertices),Vector())/len(polygon.vertices)
        for layer in range(2 if filename=='TemperateTree.glb' else 1):
            rotation=Matrix.Rotation(randomizer.uniform(-.55,.55),3,'Z')
            offset=Vector((randomizer.uniform(-.75,.75),randomizer.uniform(-.75,.75),randomizer.uniform(-.35,.35)))
            face=[]
            for index in polygon.vertices:
                face.append(len(vertices));vertices.append(center+rotation@(original.vertices[index].co-center)+offset)
            faces.append(face)
            uvs.append([original.uv_layers.active.data[loop].uv.copy() for loop in polygon.loop_indices])
            materials.append(1);smooth.append(False)
    rebuilt=bpy.data.meshes.new('TemperateCanopy')
    rebuilt.from_pydata(vertices,[],faces)
    for material in original.materials:
        rebuilt.materials.append(material)
    uv_layer=rebuilt.uv_layers.new(name='UVMap')
    for index,polygon in enumerate(rebuilt.polygons):
        polygon.material_index=materials[index];polygon.use_smooth=smooth[index]
        for loop,uv in zip(polygon.loop_indices,uvs[index]):
            uv_layer.data[loop].uv=uv
    tree.data=rebuilt
    points=[tree.matrix_world@vertex.co for vertex in tree.data.vertices]
    low=min(point.z for point in points);high=max(point.z for point in points)
    base=[point for point in points if point.z<low+(high-low)*.01]
    center=sum(base,Vector())/len(base)
    normal=bpy.data.objects.new('GroundedTemperateTree',None);bpy.context.collection.objects.link(normal)
    tree.parent=normal
    scale=height/(high-low);normal.scale=(scale,scale,scale)
    normal.location=(-center.x*scale,-center.y*scale,-low*scale)
    output=DEST/filename
    bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',export_animations=False)
    force_cutout(output)
    print('TEMPERATE_TREE_PREPARED',filename,'height',height,'leaf_cards',leaves,'vertices',len(tree.data.vertices))

prepare('tree_leaves_particles_higher','TemperateTree.glb',12)
prepare('tree_leaves_particles_lod_1','TemperateTree_LOD.glb',12)
prepare('tree_leaves_higher','TemperateTree_Broad.glb',11,'branches_leaves.png')
prepare('bush_higher','TemperateBush.glb',1.8,'leaf_small.png')
shutil.copy2(SOURCE/'LICENSE.txt',DEST/'LICENSE.txt')
(DEST/'SOURCE.md').write_text('CC0 Free Vegetation Asset Pack with LOD, existing assets/staging/sourcechat_b44/models/oga_free_vegetation_lod_pack. Original authored tree meshes and branches_small_leaves.png, with seeded nearby card layers for a fuller canopy. Missing legacy Blender materials restored by connected-component leaf-card classification. Bark reuses the existing CC0 Quaternius Stylized Nature MegaKit Bark_NormalTree texture. Near mesh and authored LOD normalized to 12 m with grounded trunk pivots. Runtime requires the shared foliage_wind.gdshader black_key cutout for the original branch texture. Reproduce with tools/prepare_temperate_tree.py.\n',encoding='utf-8')
with (DEST/'SOURCE.md').open('a',encoding='utf-8') as provenance:
    provenance.write('\nTemperateTree_Broad.glb selects the same pack\'s authored tree_leaves_higher mesh and original branches_leaves.png, normalized to 11 m. INTEGRATED in the near-start forest; no new download or generated replacement texture.\n')

# Runtime restores the original pack texture on the preserved UVs.
shutil.copy2(SOURCE/'textures/bark.JPG', DEST/'bark_albedo.jpg')
with (DEST/'SOURCE.md').open('a', encoding='utf-8') as provenance:
    provenance.write('\nRuntime surface follow-up, 2026-10-20: INTEGRATED original CC0 `textures/bark.JPG` from this same Free Vegetation pack as `bark_albedo.jpg` (byte-identical copy). `production_nature.gd` restores it on Bark_Temperate surfaces using original UVs and shared materials; embedded stylized bark remains a fallback. Explicit mipmaps and anisotropic filtering; no generated normal/PBR channel. The preparation tool also copies this external runtime texture.\n')

with (DEST/'SOURCE.md').open('a', encoding='utf-8') as provenance:
    provenance.write('\nNear-forest correction, 2026-10-20: INTEGRATED `TemperateBush.glb` from the same packs authored `bush_higher`, normalized to 1.8 m with grounded pivot. Uses original `leaf_small.png` on individual leaf cards; the first branch-atlas trial was rejected after native inspection. Existing CC0 license retained; no new download or generated bitmap. Near trees now use the two compatible temperate models; the stylized pine remains available to the taiga system.\n')
