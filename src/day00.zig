const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

const Context = struct {
    lines: [][]const u8,
};

pub fn parse(allocator: Allocator, lines: [][]const u8) *anyopaque {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    return @ptrCast(ctx);
}

pub fn part1(ptr: *anyopaque) void {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    std.debug.print("{d}\n", .{ctx.lines.len});
}

pub fn part2(ptr: *anyopaque) void {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    std.debug.print("{d}\n", .{ctx.lines[0].len});
}

// boilerplate
pub const work = common.Worker{ .day = "00", .parse = parse, .part1 = part1, .part2 = part2 };
pub fn main() void {
    common.run_day(work);
}
