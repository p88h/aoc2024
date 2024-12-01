const std = @import("std");
const common = @import("src/common.zig");
const days = @import("_days.zig").Days;
const Allocator = std.mem.Allocator;

pub fn run_day(allocator: Allocator, work: common.Worker) void {
    std.debug.print("day {s}\n", .{work.day});
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{work.day}) catch unreachable;
    const lines = common.read_lines(allocator, filename) catch unreachable;
    var t = std.time.Timer.start() catch unreachable;
    const iter = 100000;
    var ctxs = allocator.alloc(*anyopaque, iter) catch unreachable;
    for (0..iter) |i| ctxs[i] = work.parse(allocator, lines);
    std.debug.print("parse: {d}ns\n", .{t.read() / iter});
    t.reset();
    for (0..iter) |i| _ = work.part1(ctxs[i]);
    std.debug.print("part1: {d}ns\n", .{t.read() / iter});
    t.reset();
    for (0..iter) |i| _ = work.part2(ctxs[i]);
    std.debug.print("part2: {d}ns\n", .{t.read() / iter});
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

    if (runAll) {
        for (days.all) |work| run_day(allocator, work);
    } else {
        run_day(allocator, days.last);
    }
}
