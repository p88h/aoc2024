const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const ray = @import("ray.zig").ray;
const sol = @import("src").day13;

const VisState = struct {
    ctx: *sol.Context,
    camera: ray.Camera3D,
    models: std.ArrayList(ray.Model),
    textures: std.ArrayList(ray.Texture2D),
    lights: std.ArrayList(*lights.Light),
    shader: ray.Shader,
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.camera = ray.Camera3D{
        .up = .{ .y = 1 },
        .fovy = 40,
        .projection = ray.CAMERA_PERSPECTIVE,
        .target = .{ .x = 50, .y = 0, .z = 50 },
        .position = .{ .x = 30, .y = 120, .z = 160 },
    };
    vis.models = @TypeOf(vis.models).init(allocator);
    vis.textures = @TypeOf(vis.textures).init(allocator);
    vis.models.append(ray.LoadModel("resources/fence.glb")) catch unreachable;
    vis.models.append(ray.LoadModel("resources/fence.glb")) catch unreachable;
    vis.shader = lights.setup_shader(0.1);
    vis.models.items[0].materials[0].shader = vis.shader;
    vis.models.items[1].materials[0].shader = vis.shader;
    vis.models.items[1].transform = ray.MatrixRotateY(std.math.pi / 2.0);
    vis.lights = lights.setup_lights(allocator, vis.shader, vis.camera) catch {
        std.debug.panic("Could not set up lights\n", .{});
    };
    return vis;
}

pub fn distance(m: sol.Machine, a: i64, b: i64) f32 {
    const dx = m.prize[0] - (a * m.a[0] + b * m.b[0]);
    const dy = m.prize[1] - (a * m.a[1] + b * m.b[1]);
    const d = @sqrt(@as(f32, @floatFromInt(dx * dx + dy * dy)));
    const z = @sqrt(@as(f32, @floatFromInt(m.prize[0] * m.prize[0] + m.prize[1] * m.prize[1]))) * 2;
    return d / z;
}

pub fn step(vis: *VisState, aa: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > ctx.machines.items.len * 60) return true;
    // vis.camera.position = ray.Vector3{ .x = @floatFromInt(ctx.dim / 3 + cx / 3), .y = dimf / 2, .z = @floatFromInt(cz / 2 + ctx.dim / 2 + 4) };
    ray.UpdateCamera(&vis.camera, ray.CAMERA_PERSPECTIVE);
    ray.BeginMode3D(vis.camera);
    ray.BeginShaderMode(vis.shader);
    const m1 = ctx.machines.items[idx / 60];
    const m2 = ctx.machines.items[idx / 60 + 1];
    var w: f32 = @as(f32, @floatFromInt(idx % 60)) / 60.0;
    w = w * w * w * w;
    var found: sol.Point = @splat(0);
    for (0..101) |a| {
        for (0..101) |b| {
            const d1 = distance(m1, @intCast(a), @intCast(b)) * (1.0 - w);
            if (d1 == 0) found = sol.Point{ @intCast(a), @intCast(b) };
            const d2 = distance(m2, @intCast(a), @intCast(b)) * w;
            const dh = (d1 + d2) * 255;
            if (dh <= 255) {
                const h: u8 = @intFromFloat(dh);
                const pos = ray.Vector3{ .x = @floatFromInt(a), .y = dh / 5, .z = @floatFromInt(b) };
                const siz = ray.Vector3{ .x = 0.8, .y = 0.4, .z = 0.8 };

                const col = ray.Color{ .r = h, .g = (255 - h), .b = 32, .a = 255 };
                ray.DrawCubeV(pos, siz, col);
            }
        }
    }
    ray.EndShaderMode();
    ray.EndMode3D();
    var buf = [_]u8{0} ** 128;
    if (idx < 120) {
        aa.writeXY("X axis = A count", 114, 40, ray.RAYWHITE);
        aa.writeXY("Y axis = B count", 114, 41, ray.RAYWHITE);
        aa.writeXY("Z (height) = distance from goal", 110, 42, ray.RAYWHITE);
    }
    if (w <= 0.3) {
        _ = std.fmt.bufPrintZ(&buf, "Current A={any} B={any} Prize={any}", .{ m1.a, m1.b, m1.prize }) catch unreachable;
        aa.writeXY(&buf, 2, 1, ray.RAYWHITE);
        if (found[0] != 0) {
            _ = std.fmt.bufPrintZ(&buf, "Solution at {any}", .{found}) catch unreachable;
            aa.writeXY(&buf, 2, 2, ray.RAYWHITE);
        }
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 24, .fps = 60 },
};
