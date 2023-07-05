const std = @import("std");
const sdl = @import("sdl2");
const PlayField = @import("play_field.zig");
const AttractMode = @import("modes/attract.zig");
const TimedPlayMode = @import("modes/timed_play.zig").TimedPlayMode;
const bgm = @import("bgm.zig");
const GameModes = @import("modes/game_modes.zig");
const GameModeType = @import("modes/game_modes.zig").GameModeType;
const SpriteMod = @import("sprite.zig");

var current_song_index: usize = 0;
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

    bgm.start_song(current_song_index);
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
            const consumed: bool = switch (ev) {
                .quit => break :mainLoop,
                .key_down => |event| sw_blk: {
                    std.log.info("{}", .{event.keycode});
                    if (event.keycode == sdl.Keycode.escape) break :mainLoop;
                    if (event.keycode == sdl.Keycode.q) break :mainLoop;
                    const consumed = game_mode.on_key(event);
                    break :sw_blk consumed;
                },
                .mouse_button_down, .mouse_wheel => sw_blk: {
                    const consumed = game_mode.on_input(ev);
                    break :sw_blk consumed;
                },
                else => false,
            };
            if (!consumed) {
                switch (ev) {
                    .key_down => |event| {
                        global_on_key(event);
                    },
                    else => {},
                }
            }
        }
        var next_mode = game_mode.update();
        if (next_mode) |mode_type| {
            std.log.info("switching to new game mode: {?}", .{@intFromEnum(mode_type)});
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

fn global_on_key(event: sdl.KeyboardEvent) void {
    if (event.keycode == sdl.Keycode.m) {
        bgm.pause_music();
    }
    if (event.keycode == sdl.Keycode.n) {
        current_song_index += 1;
        if (current_song_index > 2) {
            current_song_index = 0;
        }
        bgm.start_song(current_song_index);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
