const CreateAndroidAppBundle = @This();
const std = @import("std");
const builtin = @import("builtin");
const zig_sokol_build = @import("../vendor/zig-sokol-crossplatform-starter/build.zig");
const auto_detect = @import("./auto-detect.zig");

const ANDROID_TARGET_API_VERSION = "34";
const ANDROID_MIN_API_VERSION = "34";
const ANDROID_BUILD_TOOLS_VERSION = "34.0.0";
const ANDROID_NDK_VERSION = "28.0.13004108";

const ANDROID_KEYSTORE_ALIAS = "androidkey";
const ANDROID_KEYSTORE_DNAME_STRING = "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown";
const ANDROID_KEYSTORE_KEYPASS = "android";


const InstallAndroidBundle = struct {
    step: *std.Build.Step,
};
const AndroidSdkConfig = struct {
    android_sdk_root: []const u8 = "",
    android_ndk_root: []const u8 = "",
    java_home: []const u8 = "",

    keytool_path: []const u8 = "",
    java_exe_path: []const u8 = "",

    android_ndk_include_host: []const u8 = "",
    android_ndk_include_host_arch_android: []const u8 = "",
    android_ndk_lib_host_arch_android: []const u8 = "",
};


step: std.Build.Step,

pub fn create_step(
    b: *std.Build,
    optimize: *const std.builtin.OptimizeMode
) !*CreateAndroidAppBundle {

    const android_arm64_cross_target = b.resolveTargetQuery(try std.zig.CrossTarget.parse(.{
        .arch_os_abi = "aarch64-linux-android",
        .cpu_features = "baseline+v8a",
    }));

    if (!android_arm64_cross_target.result.isAndroid()) {
        std.debug.print("cross target is not android\n", .{});
        @panic("not android");
    }
    const android_sdk_config = try createAndroidSdkConfig(b, android_arm64_cross_target);
    // _ = android_sdk_config;
    const android_sokol_res = try buildSokolLib(b, android_arm64_cross_target, optimize.*);

    var android_combo_lib = try zig_sokol_build.buildAppSharedLib(
        b,
        android_arm64_cross_target,
        optimize.*,
        android_sokol_res.module
    );

    const generate_libc_file = try createLibCFile(
        b,
        .{
            .include_dir = android_sdk_config.android_ndk_include_host,
            .sys_include_dir =  android_sdk_config.android_ndk_include_host_arch_android,
            .crt_dir =  android_sdk_config.android_ndk_lib_host_arch_android,
        }
    );


    // set the android lib c file for app lib and sokol lib
    android_combo_lib.artifact.step.dependOn(&generate_libc_file.step);
    android_combo_lib.artifact.setLibCFile(generate_libc_file.files.getLast().getPath());
    android_sokol_res.installed_library.artifact.step.dependOn(&generate_libc_file.step);
    android_sokol_res.installed_library.artifact.setLibCFile(generate_libc_file.files.getLast().getPath());

    var create_android = b.allocator.create(@This()) catch @panic("OOM");
    create_android.step = std.Build.Step.init(.{
        .id = .custom,
        .name = "CreateAndroid",
        //.description = "Build android shared so",
        .owner = b,
    });

    create_android.step.dependOn(&android_combo_lib.step);
    return create_android;
}

pub fn install_step(
    b: *std.Build,
    optimize: *const std.builtin.OptimizeMode
) !*InstallAndroidBundle {

    const create_android = try create_step(b, optimize);
    var install_android = b.allocator.create(InstallAndroidBundle) catch @panic("OOM");
    install_android.step = b.step("android", "Package and sign android apk");
    install_android.step.dependOn(&create_android.step);

    // install_android.dependOn(&create_android_app_bundle.step);
    return install_android;
}

// Based off of https://github.com/MasterQ32/ZigAndroidTemplate/blob/master/Sdk.zig#L906
const LibCFileConfig = struct {
    include_dir: []const u8 = "",
    sys_include_dir: []const u8 = "",
    crt_dir: []const u8 = "",
};

fn createLibCFile(b: *std.Build, config: LibCFileConfig) !*std.Build.Step.WriteFile {
    const create_lib_c_file = b.addWriteFile("android.conf", blk: {
        var buf = std.ArrayList(u8).init(b.allocator);

        errdefer buf.deinit();

        var writer = buf.writer();

        @setEvalBranchQuota(1_000_000);

        try writer.print("include_dir={s}\n", .{config.include_dir});
        try writer.print("sys_include_dir={s}\n", .{config.sys_include_dir});
        try writer.print("crt_dir={s}\n", .{config.crt_dir});
        try writer.print("msvc_lib_dir=\n", .{});
        try writer.print("kernel32_lib_dir=\n", .{});
        try writer.print("gcc_dir=\n", .{});
        break :blk buf.toOwnedSlice() catch unreachable;
    });
    create_lib_c_file.step.name = "Write Android LibC conf (android.conf)";
    return create_lib_c_file;
}

const BuildConfig = struct {
    android_sdk_root: [] const u8,
    android_ndk_root: [] const u8,
    java_home: [] const u8,
    target_api_version: [] const u8,
};

fn createAndroidSdkConfig(b: *std.Build, target: std.Build.ResolvedTarget) !AndroidSdkConfig
{
    const options = std.json.ParseOptions{};
    // const file = try  std.fs.cwd().readFile(".build_config/android.json");
    const file = std.fs.cwd().openFile(".build_config/android.json", .{.mode = std.fs.File.OpenMode.read_only}) catch @panic("no .build_config/android.json");
    defer file.close();
    var buffered = std.io.bufferedReader(file.reader());
    var reader = std.json.reader(b.allocator, buffered.reader());
    const parsed = try std.json.parseFromTokenSource(BuildConfig, b.allocator, &reader, options);
    defer parsed.deinit();
    const a_build_config: BuildConfig = parsed.value;
    const target_dir_name = switch (target.result.cpu.arch) {
        .aarch64 => "aarch64-linux-android",
        .x86_64 => "x86_64-linux-android",
        else => @panic("unsupported arch for android build"),
    };
    const ndk_root = a_build_config.android_ndk_root;
    const ndk_sysroot = b.pathJoin(&.{ a_build_config.android_ndk_root,  "/toolchains/llvm/prebuilt", toolchainHostTag(), "/sysroot" });

    const android_sdk_config: AndroidSdkConfig = .{
        .java_home = a_build_config.java_home,
        .android_ndk_root = a_build_config.android_ndk_root,
        .android_ndk_include_host_arch_android = b.pathJoin(&.{ ndk_sysroot,  "/usr/include" }),
        // .android_ndk_include_host_arch_android = b.pathJoin(&.{ a_build_config.android_ndk_root,  "/toolchains/llvm/prebuilt", toolchainHostTag(), "/sysroot" }),
        .android_ndk_include_host = b.pathJoin(&.{ndk_root,  "/sysroot/usr/include" }),
        .android_ndk_lib_host_arch_android = b.pathJoin(&.{ ndk_sysroot, "/usr/lib", target_dir_name, a_build_config.target_api_version }),
    };
    return android_sdk_config;
}

fn toolchainHostTag() []const u8 {
    const os = builtin.target.os.tag;
    return (if (os == .macos) "darwin" else @tagName(os)) ++ "-x86_64"; // HACK: Android SDK always seems to put it under x86_64 even in aarch64 envs
}

const BuildSokolError = error{FoundMoreThanOneLib};

const BuildSokolResult = struct {
    module: *std.Build.Module,
    installed_library: *std.Build.Step.InstallArtifact,
};

pub fn buildSokolLib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) !BuildSokolResult {
    const triple = try target.result.zigTriple(b.allocator);
    const name = b.fmt("libsokol_{s}", .{triple});

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    const sokol_module = dep_sokol.module("sokol");
    if (sokol_module.link_objects.items.len > 1) {
        return BuildSokolError.FoundMoreThanOneLib;
    }
    const sokol_lib = sokol_module.link_objects.getLast().other_step;
    try addCompilePaths(b, target, sokol_lib);
    const installed_lib = b.addInstallArtifact(sokol_lib, .{ .dest_sub_path = name });

    return .{
        .module = sokol_module,
        .installed_library = installed_lib,
    };
}

fn addCompilePaths(b: *std.Build, target: std.Build.ResolvedTarget, step: anytype) !void {
    if (target.result.os.tag == .ios) {
        const sysroot = std.zig.system.darwin.getSdk(b.allocator, target.result) orelse b.sysroot;
        step.addLibraryPath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/usr/lib" }) }); //(.{ .cwd_relative = "/usr/lib" });
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/usr/include" }) }); //(.{ .cwd_relative = "/usr/include" });
        step.addFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/System/Library/Frameworks" }) }); //(.{ .cwd_relative = "/System/Library/Frameworks" });
    } else if (target.result.isAndroid()) {
        const target_dir_name = switch (target.result.cpu.arch) {
            .aarch64 => "aarch64-linux-android",
            .x86_64 => "x86_64-linux-android",
            else => @panic("unsupported arch for android build"),
        };
        _ = target_dir_name;

        const android_sdk = try auto_detect.findAndroidSDKConfig(b, &target.result, .{
            .api_version = ANDROID_TARGET_API_VERSION,
            .build_tools_version = ANDROID_BUILD_TOOLS_VERSION,
            .ndk_version = ANDROID_NDK_VERSION,
        });

        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_android });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_host });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_host_android });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_host_arch_android });

        step.addLibraryPath(.{ .cwd_relative = android_sdk.android_ndk_lib_host_arch_android });
    }
}
