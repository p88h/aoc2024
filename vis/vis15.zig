const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @import("ray.zig").ray;
const sol = @import("src").day15;

const VisState = struct {
    ctx: *sol.Context,
    ins: usize,
    idx: usize,
    tiles: ray.Texture2D,
    run: bool,
    turbo: bool,
    ascii: bool,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.ctx.map = vis.ctx.map2;
    vis.ctx.robot = vis.ctx.robot2;
    vis.ctx.dimx *= 2;
    vis.ins = 0;
    vis.idx = 0;
    vis.run = false;
    vis.turbo = false;
    vis.ascii = false;
    vis.tiles = ray.LoadTexture("resources/tileset.png");
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    // 5 min limit
    if (idx > 5 * 60 * 30) return true;
    var buf = [_]u8{0} ** 128;
    buf[1] = 0;
    for (0..ctx.dimy) |y| {
        for (0..ctx.dimx) |x| {
            const px = (26 + x) * 14 - 4;
            const py = (3 + y) * 20;
            buf[0] = ctx.tile(sol.Vec2{ @intCast(y), @intCast(x) }).*;
            if (vis.ascii) {
                var col = ray.RAYWHITE;
                if (y == ctx.robot[0] and x == ctx.robot[1]) col = ray.GREEN;
                a.writeat(&buf, @intCast(px), @intCast(py), col);
                continue;
            }
            var rect: ray.Rectangle = .{ .x = 0, .width = 18, .height = 20 };
            switch (buf[0]) {
                '@' => rect.y = 40,
                '#' => {
                    rect.y = 20;
                    if (x % 2 == 1) rect.x = 14;
                },
                '[' => rect.y = 0,
                ']' => {
                    rect.y = 0;
                    rect.x = 14;
                },
                else => {
                    rect.y = 40;
                    rect.x = 14;
                },
            }
            ray.DrawTexturePro(
                vis.tiles,
                rect,
                .{ .x = @floatFromInt(px), .y = @floatFromInt(py), .width = rect.width, .height = rect.height },
                .{},
                0.0,
                ray.WHITE,
            );
        }
    }
    if (vis.ins < ctx.instructions.len and vis.idx >= ctx.instructions[vis.ins].len) {
        vis.ins += 1;
        vis.idx = 0;
    }
    if (vis.ins >= ctx.instructions.len) return true;
    var ch: u8 = ctx.instructions[vis.ins][vis.idx];
    _ = std.fmt.bufPrintZ(&buf, "Press Space for nxt move: {c} (or use arrow keys).", .{ch}) catch unreachable;
    a.writeXY(&buf, 46, 0, ray.RAYWHITE);
    _ = std.fmt.bufPrintZ(&buf, "Autorun: {any} (toggle with Enter)", .{vis.run}) catch unreachable;
    a.writeXY(&buf, 46, 1, ray.RAYWHITE);
    _ = std.fmt.bufPrintZ(&buf, "ASCII mode: {any} (toggle with F1)", .{vis.ascii}) catch unreachable;
    a.writeXY(&buf, 96, 1, ray.RAYWHITE);
    _ = std.fmt.bufPrintZ(&buf, "Turbo: {any} (toggle with Tab)", .{vis.turbo}) catch unreachable;
    a.writeXY(&buf, 146, 1, ray.RAYWHITE);
    const key = ray.GetKeyPressed();
    switch (key) {
        ray.KEY_RIGHT => ch = '>',
        ray.KEY_LEFT => ch = '<',
        ray.KEY_UP => ch = '^',
        ray.KEY_DOWN => ch = 'v',
        ray.KEY_SPACE => vis.idx += 1,
        ray.KEY_ENTER => {
            ch = '_';
            vis.run = !vis.run;
        },
        ray.KEY_F1 => {
            ch = '_';
            vis.ascii = !vis.ascii;
        },
        ray.KEY_TAB => {
            ch = '_';
            vis.turbo = !vis.turbo;
        },
        else => if (!vis.run) {
            ch = '_';
        } else {
            vis.idx += 1;
        },
    }
    var tot: usize = 0;
    while (true) {
        const prev = ctx.robot;
        switch (ch) {
            '^' => tot = ctx.move2(sol.Vec2{ -1, 0 }),
            'v' => tot = ctx.move2(sol.Vec2{ 1, 0 }),
            '<' => tot = ctx.move2(sol.Vec2{ 0, -1 }),
            '>' => tot = ctx.move2(sol.Vec2{ 0, 1 }),
            else => {},
        }
        if (!vis.turbo or tot > 0 or std.simd.countTrues(ctx.robot == prev) == 2) break;
        if (vis.run) {
            vis.idx += 1;
            if (vis.idx >= ctx.instructions[vis.ins].len) break;
            ch = ctx.instructions[vis.ins][vis.idx];
        }
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 20, .fps = 30 },
};
