const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @import("ray.zig").ray;
const sol = @import("src").day20;

const VisState = struct {
    ctx: *sol.Context,
    scnt: usize,
    pidx: usize,
    prev1: []usize,
    prev2: []usize,
    cuts: std.ArrayList(sol.Vec2),
    tdict: std.AutoHashMap(sol.Vec2, bool),
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.scnt = 0;
    const ctx = vis.ctx;
    vis.cuts = @TypeOf(vis.cuts).init(allocator);
    vis.prev1 = allocator.alloc(usize, ctx.dimx * ctx.dimy) catch unreachable;
    vis.prev2 = allocator.alloc(usize, ctx.dimx * ctx.dimy) catch unreachable;
    vis.tdict = @TypeOf(vis.tdict).init(allocator);
    @memset(vis.prev1, 0);
    @memset(vis.prev2, 0);
    _ = sol.bfs(ctx, ctx.start, ctx.end, ctx.work1, vis.prev1) - 1;
    ctx.best = sol.bfs(ctx, ctx.end, ctx.start, ctx.work2, vis.prev2) - 1;
    return vis;
}

pub fn find_cuts(vis: *VisState, pos: sol.Vec2, lim: comptime_int) void {
    const ctx = vis.ctx;
    const idimx = @as(i16, @intCast(ctx.dimx));
    const dlimit = ctx.best - 100;
    const cdim = ctx.dimy;
    const dist1 = ctx.work1;
    const dist2 = ctx.work2;
    const cpos: usize = @intCast(pos[0] * idimx + pos[1]);
    const cdist = dist1[cpos];
    std.debug.assert(cdist > 0);
    vis.cuts.clearRetainingCapacity();
    var d = sol.Vec2{ -lim, -lim };
    while (d[0] <= lim) : (d[0] += 1) {
        const ay: sol.vtype = @intCast(@abs(d[0]));
        if (pos[0] + d[0] < 1) continue;
        if (pos[0] + d[0] >= cdim) break;
        d[1] = -lim + ay;
        while (d[1] <= lim - ay) : (d[1] += 1) {
            const clen: i16 = @intCast(@abs(d[0]) + @abs(d[1]));
            if (pos[1] + d[1] < 1) continue;
            if (pos[1] + d[1] >= cdim) break;
            std.debug.assert(clen <= lim);
            const dest = pos + d;
            const dpos: usize = @intCast(dest[0] * idimx + dest[1]);
            const ddist = dist2[dpos];
            if (ddist > 0 and cdist + ddist - 2 + clen <= dlimit) vis.cuts.append(dest) catch unreachable;
        }
    }
    vis.scnt += vis.cuts.items.len;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    var buf = [_]u8{0} ** 128;
    const cidx = idx + ctx.qidx;
    if (cidx >= ctx.queue.items.len) return true;
    _ = std.fmt.bufPrintZ(&buf, "Cell: {d}/{d}", .{ cidx, ctx.queue.items.len }) catch unreachable;
    a.writeXY(&buf, 0, 0, ray.RAYWHITE);
    const idimx = @as(i16, @intCast(ctx.dimx));
    var cur = ctx.queue.items[cidx];
    var cpos: usize = @intCast(cur[0] * idimx + cur[1]);
    find_cuts(vis, cur, 20);
    // Draw map
    const bw = 10;
    const bh = 7;
    for (0..ctx.dimy) |y| {
        for (0..ctx.dimx - 1) |x| {
            const px = x * bw + 260;
            const py = y * bh + 46;
            const pos = y * ctx.dimx + x;
            var col = ray.DARKGRAY;
            if (ctx.map[pos] == '#') col = ray.BROWN;
            if (ctx.work1[pos] == 1) col = ray.GREEN;
            if (ctx.work2[pos] == 1) col = ray.BLUE;
            if (pos == cpos) col = ray.RED;
            ray.DrawRectangle(@intCast(px), @intCast(py), bw - 1, bh - 1, col);
        }
    }
    while (vis.prev1[cpos] > 0) {
        cpos = vis.prev1[cpos];
        cur = sol.Vec2{ @intCast(cpos / ctx.dimx), @intCast(cpos % ctx.dimx) };
        const px = cur[1] * bw + 260;
        const py = cur[0] * bh + 46;
        if (std.simd.countTrues(cur == ctx.start) != 2)
            ray.DrawRectangle(@intCast(px), @intCast(py), bw - 1, bh - 1, ray.LIGHTGRAY);
    }
    const tlen = vis.cuts.items.len;
    _ = std.fmt.bufPrintZ(&buf, "Cheats: {d}", .{vis.cuts.items.len}) catch unreachable;
    a.writeXY(&buf, 0, 1, ray.RAYWHITE);
    var i: usize = 0;
    vis.tdict.clearRetainingCapacity();
    for (vis.cuts.items) |t| vis.tdict.put(t, true) catch unreachable;
    while (i < vis.cuts.items.len) : (i += 1) {
        cur = vis.cuts.items[i];
        cpos = @intCast(cur[0] * idimx + cur[1]);
        const px = cur[1] * bw + 260;
        const py = cur[0] * bh + 46;
        var col = ray.DARKBLUE;
        if (i < tlen) col = ray.YELLOW;
        if (std.simd.countTrues(cur == ctx.end) != 2)
            ray.DrawRectangle(@intCast(px), @intCast(py), bw - 1, bh - 1, col);
        const ppos = vis.prev2[cpos];
        if (ppos == 0) continue;
        const prev = sol.Vec2{ @intCast(ppos / ctx.dimx), @intCast(ppos % ctx.dimx) };
        if (vis.tdict.contains(prev)) continue;
        vis.tdict.put(prev, true) catch unreachable;
        vis.cuts.append(prev) catch unreachable;
    }

    _ = std.fmt.bufPrintZ(&buf, "Total: {d}", .{vis.scnt}) catch unreachable;
    a.writeXY(&buf, 0, 2, ray.RAYWHITE);

    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 24, .fps = 60 },
};
