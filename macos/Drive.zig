const c = @import("c");
const std = @import("std");

const This = @This();

_vendor: c.CFDataRef = null,
_product: c.CFDataRef = null,
size: usize = 0,

pub const vendor = bytes("_vendor");
pub const product = bytes("_product");

pub fn deinit(self: This) void {
    if (self._vendor) |ref|
        c.CFRelease(ref);
    if (self._product) |ref|
        c.CFRelease(ref);
}

fn bytes(name: []const u8) fn (This) []const u8 {
    return struct {
        fn a(self: This) []const u8 {
            const ref = @field(self, name) orelse
                return null orelse unreachable;
            const ptr = c.CFDataGetBytePtr(ref);
            const len: usize = @intCast(c.CFDataGetLength(ref));
            return ptr[0..len];
        }
    }.a;
}
