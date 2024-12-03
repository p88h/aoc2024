const std = @import("std");
const common = @import("src").common;
const handler = @import("handler.zig").handler;
const day03 = @import("src").day03;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});

const dfa_ctx = struct {
    hist: []i32,
    buf: []u8,
    state: i32,
    pos: usize,
    idx: usize,
    flags: usize,
    cur: [2]i32,
    tot: i32,
};

fn dfa_sub(ctx: *dfa_ctx, ch: u8) i32 {
    const mul = "mul(";
    const dont = "don't()";
    const do = "do()";
    // std.debug.print("state: {d} ch: {c}\n", .{ ctx.state, ch });
    if (ctx.state < 0) {
        ctx.state = 0;
        ctx.pos = 0;
        ctx.cur = [2]i32{ 0, 0 };
        ctx.idx = 0;
        ctx.flags = 0;
    }
    switch (ctx.state) {
        // unknown, accepting don't and mul(
        0 => {
            if (ch == mul[0]) {
                ctx.state = 1;
                ctx.pos = 1;
            } else if (ch == dont[0]) {
                ctx.state = 3;
                ctx.pos = 1;
            }
        },
        // mul prefix
        1 => {
            if (ch == mul[ctx.pos]) {
                ctx.pos += 1;
            } else ctx.state = -1;
            if (ctx.pos == mul.len) ctx.state = 2;
        },
        // numbers
        2 => {
            if (ch == ',') {
                ctx.idx += 1;
                if (ctx.idx > 1) ctx.state = -1;
            } else if (ch >= '0' and ch <= '9') {
                ctx.cur[ctx.idx] = ctx.cur[ctx.idx] * 10 + @as(i32, @intCast(ch - '0'));
                ctx.flags |= ctx.idx + 1;
            } else if (ch == ')' and ctx.idx == 1 and ctx.cur[0] >= 0 and ctx.cur[1] >= 0 and ctx.flags == 3) {
                ctx.tot += ctx.cur[0] * ctx.cur[1];
                ctx.state = -2;
            } else ctx.state = -1;
        },
        // dont prefix
        3 => {
            if (ch == dont[ctx.pos]) {
                ctx.pos += 1;
            } else ctx.state = -1;
            if (ctx.pos == dont.len) {
                ctx.pos = 0;
                ctx.state = 4;
            }
        },
        // dont block
        4 => {
            if (ch == do[0]) {
                ctx.state = 5;
                ctx.pos = 1;
            }
        },
        5 => {
            if (ch == do[ctx.pos]) {
                ctx.pos += 1;
            } else {
                ctx.state = 4;
                ctx.pos = 0;
            }
            if (ctx.pos == do.len) ctx.state = -5;
        },
        else => {},
    }
    return ctx.state;
}

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    const ptr = common.create_ctx(allocator, day03.work);
    const dctx: *day03.Context = @alignCast(@ptrCast(ptr));
    var ctx = allocator.create(dfa_ctx) catch unreachable;
    ctx.buf = dctx.buf;
    ctx.hist = allocator.alloc(i32, ctx.buf.len) catch unreachable;
    @memset(std.mem.asBytes(&ctx.buf[0]), 0);
    return ctx;
}

pub fn step(ptr: *anyopaque, a: *ASCIIRay, idx: usize) bool {
    const ctx: *dfa_ctx = @alignCast(@ptrCast(ptr));
    const speed = 6;
    if (idx * speed >= ctx.buf.len) return true;
    for (0..speed) |s| {
        const pos = idx * speed + s;
        if (pos >= ctx.buf.len) break;
        ctx.hist[pos] = dfa_sub(ctx, ctx.buf[pos]);
        // repeat for proper reset
        if (ctx.state < 0) _ = dfa_sub(ctx, ctx.buf[pos]);
    }
    var cbuf = [2]u8{ 0, 0 };
    var start: usize = 0;
    const maxw = 120;
    const maxh = 33;
    const scrh = maxh - 5;

    if (idx * speed >= scrh * maxw) {
        start = ((idx * speed / maxw) - scrh + 1) * maxw;
    }
    while (start > 0 and start + maxw * maxh > ctx.buf.len) {
        start -= maxw;
    }
    const end: usize = start + maxw * maxh;
    for (start..end) |i| {
        var col = ray.LIGHTGRAY;
        switch (ctx.hist[i]) {
            1 => {
                col = ray.GREEN;
            },
            2, -2 => {
                col = ray.ORANGE;
            },
            3 => {
                col = ray.RED;
            },
            4 => {
                col = ray.DARKGRAY;
            },
            5, -5 => {
                col = ray.BLUE;
            },
            else => {},
        }
        cbuf[0] = ctx.buf[i];
        a.writeXY(&cbuf, @intCast((i - start) % maxw), @intCast((i - start) / maxw), col);
    }
    return false;
}

pub const handle = handler{ .init = init, .step = step, .window = .{ .fsize = 32 } };
