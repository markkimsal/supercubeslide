const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sglue = sokol.glue;
const sevent = sokol.app.Event;
const shader = @import("shaders/playfield.glsl.zig");
pub const sdl = @cImport({
    @cInclude("SDL.h");
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
const TimedPlayModeSokol = GameModes.TimedPlaySokol;
const SpriteMod = @import("sprite.zig");

const ANDROID = false;

const heap_alloc = std.heap.c_allocator;
pub var mode: *sdl.SDL_DisplayMode = undefined;

var current_song_index: usize = 0;
pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_AUDIO) < 0) {
        sdlPanic();
    }
    defer sdl.SDL_Quit();

    if (ANDROID) {
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_MOUSE_TOUCH_EVENTS, "1");
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_ANDROID_TRAP_BACK_BUTTON, "1");
    } else {
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_TOUCH_MOUSE_EVENTS, "0");
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_ANDROID_TRAP_BACK_BUTTON, "1");
    }

    mode = heap_alloc.create(sdl.SDL_DisplayMode) catch sdlPanic();
    _ = sdl.SDL_GetDisplayMode(0, 0, mode);
    defer sdl.SDL_free(mode);

    var window_flags: c_uint = sdl.SDL_WINDOW_SHOWN | sdl.SDL_WINDOW_RESIZABLE;
    if (ANDROID) {
        window_flags = sdl.SDL_WINDOW_FULLSCREEN | sdl.SDL_WINDOW_BORDERLESS;
    } else {
        // windowed mode, ovverride mode w/h
        mode.w = 600;
        mode.h = 800;
    }
    const window = sdl.SDL_CreateWindow("Super Cube Slide", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, mode.w, mode.h, window_flags) orelse sdlPanic();
    // second monitory
    if (!ANDROID) {
        sdl.SDL_SetWindowPosition(window, 1680, 100);
    }
    defer sdl.SDL_DestroyWindow(window);

    // bgm.start_song(current_song_index);
    // defer bgm.close();

    var renderer_flags: c_uint = sdl.SDL_RENDERER_ACCELERATED;
    if (ANDROID) {
        renderer_flags |= sdl.SDL_RENDERER_PRESENTVSYNC;
    }
    var renderer = sdl.SDL_CreateRenderer(window, -1, renderer_flags) orelse sdlPanic();

    SpriteMod.initTextures(&renderer) catch |err| {
        std.log.err("{}", .{err});
        return err;
    };

    var game_mode: GameModes.GameMode = GameModes.GameMode{ .attract = try AttractMode.AttractMode.init(heap_alloc, renderer) };
    // var game_mode: GameModes.GameMode = GameModes.GameMode{ .timed_play = try TimedPlayMode.init(renderer) };
    // const safe_area = sdl.SDL_Rect;
    // sdl.SDL_GetWindowSafeArea(&safe_area);

    var poll_event: sdl.SDL_Event = undefined;
    mainLoop: while (true) {
        const had_event = sdl.SDL_PollEvent(&poll_event);
        if (had_event > 0) {
            const consumed: bool = switch (poll_event.type) {
                sdl.SDL_WINDOWEVENT => sw_blk: {
                    //TODO: handle multiple windows?
                    if (poll_event.window.event == sdl.SDL_WINDOWEVENT_RESIZED) {
                        mode.w = poll_event.window.data1;
                        mode.h = poll_event.window.data2;
                    }
                    break :sw_blk true;
                },
                sdl.SDL_QUIT => break :mainLoop,
                sdl.SDL_KEYDOWN => sw_blk: {
                    if (poll_event.key.keysym.sym == sdl.SDLK_ESCAPE) break :mainLoop;
                    if (poll_event.key.keysym.sym == sdl.SDLK_q) break :mainLoop;
                    const consumed = game_mode.on_key(&poll_event.key);
                    break :sw_blk consumed;
                },
                sdl.SDL_MOUSEBUTTONUP,
                sdl.SDL_MOUSEBUTTONDOWN,
                sdl.SDL_MOUSEWHEEL,
                => sw_blk: {
                    const consumed = game_mode.on_input(&poll_event);
                    break :sw_blk consumed;
                },
                sdl.SDL_FINGERUP, sdl.SDL_FINGERMOTION, sdl.SDL_FINGERDOWN => sw_blk2: {
                    const consumed = game_mode.on_touch(&poll_event);
                    break :sw_blk2 consumed;
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
                GameModeType.Attract => GameModes.GameMode{ .attract = try AttractMode.AttractMode.init(heap_alloc, renderer) },
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
        // if (sdl.SDL_SetRenderDrawColor(renderer, 0xF7, 0xA4, 0x1D, 255) < 0) {}
        if (sdl.SDL_SetRenderDrawColor(renderer, 0x20, 0x10, 0x10, 0xFF) < 0) {}

        // try renderer.clear();
        if (sdl.SDL_RenderClear(renderer) > 0) {}

        game_mode.paint(renderer, mode);
        sdl.SDL_RenderPresent(renderer);
        // renderer.present();
    }
    game_mode.exit();
    // sdl.SDL_DestroyRenderer(renderer);
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

pub const app_state = struct {
    var rx: f32 = 0.0;
    var ry: f32 = 0.0;
    var direction: f16 = 1.0;
    var pip: sg.Pipeline = .{};
    pub var bind: sg.Bindings = .{};
    var pass_action: sg.PassAction = .{};
    pub var dt: f64 = 0.0;
    var game_mode: GameModes.GameMode = undefined;
    pub const offscreen = struct {
        pub var attachments: sg.Attachments = .{};
        pub var attachments_desc: sg.AttachmentsDesc = .{};
        pub var pip: sg.Pipeline = .{};
        pub var bind: sg.Bindings = .{};
        pub var pass_action: sg.PassAction = .{};
    };
};

export fn init() void {
    // var game_state = app_state{};
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    // shader and pipeline object
    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shader.fsqShaderDesc(sg.queryBackend())),
        .primitive_type = .TRIANGLE_STRIP,
        .depth = .{
            .write_enabled = true,
        },
        .cull_mode = .NONE,
    };
    pip_desc.colors[0] = .{
        // .write_mask = sg.ColorMask.RGB,
        .pixel_format = sg.PixelFormat.RGBA8,
        .blend = .{ .enabled = true, .src_factor_rgb = sg.BlendFactor.SRC_ALPHA, .dst_factor_rgb = sg.BlendFactor.ONE_MINUS_SRC_ALPHA },
    };

    pip_desc.layout.buffers[1].step_func = .PER_INSTANCE;
    pip_desc.layout.attrs[shader.ATTR_fsq_position].format = .FLOAT3;
    pip_desc.layout.attrs[shader.ATTR_fsq_texcoord0].format = .FLOAT2;
    pip_desc.layout.attrs[shader.ATTR_fsq_sppos] = .{ .format = .FLOAT4, .buffer_index = 1 };
    app_state.pip = sg.makePipeline(pip_desc);
    // framebuffer clear color
    app_state.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.15, .g = 0.15, .b = 0.25, .a = 0.25 } };

    app_state.bind.samplers[shader.SMP_smp] = sg.makeSampler(.{});

    app_state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            // positions (float3)    UV tex (float2)
            -1.0, -1.0, 1.0, 0.0, 0.0,
            1.0,  -1.0, 1.0, 1.0, 0.0,
            -1.0, 1.0,  1.0, 0.0, 1.0,
            1.0,  1.0,  1.0, 1.0, 1.0,
        }),
    });
    const max_sprites = 50;
    // an empty dynamic vertex buffer for the instancing data, goes in vertex buffer slot 1
    app_state.bind.vertex_buffers[1] = sg.makeBuffer(.{
        .usage = .STREAM,
        .size = max_sprites * @sizeOf(f32) * 4,
    });

    var offscreen_pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shader.playfieldShaderDesc(sg.queryBackend())),
        .primitive_type = .TRIANGLE_STRIP,
        .cull_mode = .NONE,
        .sample_count = 1,
        .depth = .{
            .pixel_format = .NONE,
            // .pixel_format = sg.PixelFormat.RGBA8,
            .write_enabled = true,
        },
        .color_count = 1,
    };

    offscreen_pip_desc.layout.attrs[shader.ATTR_playfield_position].format = .FLOAT3;
    offscreen_pip_desc.layout.attrs[shader.ATTR_playfield_texcoord0].format = .FLOAT2;

    offscreen_pip_desc.layout.buffers[1].step_func = .PER_INSTANCE;
    offscreen_pip_desc.layout.attrs[shader.ATTR_playfield_sppos] = .{ .format = .FLOAT2, .buffer_index = 1 };
    offscreen_pip_desc.layout.attrs[shader.ATTR_playfield_block_color] = .{ .format = .FLOAT, .buffer_index = 1 };
    offscreen_pip_desc.layout.attrs[shader.ATTR_playfield_desat] = .{ .format = .FLOAT, .buffer_index = 1 };

    app_state.offscreen.pip = sg.makePipeline(offscreen_pip_desc);
    app_state.offscreen.bind.samplers[shader.SMP_smp] = sg.makeSampler(.{});
    app_state.offscreen.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            // positions     UV tex
            -1.0, -1.0, 1.0, 0.0, 0.0,
            1.0,  -1.0, 1.0, 1.0, 0.0,
            -1.0, 1.0,  1.0, 0.0, 1.0,
            1.0,  1.0,  1.0, 1.0, 1.0,
        }),
    });

    app_state.offscreen.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 } };

    createOffscreenAttachment(sapp.width(), sapp.height());

    app_state.game_mode = GameModes.GameMode{ .timed_play_sokol = TimedPlayModeSokol.init(&app_state) catch unreachable };
}

fn createOffscreenAttachment(w: i32, h: i32) void {
    sg.destroyAttachments(app_state.offscreen.attachments);
    for (app_state.offscreen.attachments_desc.colors) |att| {
        sg.destroyImage(att.image);
    }

    // create offscreen render target images and pass
    const color_img_desc: sg.ImageDesc = .{
        .render_target = true,
        .width = w,
        .height = h,
        .sample_count = 1,
    };
    inline for (.{0}) |i| {
        app_state.offscreen.attachments_desc.colors[i].image = sg.makeImage(color_img_desc);
    }
    app_state.offscreen.attachments = sg.makeAttachments(app_state.offscreen.attachments_desc);
    app_state.bind.images[shader.IMG_tex0] = app_state.offscreen.attachments_desc.colors[0].image;
}

export fn frame() void {
    const time: f64 = @floatCast(sapp.frameDuration());
    // const time: u64 = sapp.frameCount();
    // const time: f64 = @floatCast(sapp.timing.last);
    app_state.dt += time;

    _ = app_state.game_mode.update();
    app_state.game_mode.render(&app_state);

    sg.beginPass(.{ .action = app_state.pass_action, .swapchain = sglue.swapchain() });

    //update dynamic sprite pos buffer
    var pos: [50 * 4]f32 = undefined;
    @memset(&pos, 0);
    // const mypos: f32 = @as(f32, @floatCast(std.math.sin(app_state.dt) * std.math.sin(app_state.dt)));
    const mypos: f32 = 1.0;
    // const uint32: u32 = @as(u32, @bitCast(mypos));
    pos[0] = mypos;
    sg.updateBuffer(app_state.bind.vertex_buffers[1], sg.asRange(&pos));
    sg.applyPipeline(app_state.pip);
    sg.applyBindings(app_state.bind);
    sg.draw(0, 4, 1);
    sg.endPass();
    sg.commit();
    const ns_per_ms = 1000 * 1000;
    std.time.sleep(32 * ns_per_ms);
}
export fn cleanup() void {
    sg.shutdown();
}

export fn my_event_cb(event: [*c]const sevent) callconv(.C) void {
    _ = app_state.game_mode.on_input(event);
    // switch (event.*.type) {
    //     sokol.app.EventType.MOUSE_DOWN => {
    //         _ = app_state.game_mode.ok_input();
    //     },
    //     sokol.app.EventType.TOUCHES_ENDED => {
    //     },
    //     else => {},
    // }
}
pub export const app_descriptor: sapp.Desc = .{
    .init_cb = init,
    .frame_cb = frame,
    .cleanup_cb = cleanup,
    .event_cb = my_event_cb,
    .high_dpi = true,
    .sample_count = 4,
    .icon = .{ .sokol_default = true },
    .window_title = "supercubeslide.zig",
    // .logger = .{ .func = slog.func },
    .width = 600,
    .height = 600,
};
