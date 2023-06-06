const std = @import("std");
const sdl = @import("sdl2");
// const alligator = std.heap.c_allocator;

const Sprite = @import("sprite.zig").Sprite;
const genSprite = @import("sprite.zig").genSprite;
const clearSprites = @import("sprite.zig").clearSprites;
const BlockTextureTags = @import("sprite.zig").BlockTextureTags;

const play_field_width = 18;
const play_field_height = 18;
// const FieldContainer = std.AutoHashMap(u32, std.ArrayList(Sprite));
const FieldContainer = [play_field_height][play_field_width]*Sprite;
var field: FieldContainer = undefined;

pub const PlayField = struct {
    width: u8,
    height: u8,
    x_size: u8,
    y_size: u8,
    actors: std.ArrayList(Sprite),
    // immobiles: std.ArrayList(Sprite),
    is_dirty: bool,
    alligator: std.mem.Allocator,
    field: FieldContainer,

    pub fn init(alligator: std.mem.Allocator) ?PlayField {
        // var immobiles = std.ArrayList(Sprite).init(alligator);
        return PlayField{
            .width = 18,
            .height = 18,
            .x_size = 24,
            .y_size = 24,
            .actors = std.ArrayList(Sprite).init(alligator),
            // .immobiles = immobiles,
            .is_dirty = false,
            .alligator = alligator,
            .field = field,
        };
    }

    pub fn populateField(self: *PlayField, renderer: *sdl.Renderer) void {
        _ = renderer;

        for (0..self.height) |y| {
            var xx = @intCast(i32, y);
            for (0..self.width) |x| {
                var yy = @intCast(i32, x);
                {
                    if (x % 4 == 0) {
                        self.field[y][x] = genSprite(BlockTextureTags.A, 24, 24).?;
                    } else if (x % 3 == 0) {
                        self.field[y][x] = genSprite(BlockTextureTags.C, 24, 24).?;
                    } else if (x % 2 == 0) {
                        self.field[y][x] = genSprite(BlockTextureTags.D, 24, 24).?;
                    } else {
                        self.field[y][x] = genSprite(BlockTextureTags.B, 24, 24).?;
                    }
                    self.field[y][x].setPosition(24 * xx, 24 * yy);
                }
            }
        }
    }

    pub fn close(self: *PlayField) void {
        self.*.actors.deinit();
        clearSprites();
        // self.*.immobiles.deinit();
    }

    pub fn addActor(self: *PlayField, sprite: *Sprite) !void {
        try self.actors.append(sprite.*);
    }
};
