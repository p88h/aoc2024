const std = @import("std");
const read_lines = @import("common.zig").read_lines;

pub fn main() void {
    var aa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = aa.deinit();
    const allocator = aa.allocator();
    const lines = read_lines(allocator, "input/day00.txt") catch unreachable;

    std.debug.print("{d}x{d}\n", .{ lines.len, lines[0].len });
}
