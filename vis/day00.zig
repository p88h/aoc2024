const std = @import("std");
const handler = @import("common.zig").handler;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;

pub fn init(_: *ASCIIRay) void {}

pub fn step(a: *ASCIIRay, idx: c_int) bool {
    if (idx > 100) return true;
    a.writeln("All work and no play makes Jack a dull boy");
    return false;
}

pub const handle = handler{ .init = init, .step = step };
