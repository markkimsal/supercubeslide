@vs vs
in vec4 position;
in vec4 color_in;
in vec2 texcoord0;
out vec4 color;
out vec2 uv;
flat out int tex;

struct SpriteData {
    float position[2];
};

layout(std140, binding=1) uniform DataBlock {
    vec4 pos[50];
    ivec4 block_color[50];
};

void main() {
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
    color = color_in;
    uv = texcoord0;
}
@end

@fs fs
layout(binding=1) uniform texture2D tex_a;
layout(binding=1) uniform sampler smp;
layout(binding=2) uniform texture2D tex_b;
layout(binding=3) uniform texture2D tex_c;
layout(binding=4) uniform texture2D tex_d;
in vec4 color;
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
