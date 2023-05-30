const std = @import("std");
const alligator = std.heap.c_allocator;

const Sprite = struct {};

pub const PlayField = struct {
    width    : u8,
    height   : u8,
    x_size   : u8,
    y_size   : u8,
    actors   : std.ArrayList(Sprite),
    immobiles: std.ArrayList(Sprite),
    is_dirty : bool,

    pub fn init() PlayField {
        return PlayField{
            .width     = 12,
            .height    = 12,
            .x_size    = 24,
            .y_size    = 24,
            .actors    = std.ArrayList(Sprite).init(alligator),
            .immobiles = std.ArrayList(Sprite).init(alligator),
            .is_dirty  = false,
        };
    }
};
