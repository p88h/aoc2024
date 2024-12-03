const std = @import("std");
const Allocator = std.mem.Allocator;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;

pub const Window = struct { width: c_int = 1920, height: c_int = 1080, fps: c_int = 60, fsize: c_int = 16 };

pub const handler = struct {
    window: Window = Window{},
    init: *const fn (allocator: Allocator, a: *ASCIIRay) *anyopaque,
    step: *const fn (ctx: *anyopaque, a: *ASCIIRay, idx: usize) bool,
    pub fn run(self: handler, rec: bool) !void {
        // internal semi-static context
        const ctx = struct {
            var a: *ASCIIRay = undefined;
            var h: handler = undefined;
            var p: *anyopaque = undefined;
        };
        // real init at runtime. Use arena allocator for all context stuff.
        var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        const win = self.window;
        ctx.a = try ASCIIRay.init(allocator, win.width, win.height, win.fps, rec, win.fsize);
        ctx.h = self;
        ctx.p = self.init(allocator, ctx.a);
        try ctx.a.loop(struct {
            pub fn render(idx: usize) bool {
                return ctx.h.step(ctx.p, ctx.a, idx);
            }
        }.render);
    }
};
