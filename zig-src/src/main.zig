const std = @import("std");
const sdl = @import("sdl2");
const PlayField = @import("play_field.zig");
const AttractMode = @import("modes/attract.zig");
const TimedPlayMode = @import("modes/timed_play.zig").TimedPlayMode;
const bgm = @import("bgm.zig");
const GameModes = @import("modes/game_modes.zig");
const GameModeType = @import("modes/game_modes.zig").GameModeType;
const SpriteMod = @import("sprite.zig");

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

    var renderer = try sdl.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    SpriteMod.initTextures(&renderer) catch |err| {
        std.log.err("{}", .{err});
        return;
    };

    var game_mode: GameModes.GameMode = GameModes.GameMode{ .attract = try AttractMode.AttractMode.init(&renderer) };
    // var game_mode: GameModes.GameMode = GameModes.GameMode{ .timed_play = try TimedPlayMode.init(&renderer) };

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
                .mouse_wheel => |event| {
                    _ = event;
                    var consumed = game_mode.on_input(ev);
                    _ = consumed;
                    {}
                },
                else => {},
            }
        }
        var next_mode = game_mode.update();
        if (next_mode) |mode_type| {
            std.log.info("switching to new game mode: {?}", .{@enumToInt(mode_type)});
            var new_mode = switch (mode_type) {
                GameModeType.Attract => GameModes.GameMode{ .attract = try AttractMode.AttractMode.init(&renderer) },
                GameModeType.TimedPlay => GameModes.GameMode{ .timed_play = try TimedPlayMode.init(&renderer) },
                // GameModeType.TimedPlay => try AttractMode.AttractMode.init(&renderer),
            };
            // new_mode = GameModes.GameMode{.attract = new_mode}
            defer {
                game_mode.exit();
                game_mode = new_mode;
            }
            continue :mainLoop;
        }

        try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        try renderer.clear();

        game_mode.paint(&renderer);
        renderer.present();
    }
    game_mode.exit();
    sdl.c.SDL_DestroyWindow(window.ptr);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
