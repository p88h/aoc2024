const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    dict: std.AutoHashMap(u32, bool),
    patterns: [][]const u8,
    mlen: usize,
    total: std.atomic.Value(u64),
    wait_group: std.Thread.WaitGroup,
};

// map rgbwu to 3-bit values (5,3,1,7,6)
pub inline fn chrcode(c: u8) u32 {
    return ((((c - 'b') + 3) / 4) + 1);
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.dict = std.AutoHashMap(u32, bool).init(allocator);
    // way more than expected keys => low conflict rate & good performance
    ctx.dict.ensureTotalCapacity(8000) catch unreachable;
    const first = lines[0];
    var head: usize = 0;
    var tail: usize = 0;
    ctx.mlen = 0;
    var tcode: u32 = 0;
    while (tail < first.len) {
        if (first[tail] == ',') {
            // std.debug.print("{s}:{o}\n", .{ first[head..tail], tcode });
            ctx.dict.put(tcode, true) catch unreachable;
            if (tail - head > ctx.mlen) ctx.mlen = tail - head;
            head = tail + 2;
            tail = head + 1;
            tcode = chrcode(first[head]);
        } else {
            tcode = tcode * 8 + chrcode(first[tail]);
            tail += 1;
        }
    }
    ctx.dict.put(tcode, true) catch unreachable;
    ctx.patterns = lines[2..];
    ctx.allocator = allocator;
    // std.debug.print("max towel size: {d}\n", .{ctx.mlen});
    return ctx;
}

pub fn run_range(ctx: *Context, start: usize, count: comptime_int, p1: bool) void {
    var tot: u64 = 0;
    for (ctx.patterns[start .. start + count]) |line| {
        var reachable = [_]usize{0} ** 64;
        var tmp = [_]u32{0} ** 64;
        for (line, 0..) |c, i| tmp[i] = chrcode(c);
        reachable[0] = 1;
        for (0..line.len) |i| {
            var tcode: u32 = 0;
            if (reachable[i] == 0) continue;
            for (1..ctx.mlen + 1) |j| {
                if (i + j > line.len) break;
                tcode = tcode * 8 + tmp[i + j - 1];
                if (p1 and reachable[i + j] > 0) continue;
                // const key = line[i .. i + j];
                if (ctx.dict.contains(tcode)) reachable[i + j] += reachable[i];
            }
        }
        if (p1 and reachable[line.len] > 0) {
            tot += 1;
        } else tot += reachable[line.len];
    }
    _ = ctx.total.fetchAdd(tot, .seq_cst);
    ctx.wait_group.finish();
}

pub fn run_parallel(ctx: *Context, p1: bool) u64 {
    const chunk_size = 50;
    const chunks = ctx.patterns.len / chunk_size;
    ctx.total.store(0, .seq_cst);
    ctx.wait_group.reset();
    for (0..chunks) |i| {
        ctx.wait_group.start();
        common.pool.spawn(run_range, .{ ctx, i * chunk_size, chunk_size, p1 }) catch {
            std.debug.panic("failed to spawn thread {d}\n", .{i});
        };
    }
    common.pool.waitAndWork(&ctx.wait_group);
    return ctx.total.raw;
}

pub fn part1(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{run_parallel(ctx, true)}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{run_parallel(ctx, false)}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "19",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
