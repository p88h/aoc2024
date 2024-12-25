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
    qidx: usize,
    queue: std.ArrayList(Vec2),
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
    ctx.queue = std.ArrayList(Vec2).init(allocator);
    ctx.work1 = allocator.alloc(vtype, ctx.dimx * ctx.dimy) catch unreachable;
    ctx.work2 = allocator.alloc(vtype, ctx.dimx * ctx.dimy) catch unreachable;
    @memset(ctx.work1, 0);
    @memset(ctx.work2, 0);
    return ctx;
}

pub fn bfs(ctx: *Context, start: Vec2, end: Vec2, dist: []vtype, prev: ?[]usize) vtype {
    const dirs = [_]Vec2{ Vec2{ 0, -1 }, Vec2{ 0, 1 }, Vec2{ -1, 0 }, Vec2{ 1, 0 } };
    ctx.queue.clearRetainingCapacity();
    const idimx = @as(i16, @intCast(ctx.dimx));
    const spos: usize = @intCast(start[0] * idimx + start[1]);
    dist[spos] = 1;
    ctx.queue.append(start) catch unreachable;
    ctx.qidx = 0;
    var idx: usize = 0;
    var ecnt: usize = 0;
    while (idx < ctx.queue.items.len) {
        const cur = ctx.queue.items[idx];
        const cpos: usize = @intCast(cur[0] * idimx + cur[1]);
        if (ctx.qidx == 0 and dist[cpos] > 100) ctx.qidx = idx;
        ecnt += 1;
        idx += 1;
        inline for (dirs) |move| {
            const next = cur + move;
            const npos: usize = @intCast(next[0] * idimx + next[1]);
            if (dist[npos] == 0 and ctx.map[npos] != '#') {
                dist[npos] = dist[cpos] + 1;
                if (prev != null) prev.?[npos] = cpos;
                ctx.queue.append(next) catch unreachable;
            }
        }
    }
    const epos: usize = @intCast(end[0] * idimx + end[1]);
    return dist[epos];
}

pub fn search_range(ctx: *Context, shard: usize, comptime scnt: usize, lim: comptime_int) void {
    var tot: usize = 0;
    const idimx = @as(i16, @intCast(ctx.dimx));
    const dlimit = ctx.best - 100;
    const cdim = ctx.dimy;
    const dist1 = ctx.work1;
    const dist2 = ctx.work2;
    for (ctx.qidx..ctx.queue.items.len) |i| {
        if (i % scnt != shard) continue;
        const pos = ctx.queue.items[i];
        const cpos: usize = @intCast(pos[0] * idimx + pos[1]);
        const cdist = dist1[cpos];
        std.debug.assert(cdist > 0);
        var dy: vtype = -lim;
        while (dy <= lim) : (dy += 1) {
            const ay: vtype = @intCast(@abs(dy));
            if (pos[0] + dy < 1) continue;
            if (pos[0] + dy >= cdim) break;
            var dx: vtype = -lim + ay;
            while (dx <= lim - ay) : (dx += 1) {
                const clen: i16 = @intCast(@abs(dx) + @abs(dy));
                if (pos[1] + dx < 1) continue;
                if (pos[1] + dx >= cdim) break;
                std.debug.assert(clen <= lim);
                // if (clen > 20) continue;
                const dpos: usize = @intCast((pos[0] + dy) * idimx + pos[1] + dx);
                const ddist = dist2[dpos];
                if (ddist > 0 and cdist + ddist - 2 + clen <= dlimit) tot += 1;
            }
        }
    }
    _ = ctx.total.fetchAdd(tot, .seq_cst);
    ctx.wait_group.finish();
}

pub fn run_parallel(ctx: *Context, lim: comptime_int) u64 {
    const scnt = 12;
    ctx.total.store(0, .seq_cst);
    ctx.wait_group.reset();
    for (0..scnt) |i| {
        ctx.wait_group.start();
        common.pool.spawn(search_range, .{ ctx, i, scnt, lim }) catch {
            std.debug.panic("failed to spawn thread {d}\n", .{i});
        };
    }
    common.pool.waitAndWork(&ctx.wait_group);
    return ctx.total.load(.seq_cst);
}

pub fn part1(ctx: *Context) []u8 {
    _ = bfs(ctx, ctx.start, ctx.end, ctx.work1, null) - 1;
    ctx.best = bfs(ctx, ctx.end, ctx.start, ctx.work2, null) - 1;
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{run_parallel(ctx, 2)}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{run_parallel(ctx, 20)}) catch unreachable;
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
