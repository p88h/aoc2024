const std = @import("std");
const Allocator = std.mem.Allocator;
const ray = @import("ray.zig").ray;

pub const LightType = enum { LIGHT_DIRECTIONAL, LIGHT_POINT };

// adapted from raylib's rlight.h
pub const Light = struct {
    enabled: c_int,
    light_type: LightType,
    position: ray.Vector3,
    target: ray.Vector3,
    color: ray.Color,
    enable_loc: c_int,
    type_loc: c_int,
    pos_loc: c_int,
    target_loc: c_int,
    color_loc: c_int,

    pub fn create(
        allocator: Allocator,
        index: usize,
        light_type: LightType,
        pos: ray.Vector3,
        target: ray.Vector3,
        color: ray.Color,
        shader: ray.Shader,
    ) !*Light {
        var light = try allocator.create(Light);
        light.enabled = 1;
        light.light_type = light_type;
        light.position = pos;
        light.target = target;
        light.color = color;
        var buf = [_]u8{0} ** 64;

        var name = try std.fmt.bufPrintZ(&buf, "lights[{d}].enabled", .{index});
        light.enable_loc = ray.GetShaderLocation(shader, name.ptr);

        name = try std.fmt.bufPrintZ(&buf, "lights[{d}].type", .{index});
        light.type_loc = ray.GetShaderLocation(shader, name.ptr);

        name = try std.fmt.bufPrintZ(&buf, "lights[{d}].position", .{index});
        light.pos_loc = ray.GetShaderLocation(shader, name.ptr);

        name = try std.fmt.bufPrintZ(&buf, "lights[{d}].target", .{index});
        light.target_loc = ray.GetShaderLocation(shader, name.ptr);

        name = try std.fmt.bufPrintZ(&buf, "lights[{d}].color", .{index});
        light.color_loc = ray.GetShaderLocation(shader, name.ptr);

        light.update(shader);
        return light;
    }

    // update the shaders
    pub fn update(self: *Light, shader: ray.Shader) void {
        // Send to shader light enabled state and type
        ray.SetShaderValue(shader, self.enable_loc, &self.enabled, ray.SHADER_UNIFORM_INT);
        const l_type: c_int = @intFromEnum(self.light_type);
        ray.SetShaderValue(shader, self.type_loc, &l_type, ray.SHADER_UNIFORM_INT);

        // Send to shader light target position values
        const position = [3]f32{ self.position.x, self.position.y, self.position.z };
        ray.SetShaderValue(shader, self.pos_loc, &position, ray.SHADER_UNIFORM_VEC3);

        // Send to shader light target position values
        const target = [3]f32{ self.target.x, self.target.y, self.target.z };
        ray.SetShaderValue(shader, self.target_loc, &target, ray.SHADER_UNIFORM_VEC3);

        // Send to shader light color values
        const color = [4]f32{
            @as(f32, @floatFromInt(self.color.r)) / 255,
            @as(f32, @floatFromInt(self.color.g)) / 255,
            @as(f32, @floatFromInt(self.color.b)) / 255,
            @as(f32, @floatFromInt(self.color.a)) / 255,
        };
        ray.SetShaderValue(shader, self.color_loc, &color, ray.SHADER_UNIFORM_VEC4);
    }
};

pub fn setup_shader(ambient: f32) ray.Shader {
    var shader = ray.LoadShader("resources/lighting.vs", "resources/lighting.fs");
    shader.locs[ray.SHADER_LOC_VECTOR_VIEW] = ray.GetShaderLocation(shader, "viewPos");
    const ambient_loc = ray.GetShaderLocation(shader, "ambient");
    const ambient_val = [4]f32{ ambient, ambient, ambient, 1.0 };
    ray.SetShaderValue(shader, ambient_loc, &ambient_val, ray.SHADER_UNIFORM_VEC4);
    return shader;
}

// A basic lighting setup with ambient light + some top-positioned lights
pub fn setup_lights(allocator: Allocator, shader: ray.Shader, camera: ray.Camera3D) !std.ArrayList(*Light) {
    var list = std.ArrayList(*Light).init(allocator);
    // downwards liight above camera target
    try list.append(try Light.create(
        allocator,
        0,
        LightType.LIGHT_POINT,
        ray.Vector3{ .x = camera.target.x, .y = camera.position.y, .z = camera.target.z },
        ray.Vector3{ .x = camera.target.x, .y = 0, .z = camera.target.z },
        ray.WHITE,
        shader,
    ));
    // fill light above camera, also on target
    try list.append(try Light.create(
        allocator,
        1,
        LightType.LIGHT_POINT,
        ray.Vector3{ .x = camera.position.x, .y = camera.position.y + 2, .z = camera.position.z },
        ray.Vector3{ .x = camera.target.x, .y = 1, .z = camera.target.z },
        ray.WHITE,
        shader,
    ));
    return list;
}
