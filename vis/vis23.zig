const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day23;

const VisState = struct {
    ctx: *sol.Context,
    cliques: std.ArrayList([]u8),
    done: std.AutoHashMap(u16, bool),
    pos: [1024]ray.Vector2,
    mid: usize,
    max: usize,
    tot: usize,
    random: std.Random,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.cliques = std.ArrayList([]u8).init(allocator);
    vis.done = std.AutoHashMap(u16, bool).init(allocator);
    vis.mid = 0;
    vis.max = 0;
    vis.tot = 0;
    var prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    vis.random = prng.random();
    for (vis.ctx.nodes) |node| {
        if (node.conns.len == 0) continue;
        vis.tot += 1;
        const px = std.rand.intRangeAtMost(vis.random, i32, 10, 1910);
        const py = std.rand.intRangeAtMost(vis.random, i32, 10, 1070);
        vis.pos[node.id] = .{ .x = @floatFromInt(px), .y = @floatFromInt(py) };
    }
    return vis;
}

pub inline fn format_id(id: u16) @Vector(2, u8) {
    return @Vector(2, u8){ @as(u8, @intCast('a' - 1 + (id >> 5))), @as(u8, @intCast('a' - 1 + (id & 31))) };
}

pub inline fn distance(p1: ray.Vector2, p2: ray.Vector2) f32 {
    return ray.Vector2Length(ray.Vector2Subtract(p1, p2));
}

pub inline fn force(p1: ray.Vector2, p2: ray.Vector2, scale: f32) ray.Vector2 {
    const v = ray.Vector2Subtract(p2, p1);
    const n = ray.Vector2Normalize(v);
    return ray.Vector2Scale(n, scale);
}

const master_scale = 0.3;
pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > 60 * 60) return true;
    var bus = [_]u8{' '} ** 3;
    bus[2] = 0;
    // first layer - draw connections
    for (ctx.nodes) |node| {
        if (node.conns.len == 0) continue;
        const p = vis.pos[node.id];
        for (node.conns) |id| {
            if (id == node.id) continue;
            const p2 = vis.pos[id];
            ray.DrawLineV(p, p2, ray.DARKGRAY);
        }
    }
    // second loop - draw labels and update positions
    for (ctx.nodes) |node| {
        if (node.conns.len == 0) continue;
        var p = vis.pos[node.id];
        const f = format_id(node.id);
        bus[0] = f[0];
        bus[1] = f[1];
        a.writeat(&bus, @intFromFloat(p.x), @intFromFloat(p.y), ray.LIGHTGRAY);
        // gravity
        for (node.conns) |id| {
            if (id == node.id) continue;
            const p2 = vis.pos[id];
            const d = distance(p, p2);
            if (d < 64) continue;
            p = ray.Vector2Add(p, force(p, p2, master_scale));
        }
        // anti-gravity
        for (ctx.nodes) |node2| {
            if (node2.id == node.id) continue;
            const p2 = vis.pos[node2.id];
            const d = distance(p, p2);
            if (d > 128) continue;
            var scale: f32 = master_scale / 4.0;
            if (d < 48) scale = master_scale / 2.0;
            if (d < 24) scale = master_scale;
            p = ray.Vector2Subtract(p, force(p, p2, scale));
        }

        vis.pos[node.id] = p;
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 16, .fps = 30 },
};
