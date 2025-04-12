@vs vs
in vec4 position;
in vec2 texcoord0;
out vec2 uv;
flat out int tex;

layout(std140, binding=2) uniform DataBlock {
    vec4 pos[50];
    ivec4 block_color[50];
};

void main() {
    // gl_Position = vec4(sd[gl_InstanceIndex].position[0],sd[gl_InstanceIndex].position[1], 1.0, 1.0);
    gl_Position = position * vec4(0.1, 0.1, 1.0, 1.0);

    const int newspritepos = gl_InstanceIndex;
    vec4 my_pos = vec4(pos[int(floor(newspritepos/2))]);
    if (mod(newspritepos, 2) < 1) {
        gl_Position += vec4(my_pos.x, my_pos.y, 0.0, 0.0);
        // gl_Position += vec4(my_pos.x, -0.7, 0.0, 0.0);
        // gl_Position += vec4(-0.7, -0.7, 0.0, 0.0);
    } else {
        gl_Position += vec4(my_pos.z, my_pos.w, 0.0, 0.0);
        // gl_Position += vec4(-0.9, -0.9, 0.0, 0.0);
        // gl_Position += vec4(pos[int(gl_InstanceIndex)].zw, 0.0, 0.0);
    }
tex = block_color[int(floor(newspritepos))][0];
//     if (mod(newspritepos, 2) < 1) {
// tex = block_color[int(floor(newspritepos/2))].x;
//     } else {
// tex = block_color[int(floor(newspritepos/2))].y;
//     }


    // tex = block_color[gl_InstanceIndex].x;

    // gl_Position += vec4(float(gl_InstanceIndex/10), 0.0, 0.0, 0.0);
    // if (gl_InstanceIndex > 0) {
    //     gl_Position += vec4(float(gl_InstanceIndex/10), 0.0, 0.0, 0.0);
    // }else
    // if (gl_InstanceIndex/10 > 0.5) {
    //     gl_Position += vec4(0.5, 0.0, 0.0, 0.0);
    // }else
    // if (gl_InstanceIndex/10 > 0.8) {
    //     gl_Position += vec4(my_pos.x, 0.0, 0.0, 0.0);
    // }

    // gl_Position += vec4(my_pos.x, my_pos.y, 0.0, 0.0);

    // if (mod(gl_InstanceIndex, 2) < 1) {
    //     vec4 my_pos = pos[gl_InstanceIndex];
    //     gl_Position += vec4(my_pos.x, -0.7, 0.0, 0.0);
    //     // gl_Position += vec4(-0.7, -0.7, 0.0, 0.0);
    // } else {
    //     gl_Position += vec4(-0.9, -0.9, 0.0, 0.0);
    //     // gl_Position += vec4(pos[int(gl_InstanceIndex)].zw, 0.0, 0.0);
    // }
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
flat in int tex;
out vec4 frag_color;
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
        frag_color = texture(sampler2D(tex_d, smp), uv)  + vec4(0.4); // + color; // + color;
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
