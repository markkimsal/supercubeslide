@vs vs
in vec4 position;
in vec4 color_in;
in vec2 texcoord0;
out vec4 color;
out vec2 uv;

struct SpriteData {
    float position[2];
};

layout(std140, binding=1) uniform DataBlock {
    vec4 pos[100];
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
    // gl_Position += vec4(pos, 0.0, 0.0);
    // if (gl_InstanceIndex == 0) {
    //     gl_Position += vec4(-0.5, 0.0, 0.0, 0.0);
    // }
    // if (gl_InstanceIndex == 1) {
    //     gl_Position += vec4(0.5, 0.0, 0.0, 0.0);
    // }
    color = color_in;
    uv = texcoord0;
}
@end

@fs fs
layout(binding=1) uniform texture2D tex;
layout(binding=1) uniform sampler smp;
in vec4 color;
in vec2 uv;
out vec4 frag_color;
void main() {
    frag_color = texture(sampler2D(tex, smp), uv); // + color; // + color;
    // frag_color = vec4(color.g, 0.0, 0.0, 1.0);// + color;
    // frag_color = color;
    // frag_color = vec4(1.0, 1.0, 1.0, 1.0);// + color;
}
@end

@program playfield vs fs
