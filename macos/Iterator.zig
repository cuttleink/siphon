const c = @import("c");
const std = @import("std");

const Drive = @import("Drive.zig");

_: c.io_iterator_t,

pub fn init() !@This() {
    var iter: c.io_iterator_t = undefined;
    return if (c.IOServiceGetMatchingServices(
        0,
        c.IOServiceMatching("IOCDBlockStorageDevice"),
        &iter,
    ) == c.KERN_SUCCESS)
        .{ ._ = iter }
    else
        error.MatchFailed;
}

pub fn next(self: @This()) ?Drive {
    const drive = c.IOIteratorNext(self._);
    if (drive == 0) return null;

    // var out: Drive = .{ ._ = drive };
    // return out;

    std.debug.print("Hello, world!", .{});
    return null;
}

fn next_raw(self: @This()) ?c.io_object_t {
    const val = c.IOIteratorNext(self._);
    return if (val == 0) null else val;
}

pub fn deinit(self: @This()) void {
    _ = c.IOObjectRelease(self._);
}
