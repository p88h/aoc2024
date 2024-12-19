const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    dict: std.StringHashMap(bool),
    patterns: [][]const u8,
    mlen: usize,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.dict = std.StringHashMap(bool).init(allocator);
    const first = lines[0];
    var head: usize = 0;
    var tail: usize = 0;
    ctx.mlen = 0;
    while (tail < first.len) {
        if (first[tail] == ',') {
            // std.debug.print("{d} {d}\n", .{ head, tail });
            ctx.dict.put(first[head..tail], true) catch unreachable;
            if (tail - head > ctx.mlen) ctx.mlen = tail - head;
            head = tail + 2;
            tail = head + 1;
        } else tail += 1;
    }
    ctx.dict.put(first[head..tail], true) catch unreachable;
    ctx.patterns = lines[2..];
    ctx.allocator = allocator;
    return ctx;
}

pub fn part1(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (ctx.patterns) |line| {
        var reachable = [_]bool{false} ** 100;
        reachable[0] = true;
        for (0..line.len) |i| {
            if (!reachable[i]) continue;
            for (1..ctx.mlen + 1) |j| {
                if (i + j > line.len) break;
                if (reachable[i + j]) continue;
                const key = line[i .. i + j];
                if (ctx.dict.contains(key)) reachable[i + j] = true;
            }
        }
        if (reachable[line.len]) {
            tot += 1;
        } else {
            // std.debug.print("{s} is impossible {any}\n", .{ line, reachable[0 .. line.len + 1] });
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (ctx.patterns) |line| {
        var reachable = [_]usize{0} ** 100;
        reachable[0] = 1;
        for (0..line.len) |i| {
            if (reachable[i] == 0) continue;
            for (1..ctx.mlen + 1) |j| {
                if (i + j > line.len) break;
                // if (reachable[i + j]) continue;
                const key = line[i .. i + j];
                if (ctx.dict.contains(key)) reachable[i + j] += reachable[i];
            }
        }
        if (reachable[line.len] > 0) {
            tot += reachable[line.len];
        } else {
            // std.debug.print("{s} is impossible {any}\n", .{ line, reachable[0..line.len] });
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
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
