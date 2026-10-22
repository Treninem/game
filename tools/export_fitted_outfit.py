"""Factory-Blender export of the portable default outfit, without its redundant shell.

The first migration records the accepted outer triangulation inside the .blend.
Later exports preserve it even when Blender retessellates quads after removing
the lining. Default output is an isolated build folder, never live production.
"""
from pathlib import Path
import os, sys, json, gzip, base64, struct
import bpy

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from validate_outfit_revision import GLB, vertex_match
OUT=Path(os.environ.get('IMPULS_CHARACTER_OUTPUT',str(ROOT/'build/asset_work/shell-only-review')))
SOURCE=ROOT/'assets/source/characters/fitted_outfit'
OUT.mkdir(parents=True,exist_ok=True)
REFERENCE='accepted_outer_triangulation_v1'

def remove_shell(garment):
    old=garment.data
    selected=[p for p in old.polygons if old.materials[p.material_index].name!='OutfitLining']
    assert 0<len(selected)<len(old.polygons)
    used=sorted({i for p in selected for i in p.vertices});remap={i:j for j,i in enumerate(used)}
    keys=[(k.name,[k.data[i].co.copy() for i in used],k.slider_min,k.slider_max,k.value) for k in old.shape_keys.key_blocks]
    groups=[[(g.group,g.weight) for g in old.vertices[i].groups] for i in used]
    names=[g.name for g in garment.vertex_groups]
    uv={layer.name:[[layer.data[i].uv.copy() for i in p.loop_indices] for p in selected] for layer in old.uv_layers}
    roles=sorted({p.material_index for p in selected});role_map={v:i for i,v in enumerate(roles)}
    data=bpy.data.meshes.new('Authored outer outfit')
    data.from_pydata(keys[0][1],[],[[remap[i] for i in p.vertices] for p in selected])
    for role in roles:data.materials.append(old.materials[role])
    for p,source in zip(data.polygons,selected):p.material_index=role_map[source.material_index];p.use_smooth=source.use_smooth
    for label,polygons in uv.items():
        layer=data.uv_layers.new(name=label)
        for p,values in zip(data.polygons,polygons):
            for i,value in zip(p.loop_indices,values):layer.data[i].uv=value
    garment.data=data
    for name in names:garment.vertex_groups.new(name=name)
    for i,values in enumerate(groups):
        for group,weight in values:garment.vertex_groups[group].add([i],weight,'REPLACE')
    for name,points,minimum,maximum,value in keys:
        k=garment.shape_key_add(name=name);k.slider_min=minimum;k.slider_max=maximum;k.value=value
        for p,value in zip(k.data,points):p.co=value
    data.update()
    result={'removed_inner_faces':len(old.polygons)-len(selected),'removed_inner_vertices':len(old.vertices)-len(used)}
    assert old.users==0;bpy.data.meshes.remove(old)
    return result

def reference(path):
    g=GLB(path);result={}
    for p in g.meshes()['Clothing']['primitives']:
        role=g.data['materials'][p['material']]['name']
        if role=='OutfitLining':continue
        result[role]={key:g.accessor(p['attributes'][key]) for key in ['POSITION','TEXCOORD_0','NORMAL']}
        result[role]['indices']=[v[0] for v in g.accessor(p['indices'])]
    assert set(result)=={'VikingTunic','VikingPants'}
    return result

def preserve_triangulation(path,ref):
    g=GLB(path);raw=bytearray(path.read_bytes());json_bytes=struct.unpack_from('<I',raw,12)[0]
    for p in g.meshes()['Clothing']['primitives']:
        role=g.data['materials'][p['material']]['name'];source=ref[role]
        attributes=p['attributes'];points=g.accessor(attributes['POSITION']);uv=g.accessor(attributes['TEXCOORD_0']);normals=g.accessor(attributes['NORMAL'])
        # Include normals to distinguish coincident corners on a hard seam.
        mapping=vertex_match(points,[u+n for u,n in zip(uv,normals)],[tuple(p) for p in source['POSITION']],[tuple(u)+tuple(n) for u,n in zip(source['TEXCOORD_0'],source['NORMAL'])])
        assert len(points)==len(mapping) and all(i is not None for i in mapping),(role,'Outer corner changed')
        accessor=g.data['accessors'][p['indices']];view=g.data['bufferViews'][accessor['bufferView']]
        assert accessor['count']==len(source['indices']) and not view.get('byteStride')
        fmt={5123:'H',5125:'I'}[accessor['componentType']];stride=struct.calcsize('<'+fmt)
        offset=28+json_bytes+view.get('byteOffset',0)+accessor.get('byteOffset',0)
        for i,index in enumerate(source['indices']):struct.pack_into('<'+fmt,raw,offset+i*stride,mapping[index])
    path.write_bytes(raw)

rows=[]
for sex in ['male','female']:
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(sex+'.blend')))
    bpy.context.preferences.filepaths.file_preview_type='NONE'
    cloth=bpy.data.objects['Clothing']
    if REFERENCE not in cloth:
        assert any(m.name=='OutfitLining' for m in cloth.data.materials),'Migration requires the accepted lined source'
        ref=reference(ROOT/'assets/production/characters/realistic'/(sex+'.glb'))
        cloth[REFERENCE]=base64.b64encode(gzip.compress(json.dumps(ref,separators=(',',':')).encode())).decode()
    ref=json.loads(gzip.decompress(base64.b64decode(cloth[REFERENCE])))
    cleanup=remove_shell(cloth) if any(m.name=='OutfitLining' for m in cloth.data.materials) else {'already_shell_free':True}
    path=OUT/(sex+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animation_mode='ACTIONS',export_force_sampling=True,export_morph=True,export_morph_normal=True,export_all_influences=False)
    preserve_triangulation(path,ref)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(sex+'.blend')))
    rows.append({'sex':sex,'cleanup':cleanup,'accepted_triangulation_preserved':True,'max_export_influences':4})
    print('FITTED_OUTFIT_EXPORT_OK',sex,flush=True)
(OUT/'construction.json').write_text(json.dumps(rows,indent=2)+'\n')
