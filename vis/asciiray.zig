const std = @import("std");
const fs = std.fs;
const Viewer = @import("viewer.zig").Viewer;
const ray = @cImport({
    @cInclude("raylib.h");
});
const Allocator = std.mem.Allocator;

pub const ASCIIRay = struct {
    font: ray.Font,
    fsize: f32,
    cx: f32,
    cy: f32,
    v: *Viewer,
    render_fn: *const fn (a: *ASCIIRay, idx: c_int) bool,

    const font_name = "Inconsolata-SemiBold.ttf";
    const font_file = "resources/" ++ font_name;
    const font_uri = "https://github.com/googlefonts/Inconsolata/raw/main/fonts/ttf/" ++ font_name;

    pub fn init(allocator: Allocator, w: c_int, h: c_int, fps: c_int, rec: bool, size: c_int) !*ASCIIRay {
        fs.cwd().access(font_file, .{}) catch |err| {
            if (err == error.FileNotFound) {
                std.io.getStdOut().writeAll("Try downloading the font " ++ font_file ++ "\n") catch unreachable;
                var http_client = std.http.Client{ .allocator = allocator };
                defer http_client.deinit();
                var response = std.ArrayList(u8).init(allocator);
                defer response.deinit();
                const res = try http_client.fetch(.{
                    .location = .{ .url = font_uri },
                    .method = .GET,
                    .response_storage = .{ .dynamic = &response },
                });
                if (res.status != .ok)
                    return error.FailedToFetchInputFile;
                const dir = try fs.cwd().makeOpenPath(fs.path.dirname(font_file).?, .{});
                const file = try dir.createFile(fs.path.basename(font_file), .{});
                defer file.close();
                try file.writeAll(response.items);
            }
        };
        var a = try allocator.create(ASCIIRay);
        a.v = try Viewer.init(allocator, w, h, fps, "ASCII Ray", rec);
        a.font = ray.LoadFontEx(font_file, size, null, 256);
        try std.io.getStdOut().writer().print("Font texture id: {d}", .{a.font.texture.id});
        a.fsize = @as(f32, @floatFromInt(size));
        a.cy = 0;
        a.cx = 0;
        return a;
    }

    pub fn write(self: *ASCIIRay, msg: []const u8) void {
        ray.DrawTextEx(self.font, msg.ptr, .{ .x = self.cx, .y = self.cy }, self.fsize, 1, ray.RAYWHITE);
        ray.DrawText(msg.ptr, @intFromFloat(self.cx), @intFromFloat(self.cy + self.fsize), @intFromFloat(self.fsize), ray.RAYWHITE);
        self.cx += @as(f32, @floatFromInt(msg.len)) * (self.fsize / 2);
    }

    pub fn writeln(self: *ASCIIRay, msg: []const u8) void {
        self.write(msg);
        self.cx = 0;
        self.cy += self.fsize;
        const maxy = @as(f32, @floatFromInt(self.v.height));
        if (self.cy > maxy) self.cy -= maxy;
    }

    pub fn writeXY(self: *ASCIIRay, msg: []const u8, x: f32, y: f32) void {
        self.cx = x * self.fsize / 2;
        self.cy = y * self.fsize;
        self.write(msg);
    }

    pub fn loop(self: *ASCIIRay, render: *const fn (idx: c_int) bool) !void {
        try self.v.loop(render);
    }
};
