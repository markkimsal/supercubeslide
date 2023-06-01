const sdl = @import("sdl2");
const Attract = @import("attract.zig").AttractMode;
const TimedPlay = @import("timed_play.zig").TimedPlayMode;

pub const GameModeType = enum {
    Attract,
    TimedPlay,
};

pub const GameMode = union(enum) {
    const Self = @This();
    attract: Attract,
    timed_play: TimedPlay,

    pub fn init(self: *Self, renderer: *sdl.Renderer) !GameMode {
        switch (self.*) {
            inline else => |*case| return case.init(renderer),
        }
    }

    pub fn paint(self: *Self, renderer: *sdl.Renderer) void {
        switch (self.*) {
            inline else => |*case| case.paint(renderer),
        }
    }

    pub fn exit(self: *Self) void {
        switch (self.*) {
            inline else => |*case| case.exit(),
        }
    }

    pub fn on_key(self: *Self, key_event: sdl.KeyboardEvent) bool {
        switch (self.*) {
            inline else => |*case| return case.on_key(key_event),
        }
    }
    pub fn on_input(self: *Self, event: sdl.Event) bool {
        switch (self.*) {
            inline else => |*case| return case.on_input(event),
        }
    }

    pub fn update(self: *Self) ?GameModeType {
        switch (self.*) {
            inline else => |*case| return case.update(),
        }
        return null;
    }
};
