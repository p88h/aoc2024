const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Vec256 = @Vector(8, u64);
pub const Vec8 = @Vector(8, u8);

pub const Context = struct {
    allocator: Allocator,
    keys: []Vec8,
    locks: []Vec8,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    var keylist = std.ArrayList(Vec8).init(allocator);
    var locklist = std.ArrayList(Vec8).init(allocator);
    ctx.allocator = allocator;
    var key: bool = false;
    var cur: Vec8 = @splat(0);
    for (lines) |line| {
        if (line.len == 0) {
            if (key) {
                keylist.append(cur) catch unreachable;
            } else {
                locklist.append(cur) catch unreachable;
            }
            cur = @splat(0);
            key = false;
        } else {
            key = line[0] == '#';
            for (line, 0..) |c, i| {
                if (c == '#') cur[i] += 1;
            }
        }
    }
    if (key) {
        keylist.append(cur) catch unreachable;
    } else {
        locklist.append(cur) catch unreachable;
    }
    ctx.keys = keylist.items;
    ctx.locks = locklist.items;
    return ctx;
}

pub fn match(key: Vec8, lock: Vec8) bool {
    const sum = key + lock;
    const max: Vec8 = @splat(8);
    return std.simd.countTrues(sum < max) == 8;
}

pub fn part1(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (ctx.keys) |key| {
        for (ctx.locks) |lock| {
            if (match(key, lock)) tot += 1;
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.locks.len}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "25",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
