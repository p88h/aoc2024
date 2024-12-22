const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");
const testing = std.testing;

pub const Vec8 = @Vector(8, u32);
pub const scnt = 16;
pub const pcnt = 19 * 19 * 19 * 19;
pub const pcnt_pad = ((pcnt + 63) / 64) * 64;

pub const Context = struct {
    allocator: Allocator,
    secrets: []Vec8,
    results: []u16,
    total: std.atomic.Value(u64),
    wait_group: std.Thread.WaitGroup,
};

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.allocator = allocator;
    // pad up to vector size
    var ssize = (lines.len + 7) / 8;
    // pad up to a multiple of 4
    while (ssize % 4 != 0) : (ssize += 1) {}
    ctx.secrets = allocator.alloc(Vec8, ssize) catch unreachable;
    @memset(ctx.secrets, @splat(0));
    for (lines, 0..) |line, i| {
        var num: u32 = 0;
        for (line) |ch| num = num * 10 + @as(u32, @intCast(ch - '0'));
        ctx.secrets[i / 8][i % 8] = num;
    }
    ctx.results = allocator.alloc(u16, pcnt_pad * scnt) catch unreachable;
    @memset(ctx.results, 0);
    return ctx;
}

// single hash iteration (over a vector)
pub inline fn hash_smash(v: Vec8) Vec8 {
    // this is a power of 2, so pruning becomes masking
    const pm: Vec8 = comptime @splat(16777216 - 1);
    // multiply by 64
    const v_6 = comptime @Vector(8, u5){ 6, 6, 6, 6, 6, 6, 6, 6 };
    var r = v << v_6;
    // mix
    var s = r ^ v;
    // prune
    s &= pm;
    // divide by 32, mix and prune
    const v_5 = comptime @Vector(8, u5){ 5, 5, 5, 5, 5, 5, 5, 5 };
    r = s >> v_5;
    s ^= r;
    s &= pm;
    // multiply by 2048, mix and prune
    const v_11 = comptime @Vector(8, u5){ 11, 11, 11, 11, 11, 11, 11, 11 };
    r = s << v_11;
    s ^= r;
    s &= pm;
    return s;
}

test "hulk smash" {
    var v: Vec8 = @splat(0);
    v[0] = 123;
    v = hash_smash(v);
    try testing.expect(v[0] == 15887950);
    v = hash_smash(v);
    try testing.expect(v[0] == 16495136);
    v = hash_smash(v);
    try testing.expect(v[0] == 527345);
    v = hash_smash(v);
    try testing.expect(v[0] == 704524);
    v = hash_smash(v);
    try testing.expect(v[0] == 1553684);
    v = hash_smash(v);
    try testing.expect(@reduce(.Add, v) == 12683156);
}

pub fn hash_smash_loop_1(nums: []Vec8, comptime cnt: usize) Vec8 {
    var v0 = nums[0];
    var v1 = nums[1];
    var v2 = nums[2];
    var v3 = nums[3];
    for (0..cnt) |_| {
        v0 = hash_smash(v0);
        v1 = hash_smash(v1);
        v2 = hash_smash(v2);
        v3 = hash_smash(v3);
    }
    v0 += v1;
    v3 += v2;
    v3 += v0;
    return v3;
}

test "hulk smash many" {
    var nums = [_]Vec8{@splat(0)} ** 4;
    nums[0][0] = 1;
    nums[1][5] = 10;
    nums[2][1] = 100;
    nums[2][4] = 2024;
    const rv = hash_smash_loop_1(&nums, 2000);
    try testing.expect(rv[0] == 8685429);
    try testing.expect(rv[5] == 4700978);
    try testing.expect(rv[1] == 15273692);
    try testing.expect(rv[4] == 8667524);
    try testing.expect(rv[2] == 0);
    try testing.expect(rv[3] == 0);
    try testing.expect(rv[7] == 0);
    try testing.expect(rv[6] == 0);
    const sum = @reduce(.Add, rv);
    try testing.expect(sum == 37327623);
}

const v_10 = Vec8{ 10, 10, 10, 10, 10, 10, 10, 10 };
pub inline fn hash_smash_v2(v: Vec8, h: *Vec8) Vec8 {
    const v_8 = comptime @Vector(8, u5){ 8, 8, 8, 8, 8, 8, 8, 8 };
    // previous last digits
    const pd = v % v_10;
    const nv = hash_smash(v);
    // new last digits,
    const d = (nv % v_10);
    // digits delta plus 10 to make it non-negative (range 1..19 each)
    const z = (d + v_10) - pd;
    // store price delta in history
    h.* = (h.* << v_8) + z;
    return nv;
}

pub inline fn make_pattern(a: usize, b: usize, c: usize, d: usize) u32 {
    return @intCast((a << 24) + (b << 16) + (c << 8) + d);
}

test "monkey business" {
    var v: Vec8 = @splat(0);
    var h: Vec8 = @splat(0);
    v[0] = 123;
    v = hash_smash_v2(v, &h);
    v = hash_smash_v2(v, &h);
    v = hash_smash_v2(v, &h);
    v = hash_smash_v2(v, &h);
    try testing.expect(h[0] == make_pattern(10 - 3, 10 + 6, 10 - 1, 10 - 1));
    v = hash_smash_v2(v, &h);
    v = hash_smash_v2(v, &h);
    v = hash_smash_v2(v, &h);
    v = hash_smash_v2(v, &h);
    try testing.expect(h[0] == make_pattern(10, 10 + 2, 10 - 2, 10));
}

pub fn hash_smash_loop_2(nums: []Vec8, comptime cnt: usize, pattern: u32) Vec8 {
    var v: [4]Vec8 = nums[0..4].*;
    // historys
    var h = [_]Vec8{@splat(0)} ** 4;
    // sell counts
    var r = [_]Vec8{@splat(0)} ** 4;
    for (0..cnt) |_| {
        var zcnt: usize = 0;
        inline for (0..4) |i| {
            v[i] = hash_smash_v2(v[i], &h[i]);
            // unfortunate inner loop
            inline for (0..8) |j| {
                // sell
                if (h[i][j] == pattern) {
                    r[i][j] = v[i][j] % 10;
                    v[i][j] = 0;
                }
            }
            zcnt += std.simd.countElementsWithValue(v[i], 0);
        }
        if (zcnt == 32) break;
    }
    r[0] += r[1];
    r[3] += r[2];
    return r[3] + r[0];
}

test "monkey market" {
    var nums = [_]Vec8{@splat(0)} ** 4;
    nums[0] = Vec8{ 1, 2, 3, 2024, 0, 0, 0, 0 };
    const pat = make_pattern(10 - 2, 10 + 1, 10 - 1, 10 + 3);
    const ret = hash_smash_loop_2(&nums, 2000, pat);
    try testing.expect(ret[0] == 7);
    try testing.expect(ret[1] == 7);
    try testing.expect(ret[2] == 0);
    try testing.expect(ret[3] == 9);
}

pub inline fn pack_pattern(pat: u32) usize {
    var t = pat;
    var r: u32 = 0;
    inline for (0..4) |_| {
        r = r * 19 + @as(u32, @intCast((t & 0xFF) - 1));
        t >>= 8;
    }
    return r;
}

pub fn hash_smash_loop_3(nums: []Vec8, comptime cnt: usize, totals: *[pcnt]u16) Vec8 {
    var history = [_]u32{0} ** pcnt;
    var v: [4]Vec8 = nums[0..4].*;
    // historys
    var h = [_]Vec8{@splat(0)} ** 4;
    // sell counts
    var r = [_]Vec8{@splat(0)} ** 4;
    for (0..cnt) |k| {
        var zcnt: usize = 0;
        inline for (0..4) |i| {
            v[i] = hash_smash_v2(v[i], &h[i]);
            if (k >= 3) {
                // unfortunate loop
                inline for (0..8) |j| {
                    const p = pack_pattern(h[i][j]);
                    const bit: u32 = 1 << comptime (8 * i + j);
                    // this pattern was not seen for this merchant
                    if (history[p] & bit == 0) {
                        totals.*[p] += @intCast(v[i][j] % 10);
                        history[p] |= bit;
                    }
                }
                zcnt += std.simd.countElementsWithValue(v[i], 0);
            }
        }
        if (zcnt == 32) break;
    }
    r[0] += r[1];
    r[3] += r[2];
    return r[3] + r[0];
}

pub inline fn unpack_pattern(idx: usize) u32 {
    var t = idx;
    var r: u32 = 0;
    inline for (0..4) |_| {
        r = (r << 8) + @as(u32, @intCast((t % 19) + 1));
        t /= 19;
    }
    return r;
}

pub fn max_pattern(totals: *[pcnt]u16) u32 {
    var midx = 0;
    for (1..pcnt) |p| {
        if (totals[p] > totals[midx]) midx = p;
    }
    return midx;
}

test "smart monkey" {
    var nums = [_]Vec8{@splat(0)} ** 4;
    var totals = [_]u16{0} ** pcnt;
    nums[0] = Vec8{ 1, 2, 3, 2024, 0, 0, 0, 0 };
    const pat = make_pattern(10 - 2, 10 + 1, 10 - 1, 10 + 3);
    const idx = unpack_pattern(pat);
    _ = hash_smash_loop_3(&nums, 2000, &totals);
    try testing.expect(totals[idx] == 23);
    const m = max_pattern(&totals);
    testing.expect(m == idx);
}

pub fn hash_smash_loop_shard(ctx: *Context, shard: usize, comptime iter: usize, p2: bool) void {
    var tot: u64 = 0;
    var ofs = shard * 4;
    const len = ctx.secrets.len;
    var results: *[pcnt]u16 = undefined;
    results.ptr = @alignCast(@ptrCast(ctx.results.ptr + shard * pcnt_pad));
    while (ofs < len) : (ofs += scnt * 4) {
        if (p2) {
            _ = hash_smash_loop_3(ctx.secrets[ofs .. ofs + 4], iter, results);
        } else {
            const rv = hash_smash_loop_1(ctx.secrets[ofs .. ofs + 4], iter);
            tot += @intCast(@reduce(.Add, rv));
        }
    }
    // std.debug.print("{d} ({d})\n", .{ tot, shard });
    _ = ctx.total.fetchAdd(tot, .seq_cst);
    ctx.wait_group.finish();
}

pub fn hash_smash_all(ctx: *Context, comptime iter: usize, p2: bool) u64 {
    if (scnt > 1) {
        ctx.total.store(0, .seq_cst);
        ctx.wait_group.reset();
        for (0..scnt) |s| {
            ctx.wait_group.start();
            common.pool.spawn(hash_smash_loop_shard, .{ ctx, s, iter, p2 }) catch {
                std.debug.panic("Could not spawn thread", .{});
            };
        }
        common.pool.waitAndWork(&ctx.wait_group);
    } else {
        hash_smash_loop_shard(ctx, 0, iter, p2);
    }
    if (p2) {
        var mmax: u16 = 0;
        for (0..pcnt) |p| {
            var ct: u16 = 0;
            for (0..scnt) |s| ct += ctx.results[s * pcnt_pad + p];
            if (ct > mmax) mmax = ct;
        }
        return mmax;
    } else {
        return ctx.total.load(.seq_cst);
    }
}

pub fn part1(ctx: *Context) []u8 {
    const tot = hash_smash_all(ctx, 2000, false);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    const tot = hash_smash_all(ctx, 2000, true);
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "22",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
