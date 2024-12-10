const std = @import("std");
const fs = std.fs;
const FFPipe = @import("ffpipe.zig").FFPipe;
const ray = @cImport({
    @cInclude("raylib.h");
});
const Allocator = std.mem.Allocator;

pub const Viewer = struct {
    allocator: Allocator,
    width: c_int,
    height: c_int,
    fps: c_int,
    title: []const u8,
    rec: bool,
    ff: *FFPipe,

    pub fn init(allocator: Allocator, w: c_int, h: c_int, fps: c_int, t: []const u8, rec: bool) !*Viewer {
        ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);
        ray.InitWindow(w, h, t.ptr);
        var v = try allocator.create(Viewer);
        v.width = w;
        v.height = h;
        v.fps = fps;
        v.title = t;
        v.rec = rec;
        v.allocator = allocator;
        return v;
    }

    pub fn loop(self: *Viewer, render: *const fn (idx: usize) bool) !void {
        var cnt: usize = 0;
        var done: bool = false;
        defer ray.CloseWindow();
        ray.SetTargetFPS(self.fps);
        const scale = ray.GetWindowScaleDPI().x;
        if (self.rec)
            self.ff = try FFPipe.init(self.allocator, self.width, self.height, self.fps, @intFromFloat(scale));
        while (!ray.WindowShouldClose() and !done) {
            ray.BeginDrawing();
            ray.ClearBackground(ray.BLACK);
            done = render(cnt);
            cnt += 1;
            ray.EndDrawing();
            if (self.rec) {
                const img = ray.LoadImageFromScreen();
                self.ff.put(img.data.?, img.height * img.width * 4);
                ray.MemFree(img.data);
            }
        }
        if (self.rec)
            self.ff.finish();
    }
};
