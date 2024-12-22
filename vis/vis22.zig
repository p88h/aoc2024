const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day22;

const VisState = struct {
    ctx: *sol.Context,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    return vis;
}

pub fn step(vis: *VisState, _: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > ctx.secrets.len) return true;
    for (0..idx) |i| {
        if (i >= ctx.secrets.len) break;
        var v = ctx.secrets[i];
        var h: sol.Vec8 = @splat(0);
        var history = [_]u32{0} ** sol.pcnt;
        for (0..2564) |k| {
            v = sol.hash_smash_v2(v, &h);
            if (k >= 4) {
                const p = sol.pack_patterns(h);
                for (0..8) |j| {
                    var col = ray.BLACK;
                    var pat = p[j];
                    const bit: u32 = @as(u32, 1) << @as(u5, @intCast(j));
                    if (history[pat] & bit == 0) {
                        const d: u8 = @intCast(v[j] % 10);
                        const r = (pat & 0x3F) * 2 + 0x40;
                        pat >>= 6;
                        const g = (pat & 0x3F) * 2 + 0x40;
                        pat >>= 6;
                        const b = (pat & 0x1F) * 2 + 0x40;
                        col = .{ .r = @intCast(r), .g = @intCast(g), .b = @intCast(b), .a = @intCast((d + 6) * 16) };
                        history[pat] |= bit;
                    }
                    ray.DrawPixel(@intCast(k - 4), @intCast(i * 8 + j), col);
                }
            }
        }
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .width = 2560, .height = 1440, .fsize = 32, .fps = 30 },
};
