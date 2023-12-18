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
var rand = std.rand.Xoroshiro128.init(1234);

pub const PlayField = struct {
    max_width: u8 = 18,
    max_height: u8 = 18,
    x_size: u8 = 24,
    y_size: u8 = 24,
    band_width: u8,
    band_height: u8,
    actors: std.ArrayList(Sprite),
    is_dirty: bool,
    alligator: std.mem.Allocator,
    field: FieldContainer,
    move_count: u8 = 0,

    pub fn init(alligator: std.mem.Allocator, band_w: u8, band_h: u8) ?PlayField {
        return PlayField{
            .band_width = band_w,
            .band_height = band_h,
            .actors = std.ArrayList(Sprite).init(alligator),
            .is_dirty = false,
            .alligator = alligator,
            .field = field,
        };
    }

    pub fn populateField(self: *PlayField, level_number: u16, band_w: u8, band_h: u8) void {
        // self.alligator.destroy(self.actors);
        // self.actors = std.ArrayList(Sprite).init(self.alligator);
        clearSprites();
        self.band_height = band_h;
        self.band_width = band_w;
        for (0..self.band_height) |y| {
            var yy = @as(i32, @intCast(y));
            for (0..self.band_width) |x| {
                var xx = @as(i32, @intCast(x));
                {
                    for (0..level_number) |_| {
                        _ = rand.next();
                    }
                    const tag_random = rand.next();
                    if (tag_random % 4 == 0) {
                        self.field[y][x] = genSprite(BlockTextureTags.A, 24, 24).?;
                    } else if (tag_random % 3 == 0) {
                        self.field[y][x] = genSprite(BlockTextureTags.C, 24, 24).?;
                    } else if (tag_random % 2 == 0) {
                        self.field[y][x] = genSprite(BlockTextureTags.D, 24, 24).?;
                    } else {
                        self.field[y][x] = genSprite(BlockTextureTags.B, 24, 24).?;
                    }
                    self.field[y][x].setPosition(xx, yy);
                }
            }
        }
    }

    pub fn removeRow(self: *PlayField, row_idx: usize) void {
        var row_index = row_idx;
        if (self.band_height <= row_index) {
            row_index = self.band_height - 1;
        }
        // move pointers up
        for (row_index + 1..self.band_height) |y| {
            for (0..self.band_width) |x| {
                // self.field[y][x].*.setPosition(@intCast(i32, x), @intCast(i32, y));
                self.field[y - 1][x] = self.field[y][x];
                self.field[y - 1][x].setPosition(@as(i32, @intCast(x)), @as(i32, @intCast(y - 1)));
            }
        }
        for (0..self.band_width) |x| {
            self.field[self.band_height - 1][x] = undefined;
        }
        self.snapActorToBand(self.band_height - 1, -2);
        self.band_height -= 1;
    }

    pub fn removeCol(self: *PlayField, col_idx: usize) void {
        var col_index = col_idx;
        if (self.band_width <= col_index) {
            col_index = self.band_width - 1;
        }
        // move pointers left
        for (col_index..self.band_width - 1) |x| {
            for (0..self.band_height) |y| {
                self.field[y][x] = self.field[y][x + 1];
                self.field[y][x].setPosition(@as(i32, @intCast(x)), @as(i32, @intCast(y)));
            }
        }
        for (0..self.band_height) |y| {
            self.field[y][self.band_width - 1] = undefined;
        }
        self.snapActorToBand(-2, self.band_width - 1);
        self.band_width -= 1;
    }

    fn snapActorToBand(self: PlayField, new_height: c_int, new_width: c_int) void {
        for (self.actors.items) |*actor| {
            // if the actor is at the current, about to be shrunk y
            if (actor.rect.y == self.band_height and new_height != -2) {
                actor.rect.y = new_height;
            }
            if (actor.rect.x == self.band_width and new_width != -2) {
                actor.rect.x = new_width;
            }
        }
    }

    // move the actor sprite to the outside of the block band
    // we refer to the actor sprite in coords relative to the grid
    // so -1, -1 being the upper most right and
    // band_width +1, band_height +1, being the bottom right
    fn snapToBand(self: *PlayField, sprite: *Sprite) void {
        _ = self;
        sprite.setPosition(0, 0);
    }

    pub fn close(self: *PlayField) void {
        self.*.actors.deinit();
        clearSprites();
    }

    pub fn addActor(self: *PlayField, sprite: *Sprite) !void {
        try self.actors.append(sprite.*);
        self.snapToBand(sprite);
    }

    pub fn moveActor(self: *PlayField) bool {
        var actor = &self.actors.items[0];
        var rect = actor.rect;

        // corner positions cause no movement
        if (rect.x == -1 and rect.y == -1) return false;
        if (rect.x == self.band_width and rect.y == self.band_height) return false;
        if (rect.x == self.band_width and rect.y == -1) return false;
        if (rect.x == -1 and rect.y == self.band_height) return false;

        if (rect.x == -1) {
            var new_actor = self.moveRowRight(@as(usize, @intCast(rect.y)), actor);
            _ = new_actor;
        }
        if (rect.x == self.band_width) {
            var new_actor = self.moveRowLeft(@as(usize, @intCast(rect.y)), actor);
            _ = new_actor;
        }
        if (rect.y == -1) {
            var new_actor = self.moveColDown(@as(usize, @intCast(rect.x)), actor);
            _ = new_actor;
        }
        if (rect.y == self.band_height) {
            var new_actor = self.moveColUp(@as(usize, @intCast(rect.x)), actor);
            _ = new_actor;
        }
        self.move_count += 1;
        return true;
        // std.log.info("moving actor {?}", .{actor});
    }

    fn moveRowRight(self: *PlayField, band_row: usize, actor: *Sprite) ?*Sprite {
        const bw: usize = @as(usize, self.band_width);
        var x: usize = bw - 1;
        var actor_texture_tag = actor.texture_tag;

        actor.texture_tag = self.field[band_row][x].texture_tag;
        while (x > 0) : (x -= 1) {
            self.field[band_row][x].texture_tag = self.field[band_row][x - 1].texture_tag;
        }
        self.field[band_row][0].texture_tag = actor_texture_tag;
        actor.setPosition(@as(i32, @intCast(self.band_width)), @as(i32, @intCast(band_row)));
        return null;
    }

    fn moveRowLeft(self: *PlayField, band_row: usize, actor: *Sprite) ?*Sprite {
        const bw: usize = @intCast(self.band_width);
        var x: usize = 0;
        var actor_texture_tag = actor.texture_tag;

        actor.texture_tag = self.field[band_row][x].texture_tag;
        while (x < bw - 1) : (x += 1) {
            self.field[band_row][x].texture_tag = self.field[band_row][x + 1].texture_tag;
        }
        self.field[band_row][bw - 1].texture_tag = actor_texture_tag;
        actor.setPosition(@as(i32, @intCast(-1)), @as(i32, @intCast(band_row)));
        return null;
    }

    fn moveColDown(self: *PlayField, band_col: usize, actor: *Sprite) ?*Sprite {
        const bh: usize = @intCast(self.band_height);
        var y: usize = bh - 1;
        var actor_texture_tag = actor.texture_tag;

        actor.texture_tag = self.field[y][band_col].texture_tag;
        while (y > 0) : (y -= 1) {
            self.field[y][band_col].texture_tag = self.field[y - 1][band_col].texture_tag;
        }
        self.field[0][band_col].texture_tag = actor_texture_tag;
        actor.setPosition(@intCast(band_col), @intCast(self.band_height));
        return null;
    }

    fn moveColUp(self: *PlayField, band_col: usize, actor: *Sprite) ?*Sprite {
        const bw: usize = @as(usize, @intCast(self.band_height));
        var y: usize = 0;
        var actor_texture_tag = actor.texture_tag;

        actor.texture_tag = self.field[y][band_col].texture_tag;
        while (y < bw - 1) : (y += 1) {
            self.field[y][band_col].texture_tag = self.field[y + 1][band_col].texture_tag;
        }
        self.field[bw - 1][band_col].texture_tag = actor_texture_tag;
        actor.setPosition(@as(i32, @intCast(band_col)), @as(i32, @intCast(-1)));
        return null;
    }
};
