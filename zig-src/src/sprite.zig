const std = @import("std");
const sdl = @import("sdl2");

const img_a = @embedFile("cube_a.png");
const img_b = @embedFile("cube_b.png");
const img_c = @embedFile("cube_c.png");
const img_d = @embedFile("cube_d.png");
// const texture_a = sdl.image.loadTextureMem(renderer.*, img[0..], sdl.image.ImgFormat.png) catch |err| {
//     return err;
// };

pub const BlockTextureTags = enum {
    A,
    B,
    C,
    D,
};

var block_textures: [4]sdl.Texture = undefined;

pub fn initTextures(renderer: *sdl.Renderer) !void {
    block_textures[0] = try sdl.image.loadTextureMem(renderer.*, img_a[0..], sdl.image.ImgFormat.png);
    const cube_texture_b = try sdl.image.loadTextureMem(renderer.*, img_b[0..], sdl.image.ImgFormat.png);
    block_textures[1] = cube_texture_b;
    block_textures[2] = try sdl.image.loadTextureMem(renderer.*, img_c[0..], sdl.image.ImgFormat.png);
    block_textures[3] = try sdl.image.loadTextureMem(renderer.*, img_d[0..], sdl.image.ImgFormat.png);
}
pub fn closeTextures() void {
    block_textures[0].destroy();
    block_textures[1].destroy();
}

var sprite_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var sprite_allocator = sprite_arena.allocator();

pub fn clearSprites() void {
    _ = sprite_arena.reset(std.heap.ArenaAllocator.ResetMode.free_all);
}

pub fn genSprite(tex_tag: BlockTextureTags, x_size: i32, y_size: i32) ?*Sprite {
    var s: *Sprite = sprite_allocator.create(Sprite) catch {
        return null;
    };
    s.* = Sprite.init(tex_tag, x_size, y_size);
    return s;
}

pub const Sprite = struct {
    const Self = @This();

    texture_tag: BlockTextureTags,
    rect: sdl.Rectangle,
    desaturate: f64,

    pub fn init(tex_tag: BlockTextureTags, x_size: i32, y_size: i32) Self {
        return Self{
            .texture_tag = tex_tag,
            .rect = sdl.Rectangle{ .x = 0, .y = 0, .width = @as(c_int, x_size), .height = @as(c_int, y_size) },
            .desaturate = 0,
        };
    }

    pub fn getTexture(self: Self) sdl.Texture {
        return block_textures[@intFromEnum(self.texture_tag)];
    }

    pub fn setPosition(self: *Self, x: i32, y: i32) void {
        self.rect.x = x;
        self.rect.y = y;
    }

    pub fn moveClockwise(self: *Self) void {
        // self.rect.x -= self.rect.width;
        self.rect.x -= 1;
    }

    pub fn moveCounterClockwise(self: *Self) void {
        // self.rect.x += self.rect.width;
        self.rect.x += 1;
    }
};
