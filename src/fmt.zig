const std = @import("std");

pub const width = 80;
const first = 8;
pub const size = 8;
const third = 10;
const fourth = 16;
const fifth = (width - 4 * 2) -
    (first + size + third + fourth);

pub const row = std.fmt.comptimePrint(
    \\{{s:<{0d}.{0d}}}  {{s:>{1d}.{1d}}}  {{s:<{2d}.{2d}}}  {{s:<{3d}.{3d}}}  {{s:.{4d}}}
    \\
, .{ first, size, third, fourth, fifth });
