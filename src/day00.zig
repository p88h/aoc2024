const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    lines: [][]const u8,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    ctx.allocator = allocator;
    return ctx;
}

pub fn part1(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.lines.len}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.lines[0].len}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "00",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
