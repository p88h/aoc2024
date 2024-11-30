const std = @import("std");
const fs = std.fs;
const FFPipe = @import("ffpipe.zig").FFPipe;
const ray = @cImport({
    @cInclude("raylib.h");
});
const Allocator = std.mem.Allocator;

pub const Viewer = struct {
    width: c_int,
    height: c_int,
    fps: c_int,
    title: []const u8,
    rec: bool,
    ff: *FFPipe,

    pub fn init(allocator: Allocator, w: c_int, h: c_int, fps: c_int, t: []const u8, rec: bool) !*Viewer {
        ray.InitWindow(w, h, t.ptr);
        ray.SetTargetFPS(fps);
        var v = try allocator.create(Viewer);
        v.width = w;
        v.height = h;
        v.fps = fps;
        v.title = t;
        v.rec = rec;
        if (rec)
            v.ff = try FFPipe.init(allocator, w, h, fps);
        return v;
    }

    pub fn loop(self: *Viewer, render: *const fn (idx: c_int) bool) !void {
        var cnt: c_int = 0;
        var done: bool = false;
        defer ray.CloseWindow();
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
