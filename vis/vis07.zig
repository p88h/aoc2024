const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});
const sol = @import("src").day07;

pub const VisState = struct {
    ctx: *sol.Context,
    cur: usize,
    ofs: usize,
    hist: std.ArrayList(sol.vec16),
    stack: std.ArrayList(sol.vec16),
    res: std.ArrayList(bool),
    ret: u64,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    const ptr = common.create_ctx(allocator, sol.work);
    const ctx: *sol.Context = @alignCast(@ptrCast(ptr));
    var work = allocator.create(VisState) catch unreachable;
    work.ctx = ctx;
    work.cur = 0;
    work.ofs = 0;
    work.stack = @TypeOf(work.stack).init(ctx.allocator);
    work.hist = @TypeOf(work.hist).init(ctx.allocator);
    work.res = @TypeOf(work.res).init(ctx.allocator);
    return work;
}

pub fn fold(vis: *VisState) bool {
    vis.stack.clearRetainingCapacity();
    var tv = vis.ctx.lines[vis.cur];
    var tmp = vis.ctx.targets[vis.cur];
    var ops: sol.vec16 = @splat('?');
    tv[15] = tmp;
    vis.stack.append(tv) catch unreachable;
    vis.stack.append(ops) catch unreachable;
    var pos: usize = 0;
    while (pos < vis.stack.items.len) {
        tv = vis.stack.items[pos];
        ops = vis.stack.items[pos + 1];
        pos += 2;
        tmp = tv[15];
        tv[14] = tmp;
        const len = tv[0];
        const last = tv[len];
        if (len == 1 and tmp == last) {
            vis.stack.resize(pos) catch unreachable;
            // vis.stack.append(tv) catch unreachable;
            // vis.stack.append(ops) catch unreachable;
            return true;
        }
        if (len == 1) continue;
        tv[0] -= 1;
        // addition should be possible if non-zero result
        if (tmp > last) {
            tv[15] = tmp - last;
            ops[len] = '+';
            vis.stack.append(tv) catch unreachable;
            vis.stack.append(ops) catch unreachable;
        }
        // check if multiplication is possible
        if (tmp % last == 0) {
            tv[15] = tmp / last;
            ops[len] = '*';
            vis.stack.append(tv) catch unreachable;
            vis.stack.append(ops) catch unreachable;
        }
        if (!vis.ctx.concat) continue;
        // concatenation means last digits of target(tmp) match
        var base: usize = 10;
        while (last >= base) base *= 10;
        if (tmp % base == last) {
            tv[15] = tmp / base;
            ops[len] = '|';
            vis.stack.append(tv) catch unreachable;
            vis.stack.append(ops) catch unreachable;
        }
    }
    return false;
}

fn dispvec(p: usize, a: *ASCIIRay, num: sol.vec16, ops: sol.vec16, correct: bool) void {
    var buf = [_]u8{' '} ** 64;
    buf[63] = 0;
    var ofs: usize = 0;
    for (1..14) |i| {
        if (num[i] == 0) break;
        const s = std.fmt.bufPrint(&buf, "  {d} ", .{num[i]}) catch unreachable;
        buf[s.len] = 0;
        if (i > 1) buf[0] = @intCast(ops[i]);
        // std.debug.print("@{d}:{s} ", .{ ofs, s });
        if (i <= num[0]) {
            a.writeXY(&buf, @intCast(ofs), @intCast(p + 2), ray.LIGHTGRAY);
        } else {
            a.writeXY(&buf, @intCast(ofs), @intCast(p + 2), ray.DARKGRAY);
        }
        ofs += s.len;
    }
    const s = std.fmt.bufPrint(&buf, "=?  {d}", .{num[15]}) catch unreachable;
    buf[s.len] = 0;
    // std.debug.print("@{d}:{s}\n", .{ ofs, s });
    if (correct) {
        a.writeXY(&buf, @intCast(ofs), @intCast(p + 2), ray.GREEN);
    } else {
        a.writeXY(&buf, @intCast(ofs), @intCast(p + 2), ray.LIGHTGRAY);
    }
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    if (idx > 1000) return true;
    if ((idx - vis.ofs) * 2 >= vis.stack.items.len) {
        if (vis.cur >= vis.ctx.lines.len) return true;
        if (vis.stack.items.len > 0) {
            const ll = vis.stack.items.len - 2;
            vis.hist.append(vis.stack.items[ll]) catch unreachable;
            vis.hist.append(vis.stack.items[ll + 1]) catch unreachable;
        }
        vis.ofs += vis.stack.items.len / 2;
        vis.res.append(fold(vis)) catch unreachable;
        vis.ctx.concat = !vis.ctx.concat;
        vis.cur += 1;
        std.debug.print("loaded {d} items\n", .{vis.stack.items.len / 2});
    }
    var num = vis.stack.items[(idx - vis.ofs) * 2];
    var ops = vis.stack.items[(idx - vis.ofs) * 2 + 1];
    dispvec(vis.hist.items.len / 2, a, num, ops, false);
    for (0..vis.hist.items.len / 2) |hidx| {
        num = vis.hist.items[hidx * 2];
        ops = vis.hist.items[hidx * 2 + 1];
        dispvec(hidx, a, num, ops, vis.res.items[hidx]);
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 24, .fps = 30 },
};
