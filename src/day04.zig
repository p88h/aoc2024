const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");
const meta = @import("std").meta;

const Context = struct {
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

pub fn part1(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    var tot: i32 = 0;
    const pats: [2]u32 = .{ 'X' + ('M' << 8) + ('A' << 16) + ('S' << 24), 'S' + ('A' << 8) + ('M' << 16) + ('X' << 24) };
    const width = ctx.lines[0].len;
    const height = ctx.lines.len;
    // var tv: u32 = undefined;
    for (pats) |pat| {
        for (0..height) |y| {
            for (0..width) |x| {
                if (ctx.lines[y][x] == pat & 0xFF) {
                    // vertical (down)
                    if (y + 3 < height and pat == encode(ctx.lines[y][x], ctx.lines[y + 1][x], ctx.lines[y + 2][x], ctx.lines[y + 3][x]))
                        tot += 1;
                    if (x + 3 >= width) continue;
                    // horizontal (right)
                    if (pat == encode(ctx.lines[y][x], ctx.lines[y][x + 1], ctx.lines[y][x + 2], ctx.lines[y][x + 3]))
                        tot += 1;
                    // diagonal up-right
                    if (y >= 3 and pat == encode(ctx.lines[y][x], ctx.lines[y - 1][x + 1], ctx.lines[y - 2][x + 2], ctx.lines[y - 3][x + 3]))
                        tot += 1;
                    // diagonal down-right
                    if (y + 3 < height and pat == encode(ctx.lines[y][x], ctx.lines[y + 1][x + 1], ctx.lines[y + 2][x + 2], ctx.lines[y + 3][x + 3]))
                        tot += 1;
                }
            }
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

pub fn part2(ptr: *anyopaque) []u8 {
    const ctx: *Context = @alignCast(@ptrCast(ptr));
    var tot: i32 = 0;
    const exp: u8 = 'M' + 'S';
    const width = ctx.lines[0].len;
    const height = ctx.lines.len;
    for (0..height - 2) |y| {
        for (0..width - 2) |x| {
            if (ctx.lines[y + 1][x + 1] != 'A') continue;
            const d1 = ctx.lines[y][x] + ctx.lines[y + 2][x + 2];
            const d2 = ctx.lines[y + 2][x] + ctx.lines[y][x + 2];
            if (d1 == exp and d2 == exp) tot += 1;
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}\n", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "04", .parse = parse, .part1 = part1, .part2 = part2 };
pub fn main() void {
    common.run_day(work);
}
