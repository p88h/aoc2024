const std = @import("std");
const fs = std.fs;
const cstr = []const u8;

pub fn build(b: *std.Build) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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

    const vis_main = b.addExecutable(.{
        .name = "RayVisMain",
        .root_source_file = b.path("vis/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    vis_main.linkLibrary(libray);
    vis_main.linkLibrary(libvis);
    b.installArtifact(vis_main);
    const vis_cmd = b.addRunArtifact(vis_main);
    // needed ?
    // vis_cmd.step.dependOn(b.getInstallStep());
    const vis_step = b.step("vis", "Run the visualisation app");
    vis_step.dependOn(&vis_cmd.step);

    // compose a library with all the days that will be populated into runner source
    fs.cwd().deleteFile("_days.zig") catch {};
    const file = try fs.cwd().createFile("_days.zig", .{});
    try file.writeAll("const common = @import(\"src/common.zig\");");
    try file.writeAll("pub const Days = struct {\n");
    // some magical incantations
    var dayList = std.ArrayList([]const u8).init(allocator);
    defer dayList.deinit();

    // build all per-day executables in src/
    var iter_src = try std.fs.cwd().openDir(
        "src",
        .{ .iterate = true },
    );
    defer iter_src.close();
    var iter = iter_src.iterate();
    while (try iter.next()) |entry| {
        if (!std.mem.startsWith(u8, entry.name, "day")) continue;
        var paths = [_]cstr{ "src", entry.name };
        const file_path = try fs.path.join(allocator, &paths);
        const day_name = try std.fmt.allocPrint(allocator, "day{s}", .{entry.name[3..5]});
        defer allocator.free(file_path);
        try file.writer().print("    pub const {s} = @import(\"{s}\").work;\n", .{ day_name, file_path });
        try dayList.append(day_name);
    }
    std.mem.sort([]const u8, dayList.items, {}, struct {
        pub fn lt(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lt);
    try file.writer().print("    pub const last = {s};\n", .{dayList.getLast()});
    try file.writeAll("    pub const all = [_]common.Worker { ");
    for (dayList.items) |str| {
        try file.writer().print("{s}, ", .{str});
        allocator.free(str);
    }
    try file.writeAll("};\n");
    try file.writeAll("};\n");
    file.close();

    // Emit the runner
    const runner = b.addExecutable(.{
        .name = "AoCRunner",
        .root_source_file = b.path("runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(runner);
    const run_cmd = b.addRunArtifact(runner);
    // run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the runner");
    run_step.dependOn(&run_cmd.step);

    // pass the extra arguments into the runner
    if (b.args) |args| {
        run_cmd.addArgs(args);
        vis_cmd.addArgs(args);
    }
}
