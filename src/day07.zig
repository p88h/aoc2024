const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const vec16 = @Vector(16, u64);
pub const nWorkers = 5;

pub const Context = struct {
    allocator: Allocator,
    targets: []u64,
    lines: []vec16,
    cache: []bool,
    concat: bool,
    workers: [nWorkers]WorkerState,
    wait_group: std.Thread.WaitGroup,
};

pub const WorkerState = struct {
    ctx: *Context,
    tid: usize,
    stack: std.ArrayList(vec16),
    ret: u64,
};

pub fn parseVec(line: []const u8, sep: comptime_int, T: type, len: comptime_int) @Vector(len, T) {
    var vec: @Vector(len, T) = @splat(0);
    var p: usize = 1;
    for (0..line.len) |i| {
        if (line[i] == sep) {
            p += 1;
        } else vec[p] = vec[p] * 10 + line[i] - '0';
    }
    vec[0] = @intCast(p);
    return vec;
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.targets = allocator.alloc(u64, lines.len) catch unreachable;
    ctx.lines = allocator.alloc(vec16, lines.len) catch unreachable;
    for (0..nWorkers) |i| {
        ctx.workers[i].ctx = ctx;
        ctx.workers[i].tid = i;
        ctx.workers[i].stack = std.ArrayList(vec16).init(allocator);
        ctx.workers[i].stack.ensureTotalCapacityPrecise(16) catch unreachable;
    }
    for (lines, 0..) |line, idx| {
        const sp = std.mem.indexOf(u8, line, ":").?;
        ctx.targets[idx] = std.fmt.parseInt(u64, line[0..sp], 10) catch unreachable;
        ctx.lines[idx] = parseVec(line[sp + 2 ..], ' ', u32, 16);
    }
    ctx.cache = allocator.alloc(bool, lines.len) catch unreachable;
    @memset(ctx.cache, false);
    return ctx;
}

inline fn apply(vec: vec16, mask: usize) u64 {
    var ret: u64 = vec[1];
    for (2..vec[0] + 1) |i| {
        if (mask & @as(u32, 1) << @as(u5, @intCast(i - 2)) != 0) {
            ret *= vec[i];
        } else {
            ret += vec[i];
        }
    }
    return ret;
}

pub fn combine(vec: vec16, target: u64) bool {
    const max_mask: usize = @as(usize, 1) << @as(u5, @intCast(vec[0] - 1));
    for (0..max_mask) |mask| {
        // std.debug.print("{d} x {d} ={d}\n", .{ vec, mask, apply(vec, mask) });
        if (apply(vec, mask) == target) return true;
    }
    return false;
}

pub fn fold(stack: *std.ArrayList(vec16), vec: vec16, target: u64, concat: bool) bool {
    stack.clearRetainingCapacity();
    var tv = vec;
    tv[15] = target;
    stack.append(tv) catch unreachable;
    while (stack.items.len > 0) {
        const top = stack.pop();
        const tmp = top[15];
        const len = top[0];
        const last = top[top[0]];
        // std.debug.print("{d}\n", .{top});
        if (len == 1 and tmp == last) return true;
        if (len == 1) continue;
        tv = top;
        tv[0] = len - 1;
        tv[len] = 0;
        // addition should be possible if non-zero result
        if (tmp > last) {
            tv[15] = tmp - last;
            stack.append(tv) catch unreachable;
        }
        // check if multiplication is possible
        if (top[15] % last == 0) {
            tv[15] = tmp / last;
            stack.append(tv) catch unreachable;
        }
        if (!concat) continue;
        // concatenation means last digits of target(tmp) match
        var base: usize = 10;
        while (last >= base) base *= 10;
        if (tmp % base == last) {
            tv[15] = tmp / base;
            stack.append(tv) catch unreachable;
        }
    }
    return false;
}

pub fn worker(ws: *WorkerState) void {
    const ctx = ws.ctx;
    var tot: u64 = 0;
    for (ctx.lines, 0..) |line, idx| {
        if (idx % nWorkers == ws.tid and (ctx.cache[idx] or fold(&ws.stack, line, ctx.targets[idx], ctx.concat))) {
            tot += ctx.targets[idx];
            ctx.cache[idx] = true;
        }
    }
    ws.ret = tot;
    ctx.wait_group.finish();
}

pub fn run_async(ctx: *Context) u64 {
    var tot: u64 = 0;
    ctx.wait_group.reset();
    for (0..nWorkers) |idx| {
        ctx.wait_group.start();
        common.pool.spawn(worker, .{&ctx.workers[idx]}) catch {
            std.debug.panic("failed to spawn worker {d}\n", .{idx});
        };
    }
    common.pool.waitAndWork(&ctx.wait_group);
    for (0..nWorkers) |idx| tot += ctx.workers[idx].ret;
    return tot;
}

pub fn part1(ctx: *Context) []u8 {
    ctx.concat = false;
    const tot = run_async(ctx);
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    ctx.concat = true;
    const tot = run_async(ctx);
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "07", .parse = @ptrCast(&parse), .part1 = @ptrCast(&part1), .part2 = @ptrCast(&part2) };
pub fn main() void {
    common.run_day(work);
}
