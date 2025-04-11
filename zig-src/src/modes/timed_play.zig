const std = @import("std");
const sokol = @import("sokol");
// const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const sdl = MainModule.sdl;
const GameModes = @import("game_modes.zig");
const SpriteModule = @import("../sprite.zig");
const Sprite = SpriteModule.Sprite;
const BlockTextureTags = @import("../sprite.zig").BlockTextureTags;
const PlayField = @import("../play_field.zig").PlayField;
const FieldContainer = @import("../play_field.zig").FieldContainer;
const Animation = @import("../animation.zig").Animation;
const TaggedAnimation = @import("../animation.zig").TaggedAnimation;
const AnimationType = @import("../animation.zig").AnimationType;
const app_state = @import("../sokol.zig").app_state;

const heap_alloc = std.heap.c_allocator;
pub const TimedPlayMode = struct {
    background_image: *sdl.SDL_Texture,
    cube_a: *sdl.SDL_Texture,
    play_field: PlayField,
    play_field_offset_x: c_int = 150,
    play_field_offset_y: c_int = 120,
    next_mode: ?GameModes.GameModeType,
    col_removal_idx: ?usize,
    row_removal_idx: ?usize,
    animation: ?Animation,
    touchdown: c_int,
    in_drag: bool,
    drag_dx: c_int,
    drag_ticks: c_int,
    move_count: u16 = 0,
    level_number: u16 = 0,
    score: i16 = 0,

    pub fn init(renderer: *sdl.SDL_Renderer) !TimedPlayMode {
        const img = @embedFile("background.png");
        const texture = SpriteModule.loadTextureMem(renderer, img[0..], SpriteModule.ImgFormat.png) catch |err| {
            return err;
        };
        var cube_a = @embedFile("cube_a.png");
        const cube_texture = SpriteModule.loadTextureMem(renderer, cube_a[0..], SpriteModule.ImgFormat.png) catch |err| {
            return err;
        };

        var play_field = PlayField.init(heap_alloc, 5, 5).?;

        var sprite = Sprite.init(BlockTextureTags.A, play_field.x_size, play_field.y_size);
        sprite.setPosition(-1, 0);
        play_field.addActor(&sprite) catch {
            std.log.err("Cannot add sprite to play field", .{});
        };
        play_field.populateField(0, 4, 4);
        var play_mode = TimedPlayMode{
            .background_image = texture,
            .cube_a = cube_texture,
            .next_mode = null,
            .play_field = play_field,
            .animation = null,
            .touchdown = 0,
            .in_drag = false,
            .drag_dx = 0,
            .drag_ticks = 0,
            .col_removal_idx = null,
            .row_removal_idx = null,
        };
        play_mode.recenterPlayField();
        return play_mode;
    }

    pub fn render(self: @This(), state: anytype) void {
        _ = self;
        _ = state;
    }

    pub fn paint(self: *TimedPlayMode, renderer: *sdl.SDL_Renderer, mode: *sdl.SDL_DisplayMode) void {
        const src_w = 640;
        const src_h = 480;
        // const base_tex = sdl.SDL_CreateTexture(renderer, mode.format, sdl.SDL_TEXTUREACCESS_TARGET, src_w, src_h);
        const base_tex: ?*sdl.SDL_Texture = sdl.SDL_CreateTexture(renderer, mode.format, sdl.SDL_TEXTUREACCESS_TARGET, src_w, src_h);
        if (sdl.SDL_SetRenderTarget(renderer, base_tex.?) > 0) {
            std.log.err("unable to set renderer target", .{});
            sdl.SDL_DestroyTexture(base_tex);
            return;
        }

        // self.play_field_offset_x = @as(c_int, @intFromFloat(220)) + (@divFloor((mode.w - dst.w), 2));
        // self.play_field_offset_y = @as(c_int, @intFromFloat(150)) + (@divFloor((mode.h - dst.h), 2));

        // self.play_field_offset_x = @intFromFloat(@round(@as(f64, @floatFromInt(self.play_field_offset_x)) * ratio));
        // self.play_field_offset_y = @intFromFloat(@round(@as(f64, @floatFromInt(self.play_field_offset_y)) * ratio));
        if (sdl.SDL_RenderCopy(renderer, self.background_image, null, null) > 0) {
            return;
        }
        // renderer.copy(self.background_image, null, null) catch {
        //     return;
        // };
        self.paintActors(renderer);
        self.paintBand(renderer);
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

        const play_field_rect = sdl.SDL_Rect{ .w = @as(c_int, @intCast(self.play_field.max_width)) * self.play_field.x_size, .h = @as(c_int, @intCast(self.play_field.max_height)) * self.play_field.y_size, .x = 128, .y = 88 };
        _ = play_field_rect;

        // _ = sdl.SDL_SetRenderTarget(renderer, base_tex);
        // _ = sdl.SDL_SetRenderDrawColor(renderer, 0xC0, 0xAA, 0xAA, 0xFF);
        // _ = sdl.SDL_RenderDrawRect(renderer, &play_field_rect);
        // _ = sdl.SDL_SetRenderTarget(renderer, null);

        _ = sdl.SDL_RenderCopy(renderer, base_tex, null, &dst);

        sdl.SDL_DestroyTexture(base_tex);
    }

    pub fn paintActors(self: TimedPlayMode, renderer: *sdl.SDL_Renderer) void {
        for (0..self.play_field.band_height) |y| {
            for (0..self.play_field.band_width) |x| {
                var actor = self.play_field.field[y][x].*;
                var rect = actor.rect;

                rect.x *= self.play_field.x_size; // translate coords into pixels
                rect.y *= self.play_field.y_size; // translate coords into pixels

                rect.x += self.play_field_offset_x; // playfield centering on background
                rect.y += self.play_field_offset_y; // playfield centering on background
                if (actor.desaturate != 0.0) {
                    const alpha_blend = actor.desaturate * 255;
                    const alpha_blend_2 = @as(u8, 255 - @as(u8, @intFromFloat(alpha_blend)));
                    _ = sdl.SDL_SetTextureAlphaMod(actor.getTexture(), alpha_blend_2);
                    _ = sdl.SDL_RenderCopy(renderer, actor.getTexture(), null, &rect);
                    _ = sdl.SDL_SetTextureAlphaMod(actor.getTexture(), 255);
                } else {
                    if (sdl.SDL_RenderCopy(renderer, actor.getTexture(), null, &rect) < 0) {
                        std.log.err("error copying field cube to renderer", .{});
                    }
                }
            }
        }

        for (self.play_field.actors.items) |*actor| {
            var rect = actor.rect;
            // translate from relative coords to screen coordinates

            rect.x *= self.play_field.x_size; // playfield centering on background
            rect.y *= self.play_field.y_size; // playfield centering on background

            rect.x += self.play_field_offset_x; // playfield centering on background
            rect.y += self.play_field_offset_y; // playfield centering on background

            if (sdl.SDL_RenderCopy(renderer, actor.getTexture(), null, &rect) > 0) {
                std.log.err("error copying actor to renderer", .{});
            }
        }
    }

    pub fn paintBand(self: TimedPlayMode, renderer: *sdl.SDL_Renderer) void {
        const cube_size = self.play_field.x_size;
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0xC0, 0xAA, 0xAA, 0xFF);
        // renderer.drawRect(sdl.SDL_Rect{ .width = @as(c_int, @intCast(self.play_field.band_width)) * cube_size, .height = @as(c_int, @intCast(self.play_field.band_height)) * cube_size, .x = self.play_field_offset_x, .y = self.play_field_offset_y }) catch {};
        const rect = sdl.SDL_Rect{ .w = @as(c_int, @intCast(self.play_field.band_width)) * cube_size, .h = @as(c_int, @intCast(self.play_field.band_height)) * cube_size, .x = self.play_field_offset_x, .y = self.play_field_offset_y };
        _ = sdl.SDL_RenderDrawRect(renderer, &rect);
    }

    pub fn exit(self: *TimedPlayMode) void {
        std.log.info("timed play mode: destroying background", .{});
        sdl.SDL_DestroyTexture(self.background_image);
        // self.background_image.destroy();
        self.play_field.close();
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

    // pub fn on_input_sokol(self: *@This(), event: [*c]const sokol.app.Event) bool {
    //     if (self.animation != null) {
    //         return false;
    //     }
    //     switch (event.*.type) {
    //         sdl.SDL_MOUSEWHEEL => {
    //             for (self.play_field.actors.items) |*actor| {
    //                 if (event.wheel.y > 0) {
    //                     self.moveCounterClockwise(actor);
    //                 } else {
    //                     self.moveClockwise(actor);
    //                 }
    //             }
    //         },
    //         sdl.SDL_MOUSEBUTTONUP => {
    //             if (event.button.button == sdl.SDL_BUTTON_MIDDLE or event.button.button == sdl.SDL_BUTTON_LEFT) {
    //                 if (self.play_field.moveActor()) {
    //                     self.recordMove();
    //                 }
    //             }
    //         },
    //         else => {},
    //     }
    //     return true;
    // }

    pub fn on_touch(self: *TimedPlayMode, event: *sdl.SDL_Event) bool {
        if (self.animation != null) {
            return false;
        }
        switch (event.type) {
            sdl.SDL_FINGERUP => {
                if (self.in_drag) {
                    self.in_drag = false;
                    self.touchdown = 0;
                    self.drag_dx = 0;
                    self.drag_ticks = 0;
                    return true;
                }
                if (self.play_field.moveActor()) {
                    self.recordMove();
                    return true;
                }
            },
            sdl.SDL_FINGERMOTION => {
                self.in_drag = true;
                const c_delta: c_int = @as(c_int, @intFromFloat(event.tfinger.dx * 1000));
                // std.log.debug("c_drag_dx {d} drag_ticks {d} {d:0.3}", .{self.drag_dx, self.drag_ticks, event.tfinger.dx * 1000});
                // std.log.debug("mod  {d}", .{@mod(self.drag_dx + c_delta,  100)});
                const scaling_factor = 20;

                if (@divFloor(self.drag_dx + c_delta, scaling_factor) > self.drag_ticks) {
                    self.drag_ticks = @divFloor(self.drag_dx + c_delta, scaling_factor);
                    for (self.play_field.actors.items) |*actor| {
                        self.moveClockwise(actor);
                    }
                }
                if (@divFloor(self.drag_dx + c_delta, scaling_factor) < self.drag_ticks) {
                    self.drag_ticks = @divFloor(self.drag_dx + c_delta, scaling_factor);
                    for (self.play_field.actors.items) |*actor| {
                        self.moveCounterClockwise(actor);
                    }
                }
                self.drag_dx += c_delta;
                // for (self.play_field.actors.items) |*actor| {
                //     if (event.tfinger.dx > 0.0) {
                //         self.moveCounterClockwise(actor);
                //     } else {
                //         self.moveClockwise(actor);
                //     }
                // }
                return true;
            },
            else => {},
        }
        return false;
    }

    pub fn on_key(self: *TimedPlayMode, key_event: *sdl.SDL_KeyboardEvent) bool {
        var keymatch = false;
        for (self.play_field.actors.items) |*actor| {
            if (key_event.keysym.sym == sdl.SDLK_LEFT) {
                self.moveCounterClockwise(actor);
                keymatch = true;
            }
            if (key_event.keysym.sym == sdl.SDLK_RIGHT) {
                self.moveClockwise(actor);
                keymatch = true;
            }
            if (key_event.keysym.sym == sdl.SDLK_SPACE) {
                if (self.play_field.moveActor()) {
                    self.recordMove();
                }
                keymatch = true;
            }

            if (key_event.keysym.sym == sdl.SDLK_d) {
                self.play_field.removeCol(2);
                self.recenterPlayField();
                keymatch = true;
            }

            if (key_event.keysym.sym == sdl.SDLK_AC_BACK) {
                self.next_mode = GameModes.GameModeType.Attract;
            }
        }
        return keymatch;
    }

    // graphical area is around 600 x 600
    fn recenterPlayField(self: *TimedPlayMode) void {
        const cube_size = self.play_field.x_size;
        self.play_field_offset_x = (272 - @divFloor(@as(c_int, @intCast(self.play_field.band_width)) * cube_size, 2));
        self.play_field_offset_y = (232 - @divFloor(@as(c_int, @intCast(self.play_field.band_height)) * cube_size, 2));
    }

    pub fn update(self: *TimedPlayMode) ?GameModes.GameModeType {
        if (self.next_mode) |mode| {
            return mode;
        }
        if (self.animation != null) {
            self.resolveAnimation();
            return null;
        }
        if (self.col_removal_idx) |col_idx| {
            _ = col_idx;
            self.animation = Animation{ .t0 = sdl.SDL_GetTicks64(), .duration = 450, .anim_type = AnimationType.RemoveCol };
            return null;
        }
        if (self.row_removal_idx) |row_idx| {
            _ = row_idx;
            self.animation = Animation{ .t0 = sdl.SDL_GetTicks64(), .duration = 450, .anim_type = AnimationType.RemoveRow };
            return null;
        }
        if (!self.resolveField()) {
            if (self.play_field.band_height <= 1 or self.play_field.band_width <= 1) {
                std.log.info("Congrats", .{});
                self.nextLevel();
                return null;
            }
        }
        return null;
    }

    fn resolveAnimation(self: *TimedPlayMode) void {
        if (self.animation == null) {
            return;
        }
        const animation = &self.animation.?;
        const delta: u32 = @as(u32, @intCast(sdl.SDL_GetTicks64() - self.animation.?.t0));
        switch (animation.anim_type) {
            AnimationType.RemoveCol => {
                const desaturate_percent: f64 = @as(f64, @floatFromInt(delta)) / @as(f64, @floatFromInt(animation.duration));
                for (0..self.play_field.band_height) |y| {
                    self.play_field.field[y][self.col_removal_idx.?].desaturate = desaturate_percent;
                }
            },
            AnimationType.RemoveRow => {
                const desaturate_percent: f64 = @as(f64, @floatFromInt(delta)) / @as(f64, @floatFromInt(animation.duration));
                for (0..self.play_field.band_width) |x| {
                    self.play_field.field[self.row_removal_idx.?][x].desaturate = desaturate_percent;
                }
            },
        }
        if (delta >= animation.duration) {
            switch (animation.anim_type) {
                AnimationType.RemoveCol => {
                    for (0..self.play_field.band_height) |y| {
                        self.play_field.field[y][self.col_removal_idx.?].desaturate = 0.0;
                    }
                    self.play_field.removeCol(self.col_removal_idx.?);
                    self.col_removal_idx = null;
                },
                AnimationType.RemoveRow => {
                    for (0..self.play_field.band_width) |x| {
                        self.play_field.field[self.row_removal_idx.?][x].desaturate = 0.0;
                    }
                    self.play_field.removeRow(self.row_removal_idx.?);
                    self.row_removal_idx = null;
                },
            }
            self.animation = null;
        }
    }

    fn resolveField(self: *TimedPlayMode) bool {
        if (self.play_field.band_width > 1) {
            for (0..self.play_field.band_height) |y| {
                var needs_removal = self.play_field.band_width > 1;
                for (0..self.play_field.band_width - 1) |x| {
                    needs_removal = needs_removal and self.play_field.field[y][x].texture_tag == self.play_field.field[y][x + 1].texture_tag;
                    if (!needs_removal) {
                        break;
                    }
                }
                if (needs_removal) {
                    self.row_removal_idx = y;
                    // self.play_field.removeRow(y);
                    return true;
                }
            }
        }
        if (self.play_field.band_height > 1) {
            for (0..self.play_field.band_width) |x| {
                var needs_removal = self.play_field.band_height > 1;
                for (0..self.play_field.band_height - 1) |y| {
                    needs_removal = needs_removal and self.play_field.field[y][x].texture_tag == self.play_field.field[y + 1][x].texture_tag;
                    if (!needs_removal) {
                        break;
                    }
                }
                if (needs_removal) {
                    self.col_removal_idx = x;
                    // self.play_field.removeCol(x);
                    return true;
                }
            }
        }
        return false;
    }

    fn moveClockwise(self: TimedPlayMode, actor: *Sprite) void {
        var rect = actor.rect;
        if (rect.y == self.play_field.band_height and (rect.x > -1)) {
            rect.x -= 1;
            actor.*.rect = rect;
            return;
        }

        if (rect.x == self.play_field.band_width and (rect.y < self.play_field.band_height + 1)) {
            rect.y += 1;
            actor.*.rect = rect;
            return;
        }

        if (rect.x == -1 and (rect.y > -1)) {
            rect.y -= 1;
            actor.*.rect = rect;
            return;
        }

        if (rect.y == -1 and (rect.x < self.play_field.band_width + 1)) {
            rect.x += 1;
            actor.*.rect = rect;
            return;
        }
    }

    fn moveCounterClockwise(self: TimedPlayMode, actor: *Sprite) void {
        var rect = actor.rect;
        if (rect.y == -1 and (rect.x > -1)) {
            rect.x -= 1;
            actor.*.rect = rect;
            return;
        }
        if (rect.x == self.play_field.band_width and (rect.y > -1)) {
            rect.y -= 1;
            actor.*.rect = rect;
            return;
        }

        if (rect.y == self.play_field.band_height and (rect.x < self.play_field.band_width + 1)) {
            rect.x += 1;
            actor.*.rect = rect;
            return;
        }
        if (rect.x == -1 and (rect.y < self.play_field.band_height)) {
            rect.y += 1;
            actor.*.rect = rect;
            return;
        }
    }

    fn recordMove(self: *TimedPlayMode) void {
        self.move_count += 1;
        std.log.info("Moves: {}", .{self.move_count});
    }

    fn resetMoveCounter(self: *TimedPlayMode) void {
        self.move_count = 0;
    }

    fn nextLevel(self: *TimedPlayMode) void {
        self.level_number = self.level_number + 1;
        const band_w: u8 = 4 + @as(u8, @intCast(@divTrunc(self.level_number, 1)));
        self.play_field.populateField(self.level_number, @min(self.play_field.max_width, band_w), @min(self.play_field.max_height, band_w));

        self.recenterPlayField();
        for (self.play_field.actors.items) |*actor| {
            actor.setPosition(-1, -1);
        }
        self.score += @as(i16, @intCast(self.move_count));
        std.log.info("Score: {}", .{self.score});
        self.resetMoveCounter();
    }
};
