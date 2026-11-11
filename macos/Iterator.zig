const c = @import("c");
const std = @import("std");

const Drive = @import("Drive.zig");
const This = @This();

_: c.io_iterator_t,

pub fn init() !This {
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

pub fn next(self: This) ?Drive {
    const drive = c.IOIteratorNext(self._);
    if (drive == 0) return null;

    var out: Drive = .{};
    if (c.IORegistryEntryCreateCFProperty(
        drive,
        s(.chars),
        null,
        0,
    )) |chars| {
        defer c.CFRelease(chars);

        const dict: c.CFDictionaryRef = @ptrCast(chars);
        out._vendor = ascii(c.CFDictionaryGetValue(dict, s(.vendor)));
        out._product = ascii(c.CFDictionaryGetValue(dict, s(.product)));
    }

    return out;
}

pub fn deinit(self: This) void {
    _ = c.IOObjectRelease(self._);
}

fn ascii(cf: ?*const anyopaque) c.CFDataRef {
    return c.CFStringCreateExternalRepresentation(
        null,
        @ptrCast(cf orelse return null),
        c.kCFStringEncodingASCII,
        '?',
    );
}

fn next_raw(self: This) ?c.io_object_t {
    const val = c.IOIteratorNext(self._);
    return if (val == 0) null else val;
}

fn s(comptime str: S) c.CFStringRef {
    return c.CFSTR(str._);
}

const S = struct {
    _: []const u8,

    const chars = from(c.kIOPropertyDeviceCharacteristicsKey);
    const vendor = from(c.kIOPropertyVendorNameKey);
    const product = from(c.kIOPropertyProductNameKey);

    fn from(str: []const u8) S {
        return .{ ._ = str };
    }
};
