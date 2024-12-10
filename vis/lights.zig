const std = @import("std");
const Allocator = std.mem.Allocator;

const ray = @cImport({
    @cInclude("raylib.h");
});

pub const LightType = enum { LIGHT_DIRECTIONAL, LIGHT_POINT };

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
        ray.SetShaderValue(shader, self.type_loc, &self.light_type, ray.SHADER_UNIFORM_INT);

        // Send to shader light target position values
        ray.SetShaderValue(shader, self.pos_loc, &self.position, ray.SHADER_UNIFORM_VEC3);

        // Send to shader light target position values
        ray.SetShaderValue(shader, self.target_loc, &self.target, ray.SHADER_UNIFORM_VEC3);

        // Send to shader light color values
        const color = ray.Vector4{
            .x = @floatFromInt(self.color.r),
            .y = @floatFromInt(self.color.g),
            .z = @floatFromInt(self.color.b),
            .w = @floatFromInt(self.color.a),
        };
        ray.SetShaderValue(shader, self.color_loc, &color, ray.SHADER_UNIFORM_VEC4);
    }
};

pub fn setup_lights(allocator: Allocator, shader: ray.Shader, xmax: f32, ymax: f32, zmax: f32, models: std.ArrayList(ray.Model)) !std.ArrayList(*Light) {
    var list = std.ArrayList(*Light).init(allocator);
    shader.locs[ray.SHADER_LOC_VECTOR_VIEW] = ray.GetShaderLocation(shader, "viewPos");
    shader.locs[ray.SHADER_LOC_VECTOR_VIEW] = ray.GetShaderLocation(shader, "matModel");
    const ambient_loc = ray.GetShaderLocation(shader, "ambient");
    const ambient = ray.Vector4{ .x = 0.3, .y = 0.3, .z = 0.3, .w = 1.0 };
    ray.SetShaderValue(shader, ambient_loc, &ambient, ray.SHADER_UNIFORM_VEC4);
    try list.append(try Light.create(
        allocator,
        0,
        LightType.LIGHT_POINT,
        ray.Vector3{ .x = -xmax, .y = ymax + 10, .z = zmax },
        ray.Vector3{},
        ray.WHITE,
        shader,
    ));
    try list.append(try Light.create(
        allocator,
        1,
        LightType.LIGHT_POINT,
        ray.Vector3{ .x = xmax / 2, .y = 20, .z = zmax / 2 },
        ray.Vector3{ .x = xmax / 2, .y = 0, .z = zmax / 2 },
        ray.WHITE,
        shader,
    ));
    try list.append(try Light.create(
        allocator,
        2,
        LightType.LIGHT_POINT,
        ray.Vector3{ .x = xmax / 2, .y = -20, .z = zmax / 2 },
        ray.Vector3{ .x = xmax / 2, .y = 0, .z = zmax / 2 },
        ray.WHITE,
        shader,
    ));
    for (models.items) |model| {
        model.materials[0].shader = shader;
    }
    return list;
}
