const std = @import("std");
// const sdl = @import("sdl2");

const MainModule = @import("main.zig");
const sdl = MainModule.sdl;
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

var block_textures: [4]*sdl.SDL_Texture = undefined;

pub fn initTextures(renderer: **sdl.SDL_Renderer) !void {
    block_textures[0] = try loadTextureMem(renderer.*, img_a[0..], ImgFormat.png);

    const cube_texture_b = try loadTextureMem(renderer.*, img_b[0..], ImgFormat.png);
    block_textures[1] = cube_texture_b;
    block_textures[2] = try loadTextureMem(renderer.*, img_c[0..], ImgFormat.png);
    block_textures[3] = try loadTextureMem(renderer.*, img_d[0..], ImgFormat.png);
}
pub fn closeTextures() void {
    sdl.SDL_DestroyTexture(block_textures[0]);
    sdl.SDL_DestroyTexture(block_textures[1]);
    sdl.SDL_DestroyTexture(block_textures[2]);
    sdl.SDL_DestroyTexture(block_textures[3]);
    // block_textures[0].destroy();
    // block_textures[1].destroy();
    // block_textures[2].destroy();
    // block_textures[3].destroy();
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
    rect: sdl.SDL_Rect,
    desaturate: f64,

    pub fn init(tex_tag: BlockTextureTags, x_size: i32, y_size: i32) Self {
        return Self{
            .texture_tag = tex_tag,
            .rect = sdl.SDL_Rect{ .x = 0, .y = 0, .w = @as(c_int, x_size), .h = @as(c_int, y_size) },
            .desaturate = 0,
        };
    }

    pub fn getTexture(self: Self) *sdl.SDL_Texture {
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

pub const ImgFormat = enum { png, jpg, bmp };

pub fn loadTextureMem(ren: *sdl.SDL_Renderer, img: [:0]const u8, format: ImgFormat) !*sdl.SDL_Texture {
    const rw = sdl.SDL_RWFromConstMem(
        @ptrCast(&img[0]),
        @intCast(img.len),
    ) orelse return error.SdlError;

    defer std.debug.assert(sdl.SDL_RWclose(rw) == 0);

    var surface: *sdl.SDL_Surface = undefined;
    switch (format) {
        .png => surface = sdl.IMG_LoadPNG_RW(rw) orelse return error.SdlError,
        .jpg => surface = sdl.IMG_LoadJPG_RW(rw) orelse return error.SdlError,
        .bmp => surface = sdl.IMG_LoadBMP_RW(rw) orelse return error.SdlError,
    }
    defer sdl.SDL_FreeSurface(surface);

    return sdl.SDL_CreateTextureFromSurface(ren, surface) orelse return error.SdlError;
    // return sdl.SDL_Texture{
    //     .ptr = sdl.SDL_CreateTextureFromSurface(ren.ptr, surface) orelse return error.SdlError,
    // };
}
