const std = @import("std");
const days = @import("days.zig").days;

pub fn main() !void {
    // parse arguments
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    var ap: usize = 1;
    var rec = false;
    var day: usize = days.all.len - 1;
    if (args.len > ap and std.mem.eql(u8, args[ap], "rec")) {
        std.debug.print("Recording mode on\n", .{});
        rec = true;
        ap += 1;
    }
    if (args.len > ap) {
        day += 1;
    }
    try days.all[day].run(rec);
}
