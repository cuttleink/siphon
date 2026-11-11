const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const os = switch (target.result.os.tag) {
        .macos => macos,
        else => @panic("unsupported os"),
    }(b, target, optimize);

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .imports = &.{.{ .name = "os", .module = os }},
    });

    const exe = b.addExecutable(.{
        .name = "siphon",
        .root_module = mod,
    });

    b.installArtifact(exe);
}

fn macos(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
) *std.Build.Module {
    const dep = b.dependency("xcode-frameworks", .{});
    const trans = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("macos/include.h"),
    });

    const frameworks = dep.path("Frameworks");
    trans.addIncludePath(dep.path("include"));
    trans.addFrameworkPath(frameworks);

    const c = trans.createModule();
    c.addFrameworkPath(frameworks);
    c.addLibraryPath(dep.path("lib"));
    c.linkFramework("CoreFoundation", .{});
    c.linkFramework("IOKit", .{});

    return b.createModule(.{
        .root_source_file = b.path("macos/root.zig"),
        .imports = &.{.{ .name = "c", .module = c }},
    });
}
