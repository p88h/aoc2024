const std = @import("std");
const ChildProcess = std.process.Child;
const Allocator = std.mem.Allocator;

pub const FFPipe = struct {
    child: ChildProcess,
    pipe: []c_int,

    pub fn init(allocator: Allocator) !*FFPipe {
        var f = try allocator.create(FFPipe);
        f.child = ChildProcess.init(&[_][]const u8{ "ffmpeg", "-f", "rawvideo", "-pix_fmt", "rgb0", "-s", "1920x1080", "-r", "60", "-i", "-", "out.mp4" }, allocator);
        f.child.stdin_behavior = .Pipe;
        try f.child.spawn();
        return f;
    }

    pub fn put(self: *FFPipe, ptr: *anyopaque, size: c_int) !void {
        const bytes: []const u8 = @as([*]u8, @ptrCast(ptr))[0..@intCast(size)];
        _ = try self.child.stdin.?.write(bytes);
    }

    pub fn finish(self: *FFPipe) void {
        self.child.stdin.?.close();
        _ = try self.child.wait();
        self.child.deinit();
    }
};
