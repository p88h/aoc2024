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
    frame: [sol.FRAME_SIZE]u16,
};

pub fn init(allocator: Allocator, a: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.tex = ray.LoadRenderTexture(a.v.width, a.v.height);
    vis.ctx.wait_group.reset();
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    const speed = 2;
    if (idx * speed >= 10000) return true;
    var buf = [_]u8{0} ** 16;
    ray.BeginTextureMode(vis.tex);
    for (0..speed) |i| {
        const ridx = idx * speed + i;
        const f = ridx % 160;
        const dy: i32 = @intCast((f / 16) * 108);
        const dx: i32 = @intCast((f % 16) * 116);
        const s = sol.score(ctx, ridx, &vis.frame);
        ray.DrawRectangle(dx, dy, 120, 108, ray.BLACK);
        _ = std.fmt.bufPrintZ(&buf, "{d}:{d}", .{ ridx, s }) catch unreachable;
        var col = ray.RED;
        if (s >= 5) col = ray.ORANGE;
        if (s >= 10) col = ray.YELLOW;
        if (s > 50) col = ray.GREEN;
        a.writeat(&buf, @intCast(dx), @intCast(dy), ray.RAYWHITE);
        for (ctx.robots) |robot| {
            const fpos = robot.pos + @as(sol.vec2, @splat(@intCast(ridx))) * robot.dir;
            const fx = @mod(fpos[0], sol.W);
            const fy = @mod(fpos[1], sol.H);
            ray.DrawPixel(@intCast(dx + fx), @intCast(dy + fy), col);
        }
    }
    ray.EndTextureMode();
    ray.DrawTexturePro(
        vis.tex.texture,
        .{ .x = 0, .y = @floatFromInt(a.v.height), .width = @floatFromInt(a.v.width), .height = @floatFromInt(-a.v.height) },
        .{ .x = 0, .y = 0, .width = @floatFromInt(a.v.width), .height = @floatFromInt(a.v.height) },
        .{},
        0,
        ray.WHITE,
    );
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 16, .fps = 60 },
};
