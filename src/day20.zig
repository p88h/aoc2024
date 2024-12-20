const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const vtype = i16;
pub const Vec2 = @Vector(2, vtype);

pub const Context = struct {
    allocator: Allocator,
    map: []u8,
    start: Vec2,
    end: Vec2,
    best: vtype,
    dimx: usize,
    dimy: usize,
    work1: []vtype,
    work2: []vtype,
    total: std.atomic.Value(u64),
    wait_group: std.Thread.WaitGroup,
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
    ctx.dimx = lines[0].len + 1;
    ctx.dimy = lines.len;
    ctx.map = buf;
    ctx.work1 = allocator.alloc(vtype, ctx.dimx * ctx.dimy) catch unreachable;
    ctx.work2 = allocator.alloc(vtype, ctx.dimx * ctx.dimy) catch unreachable;
    @memset(ctx.work1, 0);
    @memset(ctx.work2, 0);
    ctx.total.store(0, .seq_cst);
    return ctx;
}

pub fn bfs(ctx: *Context, start: Vec2, end: Vec2, dist: []vtype) vtype {
    const dirs = [_]Vec2{ Vec2{ 0, -1 }, Vec2{ 0, 1 }, Vec2{ -1, 0 }, Vec2{ 1, 0 } };
    var q1 = std.ArrayList(Vec2).init(ctx.allocator);
    var q2 = std.ArrayList(Vec2).init(ctx.allocator);
    var q = &q1;
    var nq = &q2;
    const idimx = @as(i16, @intCast(ctx.dimx));
    const spos: usize = @intCast(start[0] * idimx + start[1]);
    dist[spos] = 1;
    q.append(start) catch unreachable;
    var idx: usize = 0;
    var ecnt: usize = 0;
    while (idx < q.items.len) {
        const cur = q.items[idx];
        const cpos: usize = @intCast(cur[0] * idimx + cur[1]);
        ecnt += 1;
        idx += 1;
        inline for (dirs) |move| {
            const next = cur + move;
            const npos: usize = @intCast(next[0] * idimx + next[1]);
            if (dist[npos] == 0) { //or dist[nval] > dist[cval] + 1001
                dist[npos] = dist[cpos] + 1;
                if (ctx.map[npos] != '#')
                    nq.append(next) catch unreachable;
            }
        }
        // swap queues when needed
        if (idx == q.items.len) {
            const tq = q;
            q = nq;
            nq = tq;
            nq.clearRetainingCapacity();
            idx = 0;
        }
    }
    const epos: usize = @intCast(end[0] * idimx + end[1]);
    return dist[epos];
}

pub fn part1(ctx: *Context) []u8 {
    const d1 = bfs(ctx, ctx.start, ctx.end, ctx.work1) - 1;
    ctx.best = bfs(ctx, ctx.end, ctx.start, ctx.work2) - 1;
    var tot: usize = 0;
    for (0..ctx.dimx * ctx.dimy) |i| {
        if (ctx.map[i] == '#' and ctx.work1[i] > 0 and ctx.work2[i] > 0 and ctx.work1[i] + ctx.work2[i] - 2 <= d1 - 100) {
            tot += 1;
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2_range(ctx: *Context, sy: usize, num: usize) void {
    var tot: usize = 0;
    const idimx = @as(i16, @intCast(ctx.dimx));
    for (sy..sy + num) |y| {
        const iy: vtype = @intCast(y);
        for (0..ctx.dimx) |x| {
            const ix: vtype = @intCast(x);
            const cpos: usize = y * ctx.dimx + x;
            if (ctx.map[cpos] == '#' or ctx.work1[cpos] == 0) continue;
            var dy: vtype = -20;
            while (dy <= 20) : (dy += 1) {
                const ay: vtype = @intCast(@abs(dy));
                var dx: vtype = -20 + ay;
                while (dx <= 20 - ay) : (dx += 1) {
                    const clen: i16 = @intCast(@abs(dx) + @abs(dy));
                    if (clen > 20) continue;
                    if (iy + dy < 0 or iy + dy >= ctx.dimy or ix + dx < 0 or ix + dx >= ctx.dimx) continue;
                    const dpos: usize = @intCast((iy + dy) * idimx + ix + dx);
                    if (ctx.map[cpos] != '#' and ctx.map[dpos] != '#' and
                        ctx.work1[cpos] > 0 and ctx.work2[dpos] > 0 and
                        ctx.work1[cpos] + ctx.work2[dpos] - 2 + clen <= ctx.best - 100)
                    {
                        tot += 1;
                    }
                }
            }
        }
    }
    _ = ctx.total.fetchAdd(tot, .seq_cst);
    ctx.wait_group.finish();
}

pub fn part2(ctx: *Context) []u8 {
    const chunk_size = 14;
    const chunks = ctx.dimy / chunk_size;
    ctx.wait_group.reset();
    for (0..chunks) |i| {
        ctx.wait_group.start();
        common.pool.spawn(part2_range, .{ ctx, i * chunk_size, chunk_size }) catch {
            std.debug.panic("failed to spawn thread {d}\n", .{i});
        };
    }
    common.pool.waitAndWork(&ctx.wait_group);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.total.raw}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "20",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
