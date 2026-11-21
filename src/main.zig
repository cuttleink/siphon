const os = @import("os");
const std = @import("std");

const Bar = @import("Bar.zig");
const fmt = @import("fmt.zig");

pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args
        .iterateAllocator(init.gpa);
    defer args.deinit();

    const name = args.next().?;
    const in = args.next() orelse
        usage(name);
    const out = args.next() orelse
        if (std.mem.eql(u8, in, "ls"))
            return ls(init.io)
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

// TODO: This is an atrocity. This needs to be the first thing to be replaced
// and done away with once the project is stable-ish.
fn ls(io: std.Io) !void {
    var buf: [fmt.row.len * 2]u8 = undefined;
    var file = std.Io.File.stdout()
        .writer(io, &buf);
    const out = &file.interface;

    var iter: os.Iterator = try .init();
    defer iter.deinit();

    try out.print(fmt.row, .{ "DEVICE", "SIZE", "VENDOR", "PRODUCT", "NAME" });
    while (iter.next()) |drive| {
        defer drive.deinit();

        var size: [fmt.size]u8 = undefined;
        const str = if (drive.size == 0) "" else std.mem.print(
            &size,
            "{Bi:.1}",
            .{drive.size},
        ) catch unreachable;

        try out.print(fmt.row, .{
            drive.id(),
            str,
            drive.vendor(),
            drive.product(),
            drive.name(),
        });
    }

    try out.flush();
}

fn usage(name: []const u8) noreturn {
    std.debug.print(
        \\usage: {0s} ls
        \\       {0s} <device> <output>
        \\
    , .{name});
    std.process.exit(1);
}
