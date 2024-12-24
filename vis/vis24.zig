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
    ph: std.AutoHashMap(@Vector(2, u32), bool),
    swaps: std.ArrayList(*sol.Gate),
    fidx: usize = 0,
};

// rather than change labels and update all consumers,
// we change contents, then swap labels.
pub fn swap(a: *sol.Gate, b: *sol.Gate) void {
    std.debug.print("Swapping {s} and {s}\n", .{ a.label.?, b.label.? });
    const tg = a.*;
    a.* = b.*;
    b.* = tg;
    const tmp = a.label;
    a.label = b.label;
    b.label = tmp;
}

pub fn order(vis: *VisState, g: *sol.Gate) void {
    // done?
    if (g.pos[0] != 0) return;
    if (g.op == sol.Op.VALUE) {
        g.pos[1] = 20; // top
        g.pos[0] = 40;
        if (g.label.?[0] == 'y') {
            g.pos[1] += 40;
            g.pos[0] += 18;
        }
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        g.pos[0] += id * 36;
        return;
    }
    order(vis, g.left.?);
    order(vis, g.right.?);
    if (g.left.?.pos[0] > g.right.?.pos[0]) {
        const tmp = g.left;
        g.left = g.right;
        g.right = tmp;
    }
    if (g.left.?.pos[0] == g.right.?.pos[0] and g.right.?.op != sol.Op.AND) {
        const tmp = g.left;
        g.left = g.right;
        g.right = tmp;
    }
    g.pos[0] = g.left.?.pos[0];
    g.pos[1] = @max(g.left.?.pos[1], g.right.?.pos[1]) + 16;
    if (g.left.?.op == .VALUE and g.right.?.op == .VALUE) {
        g.pos[1] += 20;
        if (g.op != .AND) g.pos[1] += 40;
    } else if (g.op == .OR and g.left.?.op == .AND) {
        g.pos[1] = g.left.?.pos[1];
        g.pos[0] = g.left.?.pos[0] + 32;
    }
    if (g.label.?[0] == 'z') {
        g.pos[1] = 1000;
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        g.pos[0] = 20 + id * 32;
    }
    while (vis.ph.contains(g.pos)) g.pos[0] += 32;
    vis.ph.put(g.pos, true) catch unreachable;
}

pub fn reorder(vis: *VisState) void {
    const ctx = vis.ctx;
    vis.ph.clearRetainingCapacity();
    for (0..ctx.gcnt) |idx| ctx.gates[idx].pos = .{ 0, 0 };
    for (0..ctx.gcnt) |idx| {
        if (ctx.gates[idx].label.?[0] == 'z') order(vis, &ctx.gates[idx]);
    }
    vis.sel = null;
}

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.ph = std.AutoHashMap(@Vector(2, u32), bool).init(allocator);
    vis.fidx = 0;
    reorder(vis);
    vis.swaps = std.ArrayList(*sol.Gate).init(allocator);
    return vis;
}

pub inline fn vpos(g: *sol.Gate, dx: comptime_int, dy: comptime_int) ray.Vector2 {
    return ray.Vector2{
        .x = @floatFromInt(@as(i32, @intCast(g.pos[0])) + dx),
        .y = @floatFromInt(@as(i32, @intCast(g.pos[1])) + dy),
    };
}

pub fn reset(vis: *VisState) void {
    const ctx = vis.ctx;
    for (0..ctx.gcnt) |idx| {
        const g = &ctx.gates[idx];
        if (g.op == sol.Op.VALUE) {
            const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
            g.value = vis.fidx == id;
        } else g.value = null;
    }
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
            swap(newsel.?, vis.sel.?);
            reorder(vis);
            reset(vis);
        } else vis.sel = newsel;
    }
    const key = ray.GetKeyPressed();
    if (key == ray.KEY_SPACE) vis.sel = null;
    if (key == ray.KEY_BACKSPACE) {
        const g1 = vis.swaps.pop();
        const g2 = vis.swaps.pop();
        swap(g1, g2);
        reorder(vis);
        reset(vis);
    }
    if (key == ray.KEY_RIGHT) {
        vis.fidx = (vis.fidx + 1) % ctx.zcnt;
        reset(vis);
    }
    if (key == ray.KEY_LEFT) {
        vis.fidx = (vis.fidx + ctx.zcnt - 1) % ctx.zcnt;
        reset(vis);
    }
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
            ray.DrawRectangleLinesEx(ray.Rectangle{
                .x = @floatFromInt(@as(i32, @intCast(g.pos[0] - 12))),
                .y = @floatFromInt(@as(i32, @intCast(g.pos[1] - 16))),
                .width = 24,
                .height = 16,
            }, 2, ray.YELLOW);
            a.writeat("Selected: ", 20, 1024, ray.RAYWHITE);
            a.writeat(&buf, 100, 1024, ray.RAYWHITE);
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
