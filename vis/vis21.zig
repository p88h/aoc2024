const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day21;

const VisState = struct {
    ctx: *sol.Context,
    kidx: std.AutoHashMap(u64, usize),
    dist: usize,
    posx: c_int,
    posy: c_int,
    dx: c_int,
    dy: c_int,
};

pub fn k2s(key: u64, buf: *[64]u8) usize {
    @memset(buf, ' ');
    const d: usize = @intCast(key & 0xFF);
    var ck = key >> 8;
    var p: usize = 7;
    while (ck > 0) : (p -= 1) {
        buf[p] = @intCast(ck & 0xFF);
        ck >>= 8;
    }
    buf[8] = 0;
    return d;
}

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.ctx.log = std.ArrayList(u64).init(allocator);
    vis.dist = sol.compute_top(vis.ctx, 26);
    vis.kidx = std.AutoHashMap(u64, usize).init(allocator);
    vis.posx = 0;
    vis.posy = 0;
    vis.dx = 1;
    vis.dy = 1;
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx >= ctx.log.?.items.len) return true;
    var buf = [_]u8{' '} ** 64;
    for (0..idx) |i| {
        const key = vis.ctx.log.?.items[i];
        const val = vis.ctx.cache.get(key).?;
        const d = key & 0xFF;
        if (d > 23) continue;
        var dx: usize = vis.kidx.count();
        if (vis.kidx.contains(key >> 8)) {
            dx = vis.kidx.get(key >> 8).?;
        } else {
            vis.kidx.put(key >> 8, dx) catch unreachable;
        }
        _ = std.fmt.bufPrintZ(&buf, "{d:12}", .{val}) catch unreachable;
        a.writeXY(&buf, @intCast(dx * 12), @intCast(d), ray.GREEN);
    }
    var it = vis.kidx.iterator();
    while (it.next()) |entry| {
        const dx = entry.value_ptr.*;
        const key = entry.key_ptr.*;
        _ = k2s(key << 8, &buf);
        a.writeXY(&buf, @intCast(dx * 12 + 4), 0, ray.RED);
    }
    for (1..24) |d| {
        _ = std.fmt.bufPrintZ(&buf, "{d}", .{d}) catch unreachable;
        a.writeXY(&buf, 0, @intCast(d), ray.LIGHTGRAY);
    }
    a.writeXY("Key:", 0, 0, ray.RAYWHITE);

    a.writeXY("Min presses for: ", 0, 25, ray.YELLOW);
    const key = vis.ctx.log.?.items[idx];
    const val = vis.ctx.cache.get(key).?;
    const d = k2s(key, &buf);
    a.writeXY(&buf, 16, 25, ray.YELLOW);
    _ = std.fmt.bufPrintZ(&buf, "at depth {d} = {d}", .{ d, val }) catch unreachable;
    a.writeXY(&buf, 25, 25, ray.YELLOW);
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 20, .fps = 15 },
};
