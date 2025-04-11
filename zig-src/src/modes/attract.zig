const std = @import("std");
const sokol = @import("sokol");
// const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const sdl = MainModule.sdl;
const GameModes = @import("game_modes.zig");
const SpriteModule = @import("../sprite.zig");
const bgm = @import("../bgm.zig");
const MenuItem = @import("../ui/menu_item.zig").MenuItem;
const app_state = @import("../sokol.zig").app_state;

var debug_rect_: ?sdl.SDL_Rect = undefined;

pub const AttractMode = struct {
    background_image: *sdl.SDL_Texture,
    font: *sdl.TTF_Font,
    next_mode: ?GameModes.GameModeType,
    display_mode: ?*sdl.SDL_DisplayMode,
    menu_items: std.ArrayList(MenuItem),

    pub fn init(alligator: std.mem.Allocator, renderer: *sdl.SDL_Renderer) !AttractMode {
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

        var menu_items = std.ArrayList(MenuItem).init(alligator);
        create_menu_items(&menu_items, font, renderer);
        return AttractMode{
            .background_image = texture,
            .next_mode = null,
            .display_mode = null,
            .font = font.?,
            .menu_items = menu_items,
        };
    }

    pub fn render(self: @This(), state: anytype) void {
        _ = self;
        _ = state;
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
        if (is_vertical == true) {
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

        if (debug_rect_) |rect| {
            // const color = sdl.struct_SDL_Color;
            // sdl.SDL_GetRenderDrawColor(renderer, &color.r, &color.g, &color.b, &color.a);
            _ = sdl.SDL_SetRenderDrawColor(renderer, 0x66, 0x66, 0xEE, 0xFF);
            _ = sdl.SDL_RenderDrawRect(renderer, &rect);
            // _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        }
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

        for (self.menu_items.items) |*item| {
            item.paint(renderer);
        }
    }

    pub fn exit(self: *AttractMode) void {
        std.log.info("attract mode: destroying background", .{});
        sdl.SDL_DestroyTexture(self.background_image);
        // self.background_image.destroy();
        sdl.TTF_CloseFont(self.font);
        // self.font.close();

        for (self.menu_items.items) |*item| {
            item.destroy();
        }
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

    pub fn on_sdl_input(self: *@This(), event: *sdl.SDL_Event) bool {
        _ = self;
        _ = event;
        return true;
    }

    pub fn on_input(self: *@This(), event: [*c]const sokol.app.Event) bool {
        _ = self;
        _ = event;
        return true;
    }

    pub fn on_touch(self: *AttractMode, event: *sdl.SDL_Event) bool {
        _ = switch (event.tfinger.type) {
            sdl.SDL_FINGERUP => {
                self.touch_intersects_menu_display(event);
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

    fn touch_intersects_menu_display(self: *AttractMode, event: *sdl.SDL_Event) void {
        const display_mode = MainModule.mode;
        // _ = display_mode;

        var rect = sdl.SDL_Rect{ .x = @as(c_int, @intFromFloat(event.tfinger.x * 100.0)), .y = @as(c_int, @intFromFloat(event.tfinger.y * 100.0)), .w = 10, .h = 10 };
        // sdl.SDL_Log("\nfinger up x: %f finger up y: %f.\n", event.tfinger.x * 100, event.tfinger.y * 100);
        // sdl.SDL_Log("\nfinger up x: %d finger up y: %d.\n", @as(c_int, @intFromFloat(event.tfinger.x * 100)), @as(c_int, @intFromFloat(event.tfinger.y * 100)));
        // sdl.SDL_Log("\n1. touch event at :%d %d.\n", rect.x, rect.y);

        // scale the 0-99 percent to actual pixels.
        // rect.x = @as(c_int, @divFloor(self.display_mode.?.w * rect.x, 100));
        // rect.y = @as(c_int, @divFloor(self.display_mode.?.h * rect.y, 100));
        // sdl.SDL_Log("\n2. display_mode at :%d %d.\n", self.display_mode.?.w, self.display_mode.?.h);
        // sdl.SDL_Log("\n2. touch event at :%d %d.\n", rect.x, rect.y);

        const src_w: u32 = 640;
        const src_h: u32 = 480;

        // translate menu positions into global space
        var ratio: f64 = 1.0;
        var is_vertical = false;
        var v_padding: u32 = 0;
        var h_padding: u32 = 0;
        if (display_mode.w < display_mode.h) {
            is_vertical = true;
            const d_mode_h = @as(u32, @intCast(display_mode.h));
            ratio = (@as(f64, @floatFromInt(display_mode.w)) / @as(f64, @floatFromInt(src_w)));
            v_padding = @divFloor(@as(u32, @intCast(display_mode.h)) - src_h, 2);
            const dst_h = @as(u32, @intFromFloat(@round(src_h * ratio)));
            v_padding = @divFloor((d_mode_h - dst_h), 2);
            // v_padding = @as(u32, @intFromFloat(@as(f32, @floatFromInt(v_padding)) * ratio));
        } else {
            ratio = (@as(f64, @floatFromInt(display_mode.h)) / @as(f64, @floatFromInt(src_h)));
            h_padding = @divFloor(@as(u32, @intCast(display_mode.w)) - src_w, 2);
            h_padding = @as(u32, @intFromFloat(@as(f32, @floatFromInt(h_padding)) * ratio));
        }
        rect.x = @as(c_int, @divFloor(display_mode.w * rect.x, 100));
        rect.y = @as(c_int, @divFloor(display_mode.h * rect.y, 100));

        rect.x -= 5;
        rect.y -= 5;

        debug_rect_ = rect;
        // const rect = sdl.SDL_Rect{ .x = @as(c_int, @intFromFloat(event.tfinger.x * 100.0)), .y = @as(c_int, @intFromFloat(event.tfinger.y * 100.0)), .w = 2, .h = 2 };
        var result_rect = sdl.SDL_Rect{ .x = 0, .y = 7, .w = 0, .h = 0 };
        for (self.menu_items.items) |*item| {
            var menu_item_rect = item.rect;
            menu_item_rect.h = @intFromFloat(@as(f32, @floatFromInt(menu_item_rect.h)) * ratio);
            menu_item_rect.w = @intFromFloat(@as(f32, @floatFromInt(menu_item_rect.w)) * ratio);
            menu_item_rect.y = @intFromFloat(@as(f32, @floatFromInt(menu_item_rect.y)) * ratio);
            menu_item_rect.x = @intFromFloat(@as(f32, @floatFromInt(menu_item_rect.x)) * ratio);
            menu_item_rect.y += @as(c_int, @intCast(v_padding));
            menu_item_rect.x += @as(c_int, @intCast(h_padding));

            // debug_rect_ = menu_item_rect;
            const collide = sdl.SDL_IntersectRect(&rect, &menu_item_rect, &result_rect);
            _ = collide;
            if (sdl.SDL_IntersectRect(&rect, &menu_item_rect, &result_rect) == sdl.SDL_TRUE) {
                _ = item.on_click.?(
                    event,
                    self,
                );
                std.log.debug("Intersected with menu item {}", .{result_rect});
            }
        }
    }

    fn touch_intersects_menu(self: *AttractMode, event: *sdl.SDL_Event) void {
        const display_mode = MainModule.mode;
        _ = display_mode;

        var rect = sdl.SDL_Rect{ .x = @as(c_int, @intFromFloat(event.tfinger.x * 100.0)), .y = @as(c_int, @intFromFloat(event.tfinger.y * 100.0)), .w = 2, .h = 2 };
        // sdl.SDL_Log("\nfinger up x: %f finger up y: %f.\n", event.tfinger.x * 100, event.tfinger.y * 100);
        // sdl.SDL_Log("\nfinger up x: %d finger up y: %d.\n", @as(c_int, @intFromFloat(event.tfinger.x * 100)), @as(c_int, @intFromFloat(event.tfinger.y * 100)));
        // sdl.SDL_Log("\n1. touch event at :%d %d.\n", rect.x, rect.y);

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
        const text4 = sdl.SDL_Rect{ .x = 0, .y = 0, .w = 220, .h = 20 };
        const menu_item_4 = sdl.SDL_Rect{ .x = 330, .y = 167, .w = text4.w, .h = text4.h };
        var result_rect = sdl.SDL_Rect{ .x = 0, .y = 7, .w = 0, .h = 0 };
        if (sdl.SDL_IntersectRect(&rect, &menu_item_4, &result_rect) == sdl.SDL_TRUE) {
            std.log.debug("Intersected with menu rect {}", .{result_rect});
            bgm.pause_music();
        }

        const text0 = sdl.SDL_Rect{ .x = 0, .y = 0, .w = 260, .h = 20 };
        const menu_item_0 = sdl.SDL_Rect{ .x = 330, .y = 77, .w = text0.w, .h = text0.h };

        if (sdl.SDL_IntersectRect(&rect, &menu_item_0, &result_rect) == sdl.SDL_TRUE) {
            std.log.debug("Intersected with menu item {}", .{result_rect});
            // self.next_mode = GameModes.GameModeType.TimedPlay;
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
    pub const gray = rgb(0x99, 0x99, 0x99);
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

fn create_menu_items(menu_items: *std.ArrayList(MenuItem), font: ?*sdl.TTF_Font, renderer: *sdl.SDL_Renderer) void {
    var menu_item1 = MenuItem.init(sdl.SDL_Rect{ .x = 330, .y = 60, .w = 0, .h = 0 });
    menu_item1.set_text(font, renderer, "Press [ENTER] to start.");
    menu_item1.set_on_click(
        struct {
            fn handle(event: *sdl.SDL_Event, game_mode: *AttractMode) bool {
                _ = event;
                game_mode.next_mode = GameModes.GameModeType.TimedPlay;
                return true;
            }
        }.handle,
    );
    menu_items.append(menu_item1) catch {};

    var menu_item2 = MenuItem.init(sdl.SDL_Rect{ .x = 330, .y = 100, .w = 0, .h = 0 });
    menu_item2.set_text(font, renderer, "[N] Next Song");
    menu_item2.set_on_click(
        struct {
            fn handle(event: *sdl.SDL_Event, game_mode: *AttractMode) bool {
                bgm.start_song(bgm.song_index_ + 1);
                _ = event;
                _ = game_mode;
                return true;
            }
        }.handle,
    );
    menu_items.append(menu_item2) catch {};

    var menu_item3 = MenuItem.init(sdl.SDL_Rect{ .x = 330, .y = 130, .w = 0, .h = 0 });
    menu_item3.set_text(font, renderer, "[H] for Help");
    menu_item3.set_on_click(
        struct {
            fn handle(event: *sdl.SDL_Event, game_mode: *AttractMode) bool {
                _ = event;
                _ = game_mode;
                return true;
            }
        }.handle,
    );
    menu_items.append(menu_item3) catch {};

    var menu_item4 = MenuItem.init(sdl.SDL_Rect{ .x = 330, .y = 167, .w = 0, .h = 0 });
    menu_item4.set_text(font, renderer, "[M] Mute Music");
    menu_item4.set_on_click(
        struct {
            fn handle(event: *sdl.SDL_Event, game_mode: *AttractMode) bool {
                bgm.pause_music();
                _ = event;
                _ = game_mode;
                return true;
            }
        }.handle,
    );
    menu_items.append(menu_item4) catch {};
}
