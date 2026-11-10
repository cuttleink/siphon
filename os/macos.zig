const std = @import("std");
const c = @import("c");

pub fn foo() !void {
    const match = c.IOServiceMatching("IOMedia") orelse
        return error.MatchFailed;
    c.CFDictionarySetValue(match, c.CFSTR("Whole"), c.kCFBooleanTrue);
    c.CFDictionarySetValue(match, c.CFSTR("Removable"), c.kCFBooleanTrue);

    var iter: c.io_iterator_t = 0;
    if (c.IOServiceGetMatchingServices(0, match, &iter) != c.KERN_SUCCESS)
        return error.MatchFailed;
    defer _ = c.IOObjectRelease(iter);

    const key = c.CFSTR("BSD Name");
    while (next(iter)) |media| {
        defer _ = c.IOObjectRelease(media);

        const bsd =
            c.IORegistryEntryCreateCFProperty(media, key, null, 0) orelse
            continue;
        defer c.CFRelease(bsd);

        var name: [32]u8 = undefined;
        if (c.CFStringGetCString(
            @ptrCast(bsd),
            &name,
            name.len,
            c.kCFStringEncodingASCII,
        ) == 0) continue;

        std.debug.print("/dev/r{s}\n", .{std.mem.sliceTo(&name, 0)});
    }
}

fn next(iter: c.io_iterator_t) ?c.io_object_t {
    const val = c.IOIteratorNext(iter);
    return if (val == 0) null else val;
}
