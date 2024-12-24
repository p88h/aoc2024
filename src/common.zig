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
    return file.readToEndAlloc(allocator, 232072) catch {
        std.debug.panic("Error reading: {s}\n", .{filename});
    };
}

pub fn split_lines(allocator: Allocator, buf: []u8) [][]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitAny(u8, buf, "\n");
    while (iter.next()) |line| lines.append(line) catch unreachable;
    // remove last line if empty
    if (lines.items[lines.items.len - 1].len == 0) _ = lines.pop();
    return lines.items;
}

pub const Worker = struct {
    day: []const u8,
    parse: *const fn (allocator: Allocator, buf: []u8, lines: [][]const u8) *anyopaque,
    part1: *const fn (ctx: *anyopaque) []u8,
    part2: *const fn (ctx: *anyopaque) []u8,
};

pub fn download_file(allocator: Allocator, url: []u8, path: []u8, cookie: ?[]const u8) !void {
    std.debug.print("Trying to download {s} from {s}\n", .{ path, url });
    var http_client = std.http.Client{ .allocator = allocator };
    defer http_client.deinit();
    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();
    const res = try http_client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .response_storage = .{ .dynamic = &response },
        .extra_headers = &[_]std.http.Header{.{ .name = "Cookie", .value = cookie orelse "" }},
    });
    if (res.status != .ok)
        return error.FailedToFetchInputFile;
    const dir = try std.fs.cwd().makeOpenPath(std.fs.path.dirname(path).?, .{});
    const file = try dir.createFile(std.fs.path.basename(path), .{});
    defer file.close();
    try file.writeAll(response.items);
}

pub fn get_input(allocator: Allocator, day: []const u8) []u8 {
    const filename = std.fmt.allocPrint(allocator, "input/day{s}.txt", .{day}) catch unreachable;
    std.fs.cwd().access(filename, .{}) catch |err| {
        if (err == error.FileNotFound) {
            var buf = [_]u8{0} ** 1024;
            const cookie = std.fs.cwd().readFile(".cookie", &buf) catch "";
            const url = std.fmt.allocPrint(
                allocator,
                "https://adventofcode.com/2024/day/{s}/input",
                .{day},
            ) catch unreachable;
            download_file(allocator, url, filename, cookie) catch {};
        }
    };
    const buf = read_file(allocator, filename);
    return buf;
}

pub fn create_ctx(allocator: Allocator, work: Worker) *anyopaque {
    const buf = get_input(allocator, work.day);
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
