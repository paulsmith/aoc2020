const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const testing = std.testing;
const print = std.debug.print;
const ascii = std.ascii;
const ArrayList = std.ArrayList;
const panic = std.debug.panic;

const getLines = @import("../../lines.zig").getLines;
const strToLines = @import("../../lines.zig").strToLines;

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const lines = try getLines(&arena.allocator);
    var bags = try parseRules(&arena.allocator, lines);
    defer bags.free();
    const result = bags.countBags("shiny gold");
    print("{}\n", .{result});
}

const Bags = struct {
    map: std.StringHashMap(*Bag),
    allocator: *mem.Allocator,

    const Self = @This();

    fn new(allocator: *mem.Allocator) *Self {
        var b = allocator.create(Self) catch unreachable;
        b.map = std.StringHashMap(*Bag).init(allocator);
        b.allocator = allocator;
        return b;
    }

    fn free(self: *Self) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            var bag = entry.value;
            bag.free();
        }
        self.map.deinit();
        self.allocator.destroy(self);
    }

    fn getOrCreateBag(self: *Self, color: []const u8) !*Bag {
        var bag = self.map.get(color) orelse blk: {
            var b = Bag.new(self.allocator, color);
            try self.map.put(color, b);
            break :blk b;
        };
        return bag;
    }

    fn countColors(self: *Self, color: []const u8) i32 {
        const bag = self.map.get(color) orelse {
            panic("invalid graph, expected {}\n", .{color});
        };
        var seen = std.StringHashMap(bool).init(self.allocator);
        defer seen.deinit();
        self.countContained(bag, &seen);
        return @intCast(i32, seen.count());
    }

    fn countContained(self: *Self, bag: *Bag, seen: *std.StringHashMap(bool)) void {
        for (bag.contained_by.items) |_bag| {
            seen.put(_bag.color, true) catch unreachable;
            self.countContained(_bag, seen);
        }
    }

    fn countBags(self: *Self, color: []const u8) i32 {
        const bag = self.map.get(color) orelse {
            panic("invalid graph, expected {}\n", .{color});
        };
        const n = self.countContains(bag);
        return n;
    }

    fn countContains(self: *Self, bag: *Bag) i32 {
        var tally: i32 = 0;
        for (bag.contains.items) |edge| {
            tally += @as(i32, edge.num_bags);
            tally += @as(i32, edge.num_bags) * self.countContains(edge.bag);
        }
        return tally;
    }
};

const Bag = struct {
    color: []const u8,
    contains: ArrayList(Edge),
    contained_by: ArrayList(*Bag),
    allocator: *mem.Allocator,

    const Self = @This();

    const Edge = struct {
        num_bags: u8,
        bag: *Bag,
    };

    fn new(allocator: *mem.Allocator, color: []const u8) *Bag {
        var bag = allocator.create(Bag) catch unreachable;
        bag.allocator = allocator;
        bag.color = color;
        bag.contains = ArrayList(Edge).init(allocator);
        bag.contained_by = ArrayList(*Bag).init(allocator);
        return bag;
    }

    fn free(self: *Self) void {
        self.contains.deinit();
        self.contained_by.deinit();
        self.allocator.destroy(self);
    }

    fn addContains(self: *Self, n: u8, bag: *Bag) !void {
        try self.contains.append(Edge{ .num_bags = n, .bag = bag });
    }
};

// build graph of bags
fn parseRules(allocator: *mem.Allocator, lines: [][]const u8) !*Bags {
    var bags = Bags.new(allocator);
    for (lines) |line| {
        const s = "bags contain";
        const idx = mem.indexOf(u8, line, s).?;
        const color = line[0 .. idx - 1];
        var bag = try bags.getOrCreateBag(color);
        const rest = line[idx + s.len + 1 ..];
        var it = mem.split(rest, ", ");
        while (it.next()) |clause| {
            if (mem.startsWith(u8, clause, "no other")) {
                // no-op
            } else if (ascii.isDigit(clause[0])) {
                const n = clause[0] - '0';
                const bag_idx = mem.indexOf(u8, clause, " bag").?;
                const _color = clause[2..bag_idx];
                var _bag = try bags.getOrCreateBag(_color);
                try _bag.contained_by.append(bag);
                try bag.addContains(n, _bag);
            } else unreachable;
        }
    }
    return bags;
}

test "" {
    const input =
        \\light red bags contain 1 bright white bag, 2 muted yellow bags.
        \\dark orange bags contain 3 bright white bags, 4 muted yellow bags.
        \\bright white bags contain 1 shiny gold bag.
        \\muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
        \\shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
        \\dark olive bags contain 3 faded blue bags, 4 dotted black bags.
        \\vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
        \\faded blue bags contain no other bags.
        \\dotted black bags contain no other bags.
    ;
    const lines = try strToLines(testing.allocator, input);
    defer lines.deinit();
    var bags = try parseRules(testing.allocator, lines.items);
    defer bags.free();
    const n = bags.countBags("shiny gold");
    testing.expectEqual(@as(i32, 32), n);
}
