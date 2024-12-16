const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @import("ray.zig").ray;
const sol = @import("src").day16;

const VisState = struct {
    ctx: *sol.Context,
    cnt1: usize,
    idx: usize,
    tiles: ray.Texture2D,
    speed: usize,
    bdist: i32,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.idx = 0;
    vis.speed = 1;
    var ctx = vis.ctx;
    ctx.collect = 'o';
    const spos: usize = @intCast(ctx.start[0] * @as(i32, @intCast(ctx.dimx)) + ctx.start[1]);
    ctx.eval = sol.bfs(ctx, spos * 4 + 1, ctx.end, ctx.work1);
    ctx.best = ctx.work1[ctx.eval] + 1;
    vis.cnt1 = ctx.path.items.len;
    // go back
    ctx.collect = 'O';
    const bval = sol.bfs(ctx, ctx.eval ^ 1, ctx.start, ctx.work2);
    vis.bdist = ctx.work2[bval] + ctx.work1[bval ^ 1];
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx * 5 > ctx.path.items.len + 600) return true;
    var buf = [_]u8{0} ** 128;
    buf[1] = 0;
    const bw = 12;
    const bh = 7;
    for (0..ctx.dimy) |y| {
        for (0..ctx.dimx) |x| {
            const px = (9 + x) * bw;
            const py = (6 + y) * bh;
            if (ctx.map[y * ctx.dimx + x] == '#') ray.DrawRectangle(@intCast(px), @intCast(py), bw, bh, ray.BROWN);
        }
    }
    _ = std.fmt.bufPrintZ(&buf, "States counter: {d}", .{idx * 5}) catch unreachable;
    a.writeXY(&buf, 46, 0, ray.RAYWHITE);
    for (0..idx * 5) |i| {
        if (i >= ctx.path.items.len) break;
        const cur = ctx.path.items[i];
        const px = (9 + cur[1]) * bw;
        const py = (6 + cur[0]) * bh;
        var col = ray.LIGHTGRAY;
        if (i > vis.cnt1) {
            col = ray.RED;
            const pos: usize = @intCast(cur[0] * @as(i32, @intCast(ctx.dimx)) + cur[1]);
            for (0..4) |k| {
                if (ctx.work1[pos * 4 + k] == 0 or ctx.work2[pos * 4 + k ^ 1] == 0) continue;
                if (ctx.work1[pos * 4 + k] + ctx.work2[pos * 4 + k ^ 1] == vis.bdist) {
                    col = ray.GREEN;
                    break;
                }
            }
        }
        ray.DrawRectangle(@intCast(px + 1), @intCast(py + 1), bw - 2, bh - 2, col);
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 16, .fps = 60 },
};
