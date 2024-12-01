const std = @import("std");
const handler = @import("handler.zig").handler;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;

pub fn init(_: Allocator, _: *ASCIIRay) *anyopaque {
    return @ptrFromInt(@alignOf(anyopaque));
}

pub fn step(_: *anyopaque, a: *ASCIIRay, idx: usize) bool {
    if (idx > 100) return true;
    a.writeln("All work and no play makes Jack a dull boy");
    return false;
}

pub const handle = handler{ .init = init, .step = step };
