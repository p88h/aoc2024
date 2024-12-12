const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    buf: []u8,
    dim: usize,
    stride: usize,
    wait_group: std.Thread.WaitGroup,
};

pub fn parse(allocator: Allocator, buf: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.buf = buf;
    ctx.dim = lines.len;
    ctx.stride = ctx.dim + 1;
    ctx.allocator = allocator;
    return ctx;
}

pub inline fn cptr(ctx: *Context, pos: vec2) *u8 {
    return &ctx.buf[@as(usize, @intCast(pos[1])) * ctx.stride + @as(usize, @intCast(pos[0]))];
}

pub inline fn check(ctx: *Context, pos: vec2) u8 {
    const x = pos[0];
    const y = pos[1];
    if (x < 0 or x >= ctx.dim or y < 0 or y >= ctx.dim) return 0;
    return cptr(ctx, pos).*;
}

pub const vec2 = @Vector(2, i32);

pub fn scan(ctx: *Context, start: vec2, shared: bool) vec2 {
    var stack = std.ArrayList(vec2).init(ctx.allocator);
    var ret = vec2{ 0, 0 };
    const dirs = [4]vec2{ vec2{ 1, 0 }, vec2{ -1, 0 }, vec2{ 0, 1 }, vec2{ 0, -1 } };
    const ch = cptr(ctx, start).*;
    stack.append(start) catch unreachable;
    // mark visited by lowercasing the character
    cptr(ctx, start).* = ch ^ 32;
    while (stack.items.len > 0) {
        const cur: vec2 = stack.pop();
        ret[0] += 1;
        for (dirs) |dir| {
            const next = cur + dir;
            const nch = check(ctx, next);
            // skip visited
            if (nch == ch ^ 32) continue;
            // fences
            if (nch != ch) {
                if (shared) {
                    const mask = 223;
                    const mch = ch & mask;
                    var side: vec2 = undefined;
                    if (dir[0] != 0) { // moving horizontally
                        // check if we share fence if tile _upwards_ from us (which might have not yet been visited)
                        side = cur + vec2{ 0, -1 };
                    } else { // moving vertically
                        // check if we share fence if tile _left_ from us (which might have not yet been visited)
                        side = cur + vec2{ -1, 0 };
                    }
                    // check if side tile will have a fence towards dir
                    const diag = side + dir;
                    const sch = check(ctx, side) & mask;
                    const dch = check(ctx, diag) & mask;
                    if (sch != mch or dch == mch) {
                        ret[1] += 1;
                    }
                } else {
                    ret[1] += 1;
                }
                continue;
            }
            // mark visited
            cptr(ctx, next).* = ch ^ 32;
            stack.append(next) catch unreachable;
        }
    }
    return ret;
}

pub fn part1(ctx: *Context) []u8 {
    var tot: u64 = 0;
    for (0..ctx.dim) |y| {
        for (0..ctx.dim) |x| {
            // not visited
            if (ctx.buf[y * ctx.stride + x] & 32 == 0) {
                const start = vec2{ @intCast(x), @intCast(y) };
                const res = scan(ctx, start, false);
                // std.debug.print("{c}:  {d} * {d}\n", .{ ctx.buf[y * ctx.stride + x], res[0], res[1] });
                tot += @intCast(res[0] * res[1]);
            }
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot: u64 = 0;
    for (0..ctx.dim) |y| {
        for (0..ctx.dim) |x| {
            // not visited
            if (ctx.buf[y * ctx.stride + x] & 32 == 32) {
                const start = vec2{ @intCast(x), @intCast(y) };
                const res = scan(ctx, start, true);
                // std.debug.print("{c}:  {d} * {d}\n", .{ ctx.buf[y * ctx.stride + x], res[0], res[1] });
                tot += @intCast(res[0] * res[1]);
            }
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "12",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
