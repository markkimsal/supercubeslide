const std = @import("std");
const Build = std.Build;
// const zig_sokol_build = @import("zig_sokol_crossplatform_starter");
const zig_sokol_build = @import("./vendor/zig-sokol-crossplatform-starter/build.zig");
// const Sdk = @import("mods/sdl-zig/Sdk.zig"); // Import the Sdk at build time

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // const zig_sokol_build = try buildSokolMod(b, target, optimize);

    const default_sokol_res = try zig_sokol_build.buildSokolLib(b, target, optimize);
    var exe = try zig_sokol_build.buildExe(b, target, optimize, default_sokol_res.module);
    const install_default_exe = b.addInstallArtifact(exe, .{});

    const install_default = b.step("default", "Build binaries for the current system (or specified in command)");
    install_default.dependOn(&install_default_exe.step);

    const zigimg_dependency = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zigimg", zigimg_dependency.module("zigimg"));
    // Create a new instance of the SDL2 Sdk
    // const sdk = Sdk.init(b, null);

    // cross compiling requires pre-built folders
    const prebuilt_sdl_folder = b.option([]const u8, "prebuilt-sdl", "Absolute path to cross-compiled SDL2 family of libraries");
    const macos_sysroot_path = b.option([]const u8, "sysroot-path", "Absolute path to cross-compiled SDL2 family of libraries");

    // exe: *std.Build.Step.Compile = undefined;
    // exe = b.addExecutable(.{
    //     .name = "supercubeslide",
    //     .root_source_file = .{ .cwd_relative = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // exe.root_module.addImport("sokol", default_sokol_res.module);

    if (target.result.os.tag == .windows) {
        const lib_path = prebuilt_sdl_folder orelse "./prebuilt/x86_64-windows-gnu";
        var concat_buffer: [250]u8 = undefined;
        const start: usize = 0;
        const buffer_slice = concat_buffer[start..];
        // const sdl_path = try std.fmt.bufPrint(buffer_slice, "{s}{s}", .{ lib_path, "/SDL2/x86_64-w64-mingw32/" });

        const include_folders =
            \\/SDL2/x86_64-w64-mingw32/include/,
            \\/SDL2/x86_64-w64-mingw32/include/SDL2/,
            \\/SDL2_ttf/x86_64-w64-mingw32/include/SDL2/,
            \\/SDL2_image/x86_64-w64-mingw32/include/SDL2/,
            \\/SDL2_mixer/x86_64-w64-mingw32/include/SDL2/,
            \\
        ;
        var iter = std.mem.split(u8, include_folders, ",\n");
        while (iter.next()) |f| {
            exe.addIncludePath(.{ .cwd_relative = try std.fmt.bufPrint(buffer_slice, "{s}{s}", .{ lib_path, f }) });
        }
        const lib_folders =
            \\/SDL2/x86_64-w64-mingw32/bin/,
            \\/SDL2/x86_64-w64-mingw32/lib/,
            \\/SDL2_ttf/x86_64-w64-mingw32/bin/,
            \\/SDL2_ttf/x86_64-w64-mingw32/lib/,
            \\/SDL2_image/x86_64-w64-mingw32/bin/,
            \\/SDL2_image/x86_64-w64-mingw32/lib/,
            \\/SDL2_mixer/x86_64-w64-mingw32/bin/,
            \\/SDL2_mixer/x86_64-w64-mingw32/lib/,
            \\
        ;

        iter = std.mem.split(u8, lib_folders, ",\n");
        while (iter.next()) |f| {
            exe.addLibraryPath(.{ .cwd_relative = try std.fmt.bufPrint(buffer_slice, "{s}{s}", .{ lib_path, f }) });
        }

        exe.linkSystemLibrary("mingw32");
        exe.linkSystemLibrary2("SDL2", .{
            .preferred_link_mode = .static,
            .use_pkg_config = .no,
        });
        // exe.linkSystemLibrary("SDL2main");
        exe.linkSystemLibrary2("SDL2_image", .{
            .preferred_link_mode = .static,
            .use_pkg_config = .no,
        });
        exe.linkSystemLibrary2("SDL2_mixer", .{
            .preferred_link_mode = .static,
            .use_pkg_config = .no,
        });
        exe.linkSystemLibrary2("SDL2_ttf", .{
            .preferred_link_mode = .static,
            .use_pkg_config = .no,
        });
        // exe.linkSystemLibraryName("stdc");
        // exe.linkSystemLibraryName("libogg-0");
        // exe.linkSystemLibraryName("libmodplug-1");
        // exe.linkSystemLibraryName("tiff-5");
        // exe.linkSystemLibraryName("webp-7");
    } else if (target.result.os.tag == .macos) {
        // exe.addIncludePath(.{
        //     .cwd_relative = "/include"
        // });
        const lib_path = prebuilt_sdl_folder orelse ".";
        const sysroot_path = macos_sysroot_path orelse ".";
        var concat_buffer: [250]u8 = undefined;
        const start: usize = 0;
        const buffer_slice = concat_buffer[start..];

        const include_folders =
            \\/SDL2/x86_64-w64-mingw32/include/,
            \\/SDL2/x86_64-w64-mingw32/include/SDL2/,
            \\/SDL2_ttf/x86_64-w64-mingw32/include/SDL2/,
            \\/SDL2_image/x86_64-w64-mingw32/include/SDL2/,
            \\/SDL2_mixer/x86_64-w64-mingw32/include/SDL2/,
            \\
        ;
        var iter = std.mem.split(u8, include_folders, ",\n");
        while (iter.next()) |f| {
            exe.addIncludePath(.{ .cwd_relative = try std.fmt.bufPrint(buffer_slice, "{s}{s}", .{ lib_path, f }) });
        }

        const include_sysroot_folders =
            \\/usr/include,"
            \\/usr/lib,"
            \\/System/Library/Frameworks,
            \\
        ;
        iter = std.mem.split(u8, include_sysroot_folders, ",\n");
        while (iter.next()) |f| {
            exe.addIncludePath(.{ .cwd_relative = try std.fmt.bufPrint(buffer_slice, "{s}{s}", .{ sysroot_path, f }) });
        }

        exe.linkFramework("SDL2");
        exe.linkFramework("SDL2_ttf");
        exe.linkFramework("SDL2_image");
        exe.linkFramework("SDL2_mixer");

        exe.linkFramework("OpenGL");
        exe.linkFramework("Metal");
        exe.linkFramework("CoreVideo");
        exe.linkFramework("CoreMedia");
        exe.linkFramework("Cocoa");
        exe.linkFramework("IOKit");
        exe.linkFramework("ForceFeedback");
        exe.linkFramework("Carbon");
        exe.linkFramework("CoreAudio");
        exe.linkFramework("AudioToolbox");
        exe.linkFramework("Foundation");
        exe.linkFramework("CoreFoundation");
        exe.linkFramework("AppKit");
        exe.linkFramework("CoreGraphics");
        exe.linkFramework("CoreServices");
        exe.linkSystemLibrary("objc");
        // exe.linkSystemLibrary("jpeg");
        // exe.linkSystemLibrary("libpng");
        // exe.linkSystemLibrary("tiff");
        // exe.linkSystemLibrary("webp");
        // exe.linkSystemLibrary("ttf");
    } else {
        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("SDL2_image");
        exe.linkSystemLibrary("SDL2_mixer");
        exe.linkSystemLibrary("SDL2_ttf");
        exe.linkSystemLibrary("jpeg");
        exe.linkSystemLibrary("libpng");
        exe.linkSystemLibrary("tiff");
        exe.linkSystemLibrary("webp");
        exe.linkSystemLibrary("GL");
    }

    installStaticResources(exe);
    exe.linkLibC();
    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

const BuildSokolResult = struct {
    module: *Build.Module,
    installed_library: *Build.Step.InstallArtifact,
};
fn buildSokolMod(
    b: *Build,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) !*std.Build.Module {
    // const triple = try target.result.zigTriple(b.allocator);
    // const name = b.fmt("libsokol_{s}", .{triple});

    var dep_sokol_build = b.dependency("zig_sokol_crossplatform_starter", .{
        .target = target,
        .optimize = optimize,
    });
    // dep_sokol_build.builder.verbose = true;
    const sokol_build_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        // .root_source_file = dep_sokol_build.path("build.zig")
        .root_source_file = .{ .cwd_relative = "vendor/zig-sokol-crossplatform-starter/build.zig" },
    });
    // sokol_build_mod.build(b);
    const path = dep_sokol_build.path("build.zig");
    std.debug.print("foo: {}", .{dep_sokol_build.path("build.zig")});
    std.debug.print("foo: {s}", .{path.getPath(b)});
    // _ = sokol_build_mod;
    // sokol_build_mod.build(b);
    return sokol_build_mod;
    // const sokol_module = dep_sokol.module("sokol");
    // if (sokol_module.link_objects.items.len > 1) {
    //     return BuildSokolError.FoundMoreThanOneLib;
    // }
    // const sokol_lib = sokol_module.link_objects.getLast().other_step;
    // try addCompilePaths(b, target, sokol_lib);
    // const installed_lib = b.addInstallArtifact(sokol_lib, .{ .dest_sub_path = name });

    // return .{
    //     .module = sokol_module,
    //     .installed_library = installed_lib,
    // };
}

fn installStaticResources(exe: *std.Build.Step.Compile) void {
    exe.root_module.addAnonymousImport("loadingscreen.png", .{
        // exe.addAnonymousModule("loadingscreen.png", .{
        .root_source_file = .{ .cwd_relative = "../media/loadingscreen.png" },
    });
    exe.root_module.addAnonymousImport("background.png", .{
        .root_source_file = .{ .cwd_relative = "../media/background.png" },
    });
    exe.root_module.addAnonymousImport("cube_a.png", .{
        .root_source_file = .{ .cwd_relative = "../media/block_a.png" },
    });
    exe.root_module.addAnonymousImport("cube_b.png", .{
        .root_source_file = .{ .cwd_relative = "../media/block_b.png" },
    });
    exe.root_module.addAnonymousImport("cube_c.png", .{
        .root_source_file = .{ .cwd_relative = "../media/block_c.png" },
    });
    exe.root_module.addAnonymousImport("cube_d.png", .{
        .root_source_file = .{ .cwd_relative = "../media/block_d.png" },
    });
    exe.root_module.addAnonymousImport("freesansbold.ttf", .{
        .root_source_file = .{ .cwd_relative = "../media/freesansbold.ttf" },
    });
}
