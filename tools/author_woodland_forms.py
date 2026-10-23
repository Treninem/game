"""Whole-kit form candidate. Uses the rejected trial only for map/UV helpers.

No runtime writes: each output directory is new. Original normalized mesh
frames are retained so existing palm/string/projectile axes can be tested.
"""
from pathlib import Path
import importlib.util,os,json,math,hashlib
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('woodland_helpers',ROOT/'tools/refine_woodland_weapons.py')
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
OUT=Path(os.environ.get('IMPULS_WEAPON_FORM_OUTPUT',ROOT/'build/asset_work/woodland-forms-2026-10-23/candidate1'))
h.OUT=OUT

def tube(obj,centers,radii,segments=20):
    """Continuous tapered elliptical stave/handle in normalized world metres."""
    old=obj.data;roles=[m.name for m in old.materials]
    wood=roles.index('LightWood');dark=roles.index('DarkWood') if 'DarkWood' in roles else wood
    points=[tuple(v.co) for v in old.vertices];faces=[];materials=[]
    for face in old.polygons:
        if roles[face.material_index] not in h.WOOD:
            faces.append(tuple(face.vertices));materials.append(face.material_index)
    inverse=obj.matrix_world.inverted();start=len(points)
    for i,center in enumerate(centers):
        tangent=(Vector(centers[min(i+1,len(centers)-1)])-Vector(centers[max(0,i-1)])).normalized()
        across=Vector((0,1,0));other=tangent.cross(across).normalized()
        for j in range(segments):
            angle=math.tau*j/segments
            p=Vector(center)+across*(math.cos(angle)*radii[i][0])+other*(math.sin(angle)*radii[i][1])
            points.append(tuple(inverse@p))
    for i in range(len(centers)-1):
        for j in range(segments):
            a=start+i*segments+j;b=start+i*segments+(j+1)%segments
            faces.append((a,b,b+segments,a+segments));materials.append(dark if i<2 or i>len(centers)-4 else wood)
    faces.extend([tuple(start+j for j in reversed(range(segments))),tuple(start+(len(centers)-1)*segments+j for j in range(segments))]);materials.extend([dark,dark])
    mesh=bpy.data.meshes.new(old.name+' continuous form');mesh.from_pydata(points,[],faces)
    for m in old.materials:mesh.materials.append(m)
    for f,m in zip(mesh.polygons,materials):f.material_index=m;f.use_smooth=m in [wood,dark]
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS');bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();obj.data=mesh

def reshape(name):
    obj=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith(name))
    centers=[];radii=[]
    if name=='Bow_Wooden':
        stations=sorted(set([-.55+1.1*i/96 for i in range(97)]+[-.5157,.5157]))
        nock=.5157/.55;curve=(.2055+.070708+.025*nock**12)/nock**1.65
        for z in stations:
            s=abs(z)/.55
            # A continuous ash stave: stiff central grip, tapered curved limbs,
            # small recurved tips. String nocks stay at the controller anchors.
            x=-.070708+curve*s**1.65-.025*s**12
            centers.append((x,0,z))
            r=(.016*(1-s)**.65+.003)
            radii.append((r,.012*(1-s)**.8+.0025))
    elif name=='Axe_small':
        for i in range(65):
            z=-.325+.6434*i/64;t=i/64
            grip_t=(-.18+.325)/.6434
            x=-.09865+.040*(max(0,z+.18)/.4984)**2-.012*(math.sin(math.pi*t)-math.sin(math.pi*grip_t))
            centers.append((x,0,z));radii.append((.013+.003*math.cos(math.pi*t)**2,.016+.003*math.cos(math.pi*t)**2))
    elif name=='Dagger':
        for i in range(25):
            z=-.175+.11*i/24;t=i/24
            centers.append((.00060126,0,z));r=.010+.003*math.sin(math.pi*t);radii.append((r,r))
    else:
        for i in range(25):centers.append((0,0,-.33+.62*i/24));radii.append((.0032,.0032))
    tube(obj,centers,radii)

def build():
    assert not OUT.exists();OUT.mkdir(parents=True);(OUT/'authoring').mkdir()
    bpy.ops.wm.read_factory_settings(use_empty=True);maps=h.author_maps();rows=[]
    # This is a distinct form trial, not a continuation of the rejected palette.
    h.COLORS.update({'Steel':(.62,.65,.68,1),'LightSteel':(.76,.78,.80,1),'DarkSteel':(.32,.34,.36,1)})
    for name in ['Axe_small','Dagger','Bow_Wooden','Arrow']:
        bpy.ops.wm.read_factory_settings(use_empty=True);source=h.SOURCE/(name+'.glb');bpy.ops.import_scene.gltf(filepath=str(source));bpy.context.view_layer.update()
        if name=='Dagger':h.stone_knife()
        reshape(name)
        for obj in list(bpy.context.scene.objects):
            if obj.type=='MESH':
                if name!='Dagger':h.weld_and_bevel(obj,name)
                h.author_uvs(obj)
        roles={m.name for o in bpy.context.scene.objects if o.type=='MESH' for m in o.data.materials}
        fallback={role:h.material(role,False) for role in roles};authored={role:h.material(role,True) for role in roles}
        for o in bpy.context.scene.objects:
            if o.type=='MESH':
                for i,m in enumerate(list(o.data.materials)):o.data.materials[i]=fallback[m.name]
        for role,m in fallback.items():m.name=role+'.placeholder'
        path=OUT/(name+'.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=False,export_texcoords=True)
        for o in bpy.context.scene.objects:
            if o.type=='MESH':
                for i,m in enumerate(list(o.data.materials)):o.data.materials[i]=authored[m.name.removesuffix('.placeholder')]
        for image in bpy.data.images:
            if image.source=='FILE':image.filepath=bpy.path.relpath(bpy.path.abspath(image.filepath),start=str(OUT/'authoring'))
        bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'authoring'/(name+'.blend')),relative_remap=False)
        row={'name':name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'vertices':sum(len(o.data.vertices) for o in bpy.context.scene.objects if o.type=='MESH')};rows.append(row);print('WEAPON_FORMS_BUILT',json.dumps(row),flush=True)
    (OUT/'construction.json').write_text(json.dumps({'maps':maps,'models':rows,'status':'UNREVIEWED_FORM_CANDIDATE'},indent=2)+'\n')

if __name__=='__main__':build()
