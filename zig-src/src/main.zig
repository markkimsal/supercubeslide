const std = @import("std");
pub const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
    @cInclude("SDL_mixer.h");
});
const PlayField = @import("play_field.zig");
const AttractMode = @import("modes/attract.zig");
const TimedPlayMode = @import("modes/timed_play.zig").TimedPlayMode;
const bgm = @import("bgm.zig");
const GameModes = @import("modes/game_modes.zig");
const GameModeType = @import("modes/game_modes.zig").GameModeType;
const SpriteMod = @import("sprite.zig");

var current_song_index: usize = 0;
pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_AUDIO) < 0) {
        sdlPanic();
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow(
        "Super Cube Slide",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        640,
        480,
        sdl.SDL_WINDOW_SHOWN,
    ) orelse sdlPanic();
    defer sdl.SDL_DestroyWindow(window);

    bgm.start_song(current_song_index);
    defer bgm.close();

    var renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
    defer sdl.SDL_DestroyRenderer(renderer);

    SpriteMod.initTextures(&renderer) catch |err| {
        std.log.err("{}", .{err});
        return;
    };

    var game_mode: GameModes.GameMode = GameModes.GameMode{ .attract = try AttractMode.AttractMode.init(renderer) };
    // var game_mode: GameModes.GameMode = GameModes.GameMode{ .timed_play = try TimedPlayMode.init(&renderer) };

    var poll_event: sdl.SDL_Event = undefined;
    mainLoop: while (true) {
        const had_event = sdl.SDL_PollEvent(&poll_event);
        if (had_event > 0) {
            const consumed: bool = switch (poll_event.type) {
                sdl.SDL_QUIT => break :mainLoop,
                sdl.SDL_KEYDOWN => sw_blk: {
                    if (poll_event.key.keysym.sym == sdl.SDLK_ESCAPE) break :mainLoop;
                    if (poll_event.key.keysym.sym == sdl.SDLK_q) break :mainLoop;
                    const consumed = game_mode.on_key(&poll_event.key);
                    break :sw_blk consumed;
                },
                sdl.SDL_MOUSEBUTTONDOWN, sdl.SDL_MOUSEWHEEL => sw_blk: {
                    const consumed = game_mode.on_input(&poll_event);
                    break :sw_blk consumed;
                },
                else => false,
            };
            if (!consumed) {
                switch (poll_event.type) {
                    sdl.SDL_KEYDOWN => {
                        global_on_key(&poll_event.key);
                    },
                    else => {},
                }
            }
        }
        const next_mode = game_mode.update();
        if (next_mode) |mode_type| {
            std.log.info("switching to new game mode: {?}", .{@intFromEnum(mode_type)});
            const new_mode = switch (mode_type) {
                GameModeType.Attract => GameModes.GameMode{ .attract = try AttractMode.AttractMode.init(renderer) },
                GameModeType.TimedPlay => GameModes.GameMode{ .timed_play = try TimedPlayMode.init(renderer) },
                // GameModeType.TimedPlay => try AttractMode.AttractMode.init(&renderer),
            };
            // new_mode = GameModes.GameMode{.attract = new_mode}
            defer {
                game_mode.exit();
                game_mode = new_mode;
            }
            continue :mainLoop;
        }

        // try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        if (sdl.SDL_SetRenderDrawColor(renderer, 0xF7, 0xA4, 0x1D, 255) < 0) {}

        // try renderer.clear();
        if (sdl.SDL_RenderClear(renderer) > 0) {}

        game_mode.paint(renderer);
        sdl.SDL_RenderPresent(renderer);
        // renderer.present();
    }
    game_mode.exit();
    sdl.SDL_DestroyWindow(window);
}

fn global_on_key(event: *sdl.SDL_KeyboardEvent) void {
    if (event.keysym.sym == sdl.SDLK_m) {
        bgm.pause_music();
    }
    if (event.keysym.sym == sdl.SDLK_n) {
        current_song_index += 1;
        if (current_song_index > 2) {
            current_song_index = 0;
        }
        bgm.start_song(current_song_index);
    }
}
fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, sdl.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

// pub fn pollEvent() ?Event {
//     var ev: c.SDL_Event = undefined;
//     if (c.SDL_PollEvent(&ev) != 0)
//         return Event.from(ev);
//     return null;
// }

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
