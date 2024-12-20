const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const assert = std.debug.assert;

// Simple binary tree with insert, delete and in-order iteration
// balancing TBD.
pub fn ZTree(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        allocator: Allocator,
        root: ?*Node = null,

        pub const Node = struct {
            key: K = undefined,
            value: V = undefined,
            count: usize = 0,
            left: ?*Node = null,
            right: ?*Node = null,
            parent: ?*Node = null,
        };

        pub fn init(allocator: Allocator) Self {
            return Self{ .allocator = allocator };
        }

        fn find_upper_bound(self: *Self, at: ?*Node, key: K) ?*Node {
            if (at == null) return null;
            if (at.?.key == key) return at;
            if (at.?.key > key) return self.find_upper_bound(at.?.left, key);
            return self.find_upper_bound(at.?.right, key);
        }

        fn find_lower_bound(self: *Self, at: ?*Node, key: K) ?*Node {
            if (at == null) return null;
            if (at.?.key == key) return at;
            if (at.?.key < key) return self.find_lower_bound(at.?.right, key);
            return self.find_lower_bound(at.?.left, key);
        }

        fn insert_node(self: *Self, at: *Node, node: *Node) void {
            at.count += 1;
            // std.debug.print("{d}:{d}\n", .{ at.key, at.count });
            if (node.key < at.key) {
                if (at.left == null) {
                    at.left = node;
                    node.parent = at;
                    return;
                }
                self.insert_node(at.left.?, node);
            } else {
                if (at.right == null) {
                    at.right = node;
                    node.parent = at;
                    return;
                }
                self.insert_node(at.right.?, node);
            }
        }

        pub fn contains(self: *Self, key: K) bool {
            const t = self.find_lower_bound(self.root, key) orelse return false;
            return t.key == key;
        }

        pub fn get(self: *Self, key: K) ?V {
            const t = self.find_lower_bound(self.root, key) orelse return null;
            if (t.key != key) return null;
            return t.value;
        }

        pub fn insert(self: *Self, key: K, value: V) !*Node {
            var node = try self.allocator.create(Node);
            node.left = null;
            node.right = null;
            node.parent = null;
            node.key = key;
            node.value = value;
            node.count = 1;
            if (self.root != null) {
                self.insert_node(self.root.?, node);
            } else self.root = node;
            // std.debug.print("insert {any} onto {any}\n", .{ node, self.root });
            return node;
        }

        pub fn delete(self: *Self, key: K) !bool {
            var node = self.find_lower_bound(self.root, key) orelse return false;
            if (node.key != key) return false;
            var left = node.left;
            if (left != null) {
                // find the rightmost semi-leaf on the left side.
                var prev = left;
                while (left != null and left.?.right != null) {
                    prev = left;
                    left = left.?.right;
                    prev.?.count -= 1;
                }
                if (prev != left) {
                    // cut that semi-leaf out.
                    prev.?.right = left.?.left;
                    std.debug.assert(prev.?.key <= prev.?.right.?.key);
                } else if (left.?.left != null) {
                    // skip over
                    node.left = left.?.left;
                }
                left.?.left = null;
                left.?.count = node.count - 1;
                // left is an isolated leaf now. move it here; first right
                left.?.right = node.right;
                if (node.right != null) node.right.?.parent = left;
                // then left, unless the leaf we are moving in was a direct child
                if (left != node.left) {
                    left.?.left = node.left;
                    if (node.left != null) node.left.?.parent = left;
                }
            } else left = node.right;
            if (left != null) left.?.parent = node.parent;
            // now glue the result (or right tree, or nothing) back to the parent in our place
            if (node.parent != null) {
                if (node.parent.?.left == node) {
                    node.parent.?.left = left;
                } else {
                    node.parent.?.right = left;
                }
            } else self.root = left;
            return true;
        }

        pub const TreeIterator = struct {
            tree: *Self,
            current: ?*Node,
            pub fn init(tree: *Self) TreeIterator {
                var node = tree.root;
                while (node != null and node.?.left != null) node = node.?.left;
                return TreeIterator{
                    .tree = tree,
                    .current = node,
                };
            }

            pub fn next(self: *TreeIterator) ?*Node {
                const tmp = self.current;
                if (tmp == null) return null;
                if (tmp.?.right != null) {
                    // if right sub-tree exists, go there and fetch the first item
                    self.current = tmp.?.right;
                    while (self.current.?.left != null) self.current = self.current.?.left;
                } else {
                    while (self.current.?.parent != null and self.current.?.parent.?.right == self.current) self.current = self.current.?.parent;
                    self.current = self.current.?.parent;
                }
                return tmp;
            }
        };

        pub fn iterator(self: *Self) TreeIterator {
            return TreeIterator.init(self);
        }
    };
}

test "tree insert sorted order and delete" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = ZTree(i64, []const u8).init(allocator);

    _ = try tree.insert(1, "One");
    _ = try tree.insert(2, "Two");
    _ = try tree.insert(3, "Three");
    _ = try tree.insert(4, "Four");

    try testing.expect(tree.contains(2));
    try testing.expect(tree.contains(4));
    try testing.expect(tree.root.?.key == 1);
    try testing.expect(tree.root.?.right.?.key == 2);
    try testing.expect(tree.root.?.right.?.right.?.key == 3);

    _ = try tree.delete(2);

    try testing.expect(!tree.contains(2));
    try testing.expect(tree.root.?.right.?.key == 3);
}

test "iterate over tree in order" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = ZTree(i64, []const u8).init(allocator);

    _ = try tree.insert(4, "Four");
    _ = try tree.insert(1, "One");
    _ = try tree.insert(3, "Three");
    _ = try tree.insert(2, "Two");

    var it = tree.iterator();

    for (1..5) |idx| {
        const node = it.next();
        try testing.expect(node != null);
        try testing.expect(node.?.key == @as(i64, @intCast(idx)));
    }
    try testing.expect(it.next() == null);
}

test "insert multiple, delete, iterate" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var tree = ZTree(usize, usize).init(allocator);

    // insert a bunch of keys
    for (0..1000) |i| {
        _ = try tree.insert((i * 17) % 1009, i);
    }
    // delete 1 in 5 keys in first half
    for (0..100) |i| _ = try tree.delete((i * 5 * 17) % 1009);
    var it = tree.iterator();
    var cnt: usize = 0;
    var prev: usize = 0;
    while (it.next()) |node| {
        cnt += 1;
        try testing.expect(node.key >= prev);
        try testing.expect((node.value * 17) % 1009 == node.key);
        prev = node.key;
    }
    try testing.expect(cnt == 900);
}
