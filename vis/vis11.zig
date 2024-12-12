const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;
const sol = @import("src").day11;

const VisState = struct {
    ctx: *sol.Context,
    ofs: usize,
    cur: std.ArrayList(u64),
    next: std.ArrayList(u64),
    cnt: std.ArrayList(u64),
    cache: std.AutoHashMap(u64, u64),
    blink: usize,
    tot: usize,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.cur = vis.ctx.numbers.clone() catch unreachable;
    vis.next = @TypeOf(vis.next).init(allocator);
    vis.cnt = @TypeOf(vis.cnt).init(allocator);
    for (0..vis.cur.items.len) |_| vis.cnt.append(1) catch unreachable;
    vis.cache = @TypeOf(vis.cache).init(allocator);
    vis.ofs = 0;
    vis.blink = 1;
    vis.tot = 0;
    return vis;
}

const vec2 = @Vector(2, u64);

pub fn expand(num: u64) vec2 {
    if (num == 0) return vec2{ 1, 0 };
    var base: u64 = 1;
    while (base < 10000000000) {
        base *= 10;
        const bl = base * base / 10;
        const bh = base * base;
        if (num < bl) break;
        if (num >= bl and num < bh) return vec2{ num % base, num / base };
    }
    return vec2{ num * 2024, 0 };
}

pub fn step(vis: *VisState, a: *ASCIIRay, _: usize) bool {
    if (vis.ofs > vis.cur.items.len and vis.blink < 75) {
        const tmp = vis.cur;
        vis.cur = vis.next;
        vis.ofs = 0;
        vis.next = tmp;
        vis.next.clearRetainingCapacity();
        vis.cnt.clearRetainingCapacity();
        for (0..vis.cur.items.len) |i| vis.cnt.append(vis.cache.get(vis.cur.items[i]).?) catch unreachable;
        vis.cache.clearRetainingCapacity();
        vis.blink += 1;
        std.debug.print("{d}:{d}\n", .{ vis.blink, vis.tot });
        vis.tot = 0;
    }
    if (vis.ofs > vis.cur.items.len + 60) return true;
    var buf = [_]u8{0} ** 64;
    a.home();
    var s = std.fmt.bufPrintZ(&buf, "Blink: {d}", .{vis.blink}) catch unreachable;
    a.writeln(s);
    a.writeln("");
    a.writeln("De-duplicated stones:");
    a.writeln("");
    for (vis.next.items) |it| {
        s = std.fmt.bufPrintZ(&buf, "{d} ", .{it}) catch unreachable;
        a.writeEx(s, ray.DARKGRAY);
    }
    if (vis.ofs > 0 and vis.ofs <= vis.cur.items.len) {
        const num = vis.cur.items[vis.ofs - 1];
        const v2 = expand(num);
        for (0..2) |i| {
            var nc = vis.cnt.items[vis.ofs - 1];
            if (i == 0 or v2[i] > 0) {
                vis.tot += nc;
                s = std.fmt.bufPrintZ(&buf, "{d} ", .{v2[i]}) catch unreachable;
                a.writeEx(s, ray.GREEN);
                if (vis.cache.contains(v2[i])) {
                    nc += vis.cache.get(v2[i]).?;
                } else {
                    vis.next.append(v2[i]) catch unreachable;
                }
                vis.cache.put(v2[i], nc) catch unreachable;
            }
        }
    }
    a.write("| ");
    if (vis.ofs < vis.cur.items.len) {
        s = std.fmt.bufPrintZ(&buf, "{d} ", .{vis.cur.items[vis.ofs]}) catch unreachable;
        a.writeEx(s, ray.RAYWHITE);
        for (vis.cur.items[vis.ofs + 1 ..]) |it| {
            s = std.fmt.bufPrintZ(&buf, "{d} ", .{it}) catch unreachable;
            a.writeEx(s, ray.LIGHTGRAY);
        }
    }
    vis.ofs += 1;
    a.writeln("");
    a.writeln("");
    s = std.fmt.bufPrintZ(&buf, "Total (with duplicates): {d}", .{vis.tot}) catch unreachable;
    a.writeln(s);

    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .width = 1280, .height = 720, .fsize = 32, .fps = 60 },
};
