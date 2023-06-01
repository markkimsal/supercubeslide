const std = @import("std");
const sdl = @import("sdl2");

pub const Sprite = struct {
    const Self = @This();

    texture: sdl.Texture,
    rect : sdl.Rectangle,

    pub fn init(tex: sdl.Texture, x_size: i32, y_size: i32) Self {
        return Self {
            .texture = tex,
            .rect = sdl.Rectangle{ .x = 0, .y = 0, .width = x_size, .height = y_size },
        };
    }

    pub fn setPosition(self: *Self, x: i32, y: i32) void {
        self.rect.x = x;
        self.rect.y = y;
    }

    pub fn moveClockwise(self: *Self) void {
        self.rect.x -= self.rect.width;
    }

    pub fn moveCounterClockwise(self: *Self) void {
        self.rect.x += self.rect.width;
    }
};
