"""Preservation gate for the Blender near/far human pair, independent of bpy."""
import argparse,json,math
from pathlib import Path
from validate_outfit_revision import GLB,equivalent,vertex_match


def channels(g,animation):
    result={}
    for channel in animation['channels']:
        target=channel['target'];sampler=animation['samplers'][channel['sampler']]
        label=(g.data['nodes'][target['node']]['name'],target['path'])
        result[label]=(g.accessor(sampler['input']),g.accessor(sampler['output']))
    return result


def compare_primitive(a,b,left,right,label):
    assert left['attributes'].keys()==right['attributes'].keys(),(label,'attributes')
    for key in left['attributes']:
        equivalent(a.accessor(left['attributes'][key]),b.accessor(right['attributes'][key]),(label,key))
    equivalent(a.accessor(left['indices']),b.accessor(right['indices']),(label,'triangles'))
    assert len(left['targets'])==len(right['targets'])==9
    for i,(ta,tb) in enumerate(zip(left['targets'],right['targets'])):
        assert ta.keys()==tb.keys()
        for key in ta:equivalent(a.accessor(ta[key]),b.accessor(tb[key]),(label,'morph',i,key))


def check(before,after,sex):
    a=GLB(before);b=GLB(after);am=a.meshes();bm=b.meshes()
    parts={'HumanBody','Clothing','Boots','Eyes','HairShort','HairPonytail','Brows'}
    assert set(am)==parts and set(bm)==parts|{'HumanBodyFar'}
    assert a.image_hashes()==b.image_hashes(),'Authored image changed'
    shapes=am['HumanBody']['extras']['targetNames'];assert len(shapes)==9
    for part in bm:assert bm[part]['extras']['targetNames']==shapes,(sex,part,'shapes')
    for part in parts-{'HumanBody','Eyes'}:
        left=am[part]['primitives'];right=bm[part]['primitives'];assert len(left)==len(right)
        for i,(pa,pb) in enumerate(zip(left,right)):
            assert a.data['materials'][pa['material']]['name']==b.data['materials'][pb['material']]['name']
            compare_primitive(a,b,pa,pb,(sex,part,i))
    # The retained distance body must have the accepted skin geometry, topology,
    # UVs, four influences, and all nine morphs, not merely a similar silhouette.
    compare_primitive(a,b,am['HumanBody']['primitives'][0],bm['HumanBodyFar']['primitives'][0],(sex,'far body'))
    aa={x['name']:x for x in a.data['animations']};ab={x['name']:x for x in b.data['animations']}
    assert aa.keys()==ab.keys() and len(aa)==10
    for name in aa:
        ca=channels(a,aa[name]);cb=channels(b,ab[name]);assert ca.keys()==cb.keys()
        for key in ca:
            for i in range(2):equivalent(ca[key][i],cb[key][i],(sex,name,key,i))
    old_skin=a.data['skins'][0];new_skin=b.data['skins'][0]
    assert [a.data['nodes'][i]['name'] for i in old_skin['joints']]==[b.data['nodes'][i]['name'] for i in new_skin['joints']]
    equivalent(a.accessor(old_skin['inverseBindMatrices']),b.accessor(new_skin['inverseBindMatrices']),(sex,'bind'))
    details={}
    for part in ['HumanBody','Eyes']:
        p=bm[part]['primitives'][0];attrs=p['attributes'];positions=b.accessor(attrs['POSITION'])
        count=len(positions);old_count=len(a.accessor(am[part]['primitives'][0]['attributes']['POSITION']))
        assert count>old_count
        assert all(all(math.isfinite(v) for v in row) for row in positions)
        weight_sets=[b.accessor(attrs[k]) for k in ['WEIGHTS_0','WEIGHTS_1'] if k in attrs]
        max_influences=0
        for i in range(count):
            weights=sum((list(w[i]) for w in weight_sets),[])
            assert abs(sum(weights)-1)<1e-5 and min(weights)>=0,(sex,part,'normalized weights')
            max_influences=max(max_influences,sum(w>1e-7 for w in weights))
        assert max_influences<=8
        for t in p['targets']:
            assert len(b.accessor(t['POSITION']))==count
            assert all(all(math.isfinite(v) for v in row) for row in b.accessor(t['POSITION']))
        details[part]={'vertices_before':old_count,'vertices_after':count,'maximum_influences':max_influences}
    assert details['HumanBody']['maximum_influences']==5 and details['Eyes']['maximum_influences']==1
    return {'sex':sex,'unchanged_parts':5,'far_body_exact':True,'unchanged_images':True,'unchanged_clips':10,'morphs':9,'near':details}


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--baseline',type=Path,required=True);p.add_argument('--candidate',type=Path,required=True);p.add_argument('--report',type=Path,required=True)
    args=p.parse_args();rows=[check(args.baseline/f'{s}.glb',args.candidate/f'{s}.glb',s) for s in ['male','female']]
    args.report.write_text(json.dumps(rows,indent=2));print('HUMAN_CONTOURS_PRESERVATION_OK',json.dumps(rows))
