@vs vs
in vec4 position;
in vec2 texcoord0;
layout(location=2) in vec2 sppos;
layout(location=3) in float block_color;
layout(location=4) in float desat;
out vec2 uv;
out uint tex;
out flat float desat_pct;

void main() {
    // gl_Position = vec4(sd[gl_InstanceIndex].position[0],sd[gl_InstanceIndex].position[1], 1.0, 1.0);
    gl_Position = position * vec4(0.1, 0.1, 1.0, 1.0);
    // vec4 my_pos = vec4(sppos.x ,sspos.y, 0.0, 0.0);
    gl_Position += vec4(sppos.x, sppos.y, 0.0, 0.0);
    tex = floatBitsToInt(block_color);
    desat_pct = desat;
    uv = texcoord0;
    // flip so this sub texture matches everything else loaded
    uv.y = 1.0 - uv.y;
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

layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord0;
layout(location=2) in vec4 sppos;
layout(location=3) in float sample_idx;
layout(location=4) in float flip_uv;
out vec2 uv0;
out vec4 color0;
flat out int sample0;
flat out int uv_flip;

// layout(std140, binding=1) readonly buffer ssbo {
//     SpriteData sd[];
// };

void main() {
    // gl_Position = vec4(sd[gl_InstanceIndex].position[0],sd[gl_InstanceIndex].position[1], 1.0, 1.0);
    uv0 = texcoord0;
    // if (sppos.z > 0.0) {
    //     // usecolor = true;
    //     color0 = sppos;
    //     gl_Position = position;
    // } else {
    //     gl_Position = vec4(position[0], position[1], 1.0, 1.0);
    //     gl_Position *= vec4(sppos.x, sppos.x, 1.0, 1.0);
    // }

    gl_Position = vec4(position[0], position[1], 1.0, 1.0);
    // gl_Position *= vec4(sppos.x, sppos.y, 1.0, gl_InstanceIndex);
    gl_Position *= vec4(sppos.x, sppos.y, 1.0, 1.0);
    gl_Position += vec4(sppos.z, sppos[3], 0.0, 0.0);
    color0 = sppos;
    sample0 = int(sample_idx);
    uv_flip = int(flip_uv);
}
@end

@fs fsquad
layout(binding=1) uniform sampler smp;
layout(binding=2) uniform texture2D tex1;
layout(binding=3) uniform texture2D tex2;
layout(binding=4) uniform texture2D tex3;
layout(binding=5) uniform texture2D tex4;

in vec2 uv0;
in vec4 color0;
flat in int sample0;
flat in int uv_flip;
out vec4 frag_color;

void main() {
    vec2 uv1 = uv0;
    if (uv_flip > 0) {
        uv1.y = 1 - uv0.y;
    }
    if (sample0 > 0.0) {
        frag_color = texture(sampler2D(tex2, smp), uv1).rgba;
    } else {
        frag_color = texture(sampler2D(tex1, smp), uv1).rgba;
    }
    frag_color *= vec4(1.0, 1.0, 1.0, 1.0);
}
@end
@program fsq vsquad fsquad
