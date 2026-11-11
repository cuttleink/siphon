const builtin = @import("builtin");
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
    // Apple has a painful strategy of making stuff suck
    if (builtin.os.tag != .macos)
        @panic("unsupported outside macos");

    const trans = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("macos/include.h"),
    });

    const c = trans.createModule();
    c.addCSourceFile(.{ .file = b.path("macos/strings.c") });

    inline for ([_][]const u8{
        "CoreFoundation",
        "IOKit",
        "DiskArbitration",
    }) |fw| c.linkFramework(fw, .{});

    return b.createModule(.{
        .root_source_file = b.path("macos/root.zig"),
        .imports = &.{.{ .name = "c", .module = c }},
    });
}
