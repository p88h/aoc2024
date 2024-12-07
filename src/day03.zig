const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Context = struct { allocator: Allocator, buf: []u8, tot: i32 };

fn dfa_sub(ctx: *Context, slice: []u8) void {
    const head = "mul(";
    var state: i32 = -1;
    var pos: usize = undefined;
    var cur: [2]i32 = undefined;
    var idx: usize = undefined;
    var flags: usize = undefined;
    for (slice) |ch| {
        if (state == -1) {
            state = 0;
            pos = 0;
            cur = [2]i32{ 0, 0 };
            idx = 0;
            flags = 0;
        }
        switch (state) {
            // numbers
            1 => {
                if (ch == ',') {
                    idx += 1;
                    if (idx > 1) state = -1;
                } else if (ch >= '0' and ch <= '9') {
                    cur[idx] = cur[idx] * 10 + @as(i32, @intCast(ch - '0'));
                    flags |= idx + 1;
                } else if (ch == ')' and idx == 1 and cur[0] >= 0 and cur[1] >= 0 and flags == 3) {
                    // std.debug.print("{d}*{d}\n", .{ cur[0], cur[1] });
                    ctx.tot += cur[0] * cur[1];
                    state = -1;
                } else state = -1;
            },
            // prefix
            0 => {
                if (ch == head[pos]) {
                    pos += 1;
                } else {
                    pos = 0;
                }
                if (pos == head.len) {
                    state = 1;
                    cur = [2]i32{ 0, 0 };
                    idx = 0;
                }
            },
            else => {},
        }
    }
}

pub fn parse(allocator: Allocator, buf: []u8, _: [][]const u8) *anyopaque {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.tot = 0;
    ctx.buf = buf;
    ctx.allocator = allocator;
    return @ptrCast(ctx);
}

pub fn part1(ctx: *Context) []u8 {
    ctx.tot = 0;
    dfa_sub(ctx, ctx.buf);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    ctx.tot = 0;
    var start: usize = 0;
    while (start < ctx.buf.len) {
        const dont = std.mem.indexOfPos(u8, ctx.buf, start, "don't()");
        if (dont != null) {
            dfa_sub(ctx, ctx.buf[start..dont.?]);
            const do = std.mem.indexOfPos(u8, ctx.buf, dont.?, "do()");
            start = do orelse break;
        } else {
            dfa_sub(ctx, ctx.buf[start..]);
            break;
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{ctx.tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{ .day = "03", .parse = @ptrCast(&parse), .part1 = @ptrCast(&part1), .part2 = @ptrCast(&part2) };
pub fn main() void {
    common.run_day(work);
}
