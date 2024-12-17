const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @import("ray.zig").ray;
const sol = @import("src").day17;

const VisState = struct {
    ctx: *sol.Context,
    frames: std.ArrayList(u64),
    num: u64,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.frames = @TypeOf(vis.frames).init(allocator);
    vis.num = sol.solve_rec(vis.ctx, 0, 0, &vis.frames);
    std.debug.print("prepared {d} frames\n", .{vis.frames.items.len});
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > vis.frames.items.len + 60) return true;
    var buf = [_]u8{0} ** 256;
    _ = std.fmt.bufPrintZ(&buf, "Program: {o}", .{vis.ctx.m.program}) catch unreachable;
    a.fsize = 32;
    a.writeXY(&buf, 2, 0, ray.RAYWHITE);
    var cidx = idx;
    if (idx >= vis.frames.items.len) cidx = vis.frames.items.len - 1;
    _ = std.fmt.bufPrintZ(&buf, "Input A (Base 8): {o}", .{vis.frames.items[cidx]}) catch unreachable;
    a.writeXY(&buf, 2, 1, ray.RAYWHITE);
    vis.ctx.m.reset(vis.frames.items[cidx]);
    a.fsize = 16;
    const debugger = struct {
        var ypos: c_int = 6;
        var xpos: c_int = 2;
        var aa: *ASCIIRay = undefined;
        fn debug(comptime format: []const u8, args: anytype) void {
            var buf2 = [_]u8{0} ** 256;
            const s = std.fmt.bufPrintZ(&buf2, format, args) catch unreachable;
            var dx = xpos;
            var dy = ypos;
            while (dy > 1080 / 16 - 1) {
                dy = dy - 1080 / 16 - 1 + 7;
                dx += 80;
            }
            aa.writeXY(&buf2, dx, dy, ray.GREEN);
            if (s[s.len - 1] == '\n') {
                ypos += 1;
                xpos = 1;
            } else xpos += @intCast(s.len + 2);
        }
    };
    debugger.xpos = 1;
    debugger.ypos = 6;
    debugger.aa = a;
    ctx.m.run(debugger.debug);
    a.fsize = 32;
    _ = std.fmt.bufPrintZ(&buf, "Output: {o}", .{vis.ctx.m.out.items}) catch unreachable;
    a.writeXY(&buf, 2, 2, ray.RAYWHITE);
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 32, .fps = 15 },
};
