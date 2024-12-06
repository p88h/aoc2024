const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});
const sol = @import("src").day06;

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    return common.create_ctx(allocator, sol.work);
}

pub fn step(ptr: *anyopaque, _: *ASCIIRay, _: usize) bool {
    const ctx: *sol.Context = @alignCast(@ptrCast(ptr));
    if (ctx.map(ctx.gp.x, ctx.gp.y) != 'x') {
        ctx.update(ctx.gp.x, ctx.gp.y, 'x');
    }
    for (0..ctx.dim) |y| {
        for (0..ctx.dim) |x| {
            var ch = ctx.map(@intCast(x), @intCast(y));
            const cx: c_int = @as(c_int, @intCast(x)) * 8 + 440;
            const cy: c_int = @as(c_int, @intCast(y)) * 8 + 20;
            if (y == ctx.gp.y and x == ctx.gp.x) ch = '*';
            switch (ch) {
                '#' => ray.DrawRectangle(cx, cy, 8, 8, ray.BLUE),
                'x' => ray.DrawRectangleLines(cx, cy, 8, 8, ray.GREEN),
                '*' => ray.DrawRectangle(cx, cy, 8, 8, ray.RED),
                else => ray.DrawRectangleLines(cx + 1, cy + 1, 6, 6, ray.DARKGRAY),
            }
        }
    }
    while (ctx.ahead(ctx.gp) == '#') ctx.gp.turn();
    if (ctx.ahead(ctx.gp) == 0) return true;
    ctx.gp.move();
    return false;
}

pub const handle = handler{ .init = init, .step = step, .window = .{ .fps = 60 } };
