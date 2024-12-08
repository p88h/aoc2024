const std = @import("std");
const common = @import("src/common.zig");
const days = @import("src/_days.zig").Days;
const Allocator = std.mem.Allocator;

fn print_time_(t: u64, fmax: comptime_int) void {
    const units = [_][]const u8{ "ns", "µs", "ms", "s" };
    var ui: usize = 0;
    var d = t;
    var r: u64 = 0;
    while (d > fmax) {
        r = (d % 1000) / 100;
        d = d / 1000;
        ui += 1;
    }
    std.debug.print("\t{d}.{d} {s}", .{ d, r, units[ui] });
}

fn print_time(t: u64) void {
    return print_time_(t, 99);
}

fn cmpByLast(ctx: void, a: @Vector(4, u64), b: @Vector(4, u64)) bool {
    return std.sort.asc(u64)(ctx, a[3], b[3]);
}

pub fn run_day(allocator: Allocator, work: common.Worker) u64 {
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{work.day}) catch unreachable;
    const buf = common.read_file(allocator, filename);
    const max_chunks = 100;
    var times = [_]@Vector(4, u64){@splat(0)} ** max_chunks;
    var mid: usize = 0;
    var total_iter: usize = 0;
    var chunk_iter: usize = 10;
    for (0..100) |cnk| {
        std.debug.print("\rday {s}:", .{work.day});
        var task_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer task_arena.deinit();
        var thr_arena = std.heap.ThreadSafeAllocator{ .child_allocator = task_arena.allocator() };
        const task_allocator = thr_arena.allocator();
        var ctxs = task_allocator.alloc(*anyopaque, chunk_iter) catch unreachable;
        const lines = common.split_lines(task_allocator, buf);
        const bufs: [][]u8 = task_allocator.alloc([]u8, chunk_iter) catch unreachable;
        for (0..chunk_iter) |i| {
            bufs[i] = task_allocator.alloc(u8, buf.len) catch unreachable;
            @memcpy(bufs[i], buf);
        }
        var t = std.time.Timer.start() catch unreachable;
        for (0..chunk_iter) |i| ctxs[i] = work.parse(task_allocator, bufs[i], lines);
        times[cnk][0] = t.read() / chunk_iter;
        print_time(times[cnk][0]);
        t.reset();
        var a1: []u8 = undefined;
        var a2: []u8 = undefined;

        for (0..chunk_iter) |i| a1 = work.part1(ctxs[i]);
        times[cnk][1] = t.read() / chunk_iter;
        print_time(times[cnk][1]);
        t.reset();
        for (0..chunk_iter) |i| a2 = work.part2(ctxs[i]);
        times[cnk][2] = t.read() / chunk_iter;
        print_time(times[cnk][2]);
        times[cnk][3] = @reduce(.Add, times[cnk]);
        total_iter += chunk_iter;
        if (cnk >= 10) {
            std.mem.sort(@Vector(4, u64), times[0..cnk], {}, cmpByLast);
            const ofs = cnk / 5;
            const tmin = times[ofs][3];
            const tmax = times[cnk - ofs][3];
            const delta = 100 * (tmax - tmin) / (tmax + tmin);
            mid = cnk / 2;
            std.debug.print("\rday {s}:", .{work.day});
            for (0..4) |i| print_time(times[mid][i]);
            std.debug.print(" (+-{d}%) iter={d}    ", .{ delta, total_iter });
            if (delta <= 1) break;
        } else {
            std.debug.print("\rday {s}:", .{work.day});
            for (0..4) |i| print_time(times[mid][i]);
            std.debug.print(" (...{d}) iter={d}    ", .{ 9 - cnk, total_iter });
        }
        if (chunk_iter < 1000 and times[0][3] * chunk_iter < 10000000) chunk_iter *= 10;
        //std.debug.print("    p1:[{s}] p2:[{s}]      ", .{ a1, a2 });
    }
    std.debug.print("\n", .{});
    return times[mid][3];
}

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var runAll = false;
    var runBench = false;
    var day: usize = days.all.len - 1;
    common.ensure_pool(allocator);

    for (args) |arg| {
        if (std.mem.eql(u8, arg, "all")) {
            runAll = true;
        } else if (std.mem.eql(u8, arg, "bench")) {
            runBench = true;
        } else {
            day = std.fmt.parseInt(usize, arg, 10) catch days.all.len - 1;
        }
    }
    std.debug.print("\tparse\tpart1\tpart2\ttotal\n", .{});
    if (runAll) {
        var all: u64 = 0;
        for (days.all) |work| all += run_day(allocator, work);
        std.debug.print("\nall days total: ", .{});
        print_time_(all, 999);
        std.debug.print("\n", .{});
    } else {
        _ = run_day(allocator, days.all[day]);
    }
}
