const std = @import("std");
const days = @import("_days.zig").Days;

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
        day = try std.fmt.parseInt(usize, args[ap], 10);
    }
    try days.all[day].run(rec);
}
