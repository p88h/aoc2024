const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day19;

const VisState = struct {
    ctx: *sol.Context,
    cur: usize,
    ofs: usize,
    speed: usize,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.cur = 0;
    vis.ofs = 0;
    vis.speed = 1;
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (vis.cur >= ctx.patterns.len) return true;
    const cidx = (idx - vis.ofs) * vis.speed;
    var reachable = [_]usize{0} ** 64;
    var tmp = [_]u32{0} ** 64;
    var cols = [_]ray.Color{ray.BLACK} ** 64;
    const line = ctx.patterns[vis.cur];
    for (line, 0..) |c, i| {
        tmp[i] = sol.chrcode(c);
        cols[i] = switch (c) {
            'r' => ray.RED,
            'g' => ray.GREEN,
            'b' => ray.BLACK,
            'u' => ray.BLUE,
            'w' => ray.WHITE,
            else => ray.PINK,
        };
    }
    const tsize = 24;
    var ends = [_]usize{0} ** tsize;
    var ep: usize = 0;
    var bars: usize = 0;
    const bw = 32;
    const bh = 32;
    for (0..line.len) |k| {
        const dy = 32;
        const dx = k * bw + 2;
        ray.DrawRectangle(@intCast(dx), @intCast(dy + 1), bw, bh - 2, ray.DARKGRAY);
        ray.DrawRectangle(@intCast(dx + 1), @intCast(dy + 2), bw - 2, bh - 4, cols[k]);
    }
    a.writeXY("Decomposition:", 0, 2, ray.RAYWHITE);
    reachable[0] = 1;
    for (0..line.len) |i| {
        var tcode: u32 = 0;
        if (reachable[i] == 0) continue;
        for (1..ctx.mlen + 1) |j| {
            if (i + j > line.len) break;
            tcode = tcode * 8 + tmp[i + j - 1];
            // if (p1 and reachable[i + j] > 0) continue;
            if (ctx.dict.contains(tcode)) {
                reachable[i + j] += reachable[i];
                const dx1 = i * bw + 2;
                while (ends[ep] >= dx1) ep = (ep + 1) % tsize;
                const dy = ep * bh + 96;
                ends[ep] = (i + j + 1) * bw + 2;
                for (0..j) |k| {
                    const dx = dx1 + k * bw;
                    ray.DrawRectangle(@intCast(dx), @intCast(dy + 1), bw, bh - 2, ray.DARKGRAY);
                    ray.DrawRectangle(@intCast(dx + 1), @intCast(dy + 2), bw - 2, bh - 4, cols[i + k]);
                }
                bars += 1;
                if (bars > cidx) return false;
            }
        }
    }
    var buf = [_]u8{0} ** 128;
    _ = std.fmt.bufPrintZ(&buf, "Combinations: {d}", .{reachable[line.len]}) catch unreachable;
    a.writeXY(&buf, 0, 0, ray.RAYWHITE);
    if (cidx - bars > 60) {
        vis.ofs = idx + 1;
        vis.cur += 1;
    }
    if (vis.cur > 1) vis.speed = 1 + vis.cur / 2;
    if (vis.speed > 5) vis.speed = 5;
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .width = 1920, .height = 1080, .fsize = 32, .fps = 60 },
};
