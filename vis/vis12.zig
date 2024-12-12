const std = @import("std");
const handler = @import("handler.zig").handler;
const common = @import("src").common;
const ASCIIRay = @import("asciiray.zig").ASCIIRay;
const Allocator = std.mem.Allocator;
const lights = @import("lights.zig");
const sol = @import("src").day12;
const ray = @import("ray.zig").ray;

const VisState = struct {
    ctx: *sol.Context,
    camera: ray.Camera3D,
    models: std.ArrayList(ray.Model),
    textures: std.ArrayList(ray.Texture2D),
    lights: std.ArrayList(*lights.Light),
    shader: ray.Shader,
    order: std.ArrayList(sol.vec2),
};

pub fn init(allocator: Allocator, _: *ASCIIRay) *VisState {
    var vis = allocator.create(VisState) catch unreachable;
    const ptr = common.create_ctx(allocator, sol.work);
    vis.ctx = @alignCast(@ptrCast(ptr));
    vis.order = @TypeOf(vis.order).init(allocator);
    const dimf: f32 = @floatFromInt(vis.ctx.dim);
    vis.camera = ray.Camera3D{
        .up = .{ .y = 1 },
        .fovy = 5,
        .projection = ray.CAMERA_PERSPECTIVE,
        .target = .{ .x = 0, .y = 0, .z = 0 },
        .position = .{ .x = 30, .y = dimf / 2, .z = dimf / 2 },
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

pub fn step(vis: *VisState, a: *ASCIIRay, idx: usize) bool {
    const ctx = vis.ctx;
    if (idx > ctx.dim * 5) return true;
    const cidx: f32 = @as(f32, @floatFromInt(idx));
    if (vis.camera.fovy < 35) {
        vis.camera.fovy = 5 + @as(f32, @floatFromInt(idx)) / 10;
    }
    if (idx < ctx.dim * 3)
        vis.camera.target = ray.Vector3{ .x = cidx / 4, .y = 0, .z = cidx / 4 };
    // vis.camera.position = ray.Vector3{ .x = @floatFromInt(ctx.dim / 3 + cx / 3), .y = dimf / 2, .z = @floatFromInt(cz / 2 + ctx.dim / 2 + 4) };
    ray.UpdateCamera(&vis.camera, ray.CAMERA_PERSPECTIVE);
    ray.BeginMode3D(vis.camera);
    ray.BeginShaderMode(vis.shader);
    var pos0 = ray.Vector3{ .z = -0.5 };
    var pos1 = ray.Vector3{ .x = -0.5 };
    for (0..ctx.dim) |y| {
        pos0.x = 0;
        pos1.x = -0.5;
        for (0..vis.ctx.dim) |x| {
            const p = y * ctx.stride + x;
            const h: u8 = ctx.buf[p] - '@';
            const pos = ray.Vector3{ .x = @floatFromInt(x), .y = 0.1, .z = @floatFromInt(y) };
            const siz = ray.Vector3{ .x = 0.5, .y = @as(f32, @floatFromInt(h + 1)) / 25.0, .z = 0.5 };
            const col = ray.Color{ .r = h * 9, .g = (26 - h) * 9, .b = 32, .a = 255 };
            if (x * x + y * y < idx * idx / 5) {
                ray.DrawCubeV(pos, siz, col);
                if (p < ctx.stride or ctx.buf[p - ctx.stride] != ctx.buf[p])
                    ray.DrawModel(vis.models.items[0], pos0, 7, ray.WHITE);
                if (x == 0 or ctx.buf[p - 1] != ctx.buf[p])
                    ray.DrawModel(vis.models.items[1], pos1, 7, ray.WHITE);
            } else {
                ray.DrawCubeV(pos, siz, ray.DARKGRAY);
            }
            pos0.x += 1;
            pos1.x += 1;
        }
        pos0.z += 1;
        pos1.z += 1;
    }

    ray.EndShaderMode();
    ray.EndMode3D();
    if (idx < ctx.dim * 4) {
        var buf = [_]u8{0} ** 64;
        _ = std.fmt.bufPrintZ(&buf, "Fencing in progress", .{}) catch unreachable;
        a.writeXY(&buf, 2, 2, ray.RAYWHITE);
    }
    return false;
}

pub const handle = handler{
    .init = @ptrCast(&init),
    .step = @ptrCast(&step),
    .window = .{ .fsize = 24, .fps = 30 },
};
