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

pub fn Worker(comptime T: type) type {
    return struct {
        parse: *const fn (allocator: Allocator, lines: [][]const u8) *T,
        part1: *const fn (ctx: *T) void,
        part2: *const fn (ctx: *T) void,
    };
}

pub fn run_day(comptime T: type, day: []const u8, work: Worker(T)) void {
    var aa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = aa.deinit();
    const allocator = aa.allocator();
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{day}) catch unreachable;
    const lines = read_lines(allocator, filename) catch unreachable;
    const ctx = work.parse(allocator, lines);
    work.part1(ctx);
    work.part2(ctx);
}
