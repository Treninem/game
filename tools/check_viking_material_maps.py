"""Sample actual GLB triangle UV centroids against each baked material map."""
from pathlib import Path
import struct,json,hashlib,os
import numpy as np
from PIL import Image
r=Path(__file__).resolve().parents[1];folder=Path(os.environ.get('IMPULS_WARDROBE_MAPS',str(r/'build/asset_work/viking-materials')));rows=[]
for sex in ['male','female']:
 raw=(r/'build/asset_work/viking-humans'/(sex+'.glb')).read_bytes();length=struct.unpack_from('<I',raw,12)[0];j=json.loads(raw[20:20+length]);binary=20+length+8
 def accessor(index):
  a=j['accessors'][index];v=j['bufferViews'][a['bufferView']];count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];dtype={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']];dt=np.dtype(dtype);offset=binary+v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',count*dt.itemsize)
  return np.ndarray((a['count'],count),dtype=dtype,buffer=raw,offset=offset,strides=(stride,dt.itemsize)).copy()
 for mesh in j['meshes']:
  for primitive in mesh['primitives']:
   label=j['materials'][primitive['material']]['name']
   if not label.startswith('Viking'):continue
   uv=accessor(primitive['attributes']['TEXCOORD_0']);triangles=accessor(primitive['indices']).reshape(-1,3);centres=uv[triangles].mean(axis=1)
   maps={}
   for kind in ['normal','ao']:
    p=folder/(sex+'-'+label.lower()+'-'+kind+'.png');data=np.asarray(Image.open(p).convert('RGB'),dtype=float)/255;h,w=data.shape[:2];xy=np.clip((centres*np.array([w-1,h-1])).round().astype(int),[0,0],[w-1,h-1]);values=data[xy[:,1],xy[:,0]]
    assert np.isfinite(values).all() and (w,h)==(1024,1024)
    if kind=='normal':
     vectors=values*2-1;norm=np.linalg.norm(vectors,axis=1);stats={'unit_length_error_p95':float(np.quantile(abs(norm-1),.95)),'z_negative_fraction':float(np.mean(vectors[:,2]<0)),'xy_variation':float(np.std(vectors[:,:2]))}
     assert stats['unit_length_error_p95']<.08,(sex,label,'invalid tangent normal vectors',stats)
     assert stats['z_negative_fraction']<.001,(sex,label,'back-surface normal contamination',stats)
     assert stats['xy_variation']>.005,(sex,label,'empty tangent detail',stats)
    else:
     stats={'mean':float(values[:,0].mean()),'p10':float(np.quantile(values[:,0],.1)),'p90':float(np.quantile(values[:,0],.9))};assert .1<stats['mean']<=1,(sex,label,'empty or fully occluded map',stats)
    maps[kind]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),**stats}
   rows.append({'sex':sex,'material':label,'sampled_triangles':len(centres),'maps':maps})
out=folder/'uv-probe.json';out.write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8');print(json.dumps(rows,indent=2))
