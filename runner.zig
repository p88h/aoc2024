const std = @import("std");
const days = @import("_days.zig").Days;

pub fn main() !void {
    for (days.all) |fun| {
        try fun();
    }
}
