const c = @import("c");

_: c.io_object_t,

pub fn deinit(self: @This()) void {
    _ = c.IOObjectRelease(self._);
}
