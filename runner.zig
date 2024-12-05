const std = @import("std");
const common = @import("src/common.zig");
const days = @import("src/_days.zig").Days;
const Allocator = std.mem.Allocator;

fn print_time_(t: u64, fmax: comptime_int) void {
    const units = [_][]const u8{ "ns", "µs", "ms" };
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

pub fn run_day(allocator: Allocator, work: common.Worker) u64 {
    std.debug.print("day {s}:", .{work.day});
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{work.day}) catch unreachable;
    const buf = common.read_file(allocator, filename);
    const lines = common.split_lines(allocator, buf);
    var t = std.time.Timer.start() catch unreachable;
    const iter = 100000;
    var ctxs = allocator.alloc(*anyopaque, iter) catch unreachable;
    for (0..iter) |i| ctxs[i] = work.parse(allocator, buf, lines);
    const t1 = t.read();
    print_time(t1 / iter);
    t.reset();
    for (0..iter) |i| _ = work.part1(ctxs[i]);
    const t2 = t.read();
    print_time(t2 / iter);
    t.reset();
    for (0..iter) |i| _ = work.part2(ctxs[i]);
    const t3 = t.read();
    print_time(t3 / iter);
    print_time((t1 + t2 + t3) / iter);
    std.debug.print("\n", .{});
    return ((t1 + t2 + t3) / iter);
}

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var runAll = false;
    var runBench = false;

    for (args) |arg| {
        if (std.mem.eql(u8, arg, "all")) runAll = true;
        if (std.mem.eql(u8, arg, "bench")) runBench = true;
    }
    std.debug.print("\tparse\tpart1\tpart2\ttotal\n", .{});
    if (runAll) {
        var all: u64 = 0;
        for (days.all) |work| all += run_day(allocator, work);
        std.debug.print("\nall days total: ", .{});
        print_time_(all, 999);
        std.debug.print("\n", .{});
    } else {
        _ = run_day(allocator, days.last);
    }
}
