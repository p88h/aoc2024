const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Point = @Vector(2, i64);

pub const Machine = struct { a: Point, b: Point, prize: Point };

pub const Context = struct {
    allocator: Allocator,
    machines: std.ArrayList(Machine),
};

pub fn parseVec(line: []const u8, ofs: usize, ch: u8) Point {
    var p: Point = @splat(0);
    var i = ofs;
    while (line[i] >= '0' and line[i] <= '9') {
        p[0] = p[0] * 10 + line[i] - '0';
        i += 1;
    }
    while (line[i] != ch) i += 1;
    i += 1;
    while (i < line.len) {
        p[1] = p[1] * 10 + line[i] - '0';
        i += 1;
    }
    return p;
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.machines = std.ArrayList(Machine).init(allocator);
    for (0..(lines.len + 1) / 4) |i| {
        const m = Machine{
            .a = parseVec(lines[i * 4 + 0], 12, '+'),
            .b = parseVec(lines[i * 4 + 1], 12, '+'),
            .prize = parseVec(lines[i * 4 + 2], 9, '='),
        };
        ctx.machines.append(m) catch unreachable;
        // std.debug.print("{any}\n", .{m});
    }
    return ctx;
}

pub fn solve_slow(m: Machine) u64 {
    var sum: Point = @splat(0);
    var acnt: usize = 0;
    while (acnt <= 100) : (acnt += 1) {
        if (sum[0] > m.prize[0] or sum[1] > m.prize[1]) break;
        const xd = m.prize[0] - sum[0];
        const yd = m.prize[1] - sum[1];
        if (xd % m.b[0] == 0 and yd % m.b[1] == 0 and xd / m.b[0] == yd / m.b[1]) {
            const bcnt = xd / m.b[0];
            return 3 * acnt + bcnt;
        }
        sum = sum + m.a;
    }
    return 0;
}

pub inline fn solve_fast(m: Machine) u64 {
    const x1: f64 = @floatFromInt(m.a[0]);
    const x2: f64 = @floatFromInt(m.b[0]);
    const x3: f64 = @floatFromInt(m.prize[0]);
    const y1: f64 = @floatFromInt(m.a[1]);
    const y2: f64 = @floatFromInt(m.b[1]);
    const y3: f64 = @floatFromInt(m.prize[1]);
    const a = (x3 * y2 - y3 * x2) / (x1 * y2 - y1 * x2);
    const b = (x3 - a * x1) / x2;
    if (a == @round(a) and b == @round(b)) return @intFromFloat(3.0 * a + b);
    return 0;
}

pub fn part1(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (ctx.machines.items) |m| tot += solve_fast(m);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (ctx.machines.items) |m| {
        var m1 = m;
        m1.prize += @splat(10000000000000);
        tot += solve_fast(m1);
    }
    return std.fmt.allocPrint(ctx.allocator, "{any}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "13",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
