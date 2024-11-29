const std = @import("std");
const ASCIIRay = @import("asciiray.zig").ASCIIRay;

pub fn main() !void {
    // comptime init static context to null
    const ctx = struct {
        var a: *ASCIIRay = @ptrFromInt(@alignOf(ASCIIRay));
    };
    // real init at runtime. Use arena allocator for all context stuff.
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    ctx.a = try ASCIIRay.init(allocator, 1920, 1080, 15, true, 24);
    try ctx.a.loop(struct {
        pub fn render(idx: c_int) bool {
            if (idx > 100) return true;
            ctx.a.writeln("All work and no play makes Jack a dull boy");
            return false;
        }
    }.render);
}
