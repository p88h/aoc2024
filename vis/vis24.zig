const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day24;

const VisState = struct {
    ctx: *sol.Context,
    sel: ?*sol.Gate = null,
    swaps: std.ArrayList(*sol.Gate),
    fidx: usize = 0,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.fidx = 0;
    vis.sel = null;
    sol.reorder(vis.ctx);
    vis.swaps = std.ArrayList(*sol.Gate).init(allocator);
    return vis;
}

pub inline fn vpos(g: *sol.Gate, dx: comptime_int, dy: comptime_int) ray.Vector2 {
    return ray.Vector2{
        .x = @floatFromInt(@as(i32, @intCast(g.pos[0])) + dx),
        .y = @floatFromInt(@as(i32, @intCast(g.pos[1])) + dy),
    };
}

pub inline fn drawbox(g: *sol.Gate, col: ray.Color) void {
    ray.DrawRectangleLinesEx(ray.Rectangle{
        .x = @floatFromInt(@as(i32, @intCast(g.pos[0] - 12))),
        .y = @floatFromInt(@as(i32, @intCast(g.pos[1] - 16))),
        .width = 24,
        .height = 16,
    }, 2, col);
}

pub fn step(vis: *VisState, a: *ASCIIRay, _: usize) bool {
    const ctx = vis.ctx;
    var buf = [_]u8{' '} ** 4;
    buf[3] = 0;
    ray.DrawCircleV(ray.GetMousePosition(), 5, ray.DARKGRAY);
    ray.DrawCircleV(ray.GetMousePosition(), 1, ray.LIGHTGRAY);
    if (ray.IsMouseButtonDown(ray.MOUSE_BUTTON_LEFT)) {
        var newsel: ?*sol.Gate = null;
        for (0..ctx.gcnt) |idx| {
            const g = &ctx.gates[idx];
            if (ray.CheckCollisionPointRec(ray.GetMousePosition(), ray.Rectangle{
                .x = @floatFromInt(@as(i32, @intCast(g.pos[0] - 12))),
                .y = @floatFromInt(@as(i32, @intCast(g.pos[1] - 16))),
                .width = 24,
                .height = 18,
            })) {
                newsel = g;
            }
        }
        if (newsel != null and vis.sel != null and vis.sel != newsel) {
            vis.swaps.append(vis.sel.?) catch unreachable;
            vis.swaps.append(newsel.?) catch unreachable;
            sol.swap(newsel.?, vis.sel.?);
            sol.reorder(ctx);
            sol.reset(ctx, vis.fidx);
            vis.sel = null;
        } else vis.sel = newsel;
    }
    const key = ray.GetKeyPressed();
    if (key == ray.KEY_SPACE) vis.sel = null;
    if (key == ray.KEY_BACKSPACE) {
        const g1 = vis.swaps.pop();
        const g2 = vis.swaps.pop();
        sol.swap(g1, g2);
        sol.reorder(ctx);
        sol.reset(ctx, vis.fidx);
    }
    if (key == ray.KEY_RIGHT) {
        vis.fidx = (vis.fidx + 1) % ctx.zcnt;
        sol.reset(ctx, vis.fidx);
    }
    if (key == ray.KEY_LEFT) {
        vis.fidx = (vis.fidx + ctx.zcnt - 1) % ctx.zcnt;
        sol.reset(ctx, vis.fidx);
    }
    var badcnt: usize = 0;
    for (0..ctx.gcnt) |idx| {
        const g = &ctx.gates[idx];
        inline for (0..3) |i| buf[i] = g.label.?[i];
        var col = ray.WHITE;
        switch (g.op) {
            sol.Op.AND => col = ray.GREEN,
            sol.Op.OR => col = ray.BLUE,
            sol.Op.XOR => col = ray.RED,
            else => col = ray.WHITE,
        }
        if (!sol.eval(g)) col.a = 180;
        a.writeat(&buf, @intCast(g.pos[0] - 12), @intCast(g.pos[1] - 16), col);
        if (vis.sel == g) {
            drawbox(g, ray.YELLOW);
            a.writeat("Selected: ", 176, 1024, ray.RAYWHITE);
            a.writeat(&buf, 256, 1024, ray.RAYWHITE);
        } else if (sol.isbad(g) and (vis.sel == null or sol.hdist(g, vis.sel.?) < 80)) {
            drawbox(g, ray.BLUE);
            badcnt += 1;
        }
        var wcol = ray.BROWN;
        if (g.op != sol.Op.VALUE) {
            if (g.left.?.value.?) wcol = ray.LIGHTGRAY;
            ray.DrawLineBezier(
                vpos(g, -12, -16),
                vpos(g.left.?, 0, 0),
                2,
                wcol,
            );
            wcol = ray.BROWN;
            if (g.right.?.value.?) wcol = ray.LIGHTGRAY;
            ray.DrawLineBezier(
                vpos(g, 12, -16),
                vpos(g.right.?, 0, 0),
                2,
                wcol,
            );
        }
    }
    a.writeat("Potentially bad:", 20, 1024, ray.RAYWHITE);
    _ = std.fmt.bufPrintZ(&buf, "{d}", .{badcnt}) catch unreachable;
    a.writeat(&buf, 148, 1024, ray.RAYWHITE);

    a.writeat("Swaps:", 20, 1040, ray.RAYWHITE);
    for (vis.swaps.items, 0..) |g, p| {
        inline for (0..3) |i| buf[i] = g.label.?[i];
        a.writeat(&buf, @intCast(100 + p * 32), 1040, ray.RAYWHITE);
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 16, .fps = 30 },
};
