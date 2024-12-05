const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});
const sol = @import("src").day05;

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    return common.create_ctx(allocator, sol.work);
}

fn slowly(idx: usize) usize {
    if (idx < 300) return idx / 10;
    if (idx < 600) return 30 + (idx - 300) / 5;
    if (idx < 900) return 90 + (idx - 600) / 3;
    if (idx < 1200) return 190 + (idx - 900) / 2;
    return 340 + (idx - 1200);
}

pub fn step(ptr: *anyopaque, a: *ASCIIRay, idx: usize) bool {
    const ctx: *sol.Context = @alignCast(@ptrCast(ptr));
    var cidx = slowly(idx);
    var cr: usize = 0;
    while (cr < ctx.insns.items.len and cidx > ctx.insns.items[cr].len) {
        cidx -= ctx.insns.items[cr].len;
        cr += 1;
    }
    if (cr == ctx.insns.items.len) return true;
    var cbuf = [_]u8{0} ** 10;
    const cins = ctx.insns.items[cr];
    a.writeXY("INPUT: ", 1, 2, ray.LIGHTGRAY);
    a.writeXY("MASK: ", 1, 4, ray.LIGHTGRAY);
    // const spos = ctx.iposm[cr];
    for (0..cins.len) |i| {
        const p = cins[i];
        _ = std.fmt.bufPrint(&cbuf, "{d}", .{p}) catch unreachable;
        cbuf[2] = 0;
        a.writeXY(&cbuf, @intCast(8 + i * 3), 2, ray.RAYWHITE);
        a.writeXY("X", 2 * p, 4, ray.RAYWHITE);
    }
    const cpos = ctx.iposm.items[cr];
    a.writeXY("BITS", 203, 4, ray.RAYWHITE);
    for (0..cidx) |i| {
        const p = cins[i];
        _ = std.fmt.bufPrint(&cbuf, "RULES[{d}]:", .{p}) catch unreachable;
        cbuf[9] = 0;
        a.writeXY(&cbuf, 1, @intCast(5 + i), ray.LIGHTGRAY);
        for (10..100) |b| {
            const bs = @as(u128, 1) << @as(u7, @intCast(b));
            if (ctx.graph[p] & bs != 0) {
                if (cpos & bs != 0) {
                    a.writeXY("*", @intCast(2 * b), @intCast(5 + i), ray.RAYWHITE);
                } else {
                    a.writeXY("*", @intCast(2 * b), @intCast(5 + i), ray.DARKGRAY);
                }
            }
        }
        const pm = ctx.graph[p] & cpos;
        const pp = @popCount(pm);
        if (pp != cins.len - i - 1) {
            _ = std.fmt.bufPrint(&cbuf, "{d} x ", .{pp}) catch unreachable;
            cbuf[4] = 0;
            a.writeXY(&cbuf, 204, @intCast(5 + i), ray.RED);
        } else {
            _ = std.fmt.bufPrint(&cbuf, "{d} + ", .{pp}) catch unreachable;
            cbuf[4] = 0;
            a.writeXY(&cbuf, 204, @intCast(5 + i), ray.GREEN);
        }
    }
    const vofs = 38;
    a.writeXY("RESULTS: ", 1, vofs - 1, ray.RAYWHITE);
    var start: usize = 0;
    if (cr >= 20) start = cr - 20;
    for (start..cr) |i| {
        _ = std.fmt.bufPrint(&cbuf, "{d}  ", .{i}) catch unreachable;
        cbuf[3] = 0;
        a.writeXY(&cbuf, 1, @intCast(i + vofs - start), ray.RAYWHITE);
        const cins2 = ctx.insns.items[i];
        const cpos2 = ctx.iposm.items[i];
        const ilen = cins2.len;
        var mid: u32 = 0;
        var bad = false;
        for (0..ilen) |j| {
            const p = cins2[j];
            const pm = ctx.graph[p] & cpos2;
            const pp = @popCount(pm);
            if (pp == ilen / 2) mid = @intCast(p);
            _ = std.fmt.bufPrint(&cbuf, "{d}", .{p}) catch unreachable;
            cbuf[2] = 0;
            if (pp != ilen - j - 1) {
                bad = true;
                a.writeXY(&cbuf, @intCast(8 + j * 3), @intCast(i + vofs - start), ray.RED);
            } else {
                a.writeXY(&cbuf, @intCast(8 + j * 3), @intCast(i + vofs - start), ray.GREEN);
            }
        }
        if (bad) {
            a.writeXY("BAD", @intCast(2 + 32 * 3), @intCast(i + vofs - start), ray.RED);
        } else {
            a.writeXY("OK", @intCast(2 + 32 * 3), @intCast(i + vofs - start), ray.GREEN);
        }
        _ = std.fmt.bufPrint(&cbuf, "MID={d}", .{mid}) catch unreachable;
        cbuf[6] = 0;
        a.writeXY(&cbuf, @intCast(8 + 32 * 3), @intCast(i + vofs - start), ray.RAYWHITE);
    }

    return false;
}

pub const handle = handler{ .init = init, .step = step, .window = .{ .fps = 60, .fsize = 18 } };
