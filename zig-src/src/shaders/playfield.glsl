@vs vs
in vec4 position;
in vec2 texcoord0;
in vec2 sppos;
in float block_color;
in float desat;
out vec2 uv;
out uint tex;
out float desat_pct;

void main() {
    // gl_Position = vec4(sd[gl_InstanceIndex].position[0],sd[gl_InstanceIndex].position[1], 1.0, 1.0);
    gl_Position = position * vec4(0.1, 0.1, 1.0, 1.0);
    // vec4 my_pos = vec4(sppos.x ,sspos.y, 0.0, 0.0);
    gl_Position += vec4(sppos.x, sppos.y, 0.0, 0.0);
    tex = floatBitsToInt(block_color);
    desat_pct = desat;
    uv = texcoord0;
}
@end

@fs fs
layout(binding=1) uniform texture2D tex_a;
layout(binding=1) uniform sampler smp;
layout(binding=2) uniform texture2D tex_b;
layout(binding=3) uniform texture2D tex_c;
layout(binding=4) uniform texture2D tex_d;
in vec2 uv;
flat in uint tex;
flat in float desat_pct;
out vec4 frag_color;
vec4 generic_desaturate(vec4 color, float factor)
{
	vec3 lum = vec3(0.299, 0.587, 0.114);
	vec3 gray = vec3(dot(lum, color.xyz));
	return vec4(mix(color.xyz, gray, factor), color.a);
}

void main() {
    if (tex == 1) {
        frag_color = texture(sampler2D(tex_a, smp), uv); // + vec4(0.4); // + color;
    } else if (tex == 2) {
        frag_color = texture(sampler2D(tex_b, smp), uv); // + color; // + color;
    } else if (tex == 3) {
        frag_color = texture(sampler2D(tex_c, smp), uv); // + color; // + color;
    } else if (tex == 4) {
        frag_color = texture(sampler2D(tex_d, smp), uv); // + color; // + color;
    } else {
        frag_color = texture(sampler2D(tex_d, smp), uv)  + vec4(0.04); // + color; // + color;
    }
    if (desat_pct > 0) {
        frag_color = generic_desaturate(frag_color, desat_pct);
    }
}
@end

@program playfield vs fs

@vs vsquad
// struct SpriteData {
//     float position[2];
//     float scale[2];
// };

in vec4 position;
in vec2 texcoord0;
in vec4 sppos;
out vec2 uv0;

// layout(std140, binding=1) readonly buffer ssbo {
//     SpriteData sd[];
// };

void main() {
    // gl_Position = vec4(sd[gl_InstanceIndex].position[0],sd[gl_InstanceIndex].position[1], 1.0, 1.0);
    gl_Position = vec4(position[0], position[1], 1.0, 1.0);
    gl_Position *= vec4(sppos.x, sppos.x, 1.0, 1.0);
    uv0 = texcoord0;
}
@end

@fs fsquad
layout(binding=1) uniform texture2D tex0;
layout(binding=1) uniform sampler smp;

in vec2 uv0;
out vec4 frag_color;

vec4 generic_desaturate(vec4 color, float factor)
{
	vec3 lum = vec3(0.299, 0.587, 0.114);
	vec3 gray = vec3(dot(lum, color.xyz));
	return vec4(mix(color.xyz, gray, factor), color.a);
}
vec4 photoshop_desaturate(vec4 color)
{
    float bw = (min(color.r, min(color.g, color.b)) + max(color.r, max(color.g, color.b))) * 0.5;
    return vec4(bw, bw, bw, color.a);

}
void main() {
    frag_color = texture(sampler2D(tex0, smp), uv0).rgba;
    // frag_color = generic_desaturate(frag_color, 0.6);
    // frag_color = photoshop_desaturate(frag_color);
}


@end
@program fsq vsquad fsquad
