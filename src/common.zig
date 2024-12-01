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

pub const Worker = struct {
    day: []const u8,
    parse: *const fn (allocator: Allocator, lines: [][]const u8) *anyopaque,
    part1: *const fn (ctx: *anyopaque) []u8,
    part2: *const fn (ctx: *anyopaque) []u8,
};

pub fn run_day(work: Worker) void {
    var aa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = aa.deinit();
    const allocator = aa.allocator();
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{work.day}) catch unreachable;
    const lines = read_lines(allocator, filename) catch unreachable;
    const ctx = work.parse(allocator, lines);
    std.debug.print("{s}", .{work.part1(ctx)});
    std.debug.print("{s}", .{work.part2(ctx)});
}
