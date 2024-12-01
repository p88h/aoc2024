const handler = @import("handler.zig").handler;
// somewhat less dynamic than main unner, but meh.
pub const days = struct {
    pub const vis00 = @import("vis00.zig").handle;
    pub const vis01 = @import("vis01.zig").handle;
    pub const all = [_]handler{ vis00, vis01 };
};
