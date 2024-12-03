const std = @import("std");
const common = @import("common.zig");
const Allocator = std.mem.Allocator;

pub const Context = struct {
    allocator: Allocator,
    cnt: usize,
    left: []i32,
    right: []i32,
};

pub fn parseVec(line: []const u8, vec: *@Vector(4, i32)) usize {
    var p: usize = 0;
    for (0..line.len) |i| {
        if (line[i] == ' ') {
            if (line[i - 1] != ' ') p += 1;
        } else vec[p] = vec[p] * 10 + line[i] - '0';
    }
    return p + 1;
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *anyopaque {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.cnt = lines.len;
    ctx.left = allocator.alloc(i32, ctx.cnt) catch unreachable;
    ctx.right = allocator.alloc(i32, ctx.cnt) catch unreachable;
    ctx.allocator = allocator;
    for (0..ctx.cnt) |i| {
        const line = lines[i];
        var tmp: @Vector(4, i32) = @splat(0);
        _ = parseVec(line, &tmp);
        ctx.left[i] = tmp[0];
        ctx.right[i] = tmp[1];
    }
    return @ptrCast(ctx);
}

pub fn part1(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    std.mem.sort(i32, ctx.left, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, ctx.right, {}, comptime std.sort.asc(i32));
    var tot: u32 = 0;
    for (0..ctx.cnt) |i| {
        const diff = @abs(ctx.left[i] - ctx.right[i]);
        tot += diff;
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

pub fn part2(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    var ret: i32 = 0;
    var cmap = [_]i32{0} ** 100000;
    for (0..ctx.cnt) |i| cmap[@intCast(ctx.right[i])] += 1;
    for (0..ctx.cnt) |i| ret += ctx.left[i] * cmap[@intCast(ctx.left[i])];
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{ret}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "01", .parse = parse, .part1 = part1, .part2 = part2 };
pub fn main() void {
    common.run_day(work);
}
