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
    mid: usize,
    max: usize,
    tot: usize,
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
    for (vis.ctx.nodes) |node| {
        if (node.conns.len > 0) vis.tot += 1;
    }
    return vis;
}

pub inline fn format_id(id: u16) @Vector(2, u8) {
    return @Vector(2, u8){ @as(u8, @intCast('a' - 1 + (id >> 5))), @as(u8, @intCast('a' - 1 + (id & 31))) };
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > ctx.conns.len) return true;
    const conn = ctx.conns[idx];
    const id1: u16 = @intCast(conn >> 10);
    const id2: u16 = @intCast(conn & 1023);
    const t = sol.find_clique(ctx, id1, id2, 3);
    var buf = [_]u8{' '} ** 64;
    if (t < 3) {
        const f1 = format_id(id1);
        const f2 = format_id(id2);
        _ = std.fmt.bufPrintZ(&buf, "{c}{c},{c}{c} : not in a clique", .{ f1[0], f1[1], f2[0], f2[1] }) catch unreachable;
        a.writeXY(&buf, 0, @intCast(vis.cliques.items.len), ray.RED);
    } else {
        var good: bool = true;
        for (ctx.com3) |id| good = good and !vis.done.contains(id);
        if (good) {
            if (t > vis.max) {
                vis.max = t;
                vis.mid = vis.cliques.items.len;
            }
            vis.cliques.append(sol.format_party(ctx)) catch unreachable;
            for (ctx.com3) |id| vis.done.put(id, true) catch unreachable;
        } else {
            const f1 = format_id(id1);
            const f2 = format_id(id2);
            _ = std.fmt.bufPrintZ(&buf, "{c}{c},{c}{c} : already in a clique", .{ f1[0], f1[1], f2[0], f2[1] }) catch unreachable;
            a.writeXY(&buf, 0, @intCast(vis.cliques.items.len), ray.BLUE);
        }
    }
    for (vis.cliques.items, 0..) |c, i| {
        if (i == vis.mid) {
            a.writeXY("Best party: ", 0, @intCast(i), ray.YELLOW);
            a.writeXY(c, 12, @intCast(i), ray.RAYWHITE);
        } else {
            a.writeXY("Good party: ", 0, @intCast(i), ray.GREEN);
            a.writeXY(c, 12, @intCast(i), ray.LIGHTGRAY);
        }
    }
    _ = std.fmt.bufPrintZ(&buf, "Parties: {d} Nodes playing: {d} / {d}\n", .{
        vis.cliques.items.len,
        vis.done.count(),
        vis.tot,
    }) catch unreachable;
    a.writeXY(&buf, 0, @intCast(vis.cliques.items.len + 2), ray.LIGHTGRAY);

    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .width = 720, .height = 1280, .fsize = 24, .fps = 15 },
};
