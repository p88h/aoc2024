const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

const Context = struct {
    allocator: Allocator,
    lines: [][]const u8,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *anyopaque {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    ctx.allocator = allocator;
    return @ptrCast(ctx);
}

pub fn part1(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{ctx.lines.len}) catch unreachable;
}

pub fn part2(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{ctx.lines[0].len}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "00", .parse = parse, .part1 = part1, .part2 = part2 };
pub fn main() void {
    common.run_day(work);
}
