const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Vec2 = @Vector(2, i32);

pub const Context = struct {
    allocator: Allocator,
    map: []u8,
    start: Vec2,
    end: Vec2,
    dimx: usize,
    dimy: usize,
    work1: []i32,
    work2: []i32,
    best: i32,
    eval: usize,
    path: std.AutoHashMap(Vec2, bool),
};

pub fn parse(allocator: Allocator, buf: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    for (0..lines.len) |i| {
        for (0..lines[i].len) |j| {
            if (lines[i][j] == 'S') ctx.start = Vec2{ @intCast(i), @intCast(j) };
            if (lines[i][j] == 'E') ctx.end = Vec2{ @intCast(i), @intCast(j) };
        }
    }
    ctx.best = 0;
    ctx.dimx = lines[0].len + 1;
    ctx.dimy = lines.len;
    ctx.map = buf;
    ctx.path = std.AutoHashMap(Vec2, bool).init(allocator);
    ctx.work1 = allocator.alloc(i32, ctx.dimx * ctx.dimy * 4) catch unreachable;
    ctx.work2 = allocator.alloc(i32, ctx.dimx * ctx.dimy * 4) catch unreachable;
    @memset(ctx.work1, 0);
    @memset(ctx.work2, 0);
    return ctx;
}

pub fn bfs(ctx: *Context, start: usize, end: Vec2, dist: []i32) usize {
    const dirs = [_]Vec2{ Vec2{ 0, -1 }, Vec2{ 0, 1 }, Vec2{ -1, 0 }, Vec2{ 1, 0 } };
    var q1 = std.ArrayList(usize).init(ctx.allocator);
    var q2 = std.ArrayList(usize).init(ctx.allocator);
    var q = &q1;
    var nq = &q2;
    const idimx = @as(i32, @intCast(ctx.dimx));
    dist[start] = 1;
    q.append(start) catch unreachable;
    var idx: usize = 0;
    var ecnt: usize = 0;
    while (idx < q.items.len) {
        const cval = q.items[idx];
        const cpos = cval / 4;
        const cdir = cval % 4;
        const cur: Vec2 = Vec2{ @intCast(cpos / ctx.dimx), @intCast(cpos % ctx.dimx) };
        ecnt += 1;
        idx += 1;
        if (ctx.best > 0) {
            ctx.path.put(cur, true) catch unreachable;
        }
        if (std.simd.countTrues(cur == end) == 2) {
            return cval;
        }
        // continue moving, add to current queue
        var next = cur + dirs[cdir];
        var npos: usize = @intCast(next[0] * idimx + next[1]);
        var nval = npos * 4 + cdir;
        if (ctx.map[npos] != '#') {
            if (dist[nval] == 0) {
                dist[nval] = dist[cval] + 1;
                if (ctx.best == 0 or dist[nval] + ctx.work1[nval ^ 1] == ctx.best) {
                    q.append(nval) catch unreachable;
                }
            }
        }
        // turn left or right, but check if we wont' run into a wall first
        // these go on to the next queue (+1000 cost)
        for (dirs, 0..) |move, ndir| {
            if (ndir == cdir or ndir == cdir ^ 1) continue;
            const tval = cval - cdir + ndir;
            // keep track of turn cost, but skip putting on the queue, use the next move instead
            if (dist[tval] == 0) dist[tval] = dist[cval] + 1000; //or dist[tval] > dist[cval] + 1000
            next = cur + move;
            npos = @intCast(next[0] * idimx + next[1]);
            if (ctx.map[npos] == '#') continue;
            nval = npos * 4 + ndir;
            if (dist[nval] == 0) { //or dist[nval] > dist[cval] + 1001
                dist[nval] = dist[cval] + 1001;
                nq.append(nval) catch unreachable;
            }
        }
        // swap queues if needed
        if (idx == q.items.len) {
            const tq = q;
            q = nq;
            nq = tq;
            nq.clearRetainingCapacity();
            idx = 0;
        }
    }
    return 0;
}

pub fn part1(ctx: *Context) []u8 {
    const spos: usize = @intCast(ctx.start[0] * @as(i32, @intCast(ctx.dimx)) + ctx.start[1]);
    ctx.eval = bfs(ctx, spos * 4 + 1, ctx.end, ctx.work1);
    ctx.best = ctx.work1[ctx.eval] + 1;
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.best - 1}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    const bval = bfs(ctx, ctx.eval ^ 1, ctx.start, ctx.work2);
    const bdist = ctx.work2[bval] + ctx.work1[bval ^ 1];
    // std.debug.print("bd={d}, best={}\n", .{ bdist, ctx.best });
    var ret: usize = 0;
    var iter = ctx.path.keyIterator();
    while (iter.next()) |cur| {
        const pos: usize = @intCast(cur[0] * @as(i32, @intCast(ctx.dimx)) + cur[1]);
        for (0..4) |k| {
            if (ctx.work1[pos * 4 + k] == 0 or ctx.work2[pos * 4 + k ^ 1] == 0) continue;
            if (ctx.work1[pos * 4 + k] + ctx.work2[pos * 4 + k ^ 1] == bdist) {
                ret += 1;
                break;
            }
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ret}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "16",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
