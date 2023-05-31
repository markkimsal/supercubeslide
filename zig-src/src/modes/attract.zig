const std = @import("std");
const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const GameModes = @import("game_modes.zig");

pub const AttractMode = struct {
    background_image: sdl.Texture,
    next_mode: ?GameModes.GameModeType,

    pub fn init(renderer: *sdl.Renderer) !AttractMode {
        const img = @embedFile("loadingscreen.png");
        const texture = sdl.image.loadTextureMem(renderer.*, img[0..], sdl.image.ImgFormat.png) catch |err| {
            return err;
        };

        return AttractMode {
            .background_image = texture,
            .next_mode = null,
        };
    }

    pub fn paint(self: *AttractMode, renderer: *sdl.Renderer) void {
        renderer.copy(self.background_image, null, null) catch {
            return;
        };
        self.paintInstructors(renderer);
    }

    pub fn paintInstructors(self: *AttractMode, renderer: *sdl.Renderer) void {
        _ = self;
        renderer.setColor(sdl.Color.white) catch {
            return;
        };
        renderer.fillRect(sdl.Rectangle{ .x = 330, .y = 60, .width = 240, .height = 120 }) catch {
            return;
        };
    }

    pub fn exit(self: *AttractMode) void {

        std.log.info("attract mode: destroying background", .{});
        self.background_image.destroy();
    }

    pub fn on_key(self: *AttractMode, key_event: sdl.KeyboardEvent) bool {
        if (key_event.keycode == sdl.Keycode.space) {
            self.next_mode = GameModes.GameModeType.TimedPlay;
        }
        return true;
    }

    pub fn on_exit(self: *AttractMode) void {
        self.background_image.destroy();
    }

    pub fn update(self: *AttractMode) ?GameModes.GameModeType {
        if (self.next_mode) |mode| {
            return mode;
        }
        return null;
    }
};
