const std = @import("std");
const common = @import("common.zig");
const Allocator = std.mem.Allocator;

pub const vec8 = @Vector(8, u8);
pub const Context = struct {
    allocator: Allocator,
    cnt: []usize,
    pak: []vec8,
};

pub fn parseVec(line: []const u8, vec: *vec8) usize {
    var p: usize = 0;
    for (0..line.len) |i| {
        if (line[i] == ' ') p += 1 else vec[p] = vec[p] * 10 + line[i] - '0';
    }
    return p + 1;
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.cnt = allocator.alloc(usize, lines.len) catch unreachable;
    ctx.pak = allocator.alloc(vec8, lines.len) catch unreachable;
    ctx.allocator = allocator;
    for (0..lines.len) |i| {
        const line = lines[i];
        ctx.pak[i] = @splat(0);
        ctx.cnt[i] = parseVec(line, &ctx.pak[i]);
    }
    return ctx;
}

pub fn print_vec(n: []const u8, v: vec8, l: usize) void {
    std.debug.print("{s}: @{d} =", .{ n, l });
    for (0..l) |i| std.debug.print(" {d}", .{v[i]});
    std.debug.print("\n", .{});
}

pub fn valid(v: vec8, l: usize) bool {
    // print_vec("v", v, l);
    const tmp = std.simd.shiftElementsLeft(v, 1, 0);
    var d = v -% tmp;
    if (d[0] > 100) d = tmp -% v;
    d[l - 1] = 0;
    if (l < 8) d[l] = 0;
    // print_vec("Δ", d, l - 1);
    const z = std.simd.countElementsWithValue(d, 0);
    if (z > 9 - l) return false;
    d /= @splat(@as(u8, 4));
    const c = std.simd.countElementsWithValue(d, 0);
    if (c == 8) return true;
    return false;
}

pub fn part1(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (0..ctx.cnt.len) |i| {
        if (valid(ctx.pak[i], ctx.cnt[i])) tot += 1;
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (0..ctx.cnt.len) |i| {
        const l = ctx.cnt[i] - 1;
        const n = ctx.pak[i];
        var right: vec8 = @splat(255);
        var left: vec8 = @splat(0);
        for (0..ctx.cnt[i]) |_| {
            right = std.simd.shiftElementsRight(right, 1, 0);
            const nn = (n & left) + std.simd.rotateElementsLeft(n & right, 1);
            if (valid(nn, l)) {
                tot += 1;
                break;
            }
            left = std.simd.shiftElementsRight(left, 1, 255);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "02", .parse = @ptrCast(&parse), .part1 = @ptrCast(&part1), .part2 = @ptrCast(&part2) };
pub fn main() void {
    common.run_day(work);
}
