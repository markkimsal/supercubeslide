const std = @import("std");
// const Sdk = @import("mods/sdl-zig/Sdk.zig"); // Import the Sdk at build time

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) error{ OutOfMemory, NoSpaceLeft }!void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Create a new instance of the SDL2 Sdk
    // const sdk = Sdk.init(b, null);

    const exe = b.addExecutable(.{
        .name = "supercubeslide",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    installStaticResources(exe);
    exe.linkLibC();
    // sdk.link(exe, .dynamic);
    // exe.addModule("sdl2", sdk.getWrapperModule());
    // exe.addModule("sdl-native", sdk.getNativeModule());
    // if (exe.root_module.target.result.os.tag == .windows) {
    if (target.result.os.tag == .windows) {
        exe.addIncludePath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_ttf/include/" });
        exe.addIncludePath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_mixer/include/" });
        exe.addIncludePath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_image/include/" });
        exe.addIncludePath(.{ .path = "./prebuilt/x86_64-windows-gnu/SDL2/include/" });
        exe.addIncludePath(.{ .path = "./prebuilt/x86_64-windows-gnu/SDL2/include/SDL2/" });

        exe.addLibraryPath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_image/lib/x64/" });
        exe.addLibraryPath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_image/lib/x64/optional/" });
        exe.addLibraryPath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_ttf/lib/x64" });
        exe.addLibraryPath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_mixer/lib/x64" });
        exe.addLibraryPath(.{ .path = "./prebuilt/x86_64-windows-msvc/SDL2_mixer/lib/x64/optional/" });
        exe.addLibraryPath(.{ .path = "./prebuilt/x86_64-windows-gnu/SDL2/bin/" });
        exe.addLibraryPath(.{ .path = "./prebuilt/x86_64-windows-gnu/SDL2/lib/" });
        exe.linkSystemLibrary("mingw32");
        exe.linkSystemLibrary("SDL2");
        // exe.linkSystemLibraryName("SDL2main");
        exe.linkSystemLibrary("SDL2_image");
        exe.linkSystemLibrary("SDL2_mixer");
        exe.linkSystemLibrary("SDL2_ttf");
        // exe.linkSystemLibraryName("stdc");
        // exe.linkSystemLibraryName("libogg-0");
        // exe.linkSystemLibraryName("libmodplug-1");
        // exe.linkSystemLibraryName("tiff-5");
        // exe.linkSystemLibraryName("webp-7");
    }
    // if (target.isLinux()) {
    //     exe.linkSystemLibrary("SDL2_image");
    //     exe.linkSystemLibrary("SDL2_mixer");
    //     exe.linkSystemLibrary("SDL2_ttf");
    //     exe.linkSystemLibrary("jpeg");
    //     exe.linkSystemLibrary("libpng");
    //     exe.linkSystemLibrary("tiff");
    //     exe.linkSystemLibrary("webp");
    // }
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
        .root_source_file = .{ .path = "src/main.zig" },
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

fn installStaticResources(exe: *std.Build.Step.Compile) void {
    exe.root_module.addAnonymousImport("loadingscreen.png", .{
        // exe.addAnonymousModule("loadingscreen.png", .{
        .root_source_file = std.Build.LazyPath.relative("../media/loadingscreen.png"),
    });
    exe.root_module.addAnonymousImport("background.png", .{
        .root_source_file = std.Build.LazyPath.relative("../media/background.png"),
    });
    exe.root_module.addAnonymousImport("cube_a.png", .{
        .root_source_file = std.Build.LazyPath.relative("../media/block_a.png"),
    });
    exe.root_module.addAnonymousImport("cube_b.png", .{
        .root_source_file = std.Build.LazyPath.relative("../media/block_b.png"),
    });
    exe.root_module.addAnonymousImport("cube_c.png", .{
        .root_source_file = std.Build.LazyPath.relative("../media/block_c.png"),
    });
    exe.root_module.addAnonymousImport("cube_d.png", .{
        .root_source_file = std.Build.LazyPath.relative("../media/block_d.png"),
    });
    exe.root_module.addAnonymousImport("freesansbold.ttf", .{
        .root_source_file = std.Build.LazyPath.relative("../media/freesansbold.ttf"),
    });
}
