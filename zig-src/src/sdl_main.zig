const std = @import("std");
pub const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
    @cInclude("SDL_mixer.h");
});
const zig_main = @import("main.zig").main;


pub export fn SDL_main_zig() callconv(.C) i64 {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Parse args into string array (error union needs 'try')
    const args = std.process.argsAlloc(allocator) catch {
        return -1;
    };
    defer std.process.argsFree(allocator, args);

    // Get and print them!
    std.debug.print("There are {d} args:\n", .{args.len});
    for(args) |arg| {
        std.debug.print("  {s}\n", .{arg});
    }
    zig_main() catch {
        return -1;
    };
    return 0;
}
