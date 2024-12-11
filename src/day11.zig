const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Key = struct {
    num: u64,
    iter: u64,
};

pub const Context = struct {
    allocator: Allocator,
    numbers: std.ArrayList(u64),
    counts: std.ArrayList(u64),
    umap: []u64,
    uval: []u64,
    blink: usize,
    wait_group: std.Thread.WaitGroup,
};

const hsize = 8000;
const hmod = 7993;

pub inline fn unique_key(ctx: *Context, key: u64, ofs: comptime_int) u64 {
    const hk = (key * 17 + ofs * 11) % hmod;
    if (ctx.umap[hk] == key + 1) return hk;
    if (@cmpxchgStrong(u64, &ctx.umap[hk], 0, key + 1, .seq_cst, .seq_cst) == null) {
        return hk;
    }
    if (ofs < 16) return unique_key(ctx, key, ofs + 1);
    std.debug.print("conflict limit reached for {d}\n", .{key});
    return 0;
}

pub fn parse(allocator: Allocator, buf: []u8, _: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.numbers = std.ArrayList(u64).init(allocator);
    ctx.counts = std.ArrayList(u64).init(allocator);

    ctx.umap = allocator.alloc(u64, hsize) catch unreachable;
    @memset(ctx.umap, 0);
    ctx.uval = allocator.alloc(u64, hsize * 76) catch unreachable;
    @memset(ctx.uval, 0);

    var iter = std.mem.splitAny(u8, buf, " ");
    while (iter.next()) |num| {
        const n = std.fmt.parseInt(u64, num, 10) catch unreachable;
        ctx.numbers.append(n) catch unreachable;
        ctx.counts.append(1) catch unreachable;
    }
    ctx.blink = 1;
    return ctx;
}

const vec2 = @Vector(2, u64);

pub fn expand(num: u64) vec2 {
    if (num == 0) return vec2{ 1, 0 };
    var base: u64 = 1;
    while (base < 10000000000) {
        base *= 10;
        const bl = base * base / 10;
        const bh = base * base;
        if (num < bl) break;
        if (num >= bl and num < bh) return vec2{ num % base, num / base };
    }
    return vec2{ num * 2024, 0 };
}

pub fn iterate(ctx: *Context, lim: usize) u64 {
    var tot: u64 = 0;
    while (ctx.blink <= lim) {
        for (ctx.numbers.items, ctx.counts.items) |n, c| {
            const v = expand(n);
            inline for (0..2) |i| {
                if (i == 0 or v[i] > 0) {
                    const hk = unique_key(ctx, v[i], 0);
                    ctx.uval[hk] += c;
                }
            }
        }
        ctx.blink += 1;
        // clear the previous phase
        ctx.numbers.clearRetainingCapacity();
        ctx.counts.clearRetainingCapacity();
        // var iter = ctx.unique.iterator();
        tot = 0;
        for (0..hmod) |i| {
            tot += ctx.uval[i];
            if (ctx.umap[i] > 0 and ctx.uval[i] > 0) {
                ctx.numbers.append(ctx.umap[i] - 1) catch unreachable;
                ctx.counts.append(ctx.uval[i]) catch unreachable;
                ctx.uval[i] = 0;
            }
        }
        // std.debug.print("{d} : {d} : {d}\n", .{ ctx.numbers.items.len, ctx.unique.count(), tot });
    }
    return tot;
}

pub fn count(ctx: *Context, k: Key) u64 {
    if (k.iter == 0) return 1;
    const hk = k.iter * hsize + unique_key(ctx, k.num, 0);
    if (ctx.uval[hk] > 0) return ctx.uval[hk];
    if (k.num == 0) return count(ctx, Key{ .num = 1, .iter = k.iter - 1 });
    var base: u64 = 1;
    while (base < 10000000000) {
        base *= 10;
        const bl = base * base / 10;
        const bh = base * base;
        if (k.num < bl) break;
        if (k.num >= bl and k.num < bh) {
            const l = k.num % base;
            const h = k.num / base;
            const ret = count(ctx, Key{ .num = l, .iter = k.iter - 1 }) + count(ctx, Key{ .num = h, .iter = k.iter - 1 });
            ctx.uval[hk] = ret;
            return ret;
        }
    }
    const ret = count(ctx, Key{ .num = k.num * 2024, .iter = k.iter - 1 });
    ctx.uval[hk] = ret;
    return ret;
}

pub fn count2(ctx: *Context, k: Key, acc: *std.atomic.Value(u64)) void {
    const ret = count(ctx, k);
    _ = acc.fetchAdd(ret, .seq_cst);
    ctx.wait_group.finish();
}

pub fn part1(ctx: *Context) []u8 {
    var tot: u64 = 0;
    // const tot = iterate(ctx, 25);
    for (ctx.numbers.items) |num| tot += count(ctx, Key{ .num = num, .iter = 25 });
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot = std.atomic.Value(u64).init(0);
    ctx.wait_group.reset();
    for (ctx.numbers.items) |num| {
        ctx.wait_group.start();
        common.pool.spawn(count2, .{ ctx, Key{ .num = num, .iter = 75 }, &tot }) catch unreachable;
    }
    common.pool.waitAndWork(&ctx.wait_group);
    // const tot = iterate(ctx, 75);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot.raw}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "11",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
