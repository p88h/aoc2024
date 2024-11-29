const std = @import("std");
const Allocator = std.mem.Allocator;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;

pub const handler = struct {
    init: *const fn (a: *ASCIIRay) void,
    step: *const fn (a: *ASCIIRay, idx: c_int) bool,
};
