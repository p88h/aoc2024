const std = @import("std");
const fs = std.fs;
const cstr = []const u8;
const Allocator = std.mem.Allocator;

const gen_opts = struct { prefix: []const u8, header: []const u8, tname: []const u8, handle: []const u8 };

pub fn build(b: *std.Build) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libsrc = b.createModule(.{
        .root_source_file = b.path("src/_days.zig"),
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
    vis_main.root_module.addImport("src", libsrc);
    vis_main.linkLibrary(libray);
    b.installArtifact(vis_main);
    const vis_cmd = b.addRunArtifact(vis_main);
    // needed ?
    // vis_cmd.step.dependOn(b.getInstallStep());
    const vis_step = b.step("vis", "Run the visualisation app");
    vis_step.dependOn(&vis_cmd.step);

    const src_opts = gen_opts{
        .prefix = "day",
        .header = "pub const common = @import(\"common.zig\");\n",
        .tname = "common.Worker",
        .handle = "work",
    };
    try generate_days_file(allocator, "src", src_opts);

    const vis_opts = gen_opts{
        .prefix = "vis",
        .header = "pub const handler = @import(\"handler.zig\").handler;\n",
        .tname = "handler",
        .handle = "handle",
    };
    try generate_days_file(allocator, "vis", vis_opts);

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

fn generate_days_file(allocator: Allocator, dir: []const u8, opts: gen_opts) !void {
    // compose a library with all the days that will be populated into runner source
    var d = try fs.cwd().openDir(dir, .{});
    const filename = "_days.zig";
    d.deleteFile(filename) catch {};
    const file = try d.createFile(filename, .{});
    try file.writeAll(opts.header);
    // some magical incantations
    var dayList = std.ArrayList([]const u8).init(allocator);
    defer dayList.deinit();

    // build all per-day executables in src/
    var iter_src = try std.fs.cwd().openDir(
        dir,
        .{ .iterate = true },
    );
    defer iter_src.close();
    var iter = iter_src.iterate();
    while (try iter.next()) |entry| {
        if (!std.mem.startsWith(u8, entry.name, opts.prefix)) continue;
        var paths = [_]cstr{ dir, entry.name };
        const file_path = try fs.path.join(allocator, &paths);
        const day_name = try std.fmt.allocPrint(allocator, "{s}{s}", .{ opts.prefix, entry.name[3..5] });
        defer allocator.free(file_path);
        try file.writer().print("pub const {s} = @import(\"{s}\");\n", .{ day_name, entry.name });
        try dayList.append(day_name);
    }
    try file.writeAll("pub const Days = struct {\n");
    std.mem.sort([]const u8, dayList.items, {}, struct {
        pub fn lt(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lt);
    try file.writer().print("    pub const last = {s}.work;\n", .{dayList.getLast()});
    try file.writer().print("    pub const all = [_]{s} {{", .{opts.tname});
    for (dayList.items) |str| {
        try file.writer().print("{s}.{s}, ", .{ str, opts.handle });
        allocator.free(str);
    }
    try file.writeAll("};\n");
    try file.writeAll("};\n");
    file.close();
}
