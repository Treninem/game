"""Independent glTF geometry contracts for the normalized starter weapon kit."""
from pathlib import Path
import json,struct,math,sys,hashlib
ROOT=Path(__file__).resolve().parents[1]
def read(path):
 b=path.read_bytes();size=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+size]);offset=20+size
 length,kind=struct.unpack_from('<II',b,offset);assert kind==0x004e4942
 return j,b[offset+8:offset+8+length]
def accessor(j,b,index):
 a=j['accessors'][index];v=j['bufferViews'][a['bufferView']];fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
 n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];width=struct.calcsize(fmt)*n;start=v.get('byteOffset',0)+a.get('byteOffset',0)
 return [struct.unpack_from('<'+fmt*n,b,start+i*v.get('byteStride',width)) for i in range(a['count'])]
def transform(p,node):
 if 'matrix' in node:
  m=node['matrix'];return tuple(sum(m[c*4+r]*p[c] for c in range(3))+m[12+r] for r in range(3))
 p=[x*s for x,s in zip(p,node.get('scale',[1,1,1]))];x,y,z,w=node.get('rotation',[0,0,0,1]);u=[x,y,z]
 cross=lambda a,b:[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
 c=cross(u,p);d=cross(u,c)
 return tuple(p[i]+2*(w*c[i]+d[i])+node.get('translation',[0,0,0])[i] for i in range(3))
def geometry(path):
 j,b=read(path);parents={child:i for i,n in enumerate(j['nodes']) for child in n.get('children',[])};rows=[]
 for i,node in enumerate(j['nodes']):
  if 'mesh' not in node:continue
  chain=[node];at=i
  while at in parents:at=parents[at];chain.append(j['nodes'][at])
  for p in j['meshes'][node['mesh']]['primitives']:
   points=accessor(j,b,p['attributes']['POSITION']);world=[]
   for point in points:
    for n in chain:point=transform(point,n)
    world.append(point)
   indices=[x[0] for x in accessor(j,b,p['indices'])]
   role=j['materials'][p['material']]['name'].removesuffix('.placeholder')
   uv=accessor(j,b,p['attributes']['TEXCOORD_0']) if 'TEXCOORD_0' in p['attributes'] else []
   assert all(math.isfinite(x) for p in world+uv for x in p)
   rows.append({'node':node['name'],'role':role,'points':points,'world':world,'indices':indices,'uv':uv})
 return rows
def bounds(rows):
 points=[p for r in rows for p in r['world']]
 return [[f(p[i] for p in points) for i in range(3)] for f in [min,max]]
def quant(p):return tuple(round(x,5) for x in p)
def validate(candidate):
 rows=[]
 for name in ['Axe_small','Dagger','Bow_Wooden','Arrow']:
  source=ROOT/'assets/production/weapons/woodland'/(name+'.glb');old=geometry(source);new=geometry(candidate/(name+'.glb'))
  a=bounds(old);b=bounds(new);error=max(abs(a[s][i]-b[s][i]) for s in range(2) for i in range(3))
  if name=='Dagger':
   assert max(abs(a[s][1]-b[s][1]) for s in range(2))<.001,'Knife length changed'
   assert b[1][0]-b[0][0]<.07 and b[1][2]-b[0][2]<.035,'Stone blade exceeds grip envelope'
  else:assert error<.003,(name,error)
  for r in new:assert len(r['uv'])==len(r['points'])
  old_wood={quant(p) for r in old if 'Wood' in r['role'] for p in r['world']};new_wood={quant(p) for r in new if 'Wood' in r['role'] for p in r['world']}
  # Export rounding can cross a 10-micron bucket; use distances for misses.
  missing=[p for p in old_wood if p not in new_wood]
  max_wood=max([min(math.dist(p,q) for q in new_wood) for p in missing] or [0]);assert max_wood<.0013,(name,max_wood)
  triangles=sum(len(r['indices'])//3 for r in new);assert triangles<6000
  row={'name':name,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'candidate_sha256':hashlib.sha256((candidate/(name+'.glb')).read_bytes()).hexdigest(),'bounds_max_error_m':error,'wood_max_error_m':max_wood,'triangles':triangles}
  if name=='Bow_Wooden':
   def cord(rs):
    return sum(all(r['points'][r['indices'][k+d]][0]>.35 and abs(r['points'][r['indices'][k+d]][1])<.006 and abs(r['points'][r['indices'][k+d]][2])<.94 for d in range(3)) for r in rs for k in range(0,len(r['indices']),3))
   row['original_cord_triangles']=cord(old);row['candidate_cord_triangles']=cord(new);assert cord(old)>0 and cord(old)==cord(new),row
  if name=='Dagger':
   blade=next(r for r in new if r['node']=='StoneBlade');edges={}
   for k in range(0,len(blade['indices']),3):
    tri=[quant(blade['world'][blade['indices'][k+d]]) for d in range(3)];assert len(set(tri))==3
    for d in range(3):
     edge=tuple(sorted([tri[d],tri[(d+1)%3]]));edges[edge]=edges.get(edge,0)+1
   assert all(x==2 for x in edges.values()),'Open or non-manifold stone blade'
   assert not any('Steel' in r['role'] for r in new),'Metal blade retained on stone knife'
   row['blade_closed']=True
  rows.append(row)
 return rows
if __name__=='__main__':
 path=Path(sys.argv[1]);rows=validate(path);print(json.dumps(rows,indent=2));(path/'geometry-validation.json').write_text(json.dumps(rows,indent=2)+'\n')
