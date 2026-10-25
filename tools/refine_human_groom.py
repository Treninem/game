"""Experimental refit of existing CC0 hair cards; NOT production selected.

Both October 23 trials were rejected on rendered silhouette/cost. This keeps
the local attempt reproducible, not a claim that a replacement groom is ready.

Isolated output by default. Cap borders stay anchored; overlapping locks gain
curvature and a small root-to-tip lift instead of adding textures/materials.
"""
import bpy,os,json,hashlib,sys,gzip,base64,math
import numpy as np
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from refine_human_contours import components,preserve_outer_triangles,KEYS
OUT=Path(os.environ.get('IMPULS_GROOM_OUTPUT',ROOT/'build/asset_work/hair-shape-2026-10-23/candidate'))

def groom(obj):
    old=obj.data;groups=components(old)
    ids_to_component={i:c for c,ids in enumerate(groups) for i in ids}
    cap=set()
    for c,ids in enumerate(groups):
        span=[max(old.vertices[i].co[a] for i in ids)-min(old.vertices[i].co[a] for i in ids) for a in range(3)]
        if span[0]>.12 and span[2]>.10:cap.add(c)
    assert len(cap)==1,(obj.name,'one scalp cap required')
    keys=[(k.name,[v.co.copy() for v in k.data],k.slider_min,k.slider_max) for k in old.shape_keys.key_blocks]
    assert [k[0] for k in keys]==['Basis']+KEYS
    # Use a clean control to evaluate each key independently.
    mesh=bpy.data.meshes.new(obj.name+' groom control')
    mesh.from_pydata(keys[0][1],[],[list(p.vertices) for p in old.polygons])
    for mat in old.materials:mesh.materials.append(mat)
    for p,q in zip(mesh.polygons,old.polygons):p.material_index=q.material_index;p.use_smooth=True
    for layer in old.uv_layers:
        uv=mesh.uv_layers.new(name=layer.name)
        for i in range(len(layer.data)):uv.data[i].uv=layer.data[i].uv
    evaluator=bpy.data.objects.new(obj.name+' groom evaluator',mesh);bpy.context.collection.objects.link(evaluator)
    for group in obj.vertex_groups:evaluator.vertex_groups.new(name=group.name)
    for v in old.vertices:
        for g in v.groups:
            if g.weight>0:evaluator.vertex_groups[g.group].add([v.index],g.weight,'REPLACE')
    counts={}
    for p in mesh.polygons:
        for a,b in zip(p.vertices,list(p.vertices[1:])+[p.vertices[0]]):
            edge=tuple(sorted((a,b)));counts[edge]=counts.get(edge,0)+1
    crease=mesh.attributes.new('crease_edge','FLOAT','EDGE')
    for e in mesh.edges:
        if counts[tuple(sorted(e.vertices))]==1:crease.data[e.index].value=1 if ids_to_component[e.vertices[0]] in cap else .35
    sub=evaluator.modifiers.new('Curved scalp and layered locks','SUBSURF');sub.levels=1;sub.render_levels=1;sub.uv_smooth='PRESERVE_BOUNDARIES';sub.boundary_smooth='PRESERVE_CORNERS'
    dg=bpy.context.evaluated_depsgraph_get();surfaces=[];refined=None;topology=None;max_lift=0
    for name,points,lo,hi in keys:
        for v,p in zip(mesh.vertices,points):v.co=p
        mesh.update();dg.update()
        # Existing outer cards keep their original UVs and all morph deltas.
        for c,ids in enumerate(groups):
            if c in cap:continue
            center=sum((points[i] for i in ids),Vector())/len(ids)
            span=[max(points[i][a] for i in ids)-min(points[i][a] for i in ids) for a in range(3)]
            axis=max(range(3),key=lambda a:span[a]);low=min(points[i][axis] for i in ids)
            # The broad tail core stays fitted; smaller overlapping locks lift.
            amplitude=0 if len(ids)>200 else (.0006 if obj.name=='HairPonytail' else .0008)
            # Broad detached cards read as ribbons. Narrow their cross-flow
            # axis while keeping roots on the original scalp/tail coverage.
            cloud=np.array([tuple(points[i]-center) for i in ids])
            _,axes=np.linalg.eigh(cloud.T@cloud)
            across=Vector(axes[:,1])
            narrow=.30 if len(ids)<200 and obj.name=='HairPonytail' else .12
            for i in ids:
                t=(points[i][axis]-low)/max(span[axis],1e-6)
                amount=amplitude*math.sin(math.pi*t)**.8
                radial=points[i]-Vector((0,-.035,1.70))
                normal=mesh.vertices[i].normal.copy()
                if normal.dot(radial)<0:normal=-normal
                if normal.length<.1:normal=radial.normalized()
                mesh.vertices[i].co=points[i]-across*((points[i]-center).dot(across)*narrow)+normal*amount
                max_lift=max(max_lift,amount)
        mesh.update();dg.update()
        out=bpy.data.meshes.new_from_object(evaluator.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg)
        faces=[tuple(p.vertices) for p in out.polygons]
        if topology is None:topology=faces
        assert topology==faces,'Morph topology changed'
        surfaces.append((name,[v.co.copy() for v in out.vertices],lo,hi))
        if refined is None:refined=out
        else:bpy.data.meshes.remove(out)
    obj.data=refined
    for v,p in zip(refined.vertices,surfaces[0][1]):v.co=p
    for name,points,lo,hi in surfaces:
        key=obj.shape_key_add(name=name);key.slider_min=lo;key.slider_max=hi
        for v,p in zip(key.data,points):v.co=p
    bpy.data.objects.remove(evaluator,do_unlink=True)
    return {'part':obj.name,'source_vertices':len(old.vertices),'vertices':len(refined.vertices),'faces':len(refined.polygons),'components':len(groups),'scalp_components':len(cap),'max_card_lift_m':max_lift,'morphs':KEYS}

def build():
    assert not OUT.exists(),'Keep previous candidates and evidence';OUT.mkdir(parents=True)
    rows=[]
    for sex in ['male','female']:
        source=ROOT/'assets/source/characters/refined_contours'/(sex+'.blend')
        bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
        bpy.context.preferences.filepaths.file_preview_type='NONE'
        rig=bpy.data.objects['HumanRig'];rig.data.pose_position='REST'
        for o in bpy.context.scene.objects:
            if o.type=='MESH' and o.data.shape_keys:
                for k in o.data.shape_keys.key_blocks:k.value=0
        bpy.data.objects['HumanBodyFar'].hide_set(False)
        row={'sex':sex,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'hair':[groom(bpy.data.objects[n]) for n in ['HairShort','HairPonytail']]}
        rig.data.pose_position='POSE';dest=OUT/(sex+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_animation_mode='ACTIONS',export_force_sampling=True,export_morph=True,export_morph_normal=True,export_all_influences=True)
        cloth=bpy.data.objects['Clothing'];ref=json.loads(gzip.decompress(base64.b64decode(cloth['accepted_outer_triangulation_v1'])))
        preserve_outer_triangles(dest,ref)
        bpy.data.objects['HumanBodyFar'].hide_set(True)
        bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(sex+'.blend')))
        row['glb_sha256']=hashlib.sha256(dest.read_bytes()).hexdigest();row['bytes']=dest.stat().st_size;rows.append(row)
        print('HUMAN_GROOM_BUILT',json.dumps(row),flush=True)
    (OUT/'construction.json').write_text(json.dumps(rows,indent=2)+'\n')

if __name__=='__main__':build()
