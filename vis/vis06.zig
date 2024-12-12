const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day06;

var history: std.AutoHashMap(sol.Guard, i32) = undefined;
var shadow: std.AutoHashMap(sol.Guard, i32) = undefined;
var tracks = [_]std.ArrayList(sol.Guard){undefined} ** 4;
var tidx: usize = 0;

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    history = @TypeOf(history).init(allocator);
    shadow = @TypeOf(shadow).init(allocator);
    for (0..tracks.len) |i| tracks[i] = std.ArrayList(sol.Guard).init(allocator);
    return common.create_ctx(allocator, sol.work);
}

pub fn gray(v: u8) ray.Color {
    return ray.Color{ .r = v, .g = v, .b = v, .a = 255 };
}

pub fn step(ptr: *anyopaque, _: *ASCIIRay, _: usize) bool {
    const ctx: *sol.Context = @alignCast(@ptrCast(ptr));
    ctx.update(ctx.gp.x, ctx.gp.y, 'x');
    history.put(ctx.gp, 1) catch unreachable;
    // shadow wall pos
    const gx = ctx.gp.x + ctx.gp.dx;
    const gy = ctx.gp.y + ctx.gp.dy;
    if (ctx.ahead(ctx.gp) == '.') {
        ctx.update(gx, gy, '#');
        var gs = ctx.gp;
        gs.turn();
        shadow.clearRetainingCapacity();
        tidx = (tidx + 1) % tracks.len;
        var trk: *std.ArrayList(sol.Guard) = &tracks[tidx];
        trk.clearRetainingCapacity();
        trk.append(ctx.gp) catch unreachable;
        while (ctx.ahead(gs) != 0) {
            trk.append(gs) catch unreachable;
            if (ctx.ahead(gs) == '#') {
                if (history.contains(gs) or shadow.contains(gs)) break;
                shadow.put(gs, 1) catch unreachable;
                gs.turn();
            } else {
                gs.move();
            }
        }
        if (ctx.ahead(gs) == 0) {
            // revert
            tidx = (tidx + 3) % tracks.len;
        }
        ctx.update(gx, gy, '.');
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
    const cols = [_]ray.Color{ gray(40), gray(80), gray(160), gray(255) };
    for (0..tracks.len) |ti| {
        const trk: *std.ArrayList(sol.Guard) = &tracks[(tidx + ti + 1) % tracks.len];
        if (trk.items.len == 0) continue;
        var cx1 = @as(c_int, @intCast(trk.items[0].x)) * 8 + 440;
        var cy1 = @as(c_int, @intCast(trk.items[0].y)) * 8 + 20;
        for (trk.items[1..]) |g| {
            const cx2 = @as(c_int, @intCast(g.x)) * 8 + 440;
            const cy2 = @as(c_int, @intCast(g.y)) * 8 + 20;
            ray.DrawLine(cx1 + 4, cy1 + 4, cx2 + 4, cy2 + 4, cols[ti]);
            cx1 = cx2;
            cy1 = cy2;
        }
    }
    while (ctx.ahead(ctx.gp) == '#') ctx.gp.turn();
    if (ctx.ahead(ctx.gp) == 0) return true;
    ctx.gp.move();
    return false;
}

pub const handle = handler{ .init = init, .step = step, .window = .{ .fps = 30 } };
