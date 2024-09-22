//! This is a example build.zig!
//! Use it as a template for your own projects, all generic build instructions
//! are contained in Sdk.zig.

const std = @import("std");
const Sdk = @import("ZigAndroidTemplate").Sdk;

pub fn build(b: *std.Build) !void {
    // Default-initialize SDK
    const sdk = Sdk.init(b, null, .{
        .build_tools_version = "30.0.2",
        .ndk_version = "25.2.95196353"

    });
    const mode = b.standardOptimizeOption(.{});
    const android_version = b.option(Sdk.AndroidVersion, "android", "Select the android version, default is 'android5'") orelse .android5;
    const aaudio = b.option(bool, "aaudio", "Compile with support for AAudio, default is 'false'") orelse false;
    const opensl = b.option(bool, "opensl", "Compile with support for OpenSL ES, default is 'true'") orelse true;

    const prebuilt_sdl_folder = b.option([]const u8, "prebuilt-sdl-folder", "Absolute path to cross-compiled SDL2 family of libraries");

    // Provide some KeyStore structure so we can sign our app.
    // Recommendation: Don't hardcore your password here, everyone can read it.
    // At least not for your production keystore ;)
    const key_store = Sdk.KeyStore{
        .file = ".build_config/android.keystore",
        .alias = "default",
        .password = "ziguana",
    };

    var libraries = std.ArrayList([]const u8).init(b.allocator);
    try libraries.append("GLESv2");
    try libraries.append("EGL");
    try libraries.append("android");
    try libraries.append("log");
    // try libraries.append("SDL2");

    if (opensl) try libraries.append("OpenSLES");
    if (aaudio) try libraries.append("aaudio");

    // This is a configuration for your application.
    // Android requires several configurations to be done, this is a typical config
    const config = Sdk.AppConfig{
        .target_version = android_version,

        // This is displayed to the user
        .display_name = "Zig Android App Template",

        // This is used internally for ... things?
        .app_name = "zig-app-template",

        // This is required for the APK name. This identifies your app, android will associate
        // your signing key with this identifier and will prevent updates if the key changes.
        .package_name = "net.random_projects.zig_android_template",

        // This is a set of resources. It should at least contain a "mipmap/icon.png" resource that
        // will provide the application icon.
        .resources = &[_]Sdk.Resource{
            .{ .path = "mipmap/icon.png", .content = .{ .cwd_relative = "icon.png" } },
        },

        // .aaudio = aaudio,

        // .opensl = opensl,

        // This is a list of android permissions. Check out the documentation to figure out which you need.
        .permissions = &[_][]const u8{
            "android.permission.SET_RELEASE_APP",
            //"android.permission.RECORD_AUDIO",
        },

        // This is a list of native android apis to link against.
        .libraries = libraries.items,
    };

    // Replace by your app's main file.
    // Here this is some code to choose the example to run
    // const ExampleType = enum { egl, minimal, textview, invocationhandler };
    // const example = b.option(ExampleType, "example", "Which example to run") orelse .egl;
    // const src = switch (example) {
    //     .egl => "examples/egl/main.zig",
    //     .minimal => "examples/minimal/main.zig",
    //     .textview => "examples/textview/main.zig",
    //     .invocationhandler => "examples/invocationhandler/main.zig",
    // };
    const src = "src/sdl_main.zig";
    // const dex: ?[]const [:0]const u8 = switch (example) {
    //     .invocationhandler => &[_][:0]const u8{"src/NativeInvocationHandler.java"},
    //     else => null,
    // };
    const dex = null;

    const app = sdk.createApp(
        "app-template.apk",
        src,
        dex,
        config,
        mode,
        .{
            .aarch64 = b.option(bool, "aarch64", "Enable the aarch64 build"),
            .arm = b.option(bool, "arm", "Enable the arm build"),
            .x86_64 = b.option(bool, "x86_64", "Enable the x86_64 build"),
            .x86 = b.option(bool, "x86", "Enable the x86 build"),
        }, // default targets
        key_store,
    );

    const android_module = b.modules.get("android") orelse unreachable;

    for (app.libraries) |exe| {
        // Provide the "android" package in each executable we build
        // exe.addModule("android", android_module);
        exe.root_module.addImport("android", android_module);

        const lib_path =  "./prebuilt/x86_64-windows-gnu";
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

        exe.linkSystemLibrary2("SDL2", .{
            .preferred_link_mode = .static,
            .use_pkg_config = .no,
        });
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

        if (prebuilt_sdl_folder) |sdl_path| {
            exe.addLibraryPath( .{.cwd_relative = sdl_path});
        }
    }
 

    // Make the app build when we invoke "zig build" or "zig build install"
    b.getInstallStep().dependOn(app.final_step);

    const keystore_step = b.step("keystore", "Initialize a fresh debug keystore");
    const push_step = b.step("push", "Push the app to a connected android device");
    const run_step = b.step("run", "Run the app on a connected android device");

    keystore_step.dependOn(sdk.initKeystore(key_store, .{}));
    push_step.dependOn(app.install());
    run_step.dependOn(app.run());
}
