const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const DebugFn = fn (comptime format: []const u8, args: anytype) void;

pub const Machine = struct {
    regs: [3]u64, // A,B,C
    program: []u8,
    ip: u64,
    out: std.ArrayList(u64),

    pub inline fn reset(self: *Machine, a: u64) void {
        self.ip = 0;
        self.regs[0] = a;
        self.regs[1] = 0;
        self.regs[2] = 0;
        self.out.clearRetainingCapacity();
    }

    pub inline fn combo(self: Machine, op: u8) u64 {
        if (op < 4) return @intCast(op);
        if (op < 8) return self.regs[op - 4];
        std.debug.panic("Invalid operand: {d}", .{op});
    }

    pub inline fn step(self: *Machine, comptime debug: ?DebugFn) bool {
        const ops = [_][]const u8{ "adv", "bxl", "bst", "jnz", "bxc", "out", "bdv", "cdv" };
        if (self.ip >= self.program.len) return false;
        std.debug.assert(self.ip + 1 < self.program.len);
        const opcode = self.program[self.ip];
        const operand = self.program[self.ip + 1];
        if (debug) |dbg| dbg("{d:02}: {s} {d} ", .{ self.ip, ops[opcode], operand });
        if (debug) |dbg| dbg("[ {X:012} {X:012} {X:012} ]  ", .{ self.regs[0], self.regs[1], self.regs[2] });
        self.ip += 2;
        switch (opcode) {
            0 => { // adv
                const v: u6 = @intCast(self.combo(operand));
                self.regs[0] >>= v;
                if (debug) |dbg| dbg("A >>= {d}\n", .{v});
            },
            1 => { // bxl
                self.regs[1] ^= operand;
                if (debug) |dbg| dbg("B ^= {d}\n", .{operand});
            },
            2 => { // bst
                const v = self.combo(operand);
                self.regs[1] = v % 8;
                if (debug) |dbg| dbg("B = {d} \n", .{v});
            },
            3 => { // jnz
                if (self.regs[0] != 0) {
                    self.ip = operand;
                    if (debug) |dbg| dbg("JUMP to {d}\n", .{self.ip});
                } else {
                    if (debug) |dbg| dbg("NOOP\n", .{});
                }
            },
            4 => { // bxc
                self.regs[1] ^= self.regs[2];
                if (debug) |dbg| dbg("B ^= C\n", .{});
            },
            5 => { // out
                const v = self.combo(operand) % 8;
                if (debug) |dbg| dbg("OUT {d}\n", .{v});
                self.out.append(v) catch unreachable;
            },
            6 => { // bdv
                const v: u6 = @intCast(self.combo(operand));
                self.regs[1] = self.regs[0] >> v;
                if (debug) |dbg| dbg("B = A >> {d}\n", .{v});
            },
            7 => { // cdv
                const v: u6 = @intCast(self.combo(operand));
                self.regs[2] = self.regs[0] >> v;
                if (debug) |dbg| dbg("C = A >> {d}\n", .{v});
            },
            else => {
                std.debug.panic("Guru meditation error: {any}", .{self});
            },
        }
        return true;
    }

    pub fn run(self: *Machine, comptime debug: ?DebugFn) void {
        while (self.step(debug)) {}
    }

    pub fn run_once(self: *Machine, goal: u64) bool {
        while (self.step(null)) {
            if (self.ip == 0 and self.out.items.len > 0) break;
        }
        return (self.regs[0] == goal);
    }
};

pub const Context = struct {
    allocator: Allocator,
    m: Machine,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    for (0..3) |r| ctx.m.regs[r] = std.fmt.parseInt(u64, lines[r][12..], 10) catch unreachable;
    ctx.m.program = allocator.alloc(u8, (lines[4].len - 8) / 2) catch unreachable;
    for (0..ctx.m.program.len) |i| {
        ctx.m.program[i] = lines[4][8 + i * 2 + 1] - '0';
    }
    ctx.m.out = @TypeOf(ctx.m.out).init(allocator);
    ctx.m.ip = 0;
    return ctx;
}

pub fn join_list(allocator: Allocator, T: type, items: []const T) []u8 {
    var chars = std.ArrayList(u8).init(allocator);
    var first = true;
    for (items) |val| {
        chars.writer().print("{s}{d}", .{ if (first) "" else ",", val }) catch unreachable;
        first = false;
    }
    return chars.items;
}

pub fn part1(ctx: *Context) []u8 {
    ctx.m.run(null);
    const ret = join_list(ctx.allocator, u64, ctx.m.out.items);
    return std.fmt.allocPrint(ctx.allocator, "{s}", .{ret}) catch unreachable;
}

pub fn solve_rec(ctx: *Context, b: u64, ofs: usize, history: ?*std.ArrayList(u64)) u64 {
    const plen = ctx.m.program.len;
    if (ofs == plen) {
        // std.debug.print("{d} : {any}\n", .{ b, ctx.m.out.items });
        return b;
    }
    // std.debug.print("{d} : {any}\n", .{ b, ofs });
    for (0..8) |a| {
        if (history) |h| h.append(b * 8 + a) catch unreachable;
        if (b == 0 and a == 0) continue;
        ctx.m.reset(b * 8 + a);
        if (!ctx.m.run_once(b)) continue;
        if (ctx.m.out.items.len < 1) continue;
        if (ctx.m.program[plen - ofs - 1] == ctx.m.out.items[0]) {
            const v = solve_rec(ctx, b * 8 + a, ofs + 1, history);
            if (v > 0) return v;
        }
    }
    return 0;
}

pub fn part2(ctx: *Context) []u8 {
    const ret = solve_rec(ctx, 0, 0, null);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ret}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "17",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
