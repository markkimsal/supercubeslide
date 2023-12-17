const std = @import("std");
// const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const sdl = MainModule.sdl;
const GameModes = @import("game_modes.zig");
const SpriteModule = @import("../sprite.zig");

pub const AttractMode = struct {
    background_image: *sdl.SDL_Texture,
    font: *sdl.TTF_Font,
    next_mode: ?GameModes.GameModeType,

    pub fn init(renderer: *sdl.SDL_Renderer) !AttractMode {
        const img = @embedFile("loadingscreen.png");
        const texture = SpriteModule.loadTextureMem(renderer, img[0..], SpriteModule.ImgFormat.png) catch |err| {
            return err;
        };
        if (sdl.TTF_Init() > 0) {
            return error.SdlErrors;
        }
        const font = sdl.TTF_OpenFont("../media/freesansbold.ttf", 20);

        return AttractMode{
            .background_image = texture,
            .next_mode = null,
            .font = font.?,
        };
    }

    pub fn paint(self: *AttractMode, renderer: *sdl.SDL_Renderer) void {
        if (sdl.SDL_RenderCopy(renderer, self.background_image, null, null) > 0) {}
        // renderer.copy(self.background_image, null, null) catch {
        //     return;
        // };
        self.paintInstructors(renderer) catch {};
    }

    pub fn paintInstructors(self: *AttractMode, renderer: *sdl.SDL_Renderer) !void {
        if (sdl.SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 255) < 0) {
            // renderer.setColor(sdl.Color.white) catch {
            return;
        }

        // renderer.fillRect(sdl.Rectangle{ .x = 330, .y = 60, .width = 240, .height = 120 }) catch {
        var dst = sdl.SDL_Rect{ .x = 330, .y = 60, .w = 240, .h = 120 };
        if (sdl.SDL_RenderFillRect(renderer, @ptrCast(&dst)) > 0) {
            // if (sdl.SDL_FillRect(renderer, sdl.SDL_Rect{ .x = 330, .y = 60, .w = 240, .h = 120 }, sdl.SDL_MapRGBA(renderer.*.format, 0xFF, 0xFF, 0xFF, 255)) > 0) {
            return;
        }

        var text1 = try renderTextSolid(self.font, "Press [ENTER] to start.", Color.black);
        var text2 = try renderTextSolid(self.font, "[N] Next Song", Color.black);
        var text4 = try renderTextSolid(self.font, "[M] Mute Music ", Color.black);
        var text3 = try renderTextSolid(self.font, "[H] for Help", Color.black);
        defer sdl.SDL_FreeSurface(text1);
        defer sdl.SDL_FreeSurface(text2);
        defer sdl.SDL_FreeSurface(text3);
        defer sdl.SDL_FreeSurface(text4);

        var textext1 = try createTextureFromSurface(renderer, text1);
        var textext2 = try createTextureFromSurface(renderer, text2);
        var textext3 = try createTextureFromSurface(renderer, text3);
        var textext4 = try createTextureFromSurface(renderer, text4);
        defer sdl.SDL_DestroyTexture(textext1);
        defer sdl.SDL_DestroyTexture(textext2);
        defer sdl.SDL_DestroyTexture(textext3);
        defer sdl.SDL_DestroyTexture(textext4);

        if (sdl.SDL_RenderCopy(renderer, textext1, null, &sdl.SDL_Rect{ .x = 330, .y = 77, .w = text1.w, .h = text1.h }) > 0) {
            std.log.err("error rendering font", .{});
        }
        if (sdl.SDL_RenderCopy(renderer, textext2, null, &sdl.SDL_Rect{ .x = 330, .y = 117, .w = text2.w, .h = text2.h }) > 0) {}
        if (sdl.SDL_RenderCopy(renderer, textext3, null, &sdl.SDL_Rect{ .x = 330, .y = 142, .w = text3.w, .h = text3.h }) > 0) {}
        if (sdl.SDL_RenderCopy(renderer, textext4, null, &sdl.SDL_Rect{ .x = 330, .y = 167, .w = text4.w, .h = text4.h }) > 0) {}
        // renderer.copy(textext1, sdl.SDL_Rect{ .x = 330, .y = 77, .w = text1.ptr.w, .h = text1.ptr.h }, null) catch {};
        // renderer.copy(textext2, sdl.SDL_Rect{ .x = 330, .y = 117, .w = text2.ptr.w, .h = text2.ptr.h }, null) catch {};
        // renderer.copy(textext4, sdl.SDL_Rect{ .x = 330, .y = 142, .w = text4.ptr.w, .h = text4.ptr.h }, null) catch {};
        // renderer.copy(textext3, sdl.SDL_Rect{ .x = 330, .y = 167, .w = text3.ptr.w, .h = text3.ptr.h }, null) catch {};
    }

    pub fn exit(self: *AttractMode) void {
        std.log.info("attract mode: destroying background", .{});
        sdl.SDL_DestroyTexture(self.background_image);
        // self.background_image.destroy();
        sdl.TTF_CloseFont(self.font);
        // self.font.close();
    }

    pub fn on_key(self: *AttractMode, key_event: *sdl.SDL_KeyboardEvent) bool {
        return switch (key_event.keysym.sym) {
            sdl.SDLK_RETURN, sdl.SDLK_SPACE => {
                self.next_mode = GameModes.GameModeType.TimedPlay;
                return true;
            },
            else => false,
        };
    }

    pub fn on_input(self: AttractMode, event: *sdl.SDL_Event) bool {
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

pub fn renderTextSolid(self: *sdl.TTF_Font, text: [:0]const u8, foreground: Color) !*sdl.SDL_Surface {
    return sdl.TTF_RenderText_Solid(
        self,
        text.ptr,
        .{ .r = foreground.r, .g = foreground.g, .b = foreground.b, .a = foreground.a },
    );
}
pub fn createTextureFromSurface(renderer: *sdl.SDL_Renderer, surface: *sdl.SDL_Surface) !*sdl.SDL_Texture {
    return sdl.SDL_CreateTextureFromSurface(
        renderer,
        surface,
    ) orelse return error.SdlError;
}
pub const Color = extern struct {
    pub const black = rgb(0x00, 0x00, 0x00);
    pub const white = rgb(0xFF, 0xFF, 0xFF);
    pub const red = rgb(0xFF, 0x00, 0x00);
    pub const green = rgb(0x00, 0xFF, 0x00);
    pub const blue = rgb(0x00, 0x00, 0xFF);
    pub const magenta = rgb(0xFF, 0x00, 0xFF);
    pub const cyan = rgb(0x00, 0xFF, 0xFF);
    pub const yellow = rgb(0xFF, 0xFF, 0x00);

    r: u8,
    g: u8,
    b: u8,
    a: u8,

    /// returns a initialized color struct with alpha = 255
    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = 255 };
    }

    /// returns a initialized color struct
    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }
};
