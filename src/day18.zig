const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const DIM = 73;
pub const MAXT = 1024;
pub const Vec2 = @Vector(2, i16);

pub const Context = struct {
    allocator: Allocator,
    blocks: []Vec2,
    map: []u8,
    prev: []u16,
    dist: []u16,
    stack: []Vec2,
    start: Vec2,
    end: Vec2,
};

pub fn parseVec(line: []const u8, comptime sep: u8, T: type, len: comptime_int) @Vector(len, T) {
    var vec: @Vector(len, T) = @splat(0);
    var p: usize = 0;
    for (0..line.len) |i| {
        if (line[i] == sep) {
            p += 1;
        } else vec[p] = vec[p] * 10 + line[i] - '0';
    }
    return vec;
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.blocks = allocator.alloc(Vec2, lines.len) catch unreachable;
    for (lines, 0..) |line, i| {
        // offset everything by 1,1
        ctx.blocks[i] = parseVec(line, ',', i16, 2) + Vec2{ 1, 1 };
    }
    ctx.start = Vec2{ 1, 1 };
    ctx.end = Vec2{ DIM - 2, DIM - 2 };
    ctx.map = allocator.alloc(u8, DIM * DIM) catch unreachable;
    @memset(ctx.map, '.');
    // draw borders
    for (0..DIM) |p| {
        ctx.map[p] = '#';
        ctx.map[DIM * DIM - p - 1] = '#';
        ctx.map[DIM * p] = '#';
        ctx.map[DIM * p + DIM - 1] = '#';
    }
    ctx.prev = allocator.alloc(u16, DIM * DIM) catch unreachable;
    ctx.stack = allocator.alloc(Vec2, DIM * DIM) catch unreachable;
    ctx.dist = allocator.alloc(u16, DIM * DIM) catch unreachable;
    return ctx;
}

pub inline fn vpos(v: Vec2) usize {
    return @intCast(v[1] * DIM + v[0]);
}

pub fn bfs(ctx: *Context, start: Vec2, end: Vec2) usize {
    const dirs = [_]Vec2{ Vec2{ 0, -1 }, Vec2{ 0, 1 }, Vec2{ -1, 0 }, Vec2{ 1, 0 } };
    const spos = vpos(start);
    ctx.dist[spos] = 1;
    ctx.stack[0] = start;
    var idx: usize = 0;
    var cnt: usize = 1;
    while (idx < cnt) {
        const cur = ctx.stack[idx];
        const cpos = vpos(cur);
        idx += 1;
        if (std.simd.countTrues(cur == end) == 2) break;
        for (dirs) |move| {
            const next = cur + move;
            const npos = vpos(next);
            if (ctx.dist[npos] == 0) {
                ctx.dist[npos] = ctx.dist[cpos] + 1;
                if (ctx.map[npos] == '#') continue;
                ctx.prev[npos] = @intCast(cpos);
                ctx.stack[cnt] = next;
                cnt += 1;
            }
        }
    }
    return ctx.dist[vpos(end)];
}

pub fn part1(ctx: *Context) []u8 {
    for (0..MAXT) |i| {
        if (i >= ctx.blocks.len) break;
        const tmp = ctx.blocks[i];
        ctx.map[vpos(tmp)] = '#';
    }
    @memset(ctx.dist, 0);
    const ret = bfs(ctx, ctx.start, ctx.end);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ret - 1}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    // clear once
    @memset(ctx.dist, 0);
    // place remaining blocks
    for (MAXT..ctx.blocks.len) |i| ctx.map[vpos(ctx.blocks[i])] = '#';
    var last = ctx.blocks.len - 1;
    _ = bfs(ctx, ctx.start, ctx.end);
    // now undo, in reverse
    while (last > 1) : (last -= 1) {
        const cpos = vpos(ctx.blocks[last]);
        ctx.map[cpos] = '.';
        // reachable wall, go explore
        if (ctx.dist[cpos] > 0 and bfs(ctx, ctx.blocks[last], ctx.end) > 0) break;
    }
    // std.debug.print("reachable after removing {d} : {any}\n", .{ last, ctx.blocks[last] });
    const fb = ctx.blocks[last] - Vec2{ 1, 1 };
    return std.fmt.allocPrint(ctx.allocator, "{d},{d}", .{ fb[0], fb[1] }) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "18",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
