"""Compare actual shoulder deformation and finger bends in two GLB families.
Set IMPULS_CHARACTER_BASELINE and IMPULS_CHARACTER_OUTPUT to their directories,
then run through Blender --background --factory-startup --disable-autoexec.
The sampled default-body shoulder metrics must not regress. This does not
replace visual inspection or the separate extreme-morph/geometry validator.
"""
import bpy,json,math,os
from pathlib import Path
from mathutils import Vector
r=Path(__file__).resolve().parents[1];result=[]
for variant,folder in [('before',Path(os.environ['IMPULS_CHARACTER_BASELINE'])),('candidate',Path(os.environ['IMPULS_CHARACTER_OUTPUT']))]:
 for sex in ['male','female']:
  bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(folder/(sex+'.glb')))
  rig=next(o for o in bpy.data.objects if o.type=='ARMATURE');cloth=bpy.data.objects['Clothing']
  for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
  rest={tuple(e.vertices):(cloth.data.vertices[e.vertices[0]].co-cloth.data.vertices[e.vertices[1]].co).length for e in cloth.data.edges}
  shoulder=set()
  for v in cloth.data.vertices:
   names={cloth.vertex_groups[g.group].name:g.weight for g in v.groups}
   arm=sum(w for n,w in names.items() if n in ['LeftArm','RightArm','LeftShoulder','RightShoulder'])
   if arm>.05 and 1.1<v.co.z<1.7:shoulder.add(v.index)
  for clip in ['Idle','Walk','Run']:
   action=bpy.data.actions[clip];rig.animation_data.action=action
   if action.slots:rig.animation_data.action_slot=action.slots[0]
   ratios=[];bends=[]
   for fraction in [0,.25,.5,.75]:
    a,b=action.frame_range;bpy.context.scene.frame_set(round(a+(b-a)*fraction))
    evaluated=cloth.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
    for edge in mesh.edges:
     x,y=edge.vertices
     if (x in shoulder or y in shoulder) and rest[tuple(edge.vertices)]>.001:
      ratios.append((mesh.vertices[x].co-mesh.vertices[y].co).length/rest[tuple(edge.vertices)])
    evaluated.to_mesh_clear()
    for side in ['Left','Right']:
     for finger in ['Index','Middle','Ring','Pinky']:
      points=[rig.pose.bones[side+'Hand'+finger+str(i)].head for i in [1,2,3]]
      bends.append(math.degrees((points[1]-points[0]).angle(points[2]-points[1])))
   ratios.sort()
   result.append({'variant':variant,'sex':sex,'clip':clip,'shoulder_edge_ratio_p95':ratios[int(len(ratios)*.95)],'shoulder_edge_ratio_max':max(ratios),'finger_bend_min_deg':min(bends),'finger_bend_max_deg':max(bends)})
for row in result:
 if row['variant']=='candidate':
  baseline=next(v for v in result if v['variant']=='before' and v['sex']==row['sex'] and v['clip']==row['clip'])
  for key in ['shoulder_edge_ratio_p95','shoulder_edge_ratio_max']:
   assert row[key]<=baseline[key]+.0001,('shoulder deformation regressed',row,baseline)
(r/'build/acceptance/human-refinement-comparison.json').write_text(json.dumps(result,indent=2));print('HUMAN_REFINEMENT_INSPECTED',len(result))
