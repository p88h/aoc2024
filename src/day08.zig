const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    dim: usize,
    buf: []u8,
    lines: [][]const u8,
    pos: [80]@Vector(8, i8),
    cnt: [80]usize,
};

pub fn parse(allocator: Allocator, buf: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.dim = lines.len;
    ctx.buf = buf;
    ctx.lines = lines;
    ctx.allocator = allocator;
    @memset(&ctx.cnt, 0);
    for (0..80) |i| ctx.pos[i] = @splat(-1);
    for (lines, 0..) |line, y| {
        for (line, 0..) |c, x| {
            if (c == '.') continue;
            const d = c - '0';
            ctx.pos[d][ctx.cnt[d] * 2] = @intCast(x);
            ctx.pos[d][ctx.cnt[d] * 2 + 1] = @intCast(y);
            ctx.cnt[d] += 1;
        }
    }
    return ctx;
}

pub fn part1(ctx: *Context) []u8 {
    var unique = [_][64]bool{[_]bool{true} ** 64} ** 64;
    var tot: usize = 0;
    for (0..80) |i| {
        if (ctx.cnt[i] == 0) continue;
        for (0..ctx.cnt[i] - 1) |j| {
            for (j + 1..ctx.cnt[i]) |k| {
                const dx = ctx.pos[i][j * 2] - ctx.pos[i][k * 2];
                const dy = ctx.pos[i][j * 2 + 1] - ctx.pos[i][k * 2 + 1];
                const x1 = ctx.pos[i][j * 2] + dx;
                const y1 = ctx.pos[i][j * 2 + 1] + dy;
                const x2 = ctx.pos[i][k * 2] - dx;
                const y2 = ctx.pos[i][k * 2 + 1] - dy;
                if (x1 >= 0 and x1 < ctx.dim and y1 >= 0 and y1 < ctx.dim and unique[@intCast(y1)][@intCast(x1)]) {
                    unique[@intCast(y1)][@intCast(x1)] = false;
                    tot += 1;
                }
                if (x2 >= 0 and x2 < ctx.dim and y2 >= 0 and y2 < ctx.dim and unique[@intCast(y2)][@intCast(x2)]) {
                    unique[@intCast(y2)][@intCast(x2)] = false;
                    tot += 1;
                }
            }
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var marks = [_]u64{0} ** 64;
    var tot: usize = 0;
    for (0..80) |i| {
        for (0..ctx.cnt[i]) |j| {
            const x1 = ctx.pos[i][j * 2];
            const y1 = ctx.pos[i][j * 2 + 1];
            marks[@intCast(y1)] |= @as(u64, 1) << @as(u6, @intCast(x1));
            tot += 1;
        }
    }
    for (0..80) |i| {
        if (ctx.cnt[i] == 0) continue;
        const jk = [_]usize{ 0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3 };
        inline for (0..6) |l| {
            const j = jk[l * 2];
            const k = jk[l * 2 + 1];
            const dx = ctx.pos[i][j * 2] - ctx.pos[i][k * 2];
            const dy = ctx.pos[i][j * 2 + 1] - ctx.pos[i][k * 2 + 1];
            var x1 = ctx.pos[i][j * 2] + dx;
            var y1 = ctx.pos[i][j * 2 + 1] + dy;
            var x2 = ctx.pos[i][k * 2] - dx;
            var y2 = ctx.pos[i][k * 2 + 1] - dy;
            while (x1 >= 0 and x1 < ctx.dim and y1 >= 0 and y1 < ctx.dim) {
                if (marks[@intCast(y1)] & (@as(u64, 1) << @as(u6, @intCast(x1))) == 0) {
                    marks[@intCast(y1)] |= (@as(u64, 1) << @as(u6, @intCast(x1)));
                    tot += 1;
                }
                x1 += dx;
                y1 += dy;
            }
            while (x2 >= 0 and x2 < ctx.dim and y2 >= 0 and y2 < ctx.dim) {
                if (marks[@intCast(y2)] & (@as(u64, 1) << @as(u6, @intCast(x2))) == 0) {
                    marks[@intCast(y2)] |= (@as(u64, 1) << @as(u6, @intCast(x2)));
                    tot += 1;
                }
                x2 -= dx;
                y2 -= dy;
            }
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "08",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
