const c = @import("c");
const std = @import("std");

const Drive = @import("Drive.zig");
const This = @This();

const Ref = ?*const anyopaque;

_: c.io_iterator_t,
_session: c.DASessionRef = null,

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

pub fn next(self: *This) ?Drive {
    const drive = c.IOIteratorNext(self._);

    if (drive == 0) return null;
    defer _ = c.IOObjectRelease(drive);

    var out: Drive = .{};
    if (c.IORegistryEntryCreateCFProperty(
        drive,
        c.str_chars,
        null,
        0,
    )) |chars| {
        defer c.CFRelease(chars);

        out._vendor = ascii(get(chars, c.str_vendor));
        out._product = ascii(get(chars, c.str_product));
    }

    if (self.describe(drive)) |desc| {
        defer c.CFRelease(desc);

        out._bsd = ascii(get(desc, c.kDADiskDescriptionMediaBSDNameKey));
        out._name = ascii(get(desc, c.kDADiskDescriptionVolumeNameKey));
        if (get(desc, c.kDADiskDescriptionMediaSizeKey)) |size|
            _ = c.CFNumberGetValue(
                @ptrCast(size),
                c.kCFNumberSInt64Type,
                &out.size,
            );
    }

    return out;
}

pub fn deinit(self: This) void {
    if (self._session) |ref|
        c.CFRelease(ref);
    _ = c.IOObjectRelease(self._);
}

fn describe(self: *This, drive: c.io_object_t) c.CFDictionaryRef {
    var iter: c.io_iterator_t = undefined;
    if (c.IORegistryEntryCreateIterator(
        drive,
        c.kIOServicePlane,
        c.kIORegistryIterateRecursively,
        &iter,
    ) != c.KERN_SUCCESS) return null;
    defer _ = c.IOObjectRelease(iter);

    while (true) {
        const entry = c.IOIteratorNext(iter);

        if (entry == 0) return null;
        defer _ = c.IOObjectRelease(entry);
        if (c.IOObjectConformsTo(entry, "IOMedia") == 0)
            continue;

        const disk = c.DADiskCreateFromIOMedia(
            null,
            self.session() orelse
                return null,
            entry,
        ) orelse return null;
        defer c.CFRelease(disk);

        return c.DADiskCopyDescription(disk);
    }
}

fn ascii(cf: Ref) c.CFDataRef {
    return c.CFStringCreateExternalRepresentation(
        null,
        @ptrCast(cf orelse return null),
        c.kCFStringEncodingASCII,
        '?',
    );
}

fn session(self: *This) c.DASessionRef {
    if (self._session == null)
        self._session = c.DASessionCreate(null);
    return self._session;
}

fn get(dict: Ref, key: c.CFStringRef) Ref {
    return c.CFDictionaryGetValue(@ptrCast(dict), key);
}
