const std = @import("std");
const sdl = @import("sdl2");
const PlayField = @import("play_field.zig");
const AttractMode = @import("modes/attract.zig");
const bgm = @import("bgm.zig");

pub const GameModeType = enum {
    Attract,
    Play,
};
pub fn main() !void {
    try sdl.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer sdl.quit();

    var window = try sdl.createWindow(
        "Super Cube Slide",
        .{ .centered = {} },
        .{ .centered = {} },
        640,
        480,
        .{ .vis = .shown },
    );
    defer window.destroy();

    bgm.start_song(0);
    defer bgm.close();
    const play_field = PlayField.PlayField.init();
    _ = play_field;

    var renderer = try sdl.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    var game_mode = try AttractMode.AttractMode.init(&renderer);

    mainLoop: while (true) {
        while (sdl.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                .key_down => |event| {
                    std.log.info("{}", .{event.keycode});
                    if (event.keycode == sdl.Keycode.escape) break :mainLoop;
                    if (event.keycode == sdl.Keycode.q) break :mainLoop;
                    var consumed = game_mode.on_key(event);
                    _ = consumed;
                    {}
                },
                else => {},
            }
        }
        var next_mode = game_mode.update();
        _ = next_mode;

        try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        try renderer.clear();

        game_mode.paint(&renderer);
        renderer.present();
    }
    game_mode.on_exit();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
