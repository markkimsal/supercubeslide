const std = @import("std");
const sdl = @import("sdl2");
const MainModule = @import("../main.zig");
const GameModes = @import("game_modes.zig");
const Sprite = @import("../sprite.zig").Sprite;
const PlayField = @import("../play_field.zig").PlayField;

pub const TimedPlayMode = struct {
    background_image: sdl.Texture,
    cube_a: sdl.Texture,
    play_field: PlayField,
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
        var sprite = Sprite.init(cube_texture, 24, 24);
        sprite.setPosition(240, 240);

        var play_field = PlayField.init(std.heap.c_allocator);
        play_field.addActor(&sprite) catch {
            std.log.err("Cannot add sprite to play field", .{});
        };
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
    }

    pub fn paintActors(self: *TimedPlayMode, renderer: *sdl.Renderer) void {
        for (self.play_field.actors.items) |*actor| {
            const rect = actor.rect;
            // renderer.copy(self.cube_a, rect, null) catch {
            renderer.copy(actor.texture, rect, null) catch {
                std.log.warn("error", .{});
            };
        }
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
                        actor.*.moveClockwise();
                    } else {
                        actor.*.moveCounterClockwise();
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
};
