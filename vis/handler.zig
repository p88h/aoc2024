const std = @import("std");
const Allocator = std.mem.Allocator;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;

pub const handler = struct {
    init: *const fn (allocator: Allocator, a: *ASCIIRay) *anyopaque,
    step: *const fn (ctx: *anyopaque, a: *ASCIIRay, idx: c_int) bool,
    pub fn run(self: handler, rec: bool) !void {
        const ctx = struct {
            var a: *ASCIIRay = @ptrFromInt(@alignOf(ASCIIRay));
            var h: handler = undefined;
            var p: *anyopaque = undefined;
        };
        // real init at runtime. Use arena allocator for all context stuff.
        var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        ctx.a = try ASCIIRay.init(allocator, 1920, 1080, 15, rec, 16);
        ctx.h = self;
        ctx.p = self.init(allocator, ctx.a);
        try ctx.a.loop(struct {
            pub fn render(idx: c_int) bool {
                return ctx.h.step(ctx.p, ctx.a, idx);
            }
        }.render);
    }
};
