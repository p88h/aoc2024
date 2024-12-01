const std = @import("std");
const common = @import("src").common;
const day01 = @import("src").day01;
const handler = @import("handler.zig").handler;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    return common.create_ctx(allocator, day01.work);
}

pub fn step(ptr: *anyopaque, a: *ASCIIRay, idx: c_int) bool {
    if (idx > 100) return true;
    const ctx: *day01.Context = @alignCast(@ptrCast(ptr));
    for (0..ctx.cnt) |i| {
        const h = @divFloor(a.v.height, @as(c_int, @intFromFloat(a.fsize)));
        const y = @rem(@as(i32, @intCast(i)), h);
        const x = @divFloor(@as(i32, @intCast(i)), h) * 14;
        const s = std.fmt.allocPrint(ctx.allocator, "{d} {d}", .{ ctx.left[i], ctx.right[i] }) catch unreachable;
        defer ctx.allocator.free(s);
        a.writeXY(s, x, y);
    }
    return false;
}

pub const handle = handler{ .init = init, .step = step };
