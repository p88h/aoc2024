const std = @import("std");
const fs = std.fs;
const cstr = []const u8;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libvis = b.addStaticLibrary(.{
        .name = "RayVis",
        .root_source_file = b.path("vis/common.zig"),
        .target = target,
        .optimize = optimize,
    });
    const raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const libray = raylib.artifact("raylib");

    const exe = b.addExecutable(.{
        .name = "RayVisMain",
        .root_source_file = b.path("vis/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(libray);
    exe.linkLibrary(libvis);
    b.installArtifact(exe);
    const vis_cmd = b.addRunArtifact(exe);
    // needed ?
    vis_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        vis_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const vis_step = b.step("vis", "Run the visualisation app");
    vis_step.dependOn(&vis_cmd.step);

    const run_step = b.step("run", "Run all days");

    // build all per-day executables in src/
    var iter_src = try std.fs.cwd().openDir(
        "src",
        .{ .iterate = true },
    );
    defer iter_src.close();
    var iter = iter_src.iterate();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    while (try iter.next()) |entry| {
        var paths = [_]cstr{ "src", entry.name };
        const file_path = try fs.path.join(allocator, &paths);
        defer allocator.free(file_path);

        const day = b.addExecutable(.{
            .name = entry.name,
            .root_source_file = b.path(file_path),
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(day);
        const run_day = b.addRunArtifact(day);
        run_day.step.dependOn(b.getInstallStep());
        run_step.dependOn(&run_day.step);
    }
}
