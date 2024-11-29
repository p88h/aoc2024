const std = @import("std");
const days = @import("_days.zig").Days;

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
        for (days.all) |fun| {
            try fun();
        }
    } else {
        try days.last();
    }
}
