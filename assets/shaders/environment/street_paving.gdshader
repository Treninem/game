shader_type spatial;
render_mode cull_back;
uniform sampler2D stone_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D blend_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 pigment : source_color = vec4(0.65,0.64,0.60,1.0);
uniform vec2 unit_m = vec2(0.24,0.16);
uniform float joint_m = 0.009;
uniform int layout = 0;
uniform float grain_scale = 2.0;
varying vec2 world_xz;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
    // Reduce coordinates before laying small stones at the15km capital.
    vec2 p=mod(world_xz,vec2(96.0));
    vec2 q=p;
    if(layout==2) q=mat2(vec2(0.7071,-0.7071),vec2(0.7071,0.7071))*p;
    vec2 cell=floor(q/unit_m);
    if(layout==0||layout==1||layout==2||layout==4) q.x+=mod(cell.y,2.0)*unit_m.x*0.5;
    if(layout==3){
        // Basket bond: alternating paired longitudinal/transverse bricks.
        vec2 block=floor(p/(unit_m.x*2.0));
        vec2 local=mod(p,unit_m.x*2.0);
        q=mod(block.x+block.y,2.0)<0.5?local:local.yx;
    }
    cell=floor(q/unit_m);
    vec2 edge=min(fract(q/unit_m),1.0-fract(q/unit_m))*unit_m;
    float width=min(edge.x,edge.y);
    float aa=max(fwidth(width),0.0005);
    float face=smoothstep(joint_m*0.5-aa,joint_m*0.5+aa,width);
    if(layout>=5)face=1.0;
    if(layout==4){
        vec2 uv=abs((fract(q/unit_m)-0.5)*unit_m);
        vec2 half_stone=unit_m*0.5-vec2(joint_m*0.5);
        float corner=0.026+hash21(cell)*0.012;
        float rounded=length(max(uv-(half_stone-vec2(corner)),vec2(0.0)))-corner;
        face=1.0-smoothstep(-aa,aa,rounded);
    }
    vec3 photo=texture(stone_texture,p*grain_scale).rgb;
    if(layout==6){
        vec2 tile=p*0.75;vec2 blend=smoothstep(vec2(0.0),vec2(1.0),fract(tile));vec2 id=floor(tile);
        float a=mix(hash21(id),hash21(id+vec2(1,0)),blend.x);
        float b=mix(hash21(id+vec2(0,1)),hash21(id+vec2(1,1)),blend.x);
        photo=mix(photo,texture(blend_texture,p*grain_scale).rgb,smoothstep(0.25,0.75,mix(a,b,blend.y)));
    }
    float tone=layout>=5?1.0:mix(0.85,1.10,hash21(cell));
    float pixels_per_unit=min(unit_m.x,unit_m.y)/max(length(fwidth(q)),0.0001);
    float detail=smoothstep(0.75,3.0,pixels_per_unit);
    tone=mix(1.0,tone,detail);face=mix(0.95,face,detail);
    vec3 surface=photo*pigment.rgb*tone;
    ALBEDO=mix(surface*0.48,surface,face);
    ROUGHNESS=mix(0.99,0.92,face);
}
