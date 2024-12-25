const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");
const testing = std.testing;

pub const Vec8 = @Vector(8, u32);
pub const scnt = 12;
pub const pcnt = 19 * 19 * 19 * 19;
pub const pcnt_pad = ((pcnt + 63) / 64) * 64;
// good values are 2 / 4. 1 is slower. 8 won't work (/would need changes), and would be slower.
pub const beam = 4;

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
    // pad up to a multiple of beam
    while (ssize % beam != 0) : (ssize += 1) {}
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
    var vv: [beam]Vec8 = nums[0..beam].*;
    for (0..cnt) |_| {
        inline for (0..beam) |i| vv[i] = hash_smash(vv[i]);
    }
    inline for (1..beam) |i| vv[0] += vv[i];
    return vv[0];
}

test "hulk smash many" {
    var nums = [_]Vec8{@splat(0)} ** beam;
    nums[0][0] = 1;
    nums[0][5] = 10;
    nums[1][1] = 100;
    nums[1][4] = 2024;
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

const v_10: Vec8 = @splat(10);
const v_8s: @Vector(8, u5) = @splat(8);
const v_1: Vec8 = @splat(1);

pub inline fn hash_smash_v2(v: Vec8, h: *Vec8) Vec8 {
    // previous last digits
    const pd = v % v_10;
    const nv = hash_smash(v);
    // new last digits,
    const d = (nv % v_10);
    // digits delta plus 10 to make it non-negative (range 1..19 each)
    const z = (d + v_10) - pd;
    // store price delta in history
    h.* = (h.* << v_8s) + z;
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
    var v: [beam]Vec8 = nums[0..beam].*;
    // historys
    var h = [_]Vec8{@splat(0)} ** beam;
    // sell counts
    var r = [_]Vec8{@splat(0)} ** beam;
    for (0..cnt) |_| {
        var zcnt: usize = 0;
        inline for (0..beam) |i| {
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
        if (zcnt == beam * 8) break;
    }
    inline for (1..beam) |i| r[0] += r[i];
    return r[0];
}

test "monkey market" {
    var nums = [_]Vec8{@splat(0)} ** beam;
    nums[0] = Vec8{ 1, 2, 3, 2024, 0, 0, 0, 0 };
    const pat = make_pattern(10 - 2, 10 + 1, 10 - 1, 10 + 3);
    const ret = hash_smash_loop_2(&nums, 2000, pat);
    try testing.expect(ret[0] == 7);
    try testing.expect(ret[1] == 7);
    try testing.expect(ret[2] == 0);
    try testing.expect(ret[3] == 9);
}

pub inline fn pack_patterns(pat: Vec8) Vec8 {
    var t = pat;
    var r: Vec8 = @splat(0);
    const v_255: Vec8 = comptime @splat(255);
    const v_19: Vec8 = comptime @splat(19);
    inline for (0..4) |_| {
        r = r * v_19 + (t & v_255) - v_1;
        t >>= v_8s;
    }
    return r;
}

pub fn hash_smash_loop_3(nums: []Vec8, comptime cnt: usize, totals: *[pcnt]u16) void {
    // we'll process beam x 8 merchants at a time, using 32 bits for presence detection.
    var history = [_]u32{0} ** pcnt;
    var v: [beam]Vec8 = nums[0..beam].*;
    // local history
    var h = [_]Vec8{@splat(0)} ** beam;
    const v_1_8 = comptime std.simd.iota(u5, 8);
    for (0..cnt) |k| {
        inline for (0..beam) |i| {
            const v_b: @Vector(8, u5) = comptime @splat(8 * i);
            const v_s = comptime (v_b + v_1_8);
            const bits = comptime (v_1 << v_s);
            v[i] = hash_smash_v2(v[i], &h[i]);
            if (k >= 3) {
                const p = pack_patterns(h[i]);
                // unfortunate loop.. zig has no SIMD gather
                inline for (0..8) |j| {
                    // this pattern was not seen for this merchant
                    if (history[p[j]] & bits[j] == 0) {
                        totals.*[p[j]] += @intCast(v[i][j] % 10);
                        history[p[j]] |= bits[j];
                    }
                }
            }
        }
    }
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

pub fn max_pattern(totals: *[pcnt]u16) usize {
    var midx: usize = 0;
    for (1..pcnt) |p| {
        if (totals[p] > totals[midx]) midx = p;
    }
    return midx;
}

test "smart monkey" {
    var nums = [_]Vec8{@splat(0)} ** beam;
    var totals = [_]u16{0} ** pcnt;
    nums[0] = Vec8{ 1, 2, 3, 2024, 0, 0, 0, 0 };
    const pat = make_pattern(10 - 2, 10 + 1, 10 - 1, 10 + 3);
    const pats: Vec8 = @splat(pat);
    const idx = pack_patterns(pats)[0];
    hash_smash_loop_3(&nums, 2000, &totals);
    try testing.expect(totals[idx] == 23);
    const m = max_pattern(&totals);
    try testing.expect(m == idx);
}

pub fn hash_smash_loop_shard(ctx: *Context, shard: usize, comptime iter: usize, p2: bool) void {
    var tot: u64 = 0;
    var ofs = shard * beam;
    const len = ctx.secrets.len;
    var results: *[pcnt]u16 = undefined;
    results.ptr = @alignCast(@ptrCast(ctx.results.ptr + shard * pcnt_pad));
    while (ofs < len) : (ofs += scnt * beam) {
        if (p2) {
            hash_smash_loop_3(ctx.secrets[ofs .. ofs + beam], iter, results);
        } else {
            const rv = hash_smash_loop_1(ctx.secrets[ofs .. ofs + beam], iter);
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
