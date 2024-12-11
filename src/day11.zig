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
    count: usize,
    umap: []u64,
    uval: []u64,
    preh: []@Vector(2, u32),
    blink: usize,
    uidx: usize,
    wait_group: std.Thread.WaitGroup,
};

const hsize = 8000;
const hmod = 7993;
const tsize = 4000;

pub inline fn unique_key(ctx: *Context, key: u64, ofs: comptime_int) u64 {
    const hk = ((key * 17 + ofs * 11) % hmod) + 1;
    if (ctx.umap[hk] == key + 1) return hk;
    // if (@cmpxchgStrong(u64, &ctx.umap[hk], 0, key + 1, .seq_cst, .seq_cst) == null) {
    if (ctx.umap[hk] == 0) {
        ctx.umap[hk] = key + 1;
        ctx.uidx += 1;
        return hk;
    }
    if (ofs < 16) return unique_key(ctx, key, ofs + 1);
    std.debug.print("conflict limit reached for {d}\n", .{key});
    return 0;
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

pub fn parse(allocator: Allocator, buf: []u8, _: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.numbers = std.ArrayList(u64).init(allocator);
    ctx.numbers.ensureTotalCapacity(tsize) catch unreachable;
    ctx.uidx = 0;

    ctx.umap = allocator.alloc(u64, hsize) catch unreachable;
    @memset(ctx.umap, 0);
    ctx.uval = allocator.alloc(u64, tsize * 76) catch unreachable;
    ctx.preh = allocator.alloc(@Vector(2, u32), hsize) catch unreachable;
    @memset(ctx.preh, @splat(0));

    var iter = std.mem.splitAny(u8, buf, " ");
    while (iter.next()) |num| {
        const n = std.fmt.parseInt(u64, num, 10) catch unreachable;
        const hk = unique_key(ctx, n, 0);
        ctx.numbers.append(n) catch unreachable;
        // in phase 1 we will remap the numbers to small consecutive indexes
        ctx.uval[hk] = ctx.uidx;
        std.debug.assert(ctx.numbers.items.len == ctx.uidx);
    }
    var pos: usize = 0;
    ctx.count = ctx.numbers.items.len;

    // precompute all possible numbers and their keying
    while (pos < ctx.numbers.items.len) {
        const n = ctx.numbers.items[pos];
        const hk = unique_key(ctx, n, 0);
        const hi = ctx.uval[hk];
        const v = expand(n);
        inline for (0..2) |i| {
            if (i == 0 or v[i] > 0) {
                const ck = unique_key(ctx, v[i], 0);
                // this was a new number, add it to the list
                if (ctx.uidx > ctx.numbers.items.len) {
                    ctx.numbers.append(v[i]) catch unreachable;
                    ctx.uval[ck] = ctx.uidx;
                }
                ctx.preh[hi][i] = @intCast(ctx.uval[ck]);
            } else ctx.preh[hi][i] = tsize - 1;
        }
        pos += 1;
    }
    ctx.blink = 1;
    // the most expensive part
    @memset(ctx.uval, 0);
    for (0..ctx.count) |i| ctx.uval[i + 1] = 1;
    // std.debug.print("{d} unique numbers\n", .{ctx.uidx});
    return ctx;
}

pub fn iterate(ctx: *Context, lim: usize) u64 {
    var tot: u64 = 0;
    var cuv: []u64 = undefined;
    var nuv: []u64 = undefined;
    nuv.len = tsize;
    cuv.len = tsize;
    while (ctx.blink <= lim) {
        const ofs = (ctx.blink - 1) * tsize;
        cuv.ptr = ctx.uval.ptr + ofs;
        nuv.ptr = ctx.uval.ptr + ofs + tsize;
        for (1..ctx.uidx + 1) |n| {
            tot += cuv[n];
            if (cuv[n] == 0) continue;
            nuv[ctx.preh[n][0]] += cuv[n];
            nuv[ctx.preh[n][1]] += cuv[n];
        }
        ctx.blink += 1;
        tot = 0;
    }
    tot = 0;
    for (1..ctx.uidx + 1) |n| tot += nuv[n];
    return tot;
}

pub fn count(ctx: *Context, k: Key) u64 {
    if (k.iter == 0) return 1;
    const vk = k.iter * tsize + k.num;
    if (ctx.uval[vk] > 0) return ctx.uval[vk];
    const pre1 = ctx.preh[k.num][0];
    var ret = count(ctx, Key{ .num = pre1, .iter = k.iter - 1 });
    const pre2 = ctx.preh[k.num][1];
    if (pre2 < tsize - 1) ret += count(ctx, Key{ .num = pre2, .iter = k.iter - 1 });
    ctx.uval[vk] = ret;
    return ret;
}

pub fn count2(ctx: *Context, k: Key, acc: *std.atomic.Value(u64)) void {
    const ret = count(ctx, k);
    _ = acc.fetchAdd(ret, .seq_cst);
    ctx.wait_group.finish();
}

pub fn part1(ctx: *Context) []u8 {
    const tot = iterate(ctx, 25);
    // var tot: u64 = 0;
    // for (0..ctx.count) |num| tot += count(ctx, Key{ .num = num + 1, .iter = 25 });
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    // var tot = std.atomic.Value(u64).init(0);
    // ctx.wait_group.reset();
    // for (1..ctx.count + 1) |num| {
    //     ctx.wait_group.start();
    //     common.pool.spawn(count2, .{ ctx, Key{ .num = num, .iter = 75 }, &tot }) catch unreachable;
    // }
    // common.pool.waitAndWork(&ctx.wait_group);
    const tot = iterate(ctx, 75);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
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
