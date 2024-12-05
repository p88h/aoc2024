const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @cImport({
    @cInclude("raylib.h");
});
const sol = @import("src").day00;

pub fn init(allocator: Allocator, _: *ASCIIRay) *anyopaque {
    return common.create_ctx(allocator, sol.work);
}

pub fn step(ptr: *anyopaque, a: *ASCIIRay, idx: usize) bool {
    const ctx: *sol.Context = @alignCast(@ptrCast(ptr));
    if (idx > 100) return true;
    a.writeln(ctx.lines[0]);
    return false;
}

pub const handle = handler{ .init = init, .step = step };
