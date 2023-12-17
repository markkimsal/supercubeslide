const std = @import("std");
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
    move_count: u16 = 0,
    level_number: u16 = 0,

    pub fn init(renderer: *sdl.SDL_Renderer) !TimedPlayMode {
        const img = @embedFile("background.png");
        const texture = SpriteModule.loadTextureMem(renderer, img[0..], SpriteModule.ImgFormat.png) catch |err| {
            return err;
        };
        var cube_a = @embedFile("cube_a.png");
        var cube_texture = SpriteModule.loadTextureMem(renderer, cube_a[0..], SpriteModule.ImgFormat.png) catch |err| {
            return err;
        };
        var sprite = Sprite.init(BlockTextureTags.A, 24, 24);
        sprite.setPosition(-1, -1);

        var play_field = PlayField.init(heap_alloc, 5, 5).?;
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
            .col_removal_idx = null,
            .row_removal_idx = null,
        };
        play_mode.recenterPlayField();
        return play_mode;
    }

    pub fn paint(self: *TimedPlayMode, renderer: *sdl.SDL_Renderer) void {
        if (sdl.SDL_RenderCopy(renderer, self.background_image, null, null) > 0) {
            return;
        }
        // renderer.copy(self.background_image, null, null) catch {
        //     return;
        // };
        self.paintActors(renderer);
        self.paintBand(renderer);
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
                    var alpha_blend = actor.desaturate * 255;
                    var alpha_blend_2 = @as(u8, 255 - @as(u8, @intFromFloat(alpha_blend)));
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
        // renderer.drawRect(sdl.SDL_Rect{ .width = @as(c_int, @intCast(self.play_field.band_width)) * 24, .height = @as(c_int, @intCast(self.play_field.band_height)) * 24, .x = self.play_field_offset_x, .y = self.play_field_offset_y }) catch {};
        const rect = sdl.SDL_Rect{ .w = @as(c_int, @intCast(self.play_field.band_width)) * 24, .h = @as(c_int, @intCast(self.play_field.band_height)) * 24, .x = self.play_field_offset_x, .y = self.play_field_offset_y };
        _ = sdl.SDL_RenderDrawRect(renderer, &rect);
    }

    pub fn exit(self: *TimedPlayMode) void {
        std.log.info("timed play mode: destroying background", .{});
        sdl.SDL_DestroyTexture(self.background_image);
        // self.background_image.destroy();
        self.play_field.close();
    }

    pub fn on_input(self: *TimedPlayMode, event: *sdl.SDL_Event) bool {
        if (self.animation != null) {
            return false;
        }
        switch (event.type) {
            sdl.SDL_MOUSEWHEEL => {
                for (self.play_field.actors.items) |*actor| {
                    if (event.wheel.y > 0) {
                        self.moveCounterClockwise(actor);
                    } else {
                        self.moveClockwise(actor);
                    }
                }
            },
            sdl.SDL_MOUSEBUTTONDOWN => {
                if (event.button.button == sdl.SDL_BUTTON_MIDDLE or event.button.button == sdl.SDL_BUTTON_LEFT) {
                    self.play_field.moveActor();
                    self.recordMove();
                }
            },
            else => {},
        }
        return true;
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
                self.play_field.moveActor();
                keymatch = true;
            }

            if (key_event.keysym.sym == sdl.SDLK_d) {
                self.play_field.removeCol(2);
                self.recenterPlayField();
                keymatch = true;
            }
        }
        return keymatch;
    }

    // graphical area is around 600 x 600
    fn recenterPlayField(self: *TimedPlayMode) void {
        self.play_field_offset_x = (272 - @divFloor(@as(c_int, @intCast(self.play_field.band_width)) * 24, 2));
        self.play_field_offset_y = (232 - @divFloor(@as(c_int, @intCast(self.play_field.band_height)) * 24, 2));
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
                self.level_number = self.level_number + 1;
                var band_w: u8 = 4 + @as(u8, @intCast(@divTrunc(self.level_number, 10)));
                self.play_field.populateField(self.level_number, band_w, band_w);

                for (self.play_field.actors.items) |*actor| {
                    actor.setPosition(-1, -1);
                }

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
        var delta: u32 = @as(u32, @intCast(sdl.SDL_GetTicks64() - self.animation.?.t0));
        switch (animation.anim_type) {
            AnimationType.RemoveCol => {
                var desaturate_percent: f64 = @as(f64, @floatFromInt(delta)) / @as(f64, @floatFromInt(animation.duration));
                for (0..self.play_field.band_height) |y| {
                    self.play_field.field[y][self.col_removal_idx.?].desaturate = desaturate_percent;
                }
            },
            AnimationType.RemoveRow => {
                var desaturate_percent: f64 = @as(f64, @floatFromInt(delta)) / @as(f64, @floatFromInt(animation.duration));
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
};
