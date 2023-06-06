const std = @import("std");
const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const GameModes = @import("game_modes.zig");
const Sprite = @import("../sprite.zig").Sprite;
const BlockTextureTags = @import("../sprite.zig").BlockTextureTags;
const PlayField = @import("../play_field.zig").PlayField;
const FieldContainer = @import("../play_field.zig").FieldContainer;

const heap_alloc = std.heap.c_allocator;
pub const TimedPlayMode = struct {
    background_image: sdl.Texture,
    cube_a: sdl.Texture,
    play_field: PlayField,
    play_field_offset_x: c_int = 150,
    play_field_offset_y: c_int = 120,
    next_mode: ?GameModes.GameModeType,

    pub fn init(renderer: *sdl.Renderer) !TimedPlayMode {
        const img = @embedFile("background.png");
        const texture = sdl.image.loadTextureMem(renderer.*, img[0..], sdl.image.ImgFormat.png) catch |err| {
            return err;
        };
        var cube_a = @embedFile("cube_a.png");
        var cube_texture = sdl.image.loadTextureMem(renderer.*, cube_a[0..], sdl.image.ImgFormat.png) catch |err| {
            return err;
        };
        var sprite = Sprite.init(BlockTextureTags.A, 24, 24);
        sprite.setPosition(-1, -1);

        var play_field = PlayField.init(heap_alloc, 5, 5).?;
        play_field.addActor(&sprite) catch {
            std.log.err("Cannot add sprite to play field", .{});
        };
        play_field.populateField(renderer);
        return TimedPlayMode{
            .background_image = texture,
            .cube_a = cube_texture,
            .next_mode = null,
            .play_field = play_field,
        };
    }

    pub fn paint(self: *TimedPlayMode, renderer: *sdl.Renderer) void {
        renderer.copy(self.background_image, null, null) catch {
            return;
        };
        self.paintActors(renderer);
        self.paintBand(renderer);
    }

    pub fn paintActors(self: TimedPlayMode, renderer: *sdl.Renderer) void {
        for (0..self.play_field.band_height) |x| {
            for (0..self.play_field.band_width) |y| {
                var actor = self.play_field.field[x][y].*;
                var rect = actor.rect;
                rect.x += self.play_field_offset_x; // playfield centering on background
                rect.y += self.play_field_offset_y; // playfield centering on background
                renderer.copy(actor.getTexture(), rect, null) catch {
                    std.log.err("error copying field cube to renderer", .{});
                };
            }
        }

        for (self.play_field.actors.items) |*actor| {
            var rect = actor.rect;
            // translate from relative coords to screen coordinates

            rect.x *= self.play_field.x_size; // playfield centering on background
            rect.y *= self.play_field.y_size; // playfield centering on background

            rect.x += self.play_field_offset_x; // playfield centering on background
            rect.y += self.play_field_offset_y; // playfield centering on background

            // renderer.copy(self.cube_a, rect, null) catch {
            renderer.copy(actor.getTexture(), rect, null) catch {
                std.log.err("error copying actor to renderer", .{});
            };
        }
    }

    pub fn paintBand(self: TimedPlayMode, renderer: *sdl.Renderer) void {
        renderer.drawRect(sdl.Rectangle{ .width = self.play_field.band_width * 24, .height = self.play_field.band_height * 24, .x = self.play_field_offset_x, .y = self.play_field_offset_y }) catch {};
    }

    pub fn exit(self: *TimedPlayMode) void {
        std.log.info("timed play mode: destroying background", .{});
        self.background_image.destroy();
        self.play_field.close();
    }

    pub fn on_input(self: *TimedPlayMode, event: sdl.Event) bool {
        switch (event) {
            .mouse_wheel => |mouse_event| {
                for (self.play_field.actors.items) |*actor| {
                    if (mouse_event.delta_y > 0) {
                        self.moveCounterClockwise(actor);
                        // actor.*.moveClockwise();
                    } else {
                        self.moveClockwise(actor);
                        // actor.*.moveCounterClockwise();
                    }
                }
            },
            else => {},
        }
        return true;
    }

    pub fn on_key(self: *TimedPlayMode, key_event: sdl.KeyboardEvent) bool {
        for (self.play_field.actors.items) |*actor| {
            if (key_event.keycode == sdl.Keycode.left) {
                actor.*.moveClockwise();
            }
            if (key_event.keycode == sdl.Keycode.right) {
                actor.*.moveCounterClockwise();
            }
        }
        return true;
    }

    pub fn update(self: *TimedPlayMode) ?GameModes.GameModeType {
        if (self.next_mode) |mode| {
            return mode;
        }
        return null;
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
};
