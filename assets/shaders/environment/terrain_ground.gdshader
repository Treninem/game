shader_type spatial;
render_mode specular_disabled;
uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 ground_world;
varying vec3 ground_normal;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float field(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
    ground_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    ground_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
    vec2 p=ground_world.xz;
    float patch=field(p*0.035);
    vec2 rotated=mat2(vec2(0.8,0.6),vec2(-0.6,0.8))*p;
    vec3 grass_a=texture(grass_texture,p*0.65).rgb;
    vec3 grass_b=texture(grass_texture,rotated*0.43+vec2(0.37,0.61)).rgb;
    vec3 grass=mix(grass_a,grass_b,smoothstep(0.2,0.8,patch));
    float macro=field(p*0.009);
    vec3 tint=mix(vec3(0.40,0.46,0.31),vec3(0.63,0.65,0.49),macro);
    vec3 rock=texture(rock_texture,p*0.18).rgb*vec3(0.62,0.60,0.53);
    float slope=smoothstep(0.18,0.65,1.0-abs(normalize(ground_normal).y));
    float damp=1.0-smoothstep(1.3,3.1,ground_world.y);
    vec3 soil=grass*vec3(0.48,0.38,0.26);
    ALBEDO=mix(mix(grass*tint,soil,damp*0.65),rock,slope);
    ROUGHNESS=mix(0.96,0.78,damp);
}
