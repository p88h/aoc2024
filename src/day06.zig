const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Guard = struct {
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
    pub fn turn(self: *Guard) void {
        const tmp = self.dx;
        self.dx = -self.dy;
        self.dy = tmp;
    }
    pub fn move(self: *Guard) void {
        self.x += self.dx;
        self.y += self.dy;
    }
    pub fn key(self: *const Guard) i32 {
        const p: i32 = (self.x << 10) + (self.y << 2);
        if (self.dx != 0) {
            return p + self.dx + 1; // +0 / + 2
        } else {
            return p + self.dy + 2; // +1 / + 3
        }
    }
    pub fn from(kv: i32) Guard {
        var dx: i32 = 0;
        var dy: i32 = 0;
        switch (kv & 0x3) {
            0 => dx = -1,
            1 => dy = -1,
            2 => dx = 1,
            3 => dy = 1,
            else => {},
        }
        const ret = Guard{ .x = kv >> 10, .y = (kv >> 2) & 0xFF, .dx = dx, .dy = dy };
        std.debug.assert(ret.key() == kv);
        return ret;
    }
};

pub const Context = struct {
    allocator: Allocator,
    buf: []u8,
    dim: usize,
    gp: Guard,
    pub fn map(self: *Context, x: i32, y: i32) u8 {
        if (y >= 0 and y < self.dim and x >= 0 and x < self.dim) {
            const pos: usize = @as(usize, @intCast(y)) * (self.dim + 1) + @as(usize, @intCast(x));
            return self.buf[pos];
        }
        return 0;
    }
    pub fn update(self: *Context, x: i32, y: i32, v: u8) void {
        const pos: usize = @as(usize, @intCast(y)) * (self.dim + 1) + @as(usize, @intCast(x));
        self.buf[pos] = v;
    }
    pub fn ahead(self: *Context, gp: Guard) u8 {
        return self.map(gp.x + gp.dx, gp.y + gp.dy);
    }
};

pub fn parse(allocator: Allocator, buf: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.buf = buf;
    ctx.dim = lines.len;
    ctx.allocator = allocator;
    const sp = std.mem.indexOf(u8, buf, "^").?;
    const sx: usize = sp % (ctx.dim + 1);
    const sy: usize = sp / (ctx.dim + 1);
    ctx.gp = Guard{ .x = @intCast(sx), .y = @intCast(sy), .dx = 0, .dy = -1 };
    // std.debug.print("sx: {d}, sy: {d}, ch: {c}\n", .{ ctx.sx, ctx.sy, ctx.map[ctx.sy][ctx.sx] });
    return @ptrCast(ctx);
}

pub fn part1(ctx: *Context) []u8 {
    var tot: i32 = 0;
    var gp = ctx.gp;
    while (true) {
        if (ctx.map(gp.x, gp.y) != 'x') {
            tot += 1;
            ctx.update(gp.x, gp.y, 'x');
        }
        while (ctx.ahead(gp) == '#') gp.turn();
        if (ctx.ahead(gp) == 0) break;
        gp.move();
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot: i32 = 0;
    var history = [_]bool{false} ** (1 << 19);
    var shadow = [_]i32{-1} ** (1 << 19);
    var jumps = [_]i32{-1} ** (1 << 19);
    var prevk: i32 = -1;
    var gp = ctx.gp;
    var iter: i32 = 0;
    while (true) {
        // this will prevent shadow walls in this position
        ctx.update(gp.x, gp.y, 'X');
        // only handle history at the corners - this speeds things up a lot
        while (ctx.ahead(gp) == '#') {
            // build the jump accelerator
            if (prevk >= 0) jumps[@intCast(prevk)] = gp.key();
            history[@intCast(gp.key())] = true;
            gp.turn();
            prevk = gp.key();
        }
        if (ctx.ahead(gp) == 0) break;
        // if there is an empty field, we maybe can place an obstacle
        if (ctx.ahead(gp) == 'x') {
            // shadow wall pos
            const gx = gp.x + gp.dx;
            const gy = gp.y + gp.dy;
            ctx.update(gx, gy, '#');
            var gs = gp;
            var prevk2: i32 = -1;
            // std.debug.print("ghost walk at {d} from {d},{d} +{d}.{d}\n", .{ history.count(), gs.x, gs.y, gs.dx, gs.dy });
            gs.turn();
            iter += 1;
            while (ctx.ahead(gs) != 0) {
                if (ctx.ahead(gs) == '#') {
                    const gk: usize = @intCast(gs.key());
                    if (prevk2 >= 0) jumps[@intCast(prevk2)] = gs.key();
                    if (history[gk] or shadow[gk] == iter) break;
                    shadow[gk] = iter;
                    gs.turn();
                    // accelerate jumps except block axii
                    if (gs.x != gx and gs.y != gy) {
                        prevk2 = gs.key();
                        // jump once
                        if (jumps[@intCast(prevk2)] >= 0) gs = Guard.from(jumps[@intCast(prevk2)]);
                    } else {
                        prevk2 = -1;
                    }
                } else {
                    gs.move();
                }
            }
            // we did, in fact, loop.
            if (ctx.ahead(gs) != 0) tot += 1;
            ctx.update(gx, gy, 'x');
        }
        gp.move();
    }
    // std.debug.print("{d} {d}\n", .{ tot2, tot3 });
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "06", .parse = @ptrCast(&parse), .part1 = @ptrCast(&part1), .part2 = @ptrCast(&part2) };
pub fn main() void {
    for (0..10) |_|
        common.run_day(work);
}
