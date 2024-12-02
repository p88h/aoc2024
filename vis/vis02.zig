const std = @import("std");
const common = @import("src").common;
const day02 = @import("src").day02;
const handler = @import("handler.zig").handler;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});

pub fn init(allocator: Allocator, a: *ASCIIRay) *anyopaque {
    a.v.fps = 6;
    return common.create_ctx(allocator, day02.work);
}

fn dispvec(a: *ASCIIRay, left: day02.vec8, right: day02.vec8, num: day02.vec8, l: usize, p: usize) void {
    const fs = @as(c_int, @intFromFloat(a.fsize));
    const numw: c_int = 3 * @divFloor(fs, 2);
    const boxh: c_int = 104 + @as(c_int, @intFromFloat(a.fsize));
    const boxw: c_int = 8 * numw;
    const maxy: c_int = @divFloor(a.v.height, boxh);
    const pi = @as(c_int, @intCast(p));
    const sy: c_int = @rem(pi, maxy) * boxh;
    const sx: c_int = @divFloor(pi, maxy) * boxw;
    ray.DrawRectangleLines(sx + 1, sy + 1, boxw - 2, boxh - 2, ray.RAYWHITE);
    const ll = l - 1;
    const n = (num & left) + std.simd.rotateElementsLeft(num & right, 1);
    var ppos = ray.Vector2{ .x = @floatFromInt(sx + 2), .y = @floatFromInt(sy + n[0] + 2) };
    var pd: c_int = 0;
    for (1..ll) |i| {
        var d = n[i] -% n[i - 1];
        var dd: c_int = 1;
        if (d > 127) {
            d = n[i] -% n[i - 1];
            dd = -dd;
        }
        var col = ray.GREEN;
        if (d > 3 or (pd != 0 and dd != pd)) {
            col = ray.RED;
        }
        pd = dd;
        const npos = ray.Vector2{ .x = ppos.x + 30, .y = @floatFromInt(sy + n[i] + 2) };
        ray.DrawLineBezier(ppos, npos, 2.0, col);
        ppos = npos;
    }
    var buf = [_]u8{' '} ** 8;
    buf[7] = 0;
    for (@as(c_int, 0)..ll) |i| {
        _ = std.fmt.bufPrint(&buf, "{d}   ", .{n[i]}) catch unreachable;
        a.writeat(&buf, sx + @as(c_int, @intCast(i)) * numw, sy + boxh - fs, ray.LIGHTGRAY);
    }
}

pub fn step(ptr: *anyopaque, a: *ASCIIRay, idx: usize) bool {
    const ctx: *day02.Context = @alignCast(@ptrCast(ptr));
    if (idx >= 88) return true;
    var right: day02.vec8 = @splat(255);
    var left: day02.vec8 = @splat(0);
    for (0..idx % 8) |_| right = std.simd.shiftElementsRight(right, 1, 0);
    if (idx % 8 > 0) {
        for (1..idx % 8) |_| left = std.simd.shiftElementsRight(left, 1, 255);
    }
    const ofs: usize = (idx / 8) * 90;
    for (0..90) |i| {
        if (i + ofs >= ctx.cnt.len) break;
        dispvec(a, left, right, ctx.pak[i + ofs], ctx.cnt[i + ofs], i);
    }
    return false;
}

pub const handle = handler{ .init = init, .step = step };
