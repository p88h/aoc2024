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
    tst: []u64,
    val: []u64,
    wait_group: std.Thread.WaitGroup,
};

pub inline fn cuckoo(ctx: *Context, key: u64, ofs: comptime_int) u64 {
    const mod1 = 999979;
    const mod2 = 988877;
    const hk1 = (key + ofs) % mod1;
    const hk2 = (key + ofs) % mod2;
    if (ctx.tst[hk1] == key) return hk1 + 1;
    if (ctx.tst[hk1] == 0) {
        ctx.tst[hk1] = key;
        // ctx.val[hk1 + 1] = 0;
        return hk1 + 1;
    }
    if (ctx.tst[hk2] == key) return hk2 + 1;
    if (ctx.tst[hk2] == 0) {
        ctx.tst[hk2] = key;
        // ctx.val[hk2 + 1] = 0;
        return hk2 + 1;
    }
    // in practice, we could handle conflicts better, but we can also just kill it early for some performance bonus
    // Also, this is likely less likely to cause multi-threading issues
    // if (ofs < 3) return cuckoo(ctx, key, ofs + 1);
    return 0;
}

// this seems slightly more efficient than @memset ?
pub inline fn fast_clear_slice(ctx: *Context, sl: *[]u64, ofs: comptime_int, size: comptime_int) void {
    var vecs: []@Vector(4, u64) = undefined;
    vecs.ptr = @ptrCast(@alignCast(sl.ptr));
    vecs.len = sl.len / 4;
    const v_size: comptime_int = size / 4;
    const l_size: comptime_int = v_size / 16;
    for (0..l_size) |i| {
        inline for (0..16) |j| vecs[ofs / 4 + i * 16 + j] = @splat(0);
    }
    ctx.wait_group.finish();
}

pub fn parse(allocator: Allocator, buf: []u8, _: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    ctx.numbers = std.ArrayList(u64).init(allocator);
    ctx.tst = allocator.alignedAlloc(u64, @alignOf(@Vector(4, u64)), 1000000) catch unreachable;
    ctx.val = allocator.alignedAlloc(u64, @alignOf(@Vector(4, u64)), 1000000) catch unreachable;
    ctx.wait_group.reset();
    ctx.wait_group.start();
    common.pool.spawn(fast_clear_slice, .{ ctx, &ctx.tst, 0, 500000 }) catch unreachable;
    ctx.wait_group.start();
    common.pool.spawn(fast_clear_slice, .{ ctx, &ctx.tst, 500000, 500000 }) catch unreachable;
    ctx.wait_group.start();
    common.pool.spawn(fast_clear_slice, .{ ctx, &ctx.val, 0, 500000 }) catch unreachable;
    ctx.wait_group.start();
    fast_clear_slice(ctx, &ctx.val, 500000, 500000);
    var iter = std.mem.splitAny(u8, buf, " ");
    while (iter.next()) |num| {
        const n = std.fmt.parseInt(u64, num, 10) catch unreachable;
        ctx.numbers.append(n) catch unreachable;
    }
    common.pool.waitAndWork(&ctx.wait_group);
    return ctx;
}

pub fn count(ctx: *Context, k: Key) u64 {
    if (k.iter == 0) return 1;
    const ck = k.num * 100 + k.iter;
    const hk = cuckoo(ctx, ck, 0);
    // if (ctx.cache.contains(k)) return ctx.cache.get(k).?;
    if (hk > 0 and ctx.val[hk] > 0) return ctx.val[hk];
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
            // ctx.cache.put(k, ret) catch unreachable;
            if (hk > 0) ctx.val[hk] = ret;
            return ret;
        }
    }
    // std.debug.print("mul {d}\n", .{x});
    const ret = count(ctx, Key{ .num = k.num * 2024, .iter = k.iter - 1 });
    // ctx.cache.put(k, ret) catch unreachable;
    if (hk > 0) ctx.val[hk] = ret;
    return ret;
}

pub fn count2(ctx: *Context, k: Key, acc: *std.atomic.Value(u64)) void {
    const ret = count(ctx, k);
    _ = acc.fetchAdd(ret, .seq_cst);
    ctx.wait_group.finish();
}

pub fn part1(ctx: *Context) []u8 {
    var tot: u64 = 0;
    for (ctx.numbers.items) |num| tot += count(ctx, Key{ .num = num, .iter = 25 });
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var tot = std.atomic.Value(u64).init(0);
    // ctx.cache.ensureTotalCapacity(500000) catch unreachable;
    ctx.wait_group.reset();
    for (ctx.numbers.items) |num| {
        ctx.wait_group.start();
        common.pool.spawn(count2, .{ ctx, Key{ .num = num, .iter = 75 }, &tot }) catch unreachable;
    }
    common.pool.waitAndWork(&ctx.wait_group);
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
