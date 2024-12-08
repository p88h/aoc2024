const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});
const sol = @import("src").day08;

const Ball = struct {
    pos: ray.Vector2,
    speed: ray.Vector2,
    radius: f32,
    cnt: i32,
    color: ray.Color,
};

const VisState = struct {
    ctx: *sol.Context,
    balls: std.ArrayList(Ball),
    marks: [64][64]i32 = [_][64]i32{[_]i32{0} ** 64} ** 64,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    const ctx = vis.ctx;
    vis.balls = std.ArrayList(Ball).init(allocator);
    for (0..80) |i| {
        if (ctx.cnt[i] == 0) continue;
        for (0..ctx.cnt[i] - 1) |j| {
            for (j + 1..ctx.cnt[i]) |k| {
                const x1 = ctx.pos[i][j * 2];
                const y1 = ctx.pos[i][j * 2 + 1];
                const x2 = ctx.pos[i][k * 2];
                const y2 = ctx.pos[i][k * 2 + 1];
                const dx = x1 - x2;
                const dy = y1 - y2;
                const ball1 = Ball{
                    .pos = ray.Vector2{ .x = @floatFromInt(x1), .y = @floatFromInt(y1) },
                    .speed = ray.Vector2{ .x = @floatFromInt(dx), .y = @floatFromInt(dy) },
                    .radius = 16.0,
                    .color = ray.RED,
                    .cnt = 0,
                };
                vis.balls.append(ball1) catch unreachable;
                const ball2 = Ball{
                    .pos = ray.Vector2{ .x = @floatFromInt(x2), .y = @floatFromInt(y2) },
                    .speed = ray.Vector2{ .x = @floatFromInt(-dx), .y = @floatFromInt(-dy) },
                    .radius = 16.0,
                    .color = ray.GREEN,
                    .cnt = 0,
                };
                vis.balls.append(ball2) catch unreachable;
            }
        }
    }
    // scaling
    for (0..vis.balls.items.len) |i| {
        var ball = &vis.balls.items[i];
        ball.pos.x = ball.pos.x * 20.0 + 460;
        ball.pos.y = ball.pos.y * 20.0 + 40;
    }
    for (0..ctx.dim) |y| {
        for (0..ctx.dim) |x| {
            vis.marks[y][x] = 0;
        }
    }
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > 30 * 60) return true;
    var siz = idx % 20; // 0..19
    if (siz < 10) siz = 20 - siz; // 10..20
    siz = (20 - siz) / 2 + 2;
    var buf = [2]u8{ 0, 0 };
    for (0..ctx.dim) |y| {
        const py: c_int = @intCast(y * 20 + 40);
        for (0..ctx.dim) |x| {
            const px: c_int = @intCast(x * 20 + 460);
            switch (vis.marks[y][x]) {
                0 => ray.DrawRectangleLines(px - 8, py - 8, 16, 16, ray.DARKGRAY),
                1 => ray.DrawRectangle(px - 8, py - 8, 16, 16, ray.BLUE),
                else => {
                    ray.DrawRectangle(px - 8, py - 8, 16, 16, ray.DARKBROWN);
                    ray.DrawRectangleLines(px - 8, py - 8, 16, 16, ray.LIGHTGRAY);
                },
            }
            if (vis.marks[y][x] == 1 and idx % 20 == 0) vis.marks[y][x] = 2;
            if (ctx.lines[y][x] != '.') {
                buf[0] = ctx.lines[y][x];
                a.writeat(&buf, px - 4, py - 8, ray.WHITE);
            }
        }
    }
    for (0..vis.balls.items.len) |i| {
        if (i / 2 > idx / 20) break;
        var ball = &vis.balls.items[i];
        if (ball.pos.x < 0 or ball.pos.x > 1920 or ball.pos.y < 0 or ball.pos.y > 1080) continue;
        if (ball.pos.x >= 460 and ball.pos.y >= 40 and idx % 20 == 0) {
            const rx: usize = @intFromFloat(ball.pos.x / 20 - 23);
            const ry: usize = @intFromFloat(ball.pos.y / 20 - 2);
            ball.cnt += 1;
            if (rx <= ctx.dim and ry <= ctx.dim) vis.marks[ry][rx] = ball.cnt;
        }
        ray.DrawCircleV(ball.pos, @floatFromInt(siz), ball.color);
        ray.DrawCircleLinesV(ball.pos, @floatFromInt(siz), ray.YELLOW);
        ball.pos.x += ball.speed.x;
        ball.pos.y += ball.speed.y;
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 16, .fps = 30 },
};
