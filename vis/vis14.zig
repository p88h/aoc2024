const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @import("ray.zig").ray;
const sol = @import("src").day14;

const VisState = struct {
    ctx: *sol.Context,
    tex: ray.RenderTexture2D,
    cur: @Vector(2, u32),
    frame: [sol.FRAME_SIZE]u64,
};

pub fn init(allocator: Allocator, a: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.tex = ray.LoadRenderTexture(a.v.width, a.v.height);
    vis.cur = @Vector(2, u32){ 0, 1 };
    sol.train(vis.ctx);
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, _: usize) bool {
    const ctx = vis.ctx;
    if (vis.cur[1] >= sol.W * sol.H) return true;
    var buf = [_]u8{0} ** 64;
    a.writeat("Current Best:", 34, 2, ray.RAYWHITE);
    a.writeat("Candidate:", 977, 2, ray.RAYWHITE);
    for (0..2) |i| {
        const dx: i32 = @intCast(i * 943);
        const s = sol.score(ctx, vis.cur[i], &vis.frame);
        _ = std.fmt.bufPrintZ(&buf, "{d}:{d}", .{ vis.cur[i], s }) catch unreachable;
        a.writeat(&buf, @intCast(34 + dx), 26, ray.RAYWHITE);
        var col = ray.RED;
        if (s >= 5) col = ray.ORANGE;
        if (s >= 10) col = ray.YELLOW;
        if (s > 50) col = ray.GREEN;
        for (ctx.robots) |robot| {
            const fpos = robot.pos + @as(sol.vec2, @splat(@intCast(vis.cur[i]))) * robot.dir;
            const fx = @mod(fpos[0], sol.W);
            const fy = @mod(fpos[1], sol.H);
            ray.DrawRectangle(
                @intCast(34 + fx * 9 + dx),
                @intCast(76 + fy * 9),
                9,
                9,
                col,
            );
        }
    }
    var si: usize = 1;
    var sr = sol.score(ctx, vis.cur[1] + si, &vis.frame);
    // How many candidates to consider for every output frame
    const speed = 16;
    for (2..speed) |i| {
        const st = sol.score(ctx, vis.cur[1] + i, &vis.frame);
        if (st > sr) {
            si = i;
            sr = st;
        }
    }
    vis.cur[1] += @intCast(si);
    const sl = sol.score(ctx, vis.cur[0], &vis.frame);
    if (sl < sr) vis.cur[0] = vis.cur[1];
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 24, .fps = 30 },
};
