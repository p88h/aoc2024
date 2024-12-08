const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    graph: [128]u128, // adjacency matrix
    insns: std.ArrayList([]u8),
    iposm: std.ArrayList(u128), // occurence masks
};

pub fn parseVec(line: []const u8, sep: comptime_int, T: type, len: comptime_int, vec: *@Vector(len, T)) usize {
    var p: usize = 0;
    for (0..line.len) |i| {
        if (line[i] == sep) {
            p += 1;
        } else vec[p] = vec[p] * 10 + line[i] - '0';
    }
    return p + 1;
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    var first = true;
    @memset(&ctx.graph, 0);
    ctx.insns = std.ArrayList([]u8).init(allocator);
    ctx.iposm = std.ArrayList(u128).init(allocator);
    for (lines) |line| {
        var tv1: @Vector(4, u32) = @splat(0);
        if (first) {
            if (parseVec(line, '|', u32, 4, &tv1) < 2) {
                first = false;
                continue;
            }
            ctx.graph[tv1[0]] |= @as(u128, 1) << @as(u7, @intCast(tv1[1]));
        } else {
            var tv2: @Vector(32, u8) = @splat(0);
            var cpos: u128 = 0;
            const p = parseVec(line, ',', u8, 32, &tv2);
            var cins = allocator.alloc(u8, p) catch unreachable;
            for (0..p) |i| {
                cins[i] = tv2[i];
                cpos |= @as(u128, 1) << @as(u7, @intCast(tv2[i]));
            }
            ctx.iposm.append(cpos) catch unreachable;
            ctx.insns.append(cins) catch unreachable;
        }
    }
    return ctx;
}

pub fn part1(ctx: *Context) []u8 {
    var tot: u32 = 0;
    for (0..ctx.insns.items.len) |i| {
        const cins = ctx.insns.items[i];
        const cpos = ctx.iposm.items[i];
        const ilen = cins.len;
        var bad = false;
        for (0..ilen) |j| {
            const p = cins[j];
            const pm = ctx.graph[p] & cpos;
            const pp = @popCount(pm);
            if (pp != ilen - j - 1) {
                bad = true;
                break;
            }
        }
        if (!bad) {
            tot += @intCast(ctx.insns.items[i][ilen / 2]);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot: u32 = 0;
    for (0..ctx.insns.items.len) |i| {
        const cins = ctx.insns.items[i];
        const cpos = ctx.iposm.items[i];
        const ilen = cins.len;
        var fixs: u32 = 0;
        var bad = false;
        for (0..ilen) |j| {
            const p = cins[j];
            const pm = ctx.graph[p] & cpos;
            const pp = @popCount(pm);
            if (pp != ilen - j - 1) bad = true;
            if (pp == ilen / 2) fixs = @intCast(p);
        }
        if (bad and fixs > 0) {
            tot += @intCast(fixs);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "05",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
