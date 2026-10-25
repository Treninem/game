"""Verify removal of ONLY the redundant material primitive, independently of Blender."""
from pathlib import Path
import argparse, json
from validate_outfit_revision import GLB, equivalent, vertex_match

def triangles(ids):
    return sorted(min(tuple(ids[i+j:i+3]+ids[i:i+j]) for j in range(3)) for i in range(0,len(ids),3))

def check(before,after):
    a,b=GLB(before),GLB(after)
    assert a.image_hashes()==b.image_hashes(),'Authored image pixels changed'
    left,right=a.meshes(),b.meshes()
    assert set(left)==set(right) and len(left)==7
    removed=0
    for part in left:
        def roles(g,mesh): return {g.data['materials'][p['material']]['name']:p for p in mesh['primitives']}
        aa,bb=roles(a,left[part]),roles(b,right[part])
        if part=='Clothing':
            removed=len(a.accessor(aa['OutfitLining']['indices']))//3
            aa.pop('OutfitLining')
        assert set(aa)==set(bb),(part,'Unexpected material change')
        assert left[part].get('extras',{}).get('targetNames')==right[part].get('extras',{}).get('targetNames')
        for role,pa in aa.items():
            pb=bb[role];la,lb=pa['attributes'],pb['attributes']
            ap,bp=a.accessor(la['POSITION']),b.accessor(lb['POSITION'])
            au,bu=a.accessor(la['TEXCOORD_0']),b.accessor(lb['TEXCOORD_0'])
            mapping=list(range(len(ap)))
            if part=='Clothing':
                an=a.accessor(la['NORMAL']);bn=b.accessor(lb['NORMAL'])
                mapping=vertex_match(ap,[u+n for u,n in zip(au,an)],bp,[u+n for u,n in zip(bu,bn)])
            assert len(ap)==len(bp) and all(i is not None for i in mapping),(part,role,'Authored vertex/UV changed')
            assert set(la)==set(lb),(part,role,'Attributes changed')
            for key in la:
                source=a.accessor(la[key])
                equivalent([source[i] for i in mapping],b.accessor(lb[key]),(part,role,key))
            assert len(pa['targets'])==len(pb['targets'])==9
            for ta,tb in zip(pa['targets'],pb['targets']):
                assert ta.keys()==tb.keys()
                for key in ta:
                    source=a.accessor(ta[key])
                    equivalent([source[i] for i in mapping],b.accessor(tb[key]),(part,role,'morph',key))
            # Exporters can split coincident vertices into distinct corners.
            # Compare oriented geometric/UV triangles, not incidental indices.
            def topology(g,p):
                positions=g.accessor(p['attributes']['POSITION']);uvs=g.accessor(p['attributes']['TEXCOORD_0'])
                ids=[tuple(round(v,6) for v in positions[i[0]]+uvs[i[0]]) for i in g.accessor(p['indices'])]
                return triangles(ids)
            assert topology(a,pa)==topology(b,pb),(part,role,'Topology changed')
    assert removed>1000 and all(m.get('name')!='OutfitLining' for m in b.data['materials'])
    def clips(g):
        result={}
        for clip in g.data['animations']:
            channels={}
            for c in clip['channels']:
                target=c['target'];s=clip['samplers'][c['sampler']]
                channels[(g.data['nodes'][target['node']]['name'],target['path'])]=(g.accessor(s['input']),g.accessor(s['output']))
            result[clip['name']]=channels
        return result
    ca,cb=clips(a),clips(b);assert set(ca)==set(cb) and len(ca)==10
    for name in ca:
        assert set(ca[name])==set(cb[name])
        for target,(times,values) in ca[name].items():
            equivalent(times,cb[name][target][0],(name,target,'times'))
            equivalent(values,cb[name][target][1],(name,target,'values'))
    for sa,sb in zip(a.data['skins'],b.data['skins']):
        assert [a.data['nodes'][i]['name'] for i in sa['joints']]==[b.data['nodes'][i]['name'] for i in sb['joints']]
        equivalent(a.accessor(sa['inverseBindMatrices']),b.accessor(sb['inverseBindMatrices']),'Bind matrices changed')
    return {'removed_redundant_triangles':removed,'authored_surfaces_morphs_uvs_weights_clips_unchanged':True}

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('before',type=Path);parser.add_argument('after',type=Path);args=parser.parse_args()
    rows={sex:check(args.before/(sex+'.glb'),args.after/(sex+'.glb')) for sex in ['male','female']}
    print('OUTFIT_SHELL_REMOVAL_OK',json.dumps(rows))
