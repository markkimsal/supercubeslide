const std = @import("std");
const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const GameModes = @import("game_modes.zig");

pub const TimedPlayMode = struct {
    background_image: sdl.Texture,
    cube_a: sdl.Texture,
    next_mode: ?GameModes.GameModeType,

    pub fn init(renderer: *sdl.Renderer) !TimedPlayMode {
        const img = @embedFile("background.png");
        const texture = sdl.image.loadTextureMem(renderer.*, img[0..], sdl.image.ImgFormat.png) catch |err| {
            return err;
        };
        const cube_a = @embedFile("cube_a.png");
        const cube_texture = sdl.image.loadTextureMem(renderer.*, cube_a[0..], sdl.image.ImgFormat.png) catch |err| {
            return err;
        };

        return TimedPlayMode {
            .background_image = texture,
            .cube_a = cube_texture,
            .next_mode = null,
        };
    }

    pub fn paint(self: *TimedPlayMode, renderer: *sdl.Renderer) void {
        renderer.copy(self.background_image, null, null) catch {
            return;
        };
        self.paintActors(renderer);
    }

    pub fn paintActors(self: *TimedPlayMode, renderer: *sdl.Renderer) void {
        const rect = sdl.Rectangle{ .x = 330, .y = 60, .width = 24, .height = 24 };
        renderer.copy(self.cube_a, rect, null) catch {
            std.log.warn("error", .{});
        };
    }

    pub fn exit(self: *TimedPlayMode) void {
        std.log.info("timed play mode: destroying background", .{});
        self.background_image.destroy();
    }

    pub fn on_key(self: *TimedPlayMode, key_event: sdl.KeyboardEvent) bool {
        _ = self;
        _ = key_event;
        // if (key_event.keycode == sdl.Keycode.space) {
        //     self.next_mode = GameModes.GameModeType.TimedPlay;
        // }
        return true;
    }

    pub fn update(self: *TimedPlayMode) ?GameModes.GameModeType {
        if (self.next_mode) |mode| {
            return mode;
        }
        return null;
    }
};
