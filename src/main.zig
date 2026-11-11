const os = @import("os");
const std = @import("std");

const Bar = @import("Bar.zig");

pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args
        .iterateAllocator(init.gpa);
    defer args.deinit();

    const name = args.next().?;
    const in = args.next() orelse
        usage(name);
    const out = args.next() orelse
        if (std.mem.eql(u8, in, "ls"))
            return ls()
        else
            usage(name);
    if (args.next()) |_|
        usage(name);

    _ = out;

    const bar: Bar = try .init(init.io);
    defer bar.deinit(init.io) catch {};

    {
        var pct: f32 = 0;
        while (pct <= 100) : (pct += 0.0005) {
            try bar.update(init.io, pct);
            try init.io.sleep(
                .fromMilliseconds(1),
                .real,
            );
        }
    }
}

fn ls() !void {
    var iter: os.Iterator = try .init();
    defer iter.deinit();

    while (iter.next()) |drive| {
        defer drive.deinit();

        std.debug.print("{s} {s}\n", .{
            drive.vendor(),
            drive.product(),
        });
    }
}

fn usage(name: []const u8) noreturn {
    std.debug.print(
        \\usage: {0s} ls
        \\       {0s} <device> <output>
        \\
    , .{name});
    std.process.exit(1);
}
