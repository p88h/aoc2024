const std = @import("std");
const fs = std.fs;
const cstr = []const u8;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libvis = b.addStaticLibrary(.{
        .name = "RayVis",
        .root_source_file = b.path("vis/asciiray.zig"),
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

    fs.cwd().deleteFile("_days.zig") catch {};
    // compose a library with all the days that will also create the dispatcher source
    const file = try fs.cwd().createFile("_days.zig", .{});
    try file.writeAll("pub const Days = struct {\n");
    // some magical incantations
    try file.writeAll("    const fnError = error{Invalid};\n");
    try file.writeAll("    const fnType = *const fn () fnError!void;\n");
    var dayList = std.ArrayList([]const u8).init(allocator);
    defer dayList.deinit();
    while (try iter.next()) |entry| {
        var paths = [_]cstr{ "src", entry.name };
        const file_path = try fs.path.join(allocator, &paths);
        const day_name = try std.fmt.allocPrint(allocator, "day{s}", .{entry.name[3..5]});
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
        try file.writer().print("    pub const {s} = @import(\"{s}\").main;\n", .{ day_name, file_path });
        try dayList.append(day_name);
    }
    try file.writer().print("    pub const last = {s};\n", .{dayList.getLast()});
    try file.writeAll("    pub const all = [_]fnType { ");
    for (dayList.items) |str| {
        try file.writer().print("{s}, ", .{str});
        allocator.free(str);
    }
    try file.writeAll("};\n");
    try file.writeAll("};\n");
    file.close();
}
