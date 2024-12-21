const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    lines: [][]const u8,
    queue: std.ArrayList(State),
    cache: std.AutoHashMap(u64, usize),
    prev: []usize,
    pch: []u8,
    buf: []u8,
};

pub const Keypad1 = enum { One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Zero, Enter };

pub const Keypad2 = enum { Up, Down, Left, Right, Push };

pub const State = struct {
    pos1: Keypad1,
    pos2: Keypad2,
    pos3: Keypad2,
    // 1..275
    fn code(self: State) usize {
        const pos1: usize = @intFromEnum(self.pos1);
        const pos2: usize = @intFromEnum(self.pos2);
        const pos3: usize = @intFromEnum(self.pos3);
        return ((pos1 * 5 + pos2) * 5 + pos3) + 1;
    }
    fn of(x: usize) State {
        var t = x - 1;
        const pos3: Keypad2 = @enumFromInt(t % 5);
        t = t / 5;
        const pos2: Keypad2 = @enumFromInt(t % 5);
        t = t / 5;
        const pos1: Keypad1 = @enumFromInt(t);
        return State{ .pos1 = pos1, .pos2 = pos2, .pos3 = pos3 };
    }
    // The 'resting' state when final robot can press the desired button
    fn from(ch: u8) State {
        var pos = Keypad1.Enter;
        switch (ch) {
            '0' => pos = Keypad1.Zero,
            '1' => pos = Keypad1.One,
            '2' => pos = Keypad1.Two,
            '3' => pos = Keypad1.Three,
            '4' => pos = Keypad1.Four,
            '5' => pos = Keypad1.Five,
            '6' => pos = Keypad1.Six,
            '7' => pos = Keypad1.Seven,
            '8' => pos = Keypad1.Eight,
            '9' => pos = Keypad1.Nine,
            else => pos = Keypad1.Enter,
        }
        return State{ .pos1 = pos, .pos2 = Keypad2.Push, .pos3 = Keypad2.Push };
    }
    fn equal(self: State, other: State) bool {
        return self.pos1 == other.pos1 and self.pos2 == other.pos2 and self.pos3 == other.pos3;
    }
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    ctx.allocator = allocator;
    ctx.queue = std.ArrayList(State).init(ctx.allocator);
    ctx.prev = allocator.alloc(usize, 300) catch unreachable;
    ctx.pch = allocator.alloc(u8, 300) catch unreachable;
    ctx.buf = allocator.alloc(u8, 256) catch unreachable;
    ctx.cache = std.AutoHashMap(u64, usize).init(allocator);
    return ctx;
}

pub inline fn maybe_add(ctx: *Context, cur: State, next: State, distance: []usize, ch: u8) void {
    if (distance[next.code()] == 0) {
        distance[next.code()] = distance[cur.code()] + 1;
        ctx.prev[next.code()] = cur.code();
        ctx.pch[next.code()] = ch;
        ctx.queue.append(next) catch unreachable;
    }
}
pub inline fn maybe_move3(ctx: *Context, cur: State, pos3: Keypad2, distance: []usize, ch: u8) void {
    var next = cur;
    next.pos3 = pos3;
    maybe_add(ctx, cur, next, distance, ch);
}
pub inline fn maybe_move2(ctx: *Context, cur: State, pos2: Keypad2, distance: []usize, ch: u8) void {
    var next = cur;
    next.pos2 = pos2;
    maybe_add(ctx, cur, next, distance, ch);
}
pub inline fn maybe_move1(ctx: *Context, cur: State, pos1: Keypad1, distance: []usize, ch: u8) void {
    var next = cur;
    next.pos1 = pos1;
    maybe_add(ctx, cur, next, distance, ch);
}

pub fn bfs(ctx: *Context, start: State, end: State) usize {
    var distance = [_]usize{0} ** 300;
    distance[start.code()] = 1;
    ctx.queue.clearRetainingCapacity();
    ctx.queue.append(start) catch unreachable;
    var idx: usize = 0;
    while (idx < ctx.queue.items.len) : (idx += 1) {
        const cur = ctx.queue.items[idx];
        if (cur.equal(end)) return distance[end.code()] - 1;
        switch (cur.pos3) {
            Keypad2.Up => {
                maybe_move3(ctx, cur, .Down, &distance, 'v');
                maybe_move3(ctx, cur, .Push, &distance, '>');
                if (cur.pos2 == Keypad2.Down)
                    maybe_move2(ctx, cur, .Up, &distance, 'A');
                if (cur.pos2 == Keypad2.Right)
                    maybe_move2(ctx, cur, .Push, &distance, 'A');
            },
            Keypad2.Down => {
                maybe_move3(ctx, cur, .Up, &distance, '^');
                maybe_move3(ctx, cur, .Left, &distance, '<');
                maybe_move3(ctx, cur, .Right, &distance, '>');
                if (cur.pos2 == Keypad2.Up)
                    maybe_move2(ctx, cur, .Down, &distance, 'A');
                if (cur.pos2 == Keypad2.Push)
                    maybe_move2(ctx, cur, .Right, &distance, 'A');
            },
            Keypad2.Left => {
                maybe_move3(ctx, cur, .Down, &distance, '>');
                // or push A -- will move the second robot if valid
                if (cur.pos2 == Keypad2.Push)
                    maybe_move2(ctx, cur, .Up, &distance, 'A');
                if (cur.pos2 == Keypad2.Right)
                    maybe_move2(ctx, cur, .Down, &distance, 'A');
                if (cur.pos2 == Keypad2.Down)
                    maybe_move2(ctx, cur, .Left, &distance, 'A');
            },
            Keypad2.Right => {
                maybe_move3(ctx, cur, .Down, &distance, '<');
                maybe_move3(ctx, cur, .Push, &distance, '^');
                if (cur.pos2 == Keypad2.Up)
                    maybe_move2(ctx, cur, .Push, &distance, 'A');
                if (cur.pos2 == Keypad2.Down)
                    maybe_move2(ctx, cur, .Right, &distance, 'A');
                if (cur.pos2 == Keypad2.Left)
                    maybe_move2(ctx, cur, .Down, &distance, 'A');
            },
            Keypad2.Push => {
                maybe_move3(ctx, cur, .Up, &distance, '<');
                maybe_move3(ctx, cur, .Right, &distance, 'v');
                // When the third robot is in the 'push' state, when we push 'A', it will push 'A'
                // which will _execute_ commands on the second robot, depending on its state.
                // These commands will move the _first_ robot to the next positional state.
                switch (cur.pos2) {
                    Keypad2.Up => {
                        switch (cur.pos1) {
                            Keypad1.Zero => maybe_move1(ctx, cur, Keypad1.Two, &distance, 'A'),
                            Keypad1.Enter => maybe_move1(ctx, cur, Keypad1.Three, &distance, 'A'),
                            Keypad1.One => maybe_move1(ctx, cur, Keypad1.Four, &distance, 'A'),
                            Keypad1.Two => maybe_move1(ctx, cur, Keypad1.Five, &distance, 'A'),
                            Keypad1.Three => maybe_move1(ctx, cur, Keypad1.Six, &distance, 'A'),
                            Keypad1.Four => maybe_move1(ctx, cur, Keypad1.Seven, &distance, 'A'),
                            Keypad1.Five => maybe_move1(ctx, cur, Keypad1.Eight, &distance, 'A'),
                            Keypad1.Six => maybe_move1(ctx, cur, Keypad1.Nine, &distance, 'A'),
                            else => continue,
                        }
                    },
                    Keypad2.Down => {
                        switch (cur.pos1) {
                            Keypad1.Two => maybe_move1(ctx, cur, Keypad1.Zero, &distance, 'A'),
                            Keypad1.Three => maybe_move1(ctx, cur, Keypad1.Enter, &distance, 'A'),
                            Keypad1.Four => maybe_move1(ctx, cur, Keypad1.One, &distance, 'A'),
                            Keypad1.Five => maybe_move1(ctx, cur, Keypad1.Two, &distance, 'A'),
                            Keypad1.Six => maybe_move1(ctx, cur, Keypad1.Three, &distance, 'A'),
                            Keypad1.Seven => maybe_move1(ctx, cur, Keypad1.Four, &distance, 'A'),
                            Keypad1.Eight => maybe_move1(ctx, cur, Keypad1.Five, &distance, 'A'),
                            Keypad1.Nine => maybe_move1(ctx, cur, Keypad1.Six, &distance, 'A'),
                            else => continue,
                        }
                    },
                    Keypad2.Left => {
                        switch (cur.pos1) {
                            Keypad1.Enter => maybe_move1(ctx, cur, Keypad1.Zero, &distance, 'A'),
                            Keypad1.Two => maybe_move1(ctx, cur, Keypad1.One, &distance, 'A'),
                            Keypad1.Three => maybe_move1(ctx, cur, Keypad1.Two, &distance, 'A'),
                            Keypad1.Five => maybe_move1(ctx, cur, Keypad1.Four, &distance, 'A'),
                            Keypad1.Six => maybe_move1(ctx, cur, Keypad1.Five, &distance, 'A'),
                            Keypad1.Eight => maybe_move1(ctx, cur, Keypad1.Seven, &distance, 'A'),
                            Keypad1.Nine => maybe_move1(ctx, cur, Keypad1.Eight, &distance, 'A'),
                            else => continue,
                        }
                    },
                    Keypad2.Right => {
                        switch (cur.pos1) {
                            Keypad1.Zero => maybe_move1(ctx, cur, Keypad1.Enter, &distance, 'A'),
                            Keypad1.One => maybe_move1(ctx, cur, Keypad1.Two, &distance, 'A'),
                            Keypad1.Two => maybe_move1(ctx, cur, Keypad1.Three, &distance, 'A'),
                            Keypad1.Four => maybe_move1(ctx, cur, Keypad1.Five, &distance, 'A'),
                            Keypad1.Five => maybe_move1(ctx, cur, Keypad1.Six, &distance, 'A'),
                            Keypad1.Seven => maybe_move1(ctx, cur, Keypad1.Eight, &distance, 'A'),
                            Keypad1.Eight => maybe_move1(ctx, cur, Keypad1.Nine, &distance, 'A'),
                            else => continue,
                        }
                    },
                    else => {
                        // If pos2 is Push and pos1 is Push then it's the final state, 'nothing happens'
                    },
                }
            },
        }
    }
    return 0;
}

pub fn decode(ctx: *Context, from: State, dist: usize) []u8 {
    var code = from.code();
    var pos = dist;
    ctx.buf[pos] = 'A';
    while (pos > 0) : (pos -= 1) {
        // std.debug.print("{any}\n", .{State.of(code)});
        const ch = ctx.pch[code];
        code = ctx.prev[code];
        ctx.buf[pos - 1] = ch;
    }
    // std.debug.print("{any}\n", .{code});
    return ctx.buf[0 .. dist + 1];
}

// original (slower) solution
pub fn part1_bfs(ctx: *Context) []u8 {
    var tot: usize = 0;
    for (ctx.lines) |line| {
        var state = State.from('A');
        var entry: usize = 0;
        var ctot: usize = 0;
        for (line) |ch| {
            if (ch != 'A') entry = entry * 10 + @as(usize, @intCast(ch - '0'));
            const next = State.from(ch);
            const dist = bfs(ctx, state, next);
            // std.debug.print("{any} -> {any} = {d} : ", .{ state.pos1, next.pos1, dist });
            // std.debug.print("{s}\n", .{decode(ctx, next, dist)});
            ctot += dist + 1;
            state = next;
        }
        // std.debug.print("{d} x {d}\n", .{ entry, ctot });
        tot += entry * ctot;
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn expand1(from: u8, to: u8) []const []const u8 {
    return switch (from) {
        '<' => switch (to) {
            '^' => &.{">^A"},
            'v' => &.{">A"},
            '>' => &.{">>A"},
            'A' => &.{">>^A"}, // skip ">^>A" ? more turns
            else => &.{"A"},
        },
        'v' => switch (to) {
            '^' => &.{"^A"},
            '<' => &.{"<A"},
            '>' => &.{">A"},
            'A' => &.{ ">^A", "^>A" },
            else => &.{"A"},
        },
        '>' => switch (to) {
            'v' => &.{"<A"},
            '<' => &.{"<<A"},
            'A' => &.{"^A"},
            '^' => &.{ "^<A", "<^A" },
            else => &.{"A"},
        },
        '^' => switch (to) {
            'v' => &.{"vA"},
            '<' => &.{"v<A"},
            'A' => &.{">A"},
            '>' => &.{ ">vA", "v>A" },
            else => &.{"A"},
        },
        'A' => switch (to) {
            '^' => &.{"<A"},
            '>' => &.{"vA"},
            'v' => &.{ "<vA", "v<A" },
            '<' => &.{"v<<A"}, // skip "<v<A" - same end + more turns
            else => &.{"A"},
        },
        else => &.{},
    };
}

pub fn expand2(from: u8, to: u8) []const []const u8 {
    return switch (from) {
        '0' => switch (to) {
            '0' => &.{"A"},
            '1' => &.{"^<A"},
            '2' => &.{"^A"},
            '3' => &.{ "^>A", ">^A" },
            '4' => &.{"^^<A"}, // ; "^<^A"
            '5' => &.{"^^A"},
            '6' => &.{ "^^>A", ">^^A" }, // ; "^>^A"
            '7' => &.{"^^^<A"}, // "^^<^A" ;  "^<^^A"
            '8' => &.{"^^^A"},
            '9' => &.{ "^^^>A", ">^^^A" }, // "^>^^A" ;  "^^>^A"
            'A' => &.{">A"},
            else => &.{""}, // not really
        },
        '1' => switch (to) {
            '0' => &.{">vA"},
            '7' => &.{"^^A"},
            '8' => &.{ "^^>A", ">^^A" }, // ; "^>^A"
            '9' => &.{ "^^>>A", ">>^^A" }, // ">^>^A", "^>^>A" ; "^>>^A", ">^^>A"
            '4' => &.{"^A"},
            '5' => &.{ "^>A", ">^A" },
            '6' => &.{ "^>>A", ">>^A" }, // ; ">^>A"
            '1' => &.{"A"},
            '2' => &.{">A"},
            '3' => &.{">>A"},
            'A' => &.{">>vA"}, // ; ">v>A"
            else => &.{""},
        },
        '2' => switch (to) {
            '0' => &.{"vA"},
            '7' => &.{ "^^<A", "<^^A" }, // ; "^<^A"
            '8' => &.{"^^A"},
            '9' => &.{ "^^>A", ">^^A" }, // ;  "^>^A"
            '4' => &.{ "^<A", "<^A" },
            '5' => &.{"^A"},
            '6' => &.{ "^>A", ">^A" },
            '1' => &.{"<A"},
            '2' => &.{"A"},
            '3' => &.{">A"},
            'A' => &.{ ">vA", "v>A" },
            else => &.{""},
        },
        '3' => switch (to) {
            '0' => &.{ "<vA", "v<A" },
            '7' => &.{ "^^<<A", "<<^^A" }, // "<^<^A", "^<^<A" ;  "^<<^A"
            '8' => &.{ "^^<A", "<^^A" }, // ; "^<^A"
            '9' => &.{"^^A"},
            '4' => &.{ "^<<A", "<<^A" }, // ; "<^<A"
            '5' => &.{ "^<A", "<^A" },
            '6' => &.{"^A"},
            '1' => &.{"<<A"},
            '2' => &.{"<A"},
            '3' => &.{"A"},
            'A' => &.{"vA"},
            else => &.{""},
        },
        '4' => switch (to) {
            '0' => &.{">vvA"}, // ; "v>vA"
            '7' => &.{"^A"},
            '8' => &.{ "^>A", ">^A" },
            '9' => &.{ ">>^A", "^>>A" }, // ; ">^>A"
            '4' => &.{"A"},
            '5' => &.{">A"},
            '6' => &.{">>A"},
            '1' => &.{"vA"},
            '2' => &.{ "v>A", ">vA" },
            '3' => &.{ ">>vA", "v>>A" }, // ; ">v>A"
            'A' => &.{">>vvA"}, // ">v>vA" ; "v>>vA", "v>v>A", ">vv>A"
            else => &.{""},
        },
        '5' => switch (to) {
            '0' => &.{"vvA"},
            '7' => &.{ "^<A", "<^A" },
            '8' => &.{"^A"},
            '9' => &.{ "^>A", ">^A" },
            '4' => &.{"<A"},
            '5' => &.{"A"},
            '6' => &.{">>A"},
            '1' => &.{ "v<A", "<vA" },
            '2' => &.{"vA"},
            '3' => &.{ "v>A", ">vA" },
            'A' => &.{ ">vvA", "vv>A" }, // "v>vA"
            else => &.{""},
        },
        '6' => switch (to) {
            '0' => &.{ "<vvA", "vv<A" }, // ; "v<vA"
            '7' => &.{ "<<^A", "^<<A" }, // ; "<^<A"
            '8' => &.{ "^<A", "<^A" },
            '9' => &.{"^A"},
            '4' => &.{"<<A"},
            '5' => &.{"<A"},
            '6' => &.{"A"},
            '1' => &.{ "<<vA", "v<<A" }, // ; "<v<A"
            '2' => &.{ "v<A", "<vA" },
            '3' => &.{"vA"},
            'A' => &.{"vvA"},
            else => &.{""},
        },
        '7' => switch (to) {
            '0' => &.{">vvvA"}, //  "v>vvA" ; "vv>vA"
            '7' => &.{"A"},
            '8' => &.{">A"},
            '9' => &.{">>A"},
            '4' => &.{"vA"},
            '5' => &.{ ">vA", "v>A" },
            '6' => &.{ ">>vA", "v>>A" }, // ; ">v>A"
            '1' => &.{"vvA"},
            '2' => &.{ ">vvA", "vv>A" }, // ; "v>vA"
            '3' => &.{ ">>vvA", "vv>>A" }, // ">v>vA",  "v>v>A" ; "v>>vA"
            'A' => &.{">>vvvA"}, // ">v>vvA", "vv>>vA", "v>v>vA", ">vv>vA",  "v>vv>A" ;  "v>>vvA", "vv>v>A", ">vvv>A"
            else => &.{""},
        },
        '8' => switch (to) {
            '0' => &.{"vvvA"},
            '7' => &.{"<A"},
            '8' => &.{"A"},
            '9' => &.{">A"},
            '4' => &.{ "v<A", "<vA" },
            '5' => &.{"^A"},
            '6' => &.{ "v>A", ">vA" },
            '1' => &.{ "vv<A", "<vvA" }, // ; "v<vA"
            '2' => &.{"vvA"},
            '3' => &.{ "vv>A", ">vvA" }, // ; "v>vA"
            'A' => &.{ ">vvvA", "vvv>A" }, // "v>vvA" ;  "vv>vA"
            else => &.{""},
        },
        '9' => switch (to) {
            '0' => &.{ "<vvvA", "vvv<A" }, // "vv<vA"; "v<vvA"
            '7' => &.{"<<A"},
            '8' => &.{"<A"},
            '9' => &.{"A"},
            '4' => &.{ "<<vA", "v<<A" }, // ; "<v<A"
            '5' => &.{ "<vA", "v<A" },
            '6' => &.{"vA"},
            '1' => &.{ "<<vvA", "vv<<A" }, // "v<v<A", "<v<vA" ; "v<<vA", "<vv<A",
            '2' => &.{ "<vvA", "vv<A" }, // ; "v<vA"
            '3' => &.{"vvA"},
            'A' => &.{"vvvA"},
            else => &.{""},
        },
        'A' => switch (to) {
            '0' => &.{"<A"},
            '1' => &.{"^<<A"}, // ; "<^<A"
            '2' => &.{ "^<A", "<^A" },
            '3' => &.{"^A"},
            '4' => &.{"^^<<A"}, // "^<^<A" ; "^<<^A", "<^<^A", "<^^<A"
            '5' => &.{ "^^<A", "<^^A" }, // ; "^<^A"
            '6' => &.{"^^A"},
            '7' => &.{"^^^<<A"}, // "^^<^<A", "^<<^^A", "^<^<^A", "^<^^<A", "<^<^^A" ;  "^^<<^A", "<^^<^A", "<^^^<A"
            '8' => &.{ "^^^<A", "<^^^A" }, // "^<^^A" ; "^^<^A"
            '9' => &.{"^^^A"},
            'A' => &.{"A"},
            else => &.{""}, // not really
        },
        else => &.{""},
    };
}

// 8 bits per letter = max 7 letters, but max code is 6 so we are fine.
pub inline fn cache_key(code: []const u8, depth: usize) u64 {
    var ck: u64 = 0;
    for (code) |ch| ck = (ck << 8) | @as(u64, ch);
    // store depth in lowest bits
    return (ck << 8) + @as(u64, @intCast(depth));
}

// Handles the directional keypads
pub fn compute_length(ctx: *Context, code: []const u8, depth: usize) usize {
    const ck = cache_key(code, depth);
    if (depth == 0) return code.len;
    if (ctx.cache.contains(ck)) return ctx.cache.get(ck) orelse unreachable;
    var prev: u8 = 'A';
    var tot_len: usize = 0;
    for (code) |ch| {
        const candidates = expand1(prev, ch);
        var min_len: usize = 0;
        for (candidates) |candidate| {
            const sub = compute_length(ctx, candidate, depth - 1);
            if (min_len == 0 or sub < min_len) min_len = sub;
        }
        prev = ch;
        tot_len += min_len;
    }
    ctx.cache.put(ck, tot_len) catch unreachable;
    return tot_len;
}

// Hamdles the numeric keypad and all codes in the input
pub fn compute_top(ctx: *Context, depth: usize) usize {
    var prev: u8 = 'A';
    var ctot: usize = 0;
    for (ctx.lines) |line| {
        var tot_len: usize = 0;
        var entry: usize = 0;
        for (line) |ch| {
            if (ch != 'A') entry = entry * 10 + @as(usize, @intCast(ch - '0'));
            const candidates = expand2(prev, ch);
            var min_len: usize = 0;
            for (candidates) |candidate| {
                const sub = compute_length(ctx, candidate, depth - 1);
                if (min_len == 0 or sub < min_len) min_len = sub;
            }
            prev = ch;
            tot_len += min_len;
        }
        ctot += entry * tot_len;
    }
    return ctot;
}

pub fn part1(ctx: *Context) []u8 {
    const dist = compute_top(ctx, 3);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{dist}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    const dist = compute_top(ctx, 26);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{dist}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "21",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
