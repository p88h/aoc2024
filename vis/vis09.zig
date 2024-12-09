const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});
const sol = @import("src").day09;

const VisState = struct { ctx: *sol.Context, prev: usize, cluster: usize, done: usize, speed: usize, size: usize };

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.speed = 1;
    vis.cluster = vis.ctx.mid - 1;
    vis.prev = vis.cluster + 1;
    vis.done = 0;
    vis.size = vis.ctx.files[vis.cluster][0] + vis.ctx.files[vis.cluster][1];
    vis.size = (vis.size + 629) / 630;
    vis.size *= 630;
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > 60 * 60) return true;
    // Norton blue
    ray.ClearBackground(.{ .r = 0, .g = 0, .b = 175 });
    // Menu bars
    ray.DrawRectangle(0, 0, 1920, 16, .{ .r = 0, .g = 168, .b = 175, .a = 255 });
    ray.DrawRectangle(0, 1080 - 16, 1920, 16, .{ .r = 0, .g = 168, .b = 175, .a = 255 });
    a.writeXY("Optimize    Configure    Information    Quit!", 2, 0, ray.BLACK);
    a.writeXY("F1=Help", 230, 0, ray.BLACK);
    a.writeat("Amphibian Disk Utilities (c) 1518-2024 North Pole Corporation (R) of the North Pole (TM)", 16, 1080 - 16, ray.BLACK);
    a.writeat("Speed Disk", 1816, 1080 - 16, ray.BLACK);

    ray.DrawRectangleLines(15, 960, 936, 96, ray.YELLOW);
    ray.DrawRectangleLines(968, 960, 940, 96, ray.YELLOW);
    a.writeXY("Status", 57, 59, ray.YELLOW);
    a.writeXY("Legend", 178, 59, ray.YELLOW);
    var buf = [_]u8{0} ** 64;
    var s = std.fmt.bufPrint(&buf, "Cluster {d}", .{vis.cluster}) catch unreachable;
    buf[s.len] = 0;
    a.writeXY(&buf, 4, 61, ray.LIGHTGRAY);
    const pct = (100 * vis.done / ctx.mid);
    // percent complete
    s = std.fmt.bufPrint(&buf, "{d}%", .{pct}) catch unreachable;
    buf[s.len] = 0;
    a.writeXY(&buf, 114, 61, ray.LIGHTGRAY);
    // percent bar
    ray.DrawRectangle(30, 994, @intCast(pct * 9), 14, ray.WHITE);
    ray.DrawRectangle(@intCast(30 + pct * 9), 994, @intCast((100 - pct) * 9), 14, ray.DARKGRAY);
    // time
    const m = idx / (60 * 60);
    const s1 = (idx / 60) % 60;
    const s2 = (100 * (idx % 60)) / 60;
    s = std.fmt.bufPrint(&buf, "Elapsed Time: {d:02}:{d:02}:{d:02}", .{ m, s1, s2 }) catch unreachable;
    buf[s.len] = 0;
    a.writeXY(&buf, 49, 63, ray.LIGHTGRAY);

    // second box - legend
    ray.DrawRectangle(984, 978, 8, 14, ray.LIGHTGRAY);
    a.writeXY("Used", 126, 61, ray.LIGHTGRAY);
    ray.DrawRectangle(984, 994, 8, 14, ray.DARKGRAY);
    a.writeXY("Unused", 126, 62, ray.LIGHTGRAY);
    ray.DrawRectangle(984, 1010, 8, 14, ray.GREEN);
    a.writeXY("Done", 126, 63, ray.LIGHTGRAY);
    for (0..vis.size) |p| {
        const dx: c_int = @intCast((p % 630) * 3 + 15);
        const dy: c_int = @intCast((p / 630) * 6 + 32);
        ray.DrawRectangle(dx, dy, 2, 5, ray.DARKGRAY);
    }
    for (0..ctx.mid) |i| {
        const src = ctx.files[i];
        for (src[0]..src[0] + src[1]) |p| {
            const dx: c_int = @intCast((p % 630) * 3 + 15);
            const dy: c_int = @intCast((p / 630) * 6 + 32);
            if (i >= ctx.mid - vis.done) {
                ray.DrawRectangle(dx, dy, 2, 5, ray.GREEN);
            } else {
                ray.DrawRectangle(dx, dy, 2, 5, ray.WHITE);
            }
        }
    }
    vis.prev = vis.cluster;
    for (0..vis.speed) |_| {
        if (vis.done < ctx.mid) {
            _ = sol.defrag_file(ctx, vis.cluster);
            vis.done += 1;
            if (vis.cluster > 0) vis.cluster -= 1;
        }
    }
    if (idx > 180) vis.speed = 2;
    if (idx > 360) vis.speed = 3;
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 16, .fps = 60 },
};
