const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct {
    allocator: Allocator,
    lines: [][]const u8,
    cache: std.AutoHashMap(u64, usize),
    log: ?std.ArrayList(u64) = null,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.lines = lines;
    ctx.allocator = allocator;
    ctx.cache = std.AutoHashMap(u64, usize).init(allocator);
    ctx.log = null;
    return ctx;
}

pub inline fn expand1(from: u8, to: u8) []const []const u8 {
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

pub inline fn expand2(from: u8, to: u8) []const []const u8 {
    return switch (from) {
        '0' => switch (to) {
            '7' => &.{"^^^<A"}, // "^^<^A" ;  "^<^^A"
            '8' => &.{"^^^A"},
            '9' => &.{ "^^^>A", ">^^^A" }, // "^>^^A" ;  "^^>^A"
            '4' => &.{"^^<A"}, // ; "^<^A"
            '5' => &.{"^^A"},
            '6' => &.{ "^^>A", ">^^A" }, // ; "^>^A"
            '1' => &.{"^<A"},
            '2' => &.{"^A"},
            '3' => &.{ "^>A", ">^A" },
            '0' => &.{"A"},
            'A' => &.{">A"},
            else => &.{""}, // not really
        },
        '1' => switch (to) {
            '7' => &.{"^^A"},
            '8' => &.{ "^^>A", ">^^A" }, // ; "^>^A"
            '9' => &.{ "^^>>A", ">>^^A" }, // ">^>^A", "^>^>A" ; "^>>^A", ">^^>A"
            '4' => &.{"^A"},
            '5' => &.{ "^>A", ">^A" },
            '6' => &.{ "^>>A", ">>^A" }, // ; ">^>A"
            '1' => &.{"A"},
            '2' => &.{">A"},
            '3' => &.{">>A"},
            '0' => &.{">vA"},
            'A' => &.{">>vA"}, // ; ">v>A"
            else => &.{""},
        },
        '2' => switch (to) {
            '7' => &.{ "^^<A", "<^^A" }, // ; "^<^A"
            '8' => &.{"^^A"},
            '9' => &.{ "^^>A", ">^^A" }, // ;  "^>^A"
            '4' => &.{ "^<A", "<^A" },
            '5' => &.{"^A"},
            '6' => &.{ "^>A", ">^A" },
            '1' => &.{"<A"},
            '2' => &.{"A"},
            '3' => &.{">A"},
            '0' => &.{"vA"},
            'A' => &.{ ">vA", "v>A" },
            else => &.{""},
        },
        '3' => switch (to) {
            '7' => &.{ "^^<<A", "<<^^A" }, // "<^<^A", "^<^<A" ;  "^<<^A"
            '8' => &.{ "^^<A", "<^^A" }, // ; "^<^A"
            '9' => &.{"^^A"},
            '4' => &.{ "^<<A", "<<^A" }, // ; "<^<A"
            '5' => &.{ "^<A", "<^A" },
            '6' => &.{"^A"},
            '1' => &.{"<<A"},
            '2' => &.{"<A"},
            '3' => &.{"A"},
            '0' => &.{ "<vA", "v<A" },
            'A' => &.{"vA"},
            else => &.{""},
        },
        '4' => switch (to) {
            '7' => &.{"^A"},
            '8' => &.{ "^>A", ">^A" },
            '9' => &.{ ">>^A", "^>>A" }, // ; ">^>A"
            '4' => &.{"A"},
            '5' => &.{">A"},
            '6' => &.{">>A"},
            '1' => &.{"vA"},
            '2' => &.{ "v>A", ">vA" },
            '3' => &.{ ">>vA", "v>>A" }, // ; ">v>A"
            '0' => &.{">vvA"}, // ; "v>vA"
            'A' => &.{">>vvA"}, // ">v>vA" ; "v>>vA", "v>v>A", ">vv>A"
            else => &.{""},
        },
        '5' => switch (to) {
            '7' => &.{ "^<A", "<^A" },
            '8' => &.{"^A"},
            '9' => &.{ "^>A", ">^A" },
            '4' => &.{"<A"},
            '5' => &.{"A"},
            '6' => &.{">A"},
            '1' => &.{ "v<A", "<vA" },
            '2' => &.{"vA"},
            '3' => &.{ "v>A", ">vA" },
            '0' => &.{"vvA"},
            'A' => &.{ ">vvA", "vv>A" }, // "v>vA"
            else => &.{""},
        },
        '6' => switch (to) {
            '7' => &.{ "<<^A", "^<<A" }, // ; "<^<A"
            '8' => &.{ "^<A", "<^A" },
            '9' => &.{"^A"},
            '4' => &.{"<<A"},
            '5' => &.{"<A"},
            '6' => &.{"A"},
            '1' => &.{ "<<vA", "v<<A" }, // ; "<v<A"
            '2' => &.{ "v<A", "<vA" },
            '3' => &.{"vA"},
            '0' => &.{ "<vvA", "vv<A" }, // ; "v<vA"
            'A' => &.{"vvA"},
            else => &.{""},
        },
        '7' => switch (to) {
            '7' => &.{"A"},
            '8' => &.{">A"},
            '9' => &.{">>A"},
            '4' => &.{"vA"},
            '5' => &.{ ">vA", "v>A" },
            '6' => &.{ ">>vA", "v>>A" }, // ; ">v>A"
            '1' => &.{"vvA"},
            '2' => &.{ ">vvA", "vv>A" }, // ; "v>vA"
            '3' => &.{ ">>vvA", "vv>>A" }, // ">v>vA",  "v>v>A" ; "v>>vA"
            '0' => &.{">vvvA"}, //  "v>vvA" ; "vv>vA"
            'A' => &.{">>vvvA"}, // ">v>vvA", "vv>>vA", "v>v>vA", ">vv>vA",  "v>vv>A" ;  "v>>vvA", "vv>v>A", ">vvv>A"
            else => &.{""},
        },
        '8' => switch (to) {
            '7' => &.{"<A"},
            '8' => &.{"A"},
            '9' => &.{">A"},
            '4' => &.{ "v<A", "<vA" },
            '5' => &.{"vA"},
            '6' => &.{ "v>A", ">vA" },
            '1' => &.{ "vv<A", "<vvA" }, // ; "v<vA"
            '2' => &.{"vvA"},
            '3' => &.{ "vv>A", ">vvA" }, // ; "v>vA"
            '0' => &.{"vvvA"},
            'A' => &.{ ">vvvA", "vvv>A" }, // "v>vvA" ;  "vv>vA"
            else => &.{""},
        },
        '9' => switch (to) {
            '7' => &.{"<<A"},
            '8' => &.{"<A"},
            '9' => &.{"A"},
            '4' => &.{ "<<vA", "v<<A" }, // ; "<v<A"
            '5' => &.{ "<vA", "v<A" },
            '6' => &.{"vA"},
            '1' => &.{ "<<vvA", "vv<<A" }, // "v<v<A", "<v<vA" ; "v<<vA", "<vv<A",
            '2' => &.{ "<vvA", "vv<A" }, // ; "v<vA"
            '3' => &.{"vvA"},
            '0' => &.{ "<vvvA", "vvv<A" }, // "vv<vA"; "v<vvA"
            'A' => &.{"vvvA"},
            else => &.{""},
        },
        'A' => switch (to) {
            '7' => &.{"^^^<<A"}, // "^^<^<A", "^<<^^A", "^<^<^A", "^<^^<A", "<^<^^A" ;  "^^<<^A", "<^^<^A", "<^^^<A"
            '8' => &.{ "^^^<A", "<^^^A" }, // "^<^^A" ; "^^<^A"
            '9' => &.{"^^^A"},
            '4' => &.{"^^<<A"}, // "^<^<A" ; "^<<^A", "<^<^A", "<^^<A"
            '5' => &.{ "^^<A", "<^^A" }, // ; "^<^A"
            '6' => &.{"^^A"},
            '1' => &.{"^<<A"}, // ; "<^<A"
            '2' => &.{ "^<A", "<^A" },
            '3' => &.{"^A"},
            '0' => &.{"<A"},
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
    // if (depth == 24) std.debug.print("ctx.cache.put(cache_key(\"{s}\",{d}), {d});\n", .{ code, depth, tot_len });
    // if (depth == 1) std.debug.print("ctx.cache.put(cache_key(\"{s}\",{d}), {d});\n", .{ code, depth, tot_len });
    ctx.cache.put(ck, tot_len) catch unreachable;
    if (ctx.log != null) ctx.log.?.append(ck) catch unreachable;
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
        if (ctx.log != null) {
            const ck = cache_key(line, depth);
            ctx.cache.put(ck, tot_len) catch unreachable;
            ctx.log.?.append(ck) catch unreachable;
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
    // Populate the ~top-level cache ;)
    // These are all codes that are actually used when navigating sub-pads.
    // That allows to solve for any input in ~1us
    ctx.cache.put(cache_key("<A", 24), 9009012838) catch unreachable;
    ctx.cache.put(cache_key("A", 24), 1) catch unreachable;
    ctx.cache.put(cache_key("v<A", 24), 12192864309) catch unreachable;
    ctx.cache.put(cache_key(">>^A", 24), 10218188222) catch unreachable;
    ctx.cache.put(cache_key("v<<A", 24), 12192864310) catch unreachable;
    ctx.cache.put(cache_key(">^A", 24), 10218188221) catch unreachable;
    ctx.cache.put(cache_key(">A", 24), 5743602246) catch unreachable;
    ctx.cache.put(cache_key("<vA", 24), 11104086645) catch unreachable;
    ctx.cache.put(cache_key("^>A", 24), 9686334009) catch unreachable;
    ctx.cache.put(cache_key("vA", 24), 8357534516) catch unreachable;
    ctx.cache.put(cache_key("^A", 24), 5930403600) catch unreachable;
    ctx.cache.put(cache_key(">vA", 24), 10874983363) catch unreachable;
    ctx.cache.put(cache_key("v>A", 24), 9156556999) catch unreachable;
    ctx.cache.put(cache_key("^<A", 24), 12630544843) catch unreachable;
    ctx.cache.put(cache_key("<^A", 24), 11317884431) catch unreachable;
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
