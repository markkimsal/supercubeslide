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
    band_width: u8,
    band_height: u8,
    x_size: u8,
    y_size: u8,
    actors: std.ArrayList(Sprite),
    // immobiles: std.ArrayList(Sprite),
    is_dirty: bool,
    alligator: std.mem.Allocator,
    field: FieldContainer,

    pub fn init(alligator: std.mem.Allocator, band_w: u8, band_h: u8) ?PlayField {
        // var immobiles = std.ArrayList(Sprite).init(alligator);
        return PlayField{
            .width = 18,
            .height = 18,
            .x_size = 24,
            .y_size = 24,
            .band_width = band_w,
            .band_height = band_h,
            .actors = std.ArrayList(Sprite).init(alligator),
            // .immobiles = immobiles,
            .is_dirty = false,
            .alligator = alligator,
            .field = field,
        };
    }

    pub fn populateField(self: *PlayField, renderer: *sdl.Renderer) void {
        _ = renderer;

        for (0..self.band_height) |y| {
            var yy = @intCast(i32, y);
            for (0..self.band_width) |x| {
                var xx = @intCast(i32, x);
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
                    self.field[y][x].setPosition(xx, yy);
                }
            }
        }
    }

    pub fn removeRow(self: *PlayField) void {
        var row_index: usize = 2;
        // for (0..self.band_width) |x| {
        //     self.field[row_index][x] = undefined;
        // }
        // move pointers up
        for (row_index + 1..self.band_height) |y| {
            for (0..self.band_width) |x| {
                // self.field[y][x].*.setPosition(@intCast(i32, x), @intCast(i32, y));
                self.field[y - 1][x] = self.field[y][x];
                self.field[y - 1][x].setPosition(@intCast(i32, x), @intCast(i32, (y - 1)));
            }
        }
        for (0..self.band_width) |x| {
            self.field[self.band_height][x] = undefined;
        }
        self.snapActorToBand(self.band_height - 1);
        self.band_height -= 1;
    }

    fn snapActorToBand(self: PlayField, new_height: c_int) void {
        for (self.actors.items) |*actor| {
            // if the actor is at the current, about to be shrunk y
            if (actor.rect.y == self.band_height) {
                actor.rect.y = new_height;
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
        self.snapToBand(sprite);
    }

    // move the actor sprite to the outside of the block band
    // we refer to the actor sprite in coords relative to the grid
    // so -1, -1 being the upper most right and
    // band_width +1, band_height +1, being the bottom right
    fn snapToBand(self: *PlayField, sprite: *Sprite) void {
        _ = self;
        sprite.setPosition(0, 0);
    }
};
