const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const vec256 = @Vector(4, u64);

pub const Pos = struct {
    y: usize,
    x: usize,
};

pub const Context = struct {
    allocator: Allocator,
    dim: usize,
    lines: [][]const u8,
    bits: []vec256,
    cntr: []u64,
    start: std.ArrayList(Pos),
};

pub inline fn setbit(vec: *vec256, idx: usize) void {
    const w: usize = idx / 64;
    const b: u6 = @intCast(idx % 64);
    vec[w] |= @as(u64, 1) << b;
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    ctx.allocator = allocator;
    const dim = ctx.lines.len;
    ctx.bits = allocator.alloc(vec256, dim * dim) catch unreachable;
    ctx.cntr = allocator.alloc(u64, dim * dim) catch unreachable;
    ctx.start = @TypeOf(ctx.start).init(allocator);
    @memset(ctx.bits, @splat(0));
    @memset(ctx.cntr, 0);
    for (0..dim) |y| {
        for (0..dim) |x| {
            if (lines[y][x] == '9') {
                const p = y * dim + x;
                ctx.start.append(Pos{ .y = y, .x = x }) catch unreachable;
                setbit(&ctx.bits[p], 0); // mark visited for part 1 in bit 0
                setbit(&ctx.bits[p], ctx.start.items.len);
                ctx.cntr[p] = 1; // mark visited for part2 by setting counter to 1
            }
        }
    }
    return ctx;
}

pub fn part1(ctx: *Context) []u8 {
    const dim = ctx.lines.len;
    var tot: usize = 0;
    var arr = ctx.start.clone() catch unreachable;
    var cur = &arr;
    var alt = std.ArrayList(Pos).init(ctx.allocator);
    var next = &alt;
    next.ensureTotalCapacity(cur.items.len) catch unreachable;
    for (0..10) |_| {
        for (cur.items) |v| {
            const p = v.y * dim + v.x;
            const ch = ctx.lines[v.y][v.x] - 1;
            const me = ctx.bits[p];
            if (ch == '/') {
                tot += @reduce(.Add, @popCount(me)) - 1;
                continue;
            }
            // look around, try going down
            if (v.x > 0 and ctx.lines[v.y][v.x - 1] == ch) {
                if (ctx.bits[p - 1][0] & 1 == 0)
                    next.append(Pos{ .y = v.y, .x = v.x - 1 }) catch unreachable;
                ctx.bits[p - 1] |= me;
            }
            if (v.x + 1 < dim and ctx.lines[v.y][v.x + 1] == ch) {
                if (ctx.bits[p + 1][0] & 1 == 0)
                    next.append(Pos{ .y = v.y, .x = v.x + 1 }) catch unreachable;
                ctx.bits[p + 1] |= me;
            }
            if (v.y > 0 and ctx.lines[v.y - 1][v.x] == ch) {
                if (ctx.bits[p - dim][0] & 1 == 0)
                    next.append(Pos{ .y = v.y - 1, .x = v.x }) catch unreachable;
                ctx.bits[p - dim] |= me;
            }
            if (v.y + 1 < dim and ctx.lines[v.y + 1][v.x] == ch) {
                if (ctx.bits[p + dim][0] & 1 == 0)
                    next.append(Pos{ .y = v.y + 1, .x = v.x }) catch unreachable;
                ctx.bits[p + dim] |= me;
            }
        }
        const tmp = cur;
        cur = next;
        next = tmp;
        next.clearRetainingCapacity();
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    const dim = ctx.lines.len;
    var tot: usize = 0;
    var arr = ctx.start.clone() catch unreachable;
    var cur = &arr;
    var alt = std.ArrayList(Pos).init(ctx.allocator);
    var next = &alt;
    next.ensureTotalCapacity(cur.items.len) catch unreachable;
    for (0..10) |_| {
        for (cur.items) |v| {
            const p = v.y * dim + v.x;
            const ch = ctx.lines[v.y][v.x] - 1;
            const me = ctx.cntr[p];
            if (ch == '/') {
                tot += me;
                continue;
            }
            // look around, try going up
            if (v.x > 0 and ctx.lines[v.y][v.x - 1] == ch) {
                if (ctx.cntr[p - 1] == 0)
                    next.append(Pos{ .y = v.y, .x = v.x - 1 }) catch unreachable;
                ctx.cntr[p - 1] += me;
            }
            if (v.x + 1 < dim and ctx.lines[v.y][v.x + 1] == ch) {
                if (ctx.cntr[p + 1] == 0)
                    next.append(Pos{ .y = v.y, .x = v.x + 1 }) catch unreachable;
                ctx.cntr[p + 1] += me;
            }
            if (v.y > 0 and ctx.lines[v.y - 1][v.x] == ch) {
                if (ctx.cntr[p - dim] == 0)
                    next.append(Pos{ .y = v.y - 1, .x = v.x }) catch unreachable;
                ctx.cntr[p - dim] += me;
            }
            if (v.y + 1 < dim and ctx.lines[v.y + 1][v.x] == ch) {
                if (ctx.cntr[p + dim] == 0)
                    next.append(Pos{ .y = v.y + 1, .x = v.x }) catch unreachable;
                ctx.cntr[p + dim] += me;
            }
        }
        const tmp = cur;
        cur = next;
        next = tmp;
        next.clearRetainingCapacity();
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "10",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
