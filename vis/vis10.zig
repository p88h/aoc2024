const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @cImport({
    @cInclude("raylib.h");
});
const sol = @import("src").day10;

const VisState = struct {
    ctx: *sol.Context,
    camera: ray.Camera3D,
    models: std.ArrayList(ray.Model),
    lights: std.ArrayList(*lights.Light),
    order: std.ArrayList(sol.Pos),
    shader: ray.Shader,
};

pub fn bfs(ctx: *sol.Context) std.ArrayList(sol.Pos) {
    const dim = ctx.lines.len;
    var arr = ctx.start.clone() catch unreachable;
    var cur = &arr;
    var alt = std.ArrayList(sol.Pos).init(ctx.allocator);
    var ret = std.ArrayList(sol.Pos).init(ctx.allocator);
    var next = &alt;
    next.ensureTotalCapacity(cur.items.len) catch unreachable;
    var order: usize = 2;
    for (0..10) |_| {
        for (cur.items) |v| {
            const p = v.y * dim + v.x;
            const ch = ctx.lines[v.y][v.x] - 1;
            ret.append(v) catch unreachable;
            if (ch == '/') {
                continue;
            }
            // look around, try going down
            if (v.x > 0 and ctx.lines[v.y][v.x - 1] == ch) {
                if (ctx.cntr[p - 1] == 0)
                    next.append(sol.Pos{ .y = v.y, .x = v.x - 1 }) catch unreachable;
                ctx.cntr[p - 1] = order;
                order += 1;
            }
            if (v.x + 1 < dim and ctx.lines[v.y][v.x + 1] == ch) {
                if (ctx.cntr[p + 1] == 0)
                    next.append(sol.Pos{ .y = v.y, .x = v.x + 1 }) catch unreachable;
                ctx.cntr[p + 1] = order;
                order += 1;
            }
            if (v.y > 0 and ctx.lines[v.y - 1][v.x] == ch) {
                if (ctx.cntr[p - dim] == 0)
                    next.append(sol.Pos{ .y = v.y - 1, .x = v.x }) catch unreachable;
                ctx.cntr[p - dim] = order;
                order += 1;
            }
            if (v.y + 1 < dim and ctx.lines[v.y + 1][v.x] == ch) {
                if (ctx.cntr[p + dim] == 0)
                    next.append(sol.Pos{ .y = v.y + 1, .x = v.x }) catch unreachable;
                ctx.cntr[p + dim] = order;
                order += 1;
            }
        }
        const tmp = cur;
        cur = next;
        next = tmp;
        next.clearRetainingCapacity();
    }
    return ret;
}

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.order = bfs(vis.ctx);
    const dimf: f32 = @floatFromInt(vis.ctx.dim);
    vis.camera = ray.Camera3D{
        .up = .{ .y = 1 },
        .fovy = 45,
        .projection = ray.CAMERA_PERSPECTIVE,
        .target = .{ .x = dimf / 2, .y = 0, .z = dimf / 2 },
        .position = .{ .x = dimf / 2 - 1, .y = dimf * 1.5, .z = dimf },
    };
    vis.models = @TypeOf(vis.models).init(allocator);
    vis.models.append(ray.LoadModelFromMesh(ray.GenMeshCube(1, 10, 1))) catch unreachable;
    vis.models.append(ray.LoadModelFromMesh(ray.GenMeshSphere(1, 8, 8))) catch unreachable;
    vis.shader = lights.setup_shader(0.1);
    vis.lights = lights.setup_lights(allocator, vis.shader, vis.camera) catch {
        std.debug.panic("Could not set up lights\n", .{});
    };
    return vis;
}

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    // const ctx = vis.ctx;
    if (idx > 60 * 60) return true;
    ray.BeginMode3D(vis.camera);
    ray.BeginShaderMode(vis.shader);
    var elev: u8 = 9;
    var mcnt: usize = 0;
    for (0..vis.ctx.dim) |y| {
        for (0..vis.ctx.dim) |x| {
            const h: u8 = vis.ctx.lines[y][x] - '0';
            const pos = ray.Vector3{ .x = @floatFromInt(x), .y = 0, .z = @floatFromInt(y) };
            const siz = ray.Vector3{ .x = 1, .y = @as(f32, @floatFromInt(h + 1)) / 4, .z = 1 };
            const col = ray.Color{ .r = h * 28, .g = (9 - h) * 28, .b = 32, .a = 255 };
            const col2 = ray.Color{ .r = col.r / 2, .g = col.g / 2, .b = col.b * 4, .a = 128 };
            const p = y * vis.ctx.dim + x;
            const o = vis.ctx.cntr[p];
            if (o > 0 and o <= idx) {
                ray.DrawCubeV(pos, siz, col);
                if (h < elev) elev = h;
                mcnt += 1;
            } else {
                ray.DrawCubeV(pos, siz, col2);
            }
            ray.DrawCubeWiresV(pos, siz, ray.BROWN);
        }
    }
    ray.EndShaderMode();
    ray.EndMode3D();
    var buf = [_]u8{0} ** 64;
    _ = std.fmt.bufPrintZ(&buf, "Visited: {d} Elevation: {d}", .{ mcnt, elev }) catch unreachable;
    a.writeXY(&buf, 2, 2, ray.RAYWHITE);
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 24, .fps = 30 },
};
