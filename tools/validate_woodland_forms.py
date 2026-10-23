"""Contracts for intentional whole-form replacements, not baseline preservation.

The old material-salvage validator remains unchanged. These models deliberately
replace the old wood point sets; inspect their actual surfaces and grip/nock
positions instead of treating the old angular silhouette as acceptance.
"""
from pathlib import Path
import sys,json,math
from validate_woodland_weapons import geometry,bounds,quant,ROOT

def validate(candidate):
    rows=[]
    for name,length in [('Axe_small',.65),('Dagger',.35),('Bow_Wooden',1.1),('Arrow',.7)]:
        mesh=geometry(candidate/(name+'.glb'));box=bounds(mesh)
        assert abs(box[1][1]-box[0][1]-length)<.002,(name,box)
        count=sum(len(r['indices'])//3 for r in mesh);assert count<6000,(name,count)
        for surface in mesh:assert len(surface['uv'])==len(surface['points'])
        wood=[p for r in mesh if 'Wood' in r['role'] for p in r['world']];assert wood
        row={'name':name,'triangles':count,'bounds':box}
        if name in ['Axe_small','Dagger','Bow_Wooden']:
            grip={'Axe_small':(-.09865,-.18,0),'Dagger':(.00060126,-.12,0),'Bow_Wooden':(-.070708,0,0)}[name]
            band=[p for p in wood if abs(p[1]-grip[1])<.008];assert len(band)>=20
            # The palm axis must be enclosed by the physical handle profile.
            assert min(p[0] for p in band)<grip[0]<max(p[0] for p in band)
            assert min(p[2] for p in band)<grip[2]<max(p[2] for p in band)
            row['grip_enclosed']=True
        if name=='Bow_Wooden':
            for sign in [-1,1]:
                band=[p for p in wood if abs(p[1]-sign*.5157)<.00001];assert len(band)>=20
                center=[sum(p[i] for p in band)/len(band) for i in range(3)]
                assert math.dist(center,(.2055,sign*.5157,0))<.001,(center,sign)
            row['nock_centers_aligned']=True
        if name=='Dagger':
            blade=next(r for r in mesh if r['node']=='StoneBlade');edges={}
            for i in range(0,len(blade['indices']),3):
                tri=[quant(blade['world'][blade['indices'][i+d]]) for d in range(3)];assert len(set(tri))==3
                for d in range(3):
                    edge=tuple(sorted((tri[d],tri[(d+1)%3])));edges[edge]=edges.get(edge,0)+1
            assert all(n==2 for n in edges.values());assert not any('Steel' in r['role'] for r in mesh);row['closed_stone_blade']=True
        rows.append(row)
    return rows

if __name__=='__main__':
    candidate=Path(sys.argv[1]);rows=validate(candidate);print(json.dumps(rows,indent=2));(candidate/'form-validation.json').write_text(json.dumps(rows,indent=2)+'\n')
