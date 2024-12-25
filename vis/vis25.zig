const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day25;

const VisState = struct {
    ctx: *sol.Context,
    tex: ray.RenderTexture2D,
    num: usize,
    tidx: usize,
    speed: usize,
};

const SCREENW = 2560;

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.tex = ray.LoadRenderTexture(SCREENW, 1080);
    vis.num = 0;
    vis.tidx = 0;
    vis.speed = 1;
    return vis;
}

pub fn lock_and_key(lock: sol.Vec8, key: sol.Vec8, dx: usize, dy: usize, scale: comptime_int) void {
    var kcol = ray.GREEN;
    if (std.simd.countElementsWithValue(lock + key, 7) == 5) kcol = ray.YELLOW;
    for (0..5) |p| {
        for (0..7) |q| {
            var col = ray.BLACK;
            if (lock[p] > q and key[p] > 6 - q) {
                col = ray.RED;
            } else if (lock[p] > q) {
                col = ray.BLUE;
            } else if (key[p] > 6 - q) {
                col = kcol;
            }
            ray.DrawRectangleV(
                .{ .x = @floatFromInt(dx + scale * p), .y = @floatFromInt(dy + scale * q) },
                .{ .x = scale, .y = scale },
                col,
            );
        }
    }
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (vis.tidx >= ctx.keys.len * ctx.locks.len + 30) return true;
    ray.DrawTexturePro(
        vis.tex.texture,
        .{ .x = 0, .y = 0, .width = @floatFromInt(vis.tex.texture.width), .height = @floatFromInt(-vis.tex.texture.height) },
        .{ .x = 0, .y = 0, .width = @floatFromInt(vis.tex.texture.width), .height = @floatFromInt(vis.tex.texture.height) },
        .{ .x = 0, .y = 0 },
        0.0,
        ray.WHITE,
    );
    var buf = [_]u8{' '} ** 64;
    _ = std.fmt.bufPrintZ(&buf, "Matches found: {d}", .{vis.num}) catch unreachable;
    a.writeat(&buf, 4, 0, ray.RAYWHITE);
    const boxnum = SCREENW / (6 * 4);
    for (0..vis.speed) |i| {
        const dx = (vis.num % boxnum) * 6 * 4;
        const dy = (vis.num / boxnum) * 8 * 4 + 16;
        const kidx = vis.tidx / ctx.locks.len;
        const lidx = vis.tidx % ctx.locks.len;
        vis.tidx += 1;
        if (vis.tidx >= ctx.keys.len * ctx.locks.len) break;
        const key = ctx.keys[kidx];
        const lock = ctx.locks[lidx];
        if (i == 0) {
            a.writeat("Now testing:", 4, @intCast(dy + 8 * 4), ray.RAYWHITE);
        }
        lock_and_key(lock, key, i * 6 * 8, dy + 8 * 4 + 16, 8);
        ray.BeginTextureMode(vis.tex);
        if (sol.match(key, lock)) {
            lock_and_key(lock, key, dx, dy, 4);
            vis.num += 1;
        }
        ray.EndTextureMode();
    }
    if (vis.speed < 16 and vis.speed < idx / 60) vis.speed += 1;
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .width = SCREENW, .fsize = 16, .fps = 30 },
};
