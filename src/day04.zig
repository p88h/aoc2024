const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");
const meta = @import("std").meta;

pub const Context = struct {
    allocator: Allocator,
    lines: [][]const u8,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *anyopaque {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    ctx.allocator = allocator;
    return @ptrCast(ctx);
}

inline fn encode(v0: u8, v1: u8, v2: u8, v3: u8) u32 {
    return v0 + (@as(u32, v1) << 8) + (@as(u32, v2) << 16) + (@as(u32, v3) << 24);
}

pub inline fn match_dirs(ctx: *Context, y: usize, x: usize, w: usize, h: usize, pat: comptime_int) u32 {
    var dirs: u32 = 0;
    if (ctx.lines[y][x] == pat & 0xFF) {
        // vertical (down)
        if (y + 3 < h and pat == encode(ctx.lines[y][x], ctx.lines[y + 1][x], ctx.lines[y + 2][x], ctx.lines[y + 3][x]))
            dirs |= 1;
        if (x + 3 >= w) return dirs;
        // horizontal (right)
        if (pat == encode(ctx.lines[y][x], ctx.lines[y][x + 1], ctx.lines[y][x + 2], ctx.lines[y][x + 3]))
            dirs |= 2;
        // diagonal up-right
        if (y >= 3 and pat == encode(ctx.lines[y][x], ctx.lines[y - 1][x + 1], ctx.lines[y - 2][x + 2], ctx.lines[y - 3][x + 3]))
            dirs |= 4;
        // diagonal down-right
        if (y + 3 < h and pat == encode(ctx.lines[y][x], ctx.lines[y + 1][x + 1], ctx.lines[y + 2][x + 2], ctx.lines[y + 3][x + 3]))
            dirs |= 8;
    }
    return dirs;
}

pub const pat1 = 'X' + ('M' << 8) + ('A' << 16) + ('S' << 24);
pub const pat2 = 'S' + ('A' << 8) + ('M' << 16) + ('X' << 24);

pub fn part1(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    var tot: u32 = 0;
    const width = ctx.lines[0].len;
    const height = ctx.lines.len;
    // var tv: u32 = undefined;
    for (0..height) |y| {
        for (0..width) |x| {
            const d1 = match_dirs(ctx, y, x, width, height, pat1);
            const d2 = d1 | match_dirs(ctx, y, x, width, height, pat2);
            // count bits
            const f1 = ((d2 & 10) >> 1) + (d2 & 5);
            tot += ((f1 & 12) >> 2) + (f1 & 3);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

pub inline fn match_xmas(ctx: *Context, y: usize, x: usize) u32 {
    if (ctx.lines[y][x] != 'A') return 0;
    const exp: u8 = 'M' + 'S';
    const d1 = ctx.lines[y - 1][x - 1] + ctx.lines[y + 1][x + 1];
    const d2 = ctx.lines[y + 1][x - 1] + ctx.lines[y - 1][x + 1];
    if (d1 == exp and d2 == exp) return 1;
    return 0;
}

pub fn part2(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    var tot: u32 = 0;
    const width = ctx.lines[0].len;
    const height = ctx.lines.len;
    for (1..height - 1) |y| {
        for (1..width - 1) |x| {
            tot += match_xmas(ctx, y, x);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "04", .parse = parse, .part1 = part1, .part2 = part2 };
pub fn main() void {
    common.run_day(work);
}
