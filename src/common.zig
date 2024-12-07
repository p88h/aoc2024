const std = @import("std");
const Allocator = std.mem.Allocator;

pub var pool: std.Thread.Pool = undefined;
pub var pool_running = false;
pub var pool_allocator: Allocator = undefined;
pub var pool_arena: std.heap.ThreadSafeAllocator = undefined;

pub fn ensure_pool(allocator: Allocator) void {
    if (!pool_running) {
        pool_arena = .{
            .child_allocator = allocator,
        };
        pool_allocator = pool_arena.allocator();
        pool.init(std.Thread.Pool.Options{ .allocator = pool_allocator }) catch {
            std.debug.panic("failed to init pool\n", .{});
        };
        pool_running = true;
    }
}

pub fn shutdown_pool() void {
    if (pool_running) {
        pool.deinit();
        pool_running = false;
    }
}

pub fn read_file(allocator: Allocator, filename: []const u8) []u8 {
    // potentially common stuff
    var file = std.fs.cwd().openFile(filename, .{}) catch {
        std.debug.panic("file not found: {s}\n", .{filename});
    };
    defer file.close();
    return file.readToEndAlloc(allocator, 65535) catch {
        std.debug.panic("Error reading: {s}\n", .{filename});
    };
}

pub fn split_lines(allocator: Allocator, buf: []u8) [][]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitAny(u8, buf, "\n");
    while (iter.next()) |line| lines.append(line) catch unreachable;
    return lines.items;
}

pub const Worker = struct {
    day: []const u8,
    parse: *const fn (allocator: Allocator, buf: []u8, lines: [][]const u8) *anyopaque,
    part1: *const fn (ctx: *anyopaque) []u8,
    part2: *const fn (ctx: *anyopaque) []u8,
};

pub fn create_ctx(allocator: Allocator, work: Worker) *anyopaque {
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{work.day}) catch unreachable;
    const buf = read_file(allocator, filename);
    const lines = split_lines(allocator, buf);
    return work.parse(allocator, buf, lines);
}

pub fn run_day(work: Worker) void {
    var aa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = aa.deinit();
    ensure_pool(aa.allocator());
    const ctx = create_ctx(pool_allocator, work);
    std.debug.print("{s}\n", .{work.part1(ctx)});
    std.debug.print("{s}\n", .{work.part2(ctx)});
}
