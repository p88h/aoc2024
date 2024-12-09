const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const vec2 = @Vector(2, u32);

pub const Context = struct {
    allocator: Allocator,
    buf: []u8,
    mid: usize,
    files: [10001]vec2,
    space: [10001]vec2,
    index: [10]usize,
};

pub fn parse(allocator: Allocator, buf: []u8, _: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    ctx.buf = buf;
    ctx.allocator = allocator;
    ctx.mid = ctx.buf.len / 2 + 1;
    var free = false;
    var id: u32 = 0;
    var pos: u32 = 0;
    @memset(&ctx.files, vec2{ 0, 0 });
    @memset(&ctx.space, vec2{ 0, 0 });
    @memset(&ctx.index, ctx.mid);
    for (ctx.buf) |c| {
        const v = c - '0';
        if (free) {
            ctx.space[id] = vec2{ pos, v };
            if (ctx.index[v] > id) ctx.index[v] = id;
        } else {
            ctx.files[id] = vec2{ pos, v };
            id += 1;
        }
        pos += v;
        free = !free;
    }
    std.debug.assert(id == ctx.mid);
    // guards
    ctx.files[ctx.mid] = vec2{ pos, 0 };
    ctx.space[ctx.mid] = vec2{ pos, 200000 };
    return ctx;
}

pub fn part1(ctx: *Context) []u8 {
    var files: [10001]vec2 = [_]vec2{vec2{ 0, 0 }} ** 10001;
    var space: [10001]vec2 = [_]vec2{vec2{ 0, 0 }} ** 10001;
    // we'll mutate this, let's keep intact for part2
    @memcpy(&files, &ctx.files);
    @memcpy(&space, &ctx.space);
    // first free space on the left
    var left: usize = 0;
    // block on thr right
    var right = ctx.mid;
    var dst = &space[left];
    var tot: u64 = 0;
    var skip = false;
    while (right > 0 and !skip) {
        right -= 1;
        var src = &files[right];
        while (src[1] > 0) {
            // skip all empty 'spaces'
            while (left < ctx.mid and dst[1] == 0) {
                left += 1;
                dst = &space[left];
            }
            // check if we can 'defragment'
            if (dst[0] < src[0]) {
                tot += @intCast(dst[0] * right);
                // update free space
                dst[0] += 1;
                dst[1] -= 1;
            } else {
                // take the first digit, doesn't matter.
                tot += @intCast(src[0] * right);
                src[0] += 1;
                skip = true;
            }
            src[1] -= 1;
        }
    }
    while (right > 0) {
        const src = &files[right];
        for (src[0]..src[0] + src[1]) |p| tot += @intCast(p * right);
        right -= 1;
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    var space = ctx.space;
    var files = ctx.files;
    var tot: u64 = 0;
    var last = ctx.mid;
    var skip: usize = 10;
    while (last > 0) {
        last -= 1;
        const fsize = files[last][1];
        if (skip <= fsize) {
            for (files[last][0]..files[last][0] + fsize) |p| tot += @intCast(last * p);
            continue;
        }
        var first: usize = fsize;
        // look for larger spaces too if they are earlier
        for (fsize..10) |s| {
            if (ctx.index[s] < ctx.index[first]) first = s;
        }
        // id of the target space
        var dest = ctx.index[first];
        // can move left -- just compare the indices (space indexes are shifted right)
        if (dest <= last) {
            const target = &space[dest];
            std.debug.assert(files[last][0] > target[0]);
            // update this file
            files[last][0] = target[0];
            std.debug.assert(target[1] >= fsize);
            // update this space
            target[0] += fsize;
            target[1] -= fsize;
            // maybe insert this space into the index
            if (dest < ctx.index[target[1]]) ctx.index[target[1]] = dest;
            // scan the index forward, look for next block of the same size
            while (dest < ctx.mid and space[dest][1] != first) dest += 1;
            ctx.index[first] = dest;
        } else {
            // skip anything this size or larger from now on
            skip = fsize;
        }
        // now compute the checksum for this file
        for (files[last][0]..files[last][0] + fsize) |p| tot += @intCast(last * p);
    }
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "09",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
