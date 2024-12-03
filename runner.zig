const std = @import("std");
const common = @import("src/common.zig");
const days = @import("src/_days.zig").Days;
const Allocator = std.mem.Allocator;

pub fn print_time(t: u64) void {
    const units = [_][]const u8{ "ns", "µs", "ms" };
    var ui: usize = 0;
    var d = t;
    var r: u64 = 0;
    while (d > 99) {
        r = (d % 1000) / 100;
        d = d / 1000;
        ui += 1;
    }
    std.debug.print("\t{d}.{d} {s}", .{ d, r, units[ui] });
}

pub fn run_day(allocator: Allocator, work: common.Worker) void {
    std.debug.print("day {s}:", .{work.day});
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{work.day}) catch unreachable;
    const buf = common.read_file(allocator, filename);
    const lines = common.split_lines(allocator, buf);
    var t = std.time.Timer.start() catch unreachable;
    const iter = 100000;
    var ctxs = allocator.alloc(*anyopaque, iter) catch unreachable;
    for (0..iter) |i| ctxs[i] = work.parse(allocator, buf, lines);
    print_time(t.read() / iter);
    t.reset();
    for (0..iter) |i| _ = work.part1(ctxs[i]);
    print_time(t.read() / iter);
    t.reset();
    for (0..iter) |i| _ = work.part2(ctxs[i]);
    print_time(t.read() / iter);
    std.debug.print("\n", .{});
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
    std.debug.print("\tparse\tpart1\tpart2\n", .{});
    if (runAll) {
        for (days.all) |work| run_day(allocator, work);
    } else {
        run_day(allocator, days.last);
    }
}
