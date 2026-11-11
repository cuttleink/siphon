const std = @import("std");

const width = 80;
const inner = width - 4;
const name = "siphon";

const field = text.rep(" ", inner - name.len);
const pad = text.rep(text.braille[0], inner);

const head = text.start ++ "\r│ ";
const top = head ++ field ++ name ++ " │\n│ ";
const frame = top ++ pad ++ " │" ++ text.up ++ "\r" ++ text.stop;

out: std.Io.File,

pub fn init(io: std.Io) !@This() {
    const file = std.Io.File.stderr();
    if (!try file.isTty(io)) return error.NotTty;

    try file.writeStreamingAll(io, text.hide);
    return .{ .out = file };
}

pub fn update(self: @This(), io: std.Io, pct: f32) !void {
    var buf = frame.*;

    _ = std.mem.print(
        buf[head.len..],
        "{d:.0}%",
        .{pct},
    ) catch unreachable;

    {
        const dots: usize = @round(pct / 100 * inner * 8);
        const bar = buf[top.len..][0..pad.len];
        for (0..inner) |i| bar[i * 3 ..][0..3].* =
            text.braille[@min(dots -| i * 8, 8)].*;
    }

    try self.out.writeStreamingAll(io, &buf);
}

pub fn deinit(self: @This(), io: std.Io) !void {
    return self.out.writeStreamingAll(io, "\n\n" ++ text.show);
}

const text = struct {
    const braille = [_]*const [3]u8{ "⠀", "⠁", "⠃", "⠇", "⡇", "⡏", "⡟", "⡿", "⣿" };

    const up = "\x1b[1A";
    const start = "\x1b[?2026h";
    const stop = "\x1b[?2026l";

    const hide = "\x1b[?25l";
    const show = "\x1b[?25h";

    fn rep(str: []const u8, n: usize) [str.len * n]u8 {
        const grid: [n][str.len]u8 = @splat(str[0..str.len].*);
        return @bitCast(grid);
    }
};
