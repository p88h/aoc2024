const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");

pub const Vec2 = @Vector(2, i32);

pub const Context = struct {
    allocator: Allocator,
    map: []u8,
    map2: []u8,
    dimx: usize,
    dimy: usize,
    robot: Vec2,
    robot2: Vec2,
    instructions: [][]const u8,
    work: std.ArrayList(Vec2),
    visited: std.AutoHashMap(Vec2, bool),

    pub fn init(self: *Context, allocator: Allocator) void {
        self.allocator = allocator;
        self.work = @TypeOf(self.work).init(allocator);
        self.work.ensureTotalCapacity(512) catch unreachable;
        self.visited = @TypeOf(self.visited).init(allocator);
        self.visited.ensureTotalCapacity(512) catch unreachable;
    }

    pub inline fn tile(self: *Context, pos: Vec2) *u8 {
        const ofs: usize = @intCast(pos[0] * @as(i32, @intCast(self.dimx)) + pos[1]);
        return &self.map[ofs];
    }

    pub fn move1(self: *Context, dir: Vec2) void {
        var tmp = self.robot + dir;
        while (self.tile(tmp).* == 'O') tmp += dir;
        if (self.tile(tmp).* == '.') {
            self.tile(self.robot).* = '.';
            self.tile(tmp).* = 'O';
            self.robot += dir;
            self.tile(self.robot).* = '@';
        }
    }

    pub fn move2(self: *Context, dir: Vec2) void {
        var tmp = self.robot + dir;
        var ch = self.tile(tmp);
        // quick
        if (ch.* == '#') return;
        if (ch.* == '.') {
            self.tile(self.robot).* = '.';
            ch.* = '@';
            self.robot = tmp;
            return;
        }
        // left/right is _almost_ the same as in part1, except we have to shift memory around
        if (dir[0] == 0) {
            while (ch.* != '.' and ch.* != '#') {
                tmp += dir;
                ch = self.tile(tmp);
            }
            // no move
            if (ch.* == '#') return;
            std.debug.assert(ch.* == '.');
            // shift backwards
            while (tmp[1] != self.robot[1]) {
                tmp -= dir;
                const prev = self.tile(tmp);
                ch.* = prev.*;
                ch = prev;
            }
            self.robot += dir;
            ch.* = '.';
            return;
        }
        // not so quick: for up-down we'll build a list of positions to move
        var idx: usize = 0;
        self.work.clearRetainingCapacity();
        self.visited.clearRetainingCapacity();
        self.work.append(self.robot) catch unreachable;
        while (idx < self.work.items.len) {
            const src = self.work.items[idx];
            idx += 1;
            const dst = src + dir;
            ch = self.tile(dst);
            // no need to add anything, this can be moved
            if (ch.* == '.') continue;
            // abort whole move
            if (ch.* == '#') return;
            std.debug.assert(ch.* == '[' or ch.* == ']');
            // got to move this and its neighbor
            var neighbor = dst + Vec2{ 0, 1 };
            if (ch.* == ']') neighbor = dst + Vec2{ 0, -1 };
            if (!self.visited.contains(dst)) {
                self.work.append(dst) catch unreachable;
                self.visited.put(dst, true) catch unreachable;
            }
            if (!self.visited.contains(neighbor)) {
                self.work.append(neighbor) catch unreachable;
                self.visited.put(neighbor, true) catch unreachable;
            }
        }
        // apparently we can move everything. Let's go backwards.
        while (self.work.items.len > 0) {
            const last = self.work.pop();
            ch = self.tile(last);
            std.debug.assert(self.tile(last + dir).* == '.');
            self.tile(last + dir).* = ch.*;
            ch.* = '.';
        }
        self.robot += dir;
    }

    pub fn score(self: *Context, ch: u8) usize {
        var tot: usize = 0;
        for (1..self.dimy - 1) |y| {
            for (1..self.dimx - 2) |x| {
                if (self.map[y * self.dimx + x] == ch)
                    tot += y * 100 + x;
            }
        }
        return tot;
    }
};

pub fn parse(allocator: Allocator, buf: []u8, lines: [][]const u8) *Context {
    var ctx = allocator.create(Context) catch unreachable;
    var sep: usize = 0;
    for (0..lines.len) |i| {
        if (lines[i].len == 0) {
            sep = i;
            break;
        }
        for (0..lines[i].len) |j| {
            if (lines[i][j] == '@') ctx.robot = Vec2{ @intCast(i), @intCast(j) };
        }
    }
    ctx.dimx = lines[sep - 1].len + 1;
    ctx.dimy = sep;
    ctx.map = buf[0 .. ctx.dimx * ctx.dimy];
    ctx.map2 = allocator.alloc(u8, ctx.map.len * 2) catch unreachable;
    for (ctx.map, 0..) |ch, i| {
        if (ch == '\n') {
            ctx.map2[i * 2] = ' ';
            ctx.map2[i * 2 + 1] = '\n';
        } else if (ch == 'O') {
            ctx.map2[i * 2] = '[';
            ctx.map2[i * 2 + 1] = ']';
        } else if (ch == '@') {
            ctx.map2[i * 2] = ch;
            ctx.map2[i * 2 + 1] = '.';
        } else {
            ctx.map2[i * 2] = ch;
            ctx.map2[i * 2 + 1] = ch;
        }
    }
    ctx.robot2 = Vec2{ ctx.robot[0], ctx.robot[1] * 2 };
    ctx.instructions = lines[sep + 1 ..];
    ctx.init(allocator);
    return ctx;
}

pub fn part1(ctx: *Context) []u8 {
    for (ctx.instructions) |line| {
        for (line) |ch| {
            switch (ch) {
                '^' => ctx.move1(Vec2{ -1, 0 }),
                'v' => ctx.move1(Vec2{ 1, 0 }),
                '<' => ctx.move1(Vec2{ 0, -1 }),
                '>' => ctx.move1(Vec2{ 0, 1 }),
                else => {},
            }
        }
    }
    const tot = ctx.score('O');
    return std.fmt.allocPrint(ctx.allocator, "{d}", .{tot}) catch unreachable;
}

pub fn part2(ctx: *Context) []u8 {
    // update work area
    ctx.map = ctx.map2;
    ctx.robot = ctx.robot2;
    ctx.dimx *= 2;
    for (ctx.instructions) |line| {
        for (line) |ch| {
            switch (ch) {
                '^' => ctx.move2(Vec2{ -1, 0 }),
                'v' => ctx.move2(Vec2{ 1, 0 }),
                '<' => ctx.move2(Vec2{ 0, -1 }),
                '>' => ctx.move2(Vec2{ 0, 1 }),
                else => {},
            }
        }
    }
    const tot = ctx.score('[');
    // std.debug.print("{s}", .{ctx.map});
    return std.fmt.allocPrint(ctx.allocator, "{}", .{tot}) catch unreachable;
}

// boilerplate
pub const work = common.Worker{
    .day = "15",
    .parse = @ptrCast(&parse),
    .part1 = @ptrCast(&part1),
    .part2 = @ptrCast(&part2),
};
pub fn main() void {
    common.run_day(work);
}
