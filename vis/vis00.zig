const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day00;

const VisState = struct {
    ctx: *sol.Context,
    posx: c_int,
    posy: c_int,
    dx: c_int,
    dy: c_int,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.posx = 0;
    vis.posy = 0;
    vis.dx = 1;
    vis.dy = 1;
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > 100) return true;
    a.writeXY(ctx.lines[0], vis.posx, vis.posy, ray.RAYWHITE);
    vis.posx += vis.dx;
    vis.posy += vis.dy;
    if (vis.posx < 0 or vis.posx >= 120) {
        vis.dx = -vis.dx;
        vis.posx += vis.dx;
    }
    if (vis.posy < 0 or vis.posy >= 33) {
        vis.dy = -vis.dy;
        vis.posy += vis.dy;
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 32, .fps = 30 },
};
