"""Build an isolated wardrobe candidate; never overwrite production by default.

Uses the existing native body/rig/morph/animation pipeline and selected CC0
MakeHuman garments. Candidate art and animation acceptance remain separate.
Run with Blender --background --python tools/build_viking_humans.py.
"""
import importlib.util,os
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[1]
os.environ.setdefault('IMPULS_CHARACTER_OUTPUT',str(ROOT/'build/asset_work/viking-humans'))
spec=importlib.util.spec_from_file_location('human_builder',ROOT/'tools/build_realistic_humans.py')
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
SOURCE=ROOT/'assets/staging/characters/makehuman_viking_selected/clothes'
PARTS=[('tunic','tunicviking','TUNIC_Viking.png'),('pants','pantsviking','PantsViking.png'),('boots','bootsviking','BootsViking.png')]

def source(part):return SOURCE/('rehmanpolanski_viking_'+part)

def relax_hem_weights(weights,faces,heights):
    # A connected tunic hem is not two separate trouser legs. Its source
    # body mapping assigns adjacent centre vertices to opposite thighs.
    # Release only the low hem boundary; preserve torso/collar/cuff weights.
    neighbours=[set() for _ in weights]
    for face in faces:
        for a,b in zip(face,face[1:]+face[:1]):neighbours[a].add(b);neighbours[b].add(a)
    for _ in range(24):
        result=[]
        for i,values in enumerate(weights):
            if heights[i]>=1.0 or not neighbours[i]:result.append(values);continue
            mixed={bone:value*.5 for bone,value in values.items()}
            for j in neighbours[i]:
                for bone,value in weights[j].items():mixed[bone]=mixed.get(bone,0)+value*.5/len(neighbours[i])
            selected=sorted(mixed.items(),key=lambda item:-item[1])[:4];total=sum(v for _,v in selected)
            result.append({bone:value/total for bone,value in selected})
        weights=result
    return weights

def garment(points,variations,rig):
    all_points=[];all_faces=[];all_uv=[];all_fuv=[];all_weights=[]
    all_shapes={k:[] for k in variations};materials=[];face_materials=[]
    for part,obj_name,image in PARTS[:2]:
        folder=source(part);records,scales,_=h.mapping(folder/('rehmanpolanski_viking_'+part+'.mhclo'))
        _,uv,faces,fuv,_=h.read_obj(folder/(obj_name+'.obj'))
        vertex_offset=len(all_points);uv_offset=len(all_uv)
        all_points.extend(h.fitted(points,records,scales));all_uv.extend(uv)
        all_faces.extend([[i+vertex_offset for i in face] for face in faces])
        all_fuv.extend([[i+uv_offset if i>=0 else -1 for i in face] for face in fuv])
        weights=h.smooth_weights(h.fitted_weights(records),faces)
        if part=='tunic':weights=relax_hem_weights(weights,faces,[h.coord(p).z for p in h.fitted(points,records,scales)])
        all_weights.extend(weights)
        for key,other in variations.items():all_shapes[key].extend(h.fitted(other,records,scales))
        materials.append(h.material('Viking'+part.title(),image=folder/image,roughness=.9))
        face_materials.extend([len(materials)-1]*len(faces))
    obj=h.mesh('Clothing',all_points,all_faces,all_uv,all_fuv,all_weights,rig,materials[0],all_shapes)
    obj.data.materials.append(materials[1])
    for polygon,index in zip(obj.data.polygons,face_materials):polygon.material_index=index
    h.garment_clearance(obj)
    return obj

def body(points,variations,rig,sex):
    deleted=set()
    for part,_,_ in PARTS:
        _,_,mask=h.mapping(source(part)/('rehmanpolanski_viking_'+part+'.mhclo'));deleted|=mask
    keep=[i for i,(face,group) in enumerate(zip(h.FACES,h.GROUPS)) if group=='body' and not any(v in deleted for v in face)]
    skin=h.material('SkinHuman',image=h.SYSTEM/('skins/young_caucasian_'+sex+'/young_lightskinned_'+sex+'_diffuse.png'),roughness=.72)
    return h.mesh('HumanBody',points,[h.FACES[i] for i in keep],h.UV,[h.FACE_UV[i] for i in keep],h.W,rig,skin,variations)

h.create_garment=garment;h.create_body=body
# Reuse the complete existing rig/retarget/export routine. Only its footwear
# source block changes; the patch is checked rather than silently matching.
original=(ROOT/'tools/build_realistic_humans.py').read_text(encoding='utf-8')
start=original.index('def build_all():');end=original.index('\nif __name__',start)
routine=original[start:end]
old="""boots=SYSTEM/'clothes/shoes03/shoes03'
        rec,scale,_=mapping(boots.with_suffix('.mhclo'))
        _,uv,faces,fuv,_=read_obj(boots.with_suffix('.obj'))"""
new="""boots=VIKING_SOURCE/'rehmanpolanski_viking_boots'
        rec,scale,_=mapping(boots/'rehmanpolanski_viking_boots.mhclo')
        _,uv,faces,fuv,_=read_obj(boots/'bootsviking.obj')"""
assert routine.count(old)==1
routine=routine.replace(old,new).replace("material('LeatherBoots',(.085,.048,.026,1),roughness=.86)","material('VikingBoots',image=boots/'BootsViking.png',roughness=.86)")
h.__dict__['VIKING_SOURCE']=SOURCE
exec(compile(routine,str(__file__),'exec'),h.__dict__)
if __name__=='__main__':h.build_all()
