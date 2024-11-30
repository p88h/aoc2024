const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn read_lines(allocator: Allocator, filename: []const u8) ![][]const u8 {
    // potentially common stuff
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const file_buffer = try file.readToEndAlloc(allocator, 32768);
    var lines = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitAny(u8, file_buffer, "\n");
    while (iter.next()) |line| try lines.append(line);
    return lines.items;
}
