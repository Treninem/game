"""Independent exported-data preservation gate for the existing groom revision."""
import argparse,json,math
from pathlib import Path
from validate_outfit_revision import GLB,equivalent
from validate_human_contours import compare_primitive,channels

def check(before,after,sex):
    a,b=GLB(before),GLB(after);am,bm=a.meshes(),b.meshes()
    assert set(am)==set(bm) and len(am)==8
    assert a.image_hashes()==b.image_hashes(),'Source images changed'
    changed={'HairShort','HairPonytail'};rows=[]
    for name in am:
        assert am[name]['extras']['targetNames']==bm[name]['extras']['targetNames'] and len(bm[name]['extras']['targetNames'])==9
        assert len(am[name]['primitives'])==len(bm[name]['primitives'])
        for i,(pa,pb) in enumerate(zip(am[name]['primitives'],bm[name]['primitives'])):
            assert a.data['materials'][pa['material']]['name']==b.data['materials'][pb['material']]['name']
            if name not in changed:compare_primitive(a,b,pa,pb,(sex,name,i));continue
            p=b.accessor(pb['attributes']['POSITION']);old=a.accessor(pa['attributes']['POSITION'])
            assert len(old)<len(p)<20000,(sex,name,'bounded refined mesh',len(p))
            assert all(all(math.isfinite(v) for v in x) for x in p)
            assert len(pb['targets'])==9
            for t in pb['targets']:
                morph=b.accessor(t['POSITION']);assert len(morph)==len(p) and all(all(math.isfinite(v) for v in x) for x in morph)
            sets=[b.accessor(pb['attributes'][key]) for key in ['WEIGHTS_0','WEIGHTS_1'] if key in pb['attributes']]
            maximum=0
            for i in range(len(p)):
                w=sum((list(s[i]) for s in sets),[])
                assert abs(sum(w)-1)<1e-5 and min(w)>=0,(sex,name,i,'weights')
                maximum=max(maximum,sum(x>1e-7 for x in w))
            assert maximum <= (3 if name=='HairShort' else 6),'Interpolated hair influence budget exceeded'
            bounds_delta=max(abs(f(x[k] for x in old)-f(x[k] for x in p)) for k in range(3) for f in [min,max])
            assert bounds_delta<.012,(sex,name,'hair envelope moved',bounds_delta)
            indices=[x[0] for x in b.accessor(pb['indices'])]
            assert min(indices)>=0 and max(indices)<len(p)
            rows.append({'part':name,'vertices_before':len(old),'vertices_after':len(p),'bounds_delta_m':bounds_delta,'maximum_influences':maximum})
    aa={x['name']:x for x in a.data['animations']};ab={x['name']:x for x in b.data['animations']}
    assert aa.keys()==ab.keys() and len(aa)==10
    for name in aa:
        ca,cb=channels(a,aa[name]),channels(b,ab[name]);assert ca.keys()==cb.keys()
        for key in ca:
            for i in range(2):equivalent(ca[key][i],cb[key][i],(sex,name,key,i))
    sa,sb=a.data['skins'][0],b.data['skins'][0]
    assert [a.data['nodes'][i]['name'] for i in sa['joints']]==[b.data['nodes'][i]['name'] for i in sb['joints']]
    equivalent(a.accessor(sa['inverseBindMatrices']),b.accessor(sb['inverseBindMatrices']),(sex,'bind'))
    return {'sex':sex,'unchanged_parts':6,'unchanged_images':True,'morphs':9,'clips':10,'hair':rows}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--baseline',type=Path,required=True);p.add_argument('--candidate',type=Path,required=True);p.add_argument('--report',type=Path,required=True)
    args=p.parse_args();rows=[check(args.baseline/f'{s}.glb',args.candidate/f'{s}.glb',s) for s in ['male','female']]
    args.report.write_text(json.dumps(rows,indent=2)+'\n');print('HUMAN_GROOM_PRESERVATION_OK',json.dumps(rows))
