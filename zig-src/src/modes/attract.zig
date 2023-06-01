const std = @import("std");
const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const GameModes = @import("game_modes.zig");

pub const AttractMode = struct {
    background_image: sdl.Texture,
    font: sdl.ttf.Font,
    next_mode: ?GameModes.GameModeType,

    pub fn init(renderer: *sdl.Renderer) !AttractMode {
        const img = @embedFile("loadingscreen.png");
        const texture = sdl.image.loadTextureMem(renderer.*, img[0..], sdl.image.ImgFormat.png) catch |err| {
            return err;
        };
        try sdl.ttf.init();
        const font = try sdl.ttf.openFont("../media/freesansbold.ttf", 20);

        return AttractMode {
            .background_image = texture,
            .next_mode = null,
            .font = font,
        };
    }

    pub fn paint(self: *AttractMode, renderer: *sdl.Renderer) void {
        renderer.copy(self.background_image, null, null) catch {
            return;
        };
        self.paintInstructors(renderer) catch {};
    }

    pub fn paintInstructors(self: *AttractMode, renderer: *sdl.Renderer) !void {
        renderer.setColor(sdl.Color.white) catch {
            return;
        };
        renderer.fillRect(sdl.Rectangle{ .x = 330, .y = 60, .width = 240, .height = 120 }) catch {
            return;
        };

        var text1 = try self.font.renderTextSolid("Press [ENTER] to start.", sdl.Color.black);
		var text2 = try self.font.renderTextSolid("[N] for Next song", sdl.Color.black);
		var text3 = try self.font.renderTextSolid("[H] for Help", sdl.Color.black);
        defer text1.destroy();
        defer text2.destroy();
        defer text3.destroy();
        var textext1 = try sdl.createTextureFromSurface(renderer.*,text1);
        var textext2 = try sdl.createTextureFromSurface(renderer.*,text2);
        var textext3 = try sdl.createTextureFromSurface(renderer.*,text3);
        defer textext1.destroy();
        defer textext2.destroy();
        defer textext3.destroy();

		renderer.copy(textext1, sdl.Rectangle{ .x = 330, .y =  77, .width = text1.ptr.w, .height = text1.ptr.h }, null) catch {};
		renderer.copy(textext2, sdl.Rectangle{ .x = 330, .y = 127, .width = text2.ptr.w, .height = text2.ptr.h }, null) catch {};
		renderer.copy(textext3, sdl.Rectangle{ .x = 330, .y = 157, .width = text3.ptr.w, .height = text3.ptr.h }, null) catch {};
    }

    pub fn exit(self: *AttractMode) void {
        std.log.info("attract mode: destroying background", .{});
        self.background_image.destroy();
        self.font.close();
    }

    pub fn on_key(self: *AttractMode, key_event: sdl.KeyboardEvent) bool {
        switch (key_event.keycode) {
            sdl.Keycode.@"return", sdl.Keycode.space => self.next_mode = GameModes.GameModeType.TimedPlay,
            else => {},
        }
        return true;
    }

    pub fn on_input(self: AttractMode, event: sdl.Event) bool {
        _ = self;
        _ = event;
        return true;
    }

    pub fn update(self: *AttractMode) ?GameModes.GameModeType {
        if (self.next_mode) |mode| {
            return mode;
        }
        return null;
    }
};
