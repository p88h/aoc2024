const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    r.InitWindow(1920, 1080, "Hello RayLib");
    r.SetTargetFPS(60);
    defer r.CloseWindow();

    while (!r.WindowShouldClose()) {
        r.BeginDrawing();
        r.ClearBackground(r.BLACK);
        r.EndDrawing();
    }
}
