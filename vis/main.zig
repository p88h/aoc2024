const std = @import("std");
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const handler = @import("common.zig").handler;

pub fn main() !void {
    // somewhat less dynamic than runner, but meh.
    const days = struct {
        pub const day00 = @import("day00.zig").handle;
        pub const all = [_]handler{day00};
    };
    const ctx = struct {
        // comptime init static context to null
        var a: *ASCIIRay = @ptrFromInt(@alignOf(ASCIIRay));
        // this is simpler
        var handle: handler = days.all[days.all.len - 1];
    };
    // real init at runtime. Use arena allocator for all context stuff.
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var ap: usize = 1;
    var rec = false;
    var day: usize = days.all.len - 1;
    if (args.len > ap and std.mem.eql(u8, args[ap], "rec")) {
        rec = true;
        ap += 1;
    }
    if (args.len > ap) {
        day += 1;
    }
    ctx.a = try ASCIIRay.init(allocator, 1920, 1080, 15, rec, 24);
    ctx.handle = days.all[day];
    try ctx.a.loop(struct {
        pub fn render(idx: c_int) bool {
            return ctx.handle.step(ctx.a, idx);
        }
    }.render);
}
