const std = @import("std");

pub fn build(b: *std.Build) void {
    const mod = b.createModule(.{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .root_source_file = b.path("src/main.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "siphon",
        .root_module = mod,
    });

    b.installArtifact(exe);
}
