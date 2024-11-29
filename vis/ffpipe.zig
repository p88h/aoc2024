const std = @import("std");
const ChildProcess = std.process.Child;
const Allocator = std.mem.Allocator;

pub const FFPipe = struct {
    child: ChildProcess,
    pipe: []c_int,

    pub fn init(allocator: Allocator, width: c_int, height: c_int, fps: c_int) !*FFPipe {
        var f = try allocator.create(FFPipe);
        const res_str = try std.fmt.allocPrint(allocator, "{d}x{d}", .{ width, height });
        const fps_str = try std.fmt.allocPrint(allocator, "{d}", .{fps});
        // TODO: name the file based on the day number
        try std.fs.cwd().deleteFile("out.mp4");
        const args = &[_][]const u8{ "ffmpeg", "-loglevel", "quiet", "-f", "rawvideo", "-pix_fmt", "rgb0", "-s", res_str, "-r", fps_str, "-i", "-", "out.mp4" };
        f.child = ChildProcess.init(args, allocator);
        f.child.stdin_behavior = .Pipe;
        f.child.stdout_behavior = .Close;
        try f.child.spawn();
        return f;
    }

    pub fn put(self: *FFPipe, ptr: *anyopaque, size: c_int) !void {
        const bytes: []const u8 = @as([*]u8, @ptrCast(ptr))[0..@intCast(size)];
        _ = try self.child.stdin.?.write(bytes);
    }

    pub fn finish(self: *FFPipe) !void {
        self.child.stdin.?.close();
        self.child.stdin = null;
        _ = try self.child.wait();
    }
};
