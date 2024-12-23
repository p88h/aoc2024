const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Node = struct {
    id: u16,
    conns: []u16,
};

pub const Context = struct {
    allocator: Allocator,
    conns: []u32,
    nodes: [1024]Node,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.conns = allocator.alloc(u32, lines.len) catch unreachable;
    var ecnt = [_]usize{0} ** 1024;
    // each connection is 20-bits, 10-bits per node id (32x32 chars top)
    for (lines, 0..) |line, i| {
        var id: u32 = @intCast(line[0] - 'a' + 1);
        id = id * 32;
        id += @intCast(line[1] - 'a' + 1);
        id = id * 32;
        id += @intCast(line[3] - 'a' + 1);
        id = id * 32;
        id += @intCast(line[4] - 'a' + 1);
        ecnt[id >> 10] += 1;
        ecnt[id & 1023] += 1;
        ctx.conns[i] = id;
    }
    // build the nodes from the counts
    for (ecnt, 0..) |s, id| {
        ctx.nodes[id].id = @intCast(id);
        if (s > 0) {
            ctx.nodes[id].conns = allocator.alloc(u16, s) catch unreachable;
            ecnt[id] = 0;
        } else {
            ctx.nodes[id].conns.len = 0;
        }
    }
    // and once again, go through connections but now assign them to the nodes
    for (ctx.conns) |conn| {
        const id1: u16 = @intCast(conn >> 10);
        const id2: u16 = @intCast(conn & 1023);
        var n1 = &ctx.nodes[id1];
        var n2 = &ctx.nodes[id2];
        n1.conns[ecnt[id1]] = id2;
        ecnt[id1] += 1;
        n2.conns[ecnt[id2]] = id1;
        ecnt[id2] += 1;
    }
    for (ctx.nodes) |node| {
        if (node.conns.len == 0) continue;
        std.mem.sort(u16, node.conns, {}, comptime std.sort.asc(u16));
    }
    return ctx;
}

pub fn ordered_key(id1: u16, id2: u16, id3: u16) u32 {
    const min = @min(@min(id1, id2), id3);
    const max = @max(@max(id1, id2), id3);
    const mid = id1 + id2 + id3 - min - max;
    return @as(u32, @intCast(min)) << 20 | @as(u32, @intCast(mid)) << 10 | @as(u32, @intCast(max));
}

pub fn common_count(conn1: *[]u16, conn2: *[]u16, com: *[]u16) usize {
    var p1: usize = 0;
    var p2: usize = 0;
    var ccnt: usize = 0;
    com.len = 16;
    while (p1 < conn1.len and p2 < conn2.len) {
        // common key
        if (conn1.*[p1] == conn2.*[p2]) {
            com.*[ccnt] = conn1.*[p1];
            ccnt += 1;
            p1 += 1;
            p2 += 1;
        } else if (conn1.*[p1] < conn2.*[p2]) {
            p1 += 1;
        } else {
            p2 += 1;
        }
    }
    com.len = ccnt;
    return ccnt;
}

pub fn part1(ctx: *Context) []u8 {
    var com1 = ctx.allocator.alloc(u16, 16) catch unreachable;
    var done = std.AutoHashMap(u32, bool).init(ctx.allocator);
    for (ctx.conns) |conn| {
        const id1: u16 = @intCast(conn >> 10);
        const id2: u16 = @intCast(conn & 1023);
        // any of them starts with a 't' ?
        if ((id1 >> 5) != 20 and (id2 >> 5) != 20) continue;
        const count = common_count(&ctx.nodes[id1].conns, &ctx.nodes[id2].conns, &com1);
        if (count == 0) continue;
        for (com1) |id3| {
            const key = ordered_key(id1, id2, id3);
            if (!done.contains(key)) done.put(key, true) catch unreachable;
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{done.count()}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var com1 = ctx.allocator.alloc(u16, 16) catch unreachable;
    var com2 = ctx.allocator.alloc(u16, 16) catch unreachable;
    for (ctx.conns) |conn| {
        const id1: u16 = @intCast(conn >> 10);
        const id2: u16 = @intCast(conn & 1023);
        var min_count = common_count(&ctx.nodes[id1].conns, &ctx.nodes[id2].conns, &com1);
        if (min_count > 10) {
            for (com1) |id3| {
                if (id3 == id2) continue;
                const count1 = common_count(&ctx.nodes[id2].conns, &ctx.nodes[id3].conns, &com2);
                if (count1 < min_count) min_count = count1;
                if (min_count < 11) break;
            }
            // add id1 and id2
            if (min_count > 10) {
                com1.len += 2;
                com1[com1.len - 2] = id1;
                com1[com1.len - 1] = id2;
                std.mem.sort(u16, com1, {}, comptime std.sort.asc(u16));
                var ret: []u8 = ctx.allocator.alloc(u8, com1.len * 3 - 1) catch unreachable;
                for (com1, 0..) |id, p| {
                    if (p > 0) ret[p * 3 - 1] = ',';
                    ret[p * 3] = @as(u8, @intCast('a' - 1 + (id >> 5)));
                    ret[p * 3 + 1] = @as(u8, @intCast('a' - 1 + (id & 31)));
                }
                return ret;
            }
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.nodes[0].conns.len}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "23",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
