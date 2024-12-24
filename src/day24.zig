const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Op = enum {
    AND,
    OR,
    XOR,
    VALUE,
    UNDEF,
};

pub const Gate = struct {
    label: ?[]const u8 = null,
    value: ?bool = null,
    op: Op = .UNDEF,
    left: ?*Gate = null,
    right: ?*Gate = null,
    pos: @Vector(2, u32) = .{ 0, 0 },
};

pub const Context = struct {
    allocator: Allocator,
    gates: [1024]Gate,
    zindex: [64]*Gate,
    gmap: std.StringHashMap(*Gate),
    gcnt: usize,
    zcnt: usize,
};

pub inline fn add_gate(ctx: *Context, name: []const u8, g: Gate) *Gate {
    ctx.gates[ctx.gcnt] = g;
    ctx.gates[ctx.gcnt].label = name;
    ctx.gmap.put(name, &ctx.gates[ctx.gcnt]) catch unreachable;
    ctx.gcnt += 1;
    return &ctx.gates[ctx.gcnt - 1];
}

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.gmap = std.StringHashMap(*Gate).init(allocator);
    ctx.gmap.ensureTotalCapacity(1024) catch unreachable;
    ctx.gcnt = 0;
    ctx.zcnt = 0;
    var icnt: usize = 0;
    while (lines[icnt].len > 0) : (icnt += 1) {
        const line = lines[icnt];
        const name = line[0..3];
        const value = line[5] == '1';
        _ = add_gate(ctx, name, Gate{ .value = value, .op = .VALUE });
    }
    for (lines[icnt + 1 ..]) |line| {
        const name1 = line[0..3];
        var shift: usize = 1;
        var op = Op.VALUE;
        // operation
        switch (line[4]) {
            'A' => op = Op.AND,
            'X' => op = Op.XOR,
            'O' => {
                op = Op.OR;
                shift = 0;
            },
            else => unreachable,
        }
        const name2 = line[shift + 7 .. shift + 10];
        const name3 = line[shift + 14 ..];
        const g1 = ctx.gmap.get(name1) orelse add_gate(ctx, name1, Gate{});
        const g2 = ctx.gmap.get(name2) orelse add_gate(ctx, name2, Gate{});
        var g3 = ctx.gmap.get(name3) orelse add_gate(ctx, name3, Gate{});
        g3.op = op;
        g3.left = g1;
        g3.right = g2;
        if (name3[0] == 'z') {
            const id = (name3[1] - '0') * 10 + (name3[2] - '0');
            ctx.zindex[id] = g3;
            ctx.zcnt += 1;
        }
    }
    return ctx;
}

pub fn eval(g: *Gate) bool {
    if (g.value != null) return g.value.?;
    const l = eval(g.left.?);
    const r = eval(g.right.?);
    switch (g.op) {
        Op.AND => g.value = l and r,
        Op.OR => g.value = l or r,
        Op.XOR => g.value = l != r,
        else => {
            std.debug.panic("invalid gate operation\n", .{});
        },
    }
    return g.value.?;
}

pub fn part1(ctx: *Context) []u8 {
    var ret: u64 = 0;
    for (0..ctx.zcnt) |i| {
        const g = ctx.zindex[ctx.zcnt - i - 1];
        ret *= 2;
        if (eval(g)) ret += 1;
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ret}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.zcnt}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "24",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
