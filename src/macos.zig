const std = @import("std");
const c = @import("c");

// this is slop, I am just trying to get cross compilation working right now
// don't let it reflect poorly on me
pub fn foo() !void {
    var iter: c.io_iterator_t = 0;
    if (c.IOServiceGetMatchingServices(
        0, // default main port
        c.IOServiceMatching("IOCDBlockStorageDevice"),
        &iter,
    ) != c.KERN_SUCCESS) return error.IOKitMatchFailed;
    defer _ = c.IOObjectRelease(iter);

    const chars_key = cfstr("Device Characteristics");
    defer c.CFRelease(chars_key);
    const vendor_key = cfstr("Vendor Name");
    defer c.CFRelease(vendor_key);
    const product_key = cfstr("Product Name");
    defer c.CFRelease(product_key);

    var n: usize = 1;
    while (true) : (n += 1) {
        const drive = c.IOIteratorNext(iter);
        if (drive == 0) break;
        defer _ = c.IOObjectRelease(drive);

        const chars = c.IORegistryEntryCreateCFProperty(drive, chars_key, null, 0) orelse continue;
        defer c.CFRelease(chars);
        const dict: c.CFDictionaryRef = @ptrCast(chars);

        var vbuf: [64]u8 = undefined;
        var pbuf: [64]u8 = undefined;
        const vendor = dictString(dict, vendor_key, &vbuf) orelse "?";
        const product = dictString(dict, product_key, &pbuf) orelse "?";

        std.debug.print("{d}  Vendor: {s}  Product: {s}\n", .{ n, vendor, product });
    }
}

fn cfstr(s: [*:0]const u8) c.CFStringRef {
    return c.CFStringCreateWithCString(null, s, c.kCFStringEncodingUTF8);
}

/// Looks up a string value in `dict` and copies it into `buf`, trimmed.
fn dictString(dict: c.CFDictionaryRef, key: c.CFStringRef, buf: []u8) ?[]const u8 {
    const value = c.CFDictionaryGetValue(dict, key) orelse return null; // not owned
    if (c.CFGetTypeID(value) != c.CFStringGetTypeID()) return null;
    if (c.CFStringGetCString(@ptrCast(value), buf.ptr, @intCast(buf.len), c.kCFStringEncodingUTF8) == 0)
        return null;
    return std.mem.trim(u8, std.mem.sliceTo(buf, 0), " ");
}
