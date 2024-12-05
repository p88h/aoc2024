const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

const Context = struct {
    allocator: Allocator,
    ecnt: [128]u8,
    graph: [128][128]u32,
    insns: std.ArrayList([]u8),
    iposm: std.ArrayList([]u8), // instruction position / mask
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

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *anyopaque {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    var first = true;
    @memset(&ctx.ecnt, 0);
    ctx.insns = std.ArrayList([]u8).init(allocator);
    ctx.iposm = std.ArrayList([]u8).init(allocator);
    for (lines) |line| {
        if (first) {
            var v: @Vector(4, u32) = @splat(0);
            if (parseVec(line, '|', u32, 4, &v) < 2) {
                first = false;
                continue;
            }
            const cl = ctx.ecnt[v[0]];
            ctx.graph[v[0]][cl] = v[1];
            ctx.ecnt[v[0]] = cl + 1;
        } else {
            var v: @Vector(32, u8) = @splat(0);
            var cpos = allocator.alloc(u8, 100) catch unreachable;
            @memset(cpos, 255);
            const p = parseVec(line, ',', u8, 32, &v);
            var cins = allocator.alloc(u8, p) catch unreachable;
            for (0..p) |i| {
                cins[i] = v[i];
                cpos[v[i]] = @intCast(i);
            }
            ctx.iposm.append(cpos) catch unreachable;
            ctx.insns.append(cins) catch unreachable;
        }
    }
    return @ptrCast(ctx);
}

pub fn part1(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    var tot: u32 = 0;
    for (0..ctx.insns.items.len) |i| {
        const cins = ctx.insns.items[i];
        const cpos = ctx.iposm.items[i];
        const ilen = cins.len;
        var bad = false;
        for (0..ilen) |j| {
            const p = cins[j];
            var m: u8 = 255;
            for (0..ctx.ecnt[p]) |k| m = @min(m, cpos[ctx.graph[p][k]]);
            if (m < j) {
                bad = true;
                break;
            }
        }
        if (!bad) {
            tot += @intCast(ctx.insns.items[i][ilen / 2]);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

pub fn part2(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    var tot: u32 = 0;
    for (0..ctx.insns.items.len) |i| {
        const cins = ctx.insns.items[i];
        const cpos = ctx.iposm.items[i];
        const ilen = cins.len;
        var fixs: u32 = 0;
        for (0..ilen) |j| {
            const r = ilen - j - 1;
            var p = cins[r];
            var m: u8 = 255;
            for (0..ctx.ecnt[p]) |k| m = @min(m, cpos[ctx.graph[p][k]]);
            while (m < r) {
                var th = ctx.insns.items[i][m];
                cins[m] = p;
                cpos[p] = m;
                // fix it
                for (m + 1..r + 1) |k| {
                    const tt = cins[k];
                    cins[k] = th;
                    cpos[th] = @intCast(k);
                    th = tt;
                }
                fixs += 1;
                // redo this position
                p = cins[r];
                m = 255;
                for (0..ctx.ecnt[p]) |k| m = @min(m, cpos[ctx.graph[p][k]]);
            }
        }
        if (fixs > 0) {
            tot += @intCast(cins[ilen / 2]);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "05", .parse = parse, .part1 = part1, .part2 = part2 };
pub fn main() void {
    common.run_day(work);
}
