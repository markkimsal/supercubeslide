const std = @import("std");
const sdl = @import("sdl2");
// const alligator = std.heap.c_allocator;

const Sprite = @import("sprite.zig").Sprite;
const BlockTextureTags = @import("sprite.zig").BlockTextureTags;

// const FieldContainer = std.AutoHashMap(u32, std.ArrayList(Sprite));
const FieldContainer = std.AutoHashMap(u32, [10]Sprite);

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
        var field = FieldContainer.init(alligator);
        for (0..10) |x| {
            // field.put(@intCast(u32, x), std.ArrayList(Sprite).init(alligator)) catch |err| {
            // field.put(@intCast(u32, x), [10]*Sprite{ undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined }) catch |err| {
            // var s: [:10]
            // field.put(@intCast(u32, x), [10]*Sprite{ undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined }) catch |err| {
            // var deez = [10]Sprite{ undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined };
            var deez: [10]Sprite = undefined;
            // var deez: ?[]*Sprite = alligator.alloc(*Sprite, 10) catch |err| {
            //     std.log.err("{}", .{err});
            //     return null;
            // };
            // @intToPtr(*[10]*Sprite, @ptrToInt(&[10]*Sprite{ undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined }));
            // var deez: ?[]*Sprite = alligator.alloc(*Sprite, 10) catch null;
            field.put(@intCast(u32, x), deez) catch |err| {
                std.log.err("Cannot initialize play field grid", .{});
                std.log.err("{}", .{err});
            };
        }
        // var immobiles = std.ArrayList(Sprite).init(alligator);
        return PlayField{
            .width = 12,
            .height = 12,
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

        for (0..10) |x| {
            var xx = @intCast(i32, x);
            var field_line: ?[10]Sprite = self.field.get(@intCast(u32, x));
            if (field_line) |*arra| {
                for (0..10) |y| {
                    var yy = @intCast(i32, y);
                    {
                        // var spr = Sprite.init(cube_texture, 24, 24);
                        // arra.*[y] = @intToPtr(*Sprite, @ptrToInt(&spr));
                        // arra.*[y] = @intToPtr(*Sprite, @ptrToInt(&Sprite.init(cube_texture, 24, 24 * yy)));
                        if (y % 4 == 0) {
                            arra.*[y] = Sprite.init(BlockTextureTags.A, 24, 24);
                        } else if (y % 3 == 0) {
                            arra.*[y] = Sprite.init(BlockTextureTags.C, 24, 24);
                        } else if (y % 2 == 0) {
                            arra.*[y] = Sprite.init(BlockTextureTags.D, 24, 24);
                        } else {
                            arra.*[y] = Sprite.init(BlockTextureTags.B, 24, 24);
                        }
                        arra.*[y].setPosition(24 * xx, 24 * yy);
                    }
                }
                self.*.field.put(@intCast(u32, x), arra.*) catch {};
            }
        }
    }

    pub fn close(self: *PlayField) void {
        self.*.actors.deinit();
        // self.*.immobiles.deinit();
        self.*.field.deinit();
    }

    pub fn addActor(self: *PlayField, sprite: *Sprite) !void {
        try self.actors.append(sprite.*);
    }
};
