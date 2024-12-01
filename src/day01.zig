const std = @import("std");
const run_day = @import("common.zig").run_day;
const Allocator = std.mem.Allocator;

const Context = struct {
    allocator: Allocator,
    cnt: usize,
    left: []i32,
    right: []i32,
};

pub fn parse(allocator: Allocator, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.cnt = lines.len;
    ctx.left = allocator.alloc(i32, ctx.cnt) catch unreachable;
    ctx.right = allocator.alloc(i32, ctx.cnt) catch unreachable;
    ctx.allocator = allocator;
    for (0..ctx.cnt) |i| {
        const line = lines[i];
        var sp = std.mem.indexOf(u8, line, " ").?;
        const v1 = std.fmt.parseInt(i32, line[0..sp], 10) catch unreachable;
        while (line[sp] == ' ') sp += 1;
        const v2 = std.fmt.parseInt(i32, line[sp..], 10) catch unreachable;
        ctx.left[i] = v1;
        ctx.right[i] = v2;
    }
    return ctx;
}

pub fn part1(ctx: *Context) void {
    std.mem.sort(i32, ctx.left, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, ctx.right, {}, comptime std.sort.asc(i32));
    var tot: u32 = 0;
    for (0..ctx.cnt) |i| {
        const diff = @abs(ctx.left[i] - ctx.right[i]);
        tot += diff;
    }
    std.debug.print("{d}\n", .{tot});
}

pub fn part2(ctx: *Context) void {
    var ret: i32 = 0;
    var cmap = [_]i32{0} ** 100000;
    for (0..ctx.cnt) |i| cmap[@intCast(ctx.right[i])] += 1;
    for (0..ctx.cnt) |i| ret += ctx.left[i] * cmap[@intCast(ctx.left[i])];
    std.debug.print("{d}\n", .{ret});
}

pub fn main() void {
    run_day(Context, "01", .{ .parse = parse, .part1 = part1, .part2 = part2 });
}
