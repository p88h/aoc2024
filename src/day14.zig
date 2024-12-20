const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const vec2 = @Vector(2, i32);

pub const Robot = struct {
    pos: vec2,
    dir: vec2,
    pub fn init(vec: @Vector(4, i32)) Robot {
        return Robot{ .pos = .{ vec[0], vec[1] }, .dir = .{ vec[2], vec[3] } };
    }
};

pub fn parseVec(line: []const u8, ofs: comptime_int) @Vector(4, i32) {
    var v: @Vector(4, i32) = @splat(0);
    var p: usize = 0;
    var s: i32 = 1;
    for (ofs..line.len) |i| {
        if (line[i] == '-') {
            s = -1;
        } else if (line[i] >= '0' and line[i] <= '9') {
            v[p] = v[p] * 10 + line[i] - '0';
        } else if (line[i - 1] >= '0' and line[i - 1] <= '9') {
            v[p] *= s;
            p += 1;
            s = 1;
        }
    }
    v[3] *= s;
    return v;
}

pub const Context = struct {
    allocator: Allocator,
    robots: []Robot,
    model: []u16,
    egg: usize,
    wait_group: std.Thread.WaitGroup,
    running: std.atomic.Value(usize),
};

// build our 3x3 pattern detector
pub fn train(ctx: *Context) void {
    ctx.model = ctx.allocator.alloc(u16, 1 << 9) catch unreachable;
    @memset(ctx.model, 0);
    const patterns = [_]@Vector(2, u16){
        .{ 0b111_111_000, 0b111_000_000 }, // horizontal edge
        .{ 0b111_111_111, 0b000_111_000 },
        .{ 0b000_111_111, 0b000_000_111 },
        .{ 0b111_111_000, 0b111_111_000 }, // horizontal thick line (+full block bonus)
        .{ 0b000_111_111, 0b000_111_111 },
        .{ 0b110_110_110, 0b100_100_100 }, // vertical edge
        .{ 0b111_111_111, 0b010_010_010 },
        .{ 0b011_011_011, 0b001_001_001 },
        .{ 0b110_110_110, 0b110_110_110 }, // vertical thick line (+also full block bonus)
        .{ 0b011_011_011, 0b011_011_011 },
        .{ 0b110_111_011, 0b100_010_001 }, // diagonal right
        .{ 0b011_111_110, 0b001_010_100 }, // diagonal left
        .{ 0b111_111_110, 0b111_110_100 }, // top left corner (= block with 1 pixel missing)
        .{ 0b111_111_011, 0b111_011_001 }, // top right corner
        .{ 0b011_111_111, 0b001_011_111 }, // bottom right corner
        .{ 0b110_111_111, 0b100_110_111 }, // bottom left corner
        .{ 0b111_111_111, 0b111_111_111 }, // full block
    };
    // build the scoring table
    for (0..1 << 9) |f| {
        for (patterns) |p| {
            if (f & p[0] == p[1]) ctx.model[f] += 1;
        }
    }
}

pub const W = 101;
pub const H = 103;

pub fn parse(allocator: Allocator, _: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.robots = allocator.alloc(Robot, lines.len) catch unreachable;
    for (lines, 0..) |line, i| ctx.robots[i] = Robot.init(parseVec(line, 2));
    ctx.allocator = allocator;
    ctx.egg = 0;
    ctx.running.store(0, .seq_cst);
    return ctx;
}

pub fn qscore(ctx: *Context, f: usize) u32 {
    var tmp: @Vector(4, u32) = @splat(0);
    for (ctx.robots) |robot| {
        const fpos = robot.pos + @as(vec2, @splat(@intCast(f))) * robot.dir;
        const fx = @mod(fpos[0], W);
        const fy = @mod(fpos[1], H);
        // std.debug.print("{any} => {any} == {d} (mod {}) {d} (mod {})\n", .{ robot, fpos, fx, W, fy, H });
        // mid lanes
        if (fx == W / 2 or fy == H / 2) continue;
        // quadrants
        if (fx < W / 2 and fy < H / 2) {
            tmp[0] += 1;
        } else if (fx < W / 2 and fy > H / 2) {
            tmp[1] += 1;
        } else if (fx > W / 2 and fy < H / 2) {
            tmp[2] += 1;
        } else {
            tmp[3] += 1;
        }
    }
    return @reduce(.Mul, tmp);
}

pub fn part1(ctx: *Context) []u8 {
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{qscore(ctx, 100)}) catch unreachable;
}

const BW = (W + 2) / 3;
const BH = (H + 2) / 3;
pub const FRAME_SIZE = (BW * BH * 9 + 62) / 63;

pub fn score(ctx: *Context, f: usize, frame: *[FRAME_SIZE]u64) u16 {
    @memset(frame, 0);
    for (ctx.robots) |robot| {
        const fpos = robot.pos + @as(vec2, @splat(@intCast(f))) * robot.dir;
        const fx: usize = @intCast(@mod(fpos[0], W));
        const fy: usize = @intCast(@mod(fpos[1], H));
        const bx = fx / 3;
        const by = fy / 3;
        const bi = (by * BW + bx) * 9;
        const off = bi / 63;
        const ii: usize = (fy % 3) * 3 + (fx % 3);
        const bit = (bi % 63) + ii;
        frame[off] |= @as(u64, 1) << @as(u6, @intCast(bit));
    }
    var tot: u16 = 0;
    for (frame) |word| {
        inline for (0..7) |w| tot += ctx.model[(word >> w * 9) & 511];
    }
    return tot;
}

// instead of looking for edges, just look for solid 8-bit runs
pub fn flscore(ctx: *Context, f: usize, frame: *[FRAME_SIZE]u64) u16 {
    @memset(frame, 0);
    for (ctx.robots) |robot| {
        const fpos = robot.pos + @as(vec2, @splat(@intCast(f))) * robot.dir;
        const fx: usize = @intCast(@mod(fpos[0], W));
        const fy: usize = @intCast(@mod(fpos[1], H));
        const bi = fy * W + fx;
        const off = bi / 64;
        const bit = bi % 64;
        frame[off] |= @as(u64, 1) << @as(u6, @intCast(bit));
    }
    var tot: u16 = 0;
    const bvf: *[FRAME_SIZE / 4]@Vector(32, u8) = @ptrCast(@alignCast(frame));
    for (bvf) |bv| tot += std.simd.countElementsWithValue(bv, 255);
    return tot;
}

pub fn score_range(ctx: *Context, fmin: usize, fmax: usize) void {
    var frame = [_]@Vector(32, u8){@splat(0)} ** (FRAME_SIZE / 4);
    for (fmin..fmax) |f| {
        const tot = flscore(ctx, f, @ptrCast(&frame));
        if (tot > 10) ctx.egg = f;
        if (ctx.egg > 0) break;
    }
    ctx.wait_group.finish();
}

pub fn part2_long(ctx: *Context) []u8 {
    // this will look through up to all 101*103 states in parallel, ~440 in each thread
    ctx.wait_group.reset();
    const max_size = W * H;
    const num_threads = 24;
    const block_size = (max_size + num_threads - 1) / num_threads;
    for (0..num_threads) |f| {
        ctx.wait_group.start();
        common.pool.spawn(score_range, .{ ctx, f * block_size, (f + 1) * block_size }) catch unreachable;
    }
    common.pool.waitAndWork(&ctx.wait_group);
    return std.fmt.allocPrint(ctx.allocator, "{any}", .{ctx.egg}) catch unreachable;
}

// compute horizontal and vertical variance
pub fn hvscore(ctx: *Context, f: usize) @Vector(2, i32) {
    var hsum = [_]i32{0} ** W;
    var htot: i32 = 0;
    var vsum = [_]i32{0} ** H;
    var vtot: i32 = 0;
    const cnt: i32 = @intCast(ctx.robots.len);
    for (ctx.robots) |robot| {
        const fpos = robot.pos + @as(vec2, @splat(@intCast(f))) * robot.dir;
        const fx = @mod(fpos[0], W);
        const fy = @mod(fpos[1], H);
        hsum[@intCast(fx)] += 1;
        vsum[@intCast(fy)] += 1;
        htot += fx;
        vtot += fy;
    }
    // h, v mean
    const hexp = @divFloor(htot, cnt);
    const vexp = @divFloor(htot, cnt);
    var devx: i32 = 0;
    for (hsum, 0..) |s, x| {
        const ix: i32 = @intCast(x);
        devx += s * (ix - hexp) * (ix - hexp);
    }
    var devy: i32 = 0;
    for (vsum, 0..) |s, y| {
        const iy: i32 = @intCast(y);
        devy += s * (iy - vexp) * (iy - vexp);
    }
    return @Vector(2, i32){ @divFloor(devx, cnt), @divFloor(devy, cnt) };
}

// find minimum X/Y variances across all frames
pub fn hvmins(ctx: *Context) @Vector(2, u32) {
    var min: @Vector(2, i32) = @splat(9999);
    var pos: @Vector(2, u32) = @splat(0);
    for (0..H) |f| {
        const hv = hvscore(ctx, f);
        inline for (0..2) |i| {
            if (min[i] > hv[i]) {
                min[i] = hv[i];
                pos[i] = @intCast(f);
            }
        }
    }
    return pos;
}

// construct answer by finding P that
// P == Xmin mod W
// P == Ymin mod H
pub fn part2(ctx: *Context) []u8 {
    var tmp = hvmins(ctx);
    // values are tiny, this loop is fastest way to compute.
    while (tmp[0] != tmp[1]) {
        if (tmp[0] < tmp[1]) {
            tmp[0] += @intCast(W);
        } else {
            tmp[1] += @intCast(H);
        }
    }
    return std.fmt.allocPrint(ctx.allocator, "{any}", .{tmp[0]}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "14",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};

pub fn main() void {
    common.run_day(work);
}
