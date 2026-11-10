const os = @import("os");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args
        .iterateAllocator(init.gpa);
    defer args.deinit();

    try os.foo();
}
