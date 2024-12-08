const std = @import("std");
const ChildProcess = std.process.Child;
const Allocator = std.mem.Allocator;

pub const FFPipe = struct {
    child: ChildProcess,
    pipe: []c_int,
    running: bool,

    pub fn init(allocator: Allocator, width: c_int, height: c_int, fps: c_int, scale: c_int) !*FFPipe {
        var f = try allocator.create(FFPipe);
        const res1_str = try std.fmt.allocPrint(allocator, "{d}x{d}", .{ width * scale, height * scale });
        const res2_str = try std.fmt.allocPrint(allocator, "{d}x{d}", .{ width, height });
        const fps_str = try std.fmt.allocPrint(allocator, "{d}", .{fps});
        // TODO: name the file based on the day number
        std.fs.cwd().deleteFile("out.mp4") catch {};
        const args = &[_][]const u8{
            "ffmpeg",
            "-loglevel",
            "quiet",
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb0",
            "-s",
            res1_str,
            "-r",
            fps_str,
            "-i",
            "-",
            "-s",
            res2_str,
            "out.mp4",
        };
        f.child = ChildProcess.init(args, allocator);
        f.child.stdin_behavior = .Pipe;
        f.child.stdout_behavior = .Close;
        f.running = true;
        f.child.spawn() catch |err| {
            std.debug.print("Error running ffmpeg, recording disabled:\n{s}", .{@typeName(@TypeOf(err))});
            f.running = false;
        };
        return f;
    }

    pub fn put(self: *FFPipe, ptr: *anyopaque, size: c_int) void {
        if (self.running) {
            const bytes: []const u8 = @as([*]u8, @ptrCast(ptr))[0..@intCast(size)];
            self.child.stdin.?.writeAll(bytes) catch |err| {
                std.debug.print("Error writing to ffmpeg, recording stopped:\n{s}", .{@typeName(@TypeOf(err))});
                self.finish();
            };
        }
    }

    pub fn finish(self: *FFPipe) void {
        if (self.running) {
            self.running = false;
            self.child.stdin.?.close();
            self.child.stdin = null;
            _ = self.child.wait() catch |err| {
                std.debug.print("Error waiting for ffmpeg (ignored):\n{s}", .{@typeName(@TypeOf(err))});
            };
        }
    }
};
