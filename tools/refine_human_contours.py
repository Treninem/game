"""Author a near human surface and retain the accepted far body in Blender.

Default output is isolated under build/. No live scene/model is overwritten.
The existing CC0 body, UVs, rig and nine morphs remain the source of truth.
"""
from pathlib import Path
import itertools
import bpy,os,sys,json,struct,gzip,base64,hashlib
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from validate_outfit_revision import GLB,vertex_match
OUT=Path(os.environ.get('IMPULS_CHARACTER_OUTPUT',str(ROOT/'build/asset_work/human-contour-2026-10-23/candidate')))
SOURCE=ROOT/'assets/source/characters/fitted_outfit'
KEYS=['FaceWidth','FaceHeight','FaceDepth','Nose','NoseWidth','NoseHeight','Jaw','HeadSize','Build']

def components(mesh):
    adjacency={i:set() for p in mesh.polygons for i in p.vertices}
    for p in mesh.polygons:
        for a,b in zip(p.vertices,list(p.vertices[1:])+[p.vertices[0]]):
            adjacency[a].add(b);adjacency[b].add(a)
    result=[]
    while adjacency:
        todo=[next(iter(adjacency))];seen=set()
        while todo:
            i=todo.pop()
            if i not in adjacency:continue
            seen.add(i);todo.extend(adjacency.pop(i)-seen)
        result.append(sorted(seen))
    return sorted(result,key=lambda ids:sum(mesh.vertices[i].co.x for i in ids)/len(ids))

def preserve_outer_triangles(path,reference):
    g=GLB(path);raw=bytearray(path.read_bytes());json_size=struct.unpack_from('<I',raw,12)[0]
    for primitive in g.meshes()['Clothing']['primitives']:
        role=g.data['materials'][primitive['material']]['name'];old=reference[role];attrs=primitive['attributes']
        points=g.accessor(attrs['POSITION']);uv=g.accessor(attrs['TEXCOORD_0']);normals=g.accessor(attrs['NORMAL'])
        mapping=vertex_match(points,[u+n for u,n in zip(uv,normals)],[tuple(p) for p in old['POSITION']],[tuple(u)+tuple(n) for u,n in zip(old['TEXCOORD_0'],old['NORMAL'])])
        assert len(points)==len(mapping) and all(i is not None for i in mapping),(role,'Unchanged outer garment corner moved')
        accessor=g.data['accessors'][primitive['indices']];view=g.data['bufferViews'][accessor['bufferView']]
        assert accessor['count']==len(old['indices']) and not view.get('byteStride')
        fmt={5123:'H',5125:'I'}[accessor['componentType']];stride=struct.calcsize('<'+fmt)
        offset=28+json_size+view.get('byteOffset',0)+accessor.get('byteOffset',0)
        for i,index in enumerate(old['indices']):struct.pack_into('<'+fmt,raw,offset+i*stride,mapping[index])
    path.write_bytes(raw)

def bounds(points,ids):
    low=Vector([min(points[i][a] for i in ids) for a in range(3)])
    high=Vector([max(points[i][a] for i in ids) for a in range(3)])
    return (low+high)*.5,(high-low)*.5

def restore_far_weights(far,sex):
    """Use the accepted exported four weights, not uncapped authoring groups."""
    g=GLB(ROOT/'assets/production/characters/realistic'/(sex+'.glb'))
    node=next(n for n in g.data['nodes'] if n.get('name')=='HumanBody')
    primitive=g.data['meshes'][node['mesh']]['primitives'][0]
    joints=[g.data['nodes'][i]['name'] for i in g.data['skins'][node['skin']]['joints']]
    positions=g.accessor(primitive['attributes']['POSITION']);bones=g.accessor(primitive['attributes']['JOINTS_0']);weights=g.accessor(primitive['attributes']['WEIGHTS_0'])
    buckets={}
    def cell(p):return tuple(round(v*10000) for v in p)
    for p,ids,values in zip(positions,bones,weights):
        point=Vector((p[0],-p[2],p[1]));buckets.setdefault(cell(point),[]).append((point,{joints[i]:w for i,w in zip(ids,values) if w>0}))
    used={i for p in far.data.polygons for i in p.vertices};matched=0
    for vertex in far.data.vertices:
        values=None;center=cell(vertex.co)
        for delta in itertools.product([-1,0,1],repeat=3):
            for point,old in buckets.get(tuple(a+b for a,b in zip(center,delta)),[]):
                if (point-vertex.co).length<1e-6:values=old;break
            if values is not None:break
        if values is None:
            assert vertex.index not in used,('Accepted far body point moved',sex,vertex.index,tuple(vertex.co))
            old=sorted([(far.vertex_groups[v.group].name,v.weight) for v in vertex.groups if v.weight>0],key=lambda x:-x[1])[:4]
            total=sum(w for _,w in old);values={name:w/total for name,w in old} if total else {}
        else:matched+=vertex.index in used
        for influence in list(vertex.groups):far.vertex_groups[influence.group].remove([vertex.index])
        for name,weight in values.items():far.vertex_groups[name].add([vertex.index],weight,'REPLACE')
    assert matched==len(used)
    return {'accepted_exported_weights_restored':matched,'maximum_influences':4}

def smooth_surface(original,levels,preserve_eye_bounds=False):
    data=original.data
    used=sorted({i for p in data.polygons for i in p.vertices});mapping={old:i for i,old in enumerate(used)}
    keys=[(k.name,[k.data[i].co.copy() for i in used],k.slider_min,k.slider_max) for k in data.shape_keys.key_blocks]
    assert [k[0] for k in keys]==['Basis']+KEYS
    clean=bpy.data.meshes.new(original.name+' contour control')
    clean.from_pydata(keys[0][1],[],[[mapping[i] for i in p.vertices] for p in data.polygons])
    for material in data.materials:clean.materials.append(material)
    for target,source in zip(clean.polygons,data.polygons):target.material_index=source.material_index;target.use_smooth=True
    for layer in data.uv_layers:
        target=clean.uv_layers.new(name=layer.name)
        for p,old in zip(clean.polygons,data.polygons):
            for i,j in zip(p.loop_indices,old.loop_indices):target.data[i].uv=layer.data[j].uv
    temp=bpy.data.objects.new(original.name+' contour evaluator',clean)
    bpy.context.collection.objects.link(temp)
    for group in original.vertex_groups:temp.vertex_groups.new(name=group.name)
    for old,new in mapping.items():
        for influence in data.vertices[old].groups:
            if influence.weight>0:temp.vertex_groups[influence.group].add([new],influence.weight,'REPLACE')
    # Mask openings and cuff boundaries stay on their accepted control edges.
    incidence={}
    for p in clean.polygons:
        for a,b in zip(p.vertices,list(p.vertices[1:])+[p.vertices[0]]):
            edge=tuple(sorted((a,b)));incidence[edge]=incidence.get(edge,0)+1
    crease=clean.attributes.new('crease_edge','FLOAT','EDGE')
    for edge in clean.edges:
        if incidence.get(tuple(sorted(edge.vertices)),0)==1:crease.data[edge.index].value=1.0
    sub=temp.modifiers.new('Near surface curvature','SUBSURF')
    sub.levels=levels;sub.render_levels=levels;sub.boundary_smooth='PRESERVE_CORNERS';sub.uv_smooth='PRESERVE_BOUNDARIES'
    dg=bpy.context.evaluated_depsgraph_get()
    surfaces=[];refined=None;topology=None
    eye_components=components(clean) if preserve_eye_bounds else None
    if preserve_eye_bounds:assert len(eye_components)==2,'Expected two separately fitted eyes'
    for name,points,minimum,maximum in keys:
        for vertex,point in zip(clean.vertices,points):vertex.co=point
        clean.update();dg.update()
        evaluated=temp.evaluated_get(dg)
        mesh=bpy.data.meshes.new_from_object(evaluated,preserve_all_data_layers=True,depsgraph=dg)
        indices=[tuple(p.vertices) for p in mesh.polygons]
        if topology is None:topology=indices
        assert indices==topology,'Morph subdivision changed topology'
        coordinates=[v.co.copy() for v in mesh.vertices]
        if preserve_eye_bounds:
            groups=components(mesh);assert len(groups)==2
            for old_ids,new_ids in zip(eye_components,groups):
                old_center,old_radius=bounds(points,old_ids);center,radius=bounds(coordinates,new_ids)
                assert min(radius)>1e-6
                for i in new_ids:
                    coordinates[i]=old_center+Vector([(coordinates[i][a]-center[a])*old_radius[a]/radius[a] for a in range(3)])
        surfaces.append((name,coordinates,minimum,maximum))
        if refined is None:refined=mesh
        else:bpy.data.meshes.remove(mesh)
    # Keep all interpolated influences; dropping the fifth can change fingers.
    maximum_influences=max(sum(g.weight>1e-5 for g in v.groups) for v in refined.vertices)
    assert maximum_influences<=8,'Godot skin influence budget exceeded'
    original.data=refined
    for vertex,point in zip(refined.vertices,surfaces[0][1]):vertex.co=point
    for name,points,minimum,maximum in surfaces:
        key=original.shape_key_add(name=name);key.slider_min=minimum;key.slider_max=maximum;key.value=0
        for vertex,point in zip(key.data,points):vertex.co=point
    refined.update()
    original['contour_source']='Existing MakeHuman CC0 fitted body; affine Catmull-Clark per morph'
    original['contour_levels']=levels
    bpy.data.objects.remove(temp,do_unlink=True)
    return {'source_vertices':len(data.vertices),'rendered_control_vertices':len(used),'vertices':len(refined.vertices),'faces':len(refined.polygons),'levels':levels,'maximum_influences':maximum_influences,'all_morphs':KEYS,'eye_bounds_preserved':preserve_eye_bounds,'open_boundaries_preserved':True}

def build_all():
    OUT.mkdir(parents=True,exist_ok=True);rows=[]
    sexes=os.environ.get('IMPULS_CONTOUR_SEX','male,female').split(',')
    for sex in sexes:
        assert sex in ['male','female']
        assert not (OUT/(sex+'.glb')).exists(),'Keep previous candidate evidence'
        source=SOURCE/(sex+'.blend')
        bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
        bpy.context.preferences.filepaths.file_preview_type='NONE'
        rig=bpy.data.objects['HumanRig'];rig.data.pose_position='REST'
        for obj in bpy.context.scene.objects:
            if obj.type=='MESH' and obj.data.shape_keys:
                for key in obj.data.shape_keys.key_blocks:key.value=0
        body=bpy.data.objects['HumanBody']
        far=body.copy();far.data=body.data.copy();far.name='HumanBodyFar';bpy.context.collection.objects.link(far)
        far['contour_role']='Accepted original body for runtime distance LOD; same rig and morphs'
        row={'sex':sex,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'far_weights':restore_far_weights(far,sex),'body':smooth_surface(body,1),'eyes':smooth_surface(bpy.data.objects['Eyes'],2,True),'far_body_vertices':len(far.data.vertices),'far_body_faces':len(far.data.polygons),'unchanged_parts':['Clothing','Boots','Brows','HairShort','HairPonytail'],'runtime_lod_required':True}
        rig.data.pose_position='POSE'
        path=OUT/(sex+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animation_mode='ACTIONS',export_force_sampling=True,export_morph=True,export_morph_normal=True,export_all_influences=True)
        cloth=bpy.data.objects['Clothing'];ref=json.loads(gzip.decompress(base64.b64decode(cloth['accepted_outer_triangulation_v1'])))
        preserve_outer_triangles(path,ref)
        # Export includes the two explicit runtime roles; the editable file
        # opens with the distance reference hidden so its skin cannot z-fight.
        far.hide_set(True)
        bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(sex+'.blend')))
        row['glb_sha256']=hashlib.sha256(path.read_bytes()).hexdigest();row['glb_bytes']=path.stat().st_size
        rows.append(row);print('HUMAN_CONTOUR_BUILT',json.dumps(row),flush=True)
    (OUT/'construction.json').write_text(json.dumps(rows,indent=2)+'\n')

if __name__=='__main__':build_all()
