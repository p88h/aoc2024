const std = @import("std");
const common = @import("src").common;
const handler = @import("handler.zig").handler;
const day04 = @import("src").day04;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});

pub var scratch: [256][256]u32 = [_][256]u32{[_]u32{0} ** 256} ** 256;
pub var colmap: [256]ray.Color = [_]ray.Color{ray.DARKGRAY} ** 256;

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    for (0..256) |c| {
        if (c & 1 != 0) {
            colmap[c].r |= 128;
        }
        if (c & 2 != 0) {
            colmap[c].g |= 128;
        }
        if (c & 4 != 0) {
            colmap[c].b |= 128;
        }
        if (c & 8 != 0) {
            colmap[c].r |= 128;
            colmap[c].g |= 128;
        }
        if (c & 16 != 0) {
            colmap[c].g |= 128;
            colmap[c].b |= 128;
        }
    }
    colmap[0] = ray.LIGHTGRAY;
    return common.create_ctx(allocator, day04.work);
}

pub fn step(ptr: *anyopaque, a: *ASCIIRay, idx: usize) bool {
    const ctx: *day04.Context = @alignCast(@ptrCast(ptr));
    const speed = 14;
    const width = ctx.lines[0].len;
    const height = ctx.lines.len;
    const maxh: usize = 40;
    const scrh = maxh - 5;
    if (idx >= width * (height + 24) / speed) return true;
    for (0..speed) |s| {
        const pos = idx * speed + s;
        const px = pos % width;
        const py = pos / width;
        if (py < height) {
            const tt = day04.match_dirs(ctx, py, px, width, height, day04.pat1) |
                day04.match_dirs(ctx, py, px, width, height, day04.pat2);
            if (tt & 1 > 0) {
                scratch[py][px] |= 1;
                scratch[py + 1][px] |= 1;
                scratch[py + 2][px] |= 1;
                scratch[py + 3][px] |= 1;
            }
            if (tt & 2 > 0) {
                scratch[py][px] |= 2;
                scratch[py][px + 1] |= 2;
                scratch[py][px + 2] |= 2;
                scratch[py][px + 3] |= 2;
            }
            if (tt & 4 > 0) {
                scratch[py][px] |= 4;
                scratch[py - 1][px + 1] |= 4;
                scratch[py - 2][px + 2] |= 4;
                scratch[py - 3][px + 3] |= 4;
            }
            if (tt & 8 > 0) {
                scratch[py][px] |= 8;
                scratch[py + 1][px + 1] |= 8;
                scratch[py + 2][px + 2] |= 8;
                scratch[py + 3][px + 3] |= 8;
            }
        }
        if (py >= 16) {
            // reset
            scratch[py - 16][px] = 32;
        }
        if (py > 20 and py - 19 < height and px > 0 and px + 1 < width) {
            if (day04.match_xmas(ctx, py - 20, px) > 0) {
                scratch[py - 21][px - 1] |= 16;
                scratch[py - 21][px + 1] |= 16;
                scratch[py - 20][px] |= 16;
                scratch[py - 19][px + 1] |= 16;
                scratch[py - 19][px - 1] |= 16;
            }
        }
        if (scratch[py][px] == 0) scratch[py][px] = 32;
    }

    var start: usize = 0;
    if (idx * speed >= scrh * width) {
        start = ((idx * speed / width) - scrh + 1);
    }
    while (start > 0 and start + maxh > ctx.lines.len) {
        start -= 1;
    }
    const end: usize = start + maxh;

    var cbuf = [2]u8{ 0, 0 };
    for (start..end) |y| {
        for (0..width) |x| {
            cbuf[0] = ctx.lines[y][x];
            a.writeXY(&cbuf, @intCast(x + 1), @intCast(y - start), colmap[scratch[y][x]]);
        }
    }
    return false;
}

pub const handle = handler{ .init = init, .step = step, .window = .{ .width = 1280, .height = 720, .fsize = 18 } };
