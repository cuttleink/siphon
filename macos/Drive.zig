const c = @import("c");
const std = @import("std");

const This = @This();

_vendor: c.CFDataRef = null,
_product: c.CFDataRef = null,
_name: c.CFDataRef = null,
_bsd: c.CFDataRef = null,
size: u64 = 0,

pub const vendor = bytes("_vendor");
pub const product = bytes("_product");

pub const bsd = bytes("_bsd");
pub const name = bytes("_name");

pub fn deinit(self: This) void {
    if (self._vendor) |ref|
        c.CFRelease(ref);
    if (self._product) |ref|
        c.CFRelease(ref);

    if (self._bsd) |ref|
        c.CFRelease(ref);
    if (self._name) |ref|
        c.CFRelease(ref);
}

fn bytes(field: []const u8) fn (This) []const u8 {
    return struct {
        fn a(self: This) []const u8 {
            const ref = @field(self, field) orelse return "";
            const len: usize = @intCast(c.CFDataGetLength(ref));
            const ptr = c.CFDataGetBytePtr(ref);
            return ptr[0..len];
        }
    }.a;
}
