const std = @import("std");
const common = @import("src/common.zig");
const days = @import("_days.zig").Days;
const Allocator = std.mem.Allocator;

pub fn run_day(allocator: Allocator, work: common.Worker) void {
    std.debug.print("day {s}\n", .{work.day});
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{work.day}) catch unreachable;
    const lines = common.read_lines(allocator, filename) catch unreachable;
    const ctx = work.parse(allocator, lines);
    work.part1(ctx);
    work.part2(ctx);
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
