const sdl = @import("sdl2");
const MainModule = @import("../main.zig");

pub const AttractMode = struct {
    background_image: sdl.Texture,

    pub fn init(renderer: *sdl.Renderer) !AttractMode {
        const img = @embedFile("loadingscreen.png");
        const texture = sdl.image.loadTextureMem(renderer.*, img[0..], sdl.image.ImgFormat.png) catch |err| {
            return err;
        };

        return AttractMode{
            .background_image = texture,
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
        renderer.fillRect(sdl.Rectangle{.x = 330, .y = 60, .width = 240, .height =120}) catch {
            return;
        };
    }

    pub fn exit_mode(self: *AttractMode) void {
        self.background_image.destroy();
    }

    pub fn on_key(self: *AttractMode, key_event: sdl.KeyboardEvent) bool {
        _ = self;
        _ = key_event;
        return true;
    }

    pub fn on_exit(self: *AttractMode) void {
        self.background_image.destroy();
    }

    pub fn update(self: *AttractMode) ?MainModule.GameModeType {
        _ = self;
        return null;
    }
};
