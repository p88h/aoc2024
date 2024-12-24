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
    conns: usize = 0,
    pos: @Vector(2, u32) = .{ 0, 0 },
};

pub const Context = struct {
    allocator: Allocator,
    gates: [1024]Gate,
    zindex: [64]*Gate,
    gmap: std.StringHashMap(*Gate),
    ph: std.AutoHashMap(@Vector(2, u32), bool),
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
    ctx.ph = std.AutoHashMap(@Vector(2, u32), bool).init(allocator);
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
        g1.conns += 1;
        g2.conns += 1;
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

// uses screen coordinates same as for visualisation.
pub const hstep = 38;
pub const vstep = 17;
pub fn order(ctx: *Context, g: *Gate) void {
    // done?
    if (g.pos[0] != 0) return;
    if (g.op == Op.VALUE) {
        g.pos[1] = 40; // top margin
        g.pos[0] = 40; // left
        if (g.label.?[0] == 'y') {
            g.pos[1] += vstep * 2;
            g.pos[0] += hstep / 2;
        }
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        g.pos[0] += id * hstep;
        return;
    }
    g.left.?.conns += 1;
    order(ctx, g.left.?);
    g.right.?.conns += 1;
    order(ctx, g.right.?);
    if (g.left.?.pos[0] > g.right.?.pos[0]) {
        const tmp = g.left;
        g.left = g.right;
        g.right = tmp;
    }
    g.pos[0] = g.left.?.pos[0];
    if (g.left.?.pos[0] == g.right.?.pos[0] and g.right.?.op != Op.AND) {
        const tmp = g.left;
        g.left = g.right;
        g.right = tmp;
    }
    g.pos[1] = @max(g.left.?.pos[1], g.right.?.pos[1]) + vstep;
    if (g.left.?.op == .VALUE and g.right.?.op == .VALUE) {
        g.pos[1] += vstep;
        if (g.op != .AND) g.pos[1] += vstep * 2;
    } else if (g.op == .OR and g.left.?.op == .AND) {
        g.pos[1] = g.left.?.pos[1];
        g.pos[0] = g.left.?.pos[0] + hstep;
    }
    if (g.label.?[0] == 'z') {
        g.pos[1] = 1000; // bottom
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        g.pos[0] = 40 + id * hstep;
    }
    while (ctx.ph.contains(g.pos)) g.pos[0] += hstep;
    ctx.ph.put(g.pos, true) catch unreachable;
}

pub fn reorder(ctx: *Context) void {
    ctx.ph.clearRetainingCapacity();
    for (0..ctx.gcnt) |idx| {
        ctx.gates[idx].pos = .{ 0, 0 };
        ctx.gates[idx].conns = 0;
    }
    for (0..ctx.gcnt) |idx| {
        if (ctx.gates[idx].label.?[0] == 'z') order(ctx, &ctx.gates[idx]);
    }
}

// rather than change labels and update all consumers,
// we change contents, then swap labels.
pub fn swap(a: *Gate, b: *Gate) void {
    std.debug.print("Swapping {s} and {s}\n", .{ a.label.?, b.label.? });
    const tg = a.*;
    a.* = b.*;
    b.* = tg;
    const tmp = a.label;
    a.label = b.label;
    b.label = tmp;
}

pub fn reset(ctx: *Context, idx: usize) void {
    for (0..ctx.gcnt) |i| {
        const g = &ctx.gates[i];
        if (g.op == Op.VALUE) {
            const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
            g.value = idx == id;
        } else g.value = null;
    }
}

pub fn isbad(g: *const Gate) bool {
    if (g.op == Op.VALUE) return false;
    if (g.label.?[0] == 'z') {
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        if (id < 45) return g.op != .XOR;
        return false;
    }
    if (g.op == .XOR and (g.left.?.op != .VALUE or g.right.?.op != .VALUE)) return true;
    if (g.left.?.op == .VALUE and g.right.?.op == .VALUE and g.op == .AND) {
        if (g.left.?.label.?[1] == '0' and g.left.?.label.?[2] == '0') return g.conns != 2;
        return g.conns != 1;
    }
    if (g.left.?.op == .VALUE and g.right.?.op == .VALUE and g.op == .XOR) return g.conns != 2;
    return false;
}

pub fn hdist(a: *Gate, b: *Gate) u32 {
    if (a.pos[0] > b.pos[0]) return a.pos[0] - b.pos[0];
    return b.pos[0] - a.pos[0];
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

pub fn part2(ctx: *Context) []u8 {
    var arr = std.ArrayList([]const u8).init(ctx.allocator);
    for (0..ctx.gcnt) |i| {
        const g = &ctx.gates[i];
        if (isbad(g)) arr.append(g.label.?) catch unreachable;
    }
    std.mem.sort([]const u8, arr.items, {}, compareStrings);
    return std.fmt.allocPrint(ctx.allocator, "{s}", .{arr.items}) catch unreachable;
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
