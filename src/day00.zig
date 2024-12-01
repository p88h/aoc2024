const std = @import("std");
const Allocator = std.mem.Allocator;
const run_day = @import("common.zig").run_day;

const Context = struct {
    lines: [][]u8,
};

pub fn parse(allocator: Allocator, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    return ctx;
}

pub fn part1(ctx: *Context) void {
    std.debug.print("{d}\n", .{ctx.lines.len});
}

pub fn part2(ctx: *Context) void {
    std.debug.print("{d}\n", .{ctx.lines[0].len});
}

pub fn main() void {
    run_day(Context, "00", .{ .parse = parse, .part1 = part1, .part2 = part2 });
}
