const std = @import("std");
const common = @import("src").common;
const day01 = @import("src").day01;
const handler = @import("handler.zig").handler;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    return common.create_ctx(allocator, day01.work);
}

fn writenum(ctx: *day01.Context, a: *ASCIIRay, i: usize, o: i32, n: i32, color: ray.Color) void {
    const h = @divFloor(a.v.height, @as(c_int, @intFromFloat(a.fsize)));
    const y = @rem(@as(i32, @intCast(i)), h);
    const x = @divFloor(@as(i32, @intCast(i)), h) * 14 + o;
    const s = std.fmt.allocPrint(ctx.allocator, "{d}", .{n}) catch unreachable;
    defer ctx.allocator.free(s);
    a.writeXY(s, x, y, color);
}

pub fn step(ptr: *anyopaque, a: *ASCIIRay, idx: usize) bool {
    const ctx: *day01.Context = @alignCast(@ptrCast(ptr));
    if (idx >= 2 * ctx.cnt) return true;
    for (0..ctx.cnt) |i| {
        writenum(ctx, a, i, 0, ctx.left[i], ray.LIGHTGRAY);
        writenum(ctx, a, i, 6, ctx.right[i], ray.LIGHTGRAY);
        if (i > 0 and idx % 2 == i % 2) {
            if (ctx.left[i] < ctx.left[i - 1]) std.mem.swap(i32, &ctx.left[i], &ctx.left[i - 1]);
            if (ctx.right[i] < ctx.right[i - 1]) std.mem.swap(i32, &ctx.right[i], &ctx.right[i - 1]);
        }
    }
    if (idx < ctx.cnt) return false;
    var rpos: usize = 0;
    for (0..idx - ctx.cnt) |i| {
        writenum(ctx, a, i, 0, ctx.left[i], ray.DARKGRAY);
        while (rpos < ctx.cnt and ctx.left[i] > ctx.right[rpos]) {
            writenum(ctx, a, rpos, 6, ctx.right[rpos], ray.DARKBROWN);
            rpos += 1;
        }
        while (rpos < ctx.cnt and ctx.left[i] == ctx.right[rpos]) {
            writenum(ctx, a, i, 0, ctx.left[i], ray.RAYWHITE);
            writenum(ctx, a, rpos, 6, ctx.right[rpos], ray.RAYWHITE);
            rpos += 1;
        }
    }

    return false;
}

pub const handle = handler{ .init = init, .step = step };
