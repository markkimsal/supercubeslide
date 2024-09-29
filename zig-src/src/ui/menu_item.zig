const MainModule = @import("../main.zig");
const GameModes = @import("../modes/game_modes.zig");
const GameMode = GameModes.GameMode;
const AttractMode = @import("../modes/attract.zig").AttractMode;
const TimedPlayMode = @import("../modes/timed_play.zig").TimedPlayMode;
const sdl = MainModule.sdl;
const Color = @import("../modes/attract.zig").Color;
const std = @import("std");

pub const MenuItem = struct {
    const Self = @This();

    rect: sdl.SDL_Rect,
    texture: ?*sdl.SDL_Texture,
    desaturate: f64,
    padding: i8,
    on_click: ?*const(fn(event: *sdl.SDL_Event, game_mode: *AttractMode) bool),

    pub fn init(rect: sdl.SDL_Rect) Self {
        return Self{
            .rect = rect,
            .desaturate = 0.0,
            .texture = null,
            .padding = 10,
            .on_click = undefined,
        };
    }

    pub fn set_on_click(self: *Self, callback: *const(fn(event: *sdl.SDL_Event, game_mode: *AttractMode) bool)) void {
        self.on_click = callback;
    }

    pub fn set_text(self: *Self, font: ?*sdl.TTF_Font, renderer: *sdl.SDL_Renderer, text: [:0]const u8) void {
        // _ = text;
        const text_surface = renderTextSolid(font, text, Color.black) catch {
            unreachable;
        };
        defer sdl.SDL_FreeSurface(text_surface);
        const text_texture = createTextureFromSurface(renderer, text_surface) catch {
            unreachable;
        };
        self.texture = text_texture;

        self.rect.h = text_surface.h + self.padding;
        self.rect.w = text_surface.w + self.padding;
        // return;
        defer sdl.SDL_DestroyTexture(text_texture);
        // const mode = MainModule.mode;
        self.texture = sdl.SDL_CreateTexture(renderer, sdl.SDL_PIXELFORMAT_RGB24, sdl.SDL_TEXTUREACCESS_TARGET, text_surface.w + self.padding, text_surface.h + self.padding);

        if (sdl.SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF) < 0) {}
        _ = sdl.SDL_SetRenderTarget(renderer, self.texture);
        _ = sdl.SDL_RenderClear(renderer);
        _ = sdl.SDL_RenderCopy(renderer, text_texture, null, &sdl.SDL_Rect{ .x = @divFloor(self.padding, 2), .y = @divFloor(self.padding, 2), .w = text_surface.w, .h = text_surface.h });
        _ = sdl.SDL_SetRenderTarget(renderer, null);
        // self.rect.h = text_surface.h + self.padding;
        // self.rect.w = text_surface.w + self.padding;
    }

    pub fn paint(self: *Self, renderer: *sdl.SDL_Renderer) void {
        const textext1 = self.texture;
        if (sdl.SDL_RenderCopy(renderer, textext1, null, &self.rect) > 0) {}

        if (sdl.SDL_SetRenderDrawColor(renderer, Color.gray.r, Color.gray.g, Color.gray.b, Color.gray.a) > 0) {}
        if (sdl.SDL_RenderDrawRect(renderer, &self.rect) > 0) {}
    }

    pub fn destroy(self: *Self) void {
        _ = sdl.SDL_DestroyTexture(self.texture);
        // _ = sdl.SDL_free(&self.rect);
    }
};

fn renderTextSolid(self: ?*sdl.TTF_Font, text: [:0]const u8, foreground: Color) !*sdl.SDL_Surface {
    return sdl.TTF_RenderText_Solid(
        self,
        text.ptr,
        .{ .r = foreground.r, .g = foreground.g, .b = foreground.b, .a = foreground.a },
    ) orelse return error.SdlError;
}

fn createTextureFromSurface(renderer: *sdl.SDL_Renderer, surface: *sdl.SDL_Surface) !*sdl.SDL_Texture {
    return sdl.SDL_CreateTextureFromSurface(
        renderer,
        surface,
    ) orelse return error.SdlError;
}
