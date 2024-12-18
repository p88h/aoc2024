const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @import("ray.zig").ray;
const sol = @import("src").day18;

const VisState = struct {
    ctx: *sol.Context,
    best: usize,
    prev: usize,
    scnt: usize,
    pidx: usize,
    minbps: usize,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.scnt = 0;
    vis.best = (sol.DIM - 1) * 2;
    vis.minbps = 2_000_000_000_000;
    update_path(vis, 0);
    return vis;
}

pub fn update_path(vis: *VisState, idx: usize) void {
    const ctx = vis.ctx;
    const spos = sol.vpos(ctx.start);
    var epos = sol.vpos(ctx.end);
    vis.prev = vis.best;
    vis.pidx = idx + 1;
    vis.scnt += 1;
    vis.best = sol.bfs(ctx, ctx.start, ctx.end);
    if (vis.best == 0) return;
    vis.best -= 1;
    while (epos != spos) {
        ctx.dist[epos] = 1;
        epos = ctx.prev[epos];
    }
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    var buf = [_]u8{0} ** 128;
    if (idx >= ctx.blocks.len) return true;
    _ = std.fmt.bufPrintZ(&buf, "Time: {d} ns", .{idx}) catch unreachable;
    a.writeXY(&buf, 0, 0, ray.RAYWHITE);
    // add a block
    const tmp = ctx.blocks[idx];
    const tpos = sol.vpos(tmp);
    ctx.map[tpos] = '#';
    // critical path ?
    var bps: usize = 0;
    if (vis.best > 0) {
        if (ctx.dist[tpos] == 1) update_path(vis, idx);
        bps = (1_000_000_000 * vis.best) / (idx + 1);
    } else {
        // bytes per second at last good path
        bps = (1_000_000_000 * vis.prev) / vis.pidx;
    }
    _ = std.fmt.bufPrintZ(&buf, "Distance: {d} px", .{vis.best}) catch unreachable;
    a.writeXY(&buf, 0, 1, ray.RAYWHITE);
    _ = std.fmt.bufPrintZ(&buf, "BFS runs: {d}", .{vis.scnt}) catch unreachable;
    a.writeXY(&buf, 0, 2, ray.RAYWHITE);
    a.writeXY("Historians lost: 0", 0, 3, ray.GREEN);
    a.writeXY("           (today)", 0, 4, ray.GREEN);
    if (bps > 0 and bps < vis.minbps) vis.minbps = bps;
    for (0..2) |i| {
        const units = [_][]const u8{ "", "K", "M", "G" };
        var uidx: usize = 0;
        if (i == 1) bps = vis.minbps;
        while (bps > 1024) {
            bps /= 1024;
            uidx += 1;
        }
        var pfx: []const u8 = "";
        if (i == 1) pfx = "Min ";
        _ = std.fmt.bufPrintZ(&buf, "{s}Speed: {d} {s}Bps", .{ pfx, bps, units[uidx] }) catch unreachable;
        a.writeXY(&buf, 0, @intCast(6 + i), ray.YELLOW);
    }

    // Draw
    const bw = 20;
    const bh = 15;
    for (1..sol.DIM - 1) |y| {
        for (1..sol.DIM - 1) |x| {
            const px = x * bw + 230;
            const py = y * bh - 7;
            const pos = y * sol.DIM + x;
            var col = ray.DARKGRAY;
            if (ctx.map[pos] == '#') col = ray.BROWN;
            if (ctx.dist[pos] == 1) col = ray.WHITE;
            ray.DrawRectangle(@intCast(px), @intCast(py), bw - 1, bh - 1, col);
        }
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 24, .fps = 30 },
};
