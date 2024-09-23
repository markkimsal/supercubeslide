const std = @import("std");
// const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const sdl = MainModule.sdl;
const GameModes = @import("game_modes.zig");
const SpriteModule = @import("../sprite.zig");
const bgm = @import("../bgm.zig");

pub const AttractMode = struct {
    background_image: *sdl.SDL_Texture,
    font: *sdl.TTF_Font,
    next_mode: ?GameModes.GameModeType,
    display_mode: ?*sdl.SDL_DisplayMode,

    pub fn init(renderer: *sdl.SDL_Renderer) !AttractMode {
        const img = @embedFile("loadingscreen.png");
        const texture = SpriteModule.loadTextureMem(renderer, img[0..], SpriteModule.ImgFormat.png) catch |err| {
            return err;
        };
        if (sdl.TTF_Init() > 0) {
            return error.SdlErrors;
        }
        const font_mem = @embedFile("freesansbold.ttf");
        const font_rw = sdl.SDL_RWFromConstMem(
            @ptrCast(&font_mem[0]),
            @intCast(font_mem.len),
        ) orelse return error.SdlError;

        const font = sdl.TTF_OpenFontRW(font_rw, 1, 20);

        return AttractMode{
            .background_image = texture,
            .next_mode = null,
            .display_mode = null,
            .font = font.?,
        };
    }

    pub fn paint(self: *AttractMode, renderer: *sdl.SDL_Renderer, mode: *sdl.SDL_DisplayMode) void {

        self.display_mode = mode;
        const src_w = 640;
        const src_h = 480;
        // const base_tex = sdl.SDL_CreateTexture(renderer, mode.format, sdl.SDL_TEXTUREACCESS_TARGET, src_w, src_h);
        const base_tex: ?*sdl.SDL_Texture = sdl.SDL_CreateTexture(renderer, mode.format, sdl.SDL_TEXTUREACCESS_TARGET, src_w, src_h);

        if (sdl.SDL_SetRenderTarget(renderer, base_tex.?) > 0) {
            std.log.err("unable to set renderer target", .{});
            sdl.SDL_DestroyTexture(base_tex);
            return;
        }


        // const dst = sdl.SDL_Rect{ .x = 0, .y = 0, .w = 800, .h = 600 };
        if (sdl.SDL_RenderCopy(renderer, self.background_image, null, null) > 0) {}
        // renderer.copy(self.background_image, null, null) catch {
        //     return;
        // };
        self.paintInstructors(renderer) catch {};

        _ = sdl.SDL_SetRenderTarget(renderer, null);
        var dst = sdl.SDL_Rect{ .x = @divFloor((mode.w - src_w), 2), .y = @divFloor((mode.h - src_h), 2), .w = src_w, .h = src_h };
        const is_vertical = mode.h > mode.w;
        var ratio: f64 = (@as(f64, @floatFromInt(mode.w)) / @as(f64, @floatFromInt(src_w)));
        if(is_vertical == true) {
            // stretch out
            dst.x = 0;
            dst.w = mode.w;

            dst.h = @as(c_int, @intFromFloat(@round(src_h * ratio)));
            dst.y = @divFloor((mode.h - dst.h), 2);
        } else {
            // stretch out
            dst.y = 0;
            dst.h = mode.h;

            ratio = (@as(f64, @floatFromInt(mode.h)) / @as(f64, @floatFromInt(src_h)));
            dst.w = @as(c_int, @intFromFloat(@round(src_w * ratio)));
            dst.x = @divFloor((mode.w - dst.w), 2);
        }


        _ = sdl.SDL_RenderCopy(renderer, base_tex, null, &dst);
        sdl.SDL_DestroyTexture(base_tex);
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

        const text1 = try renderTextSolid(self.font, "Press [ENTER] to start.", Color.black);
        const text2 = try renderTextSolid(self.font, "[N] Next Song", Color.black);
        const text4 = try renderTextSolid(self.font, "[M] Mute Music ", Color.black);
        const text3 = try renderTextSolid(self.font, "[H] for Help", Color.black);
        defer sdl.SDL_FreeSurface(text1);
        defer sdl.SDL_FreeSurface(text2);
        defer sdl.SDL_FreeSurface(text3);
        defer sdl.SDL_FreeSurface(text4);

        const textext1 = try createTextureFromSurface(renderer, text1);
        const textext2 = try createTextureFromSurface(renderer, text2);
        const textext3 = try createTextureFromSurface(renderer, text3);
        const textext4 = try createTextureFromSurface(renderer, text4);
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

    pub fn on_touch(self: *AttractMode, event: *sdl.SDL_Event) bool {
        _ = switch (event.tfinger.type) {
            sdl.SDL_FINGERUP => {
                self.touch_intersects_menu(event);
                return true;
            },
            else => false,
        };

        return true;
    }

    pub fn update(self: *AttractMode) ?GameModes.GameModeType {
        if (self.next_mode) |mode| {
            return mode;
        }
        return null;
    }

    fn touch_intersects_menu(self: *AttractMode, event: *sdl.SDL_Event) void {

        var rect = sdl.SDL_Rect {.x = @as(c_int, @intFromFloat(event.tfinger.x * 100.0)), .y = @as(c_int, @intFromFloat(event.tfinger.y * 100.0)), .w = 2, .h = 2};
        sdl.SDL_Log("\nfinger up x: %f finger up y: %f.\n",
        event.tfinger.x * 100,
        event.tfinger.y * 100
        );
        sdl.SDL_Log("\nfinger up x: %d finger up y: %d.\n",
        @as(c_int,@intFromFloat(event.tfinger.x * 100)),
        @as(c_int,@intFromFloat(event.tfinger.y * 100))
        );


        sdl.SDL_Log("\n1. touch event at :%d %d.\n", rect.x, rect.y);
        // scale the 0-99 percent to actual pixels.
        rect.x = @as(c_int, @divFloor(self.display_mode.?.w * rect.x, 100));
        rect.y = @as(c_int, @divFloor(self.display_mode.?.h * rect.y, 100));
        sdl.SDL_Log("\n2. display_mode at :%d %d.\n", self.display_mode.?.w, self.display_mode.?.h);
        sdl.SDL_Log("\n2. touch event at :%d %d.\n", rect.x, rect.y);
        const src_w = 640;
        const src_h = 480;

        // translate the click into the base 640x480 coord space (minus centering padding)
        const ratio: f64 = (@as(f64, @floatFromInt(self.display_mode.?.w)) / @as(f64, @floatFromInt(src_w)));
        const is_vertical = self.display_mode.?.h > self.display_mode.?.w;
        if (is_vertical) {
            rect.y -= @as(c_int, @intFromFloat(@divFloor((@as(f64, @floatFromInt(self.display_mode.?.h)) - @as(f64, src_h) * ratio), 2)));
            rect.y = @as(c_int, @intFromFloat(@round(@as(f64, @floatFromInt(rect.y)) / ratio)));
            rect.x = @as(c_int, @intFromFloat(@round(@as(f64, @floatFromInt(rect.x)) / ratio)));
        }
        // std.log.debug("touch event at rect {}", .{rect});
        sdl.SDL_Log("\n3. touch event at :%d %d.\n", rect.x, rect.y);

        // this should be from the rendered text, just guessing for now
        const text4 = sdl.SDL_Rect {.x = 0, .y = 0, .w = 220, .h = 20};
        const menu_item_4 = sdl.SDL_Rect{ .x = 330, .y = 167, .w = text4.w, .h = text4.h };
        var result_rect = sdl.SDL_Rect{ .x = 0, .y = 7, .w = 0, .h = 0};
        if (sdl.SDL_IntersectRect(&rect, &menu_item_4, &result_rect) == sdl.SDL_TRUE) {
            std.log.debug("Intersected with menu item {}", .{result_rect});
            bgm.pause_music();
        }

        const text0 = sdl.SDL_Rect {.x = 0, .y = 0, .w = 260, .h = 20};
        const menu_item_0 = sdl.SDL_Rect{ .x = 330, .y = 77, .w = text0.w, .h = text0.h };

        if (sdl.SDL_IntersectRect(&rect, &menu_item_0, &result_rect) == sdl.SDL_TRUE) {
            std.log.debug("Intersected with menu item {}", .{result_rect});
            self.next_mode = GameModes.GameModeType.TimedPlay;
        }
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
