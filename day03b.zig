const std = @import("std");
const lines = @import("./lines.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const map = try lines.getLines(&gpa.allocator);
    const width = map[0].len;
    const Slope = struct {
        right: usize,
        down: usize,
    };
    const slopes = [_]Slope{
        Slope{ .right = 1, .down = 1 },
        Slope{ .right = 3, .down = 1 },
        Slope{ .right = 5, .down = 1 },
        Slope{ .right = 7, .down = 1 },
        Slope{ .right = 1, .down = 2 },
    };
    var product: usize = 1;
    for (slopes) |slope| {
        var height: usize = 0;
        var xpos: usize = 0;
        var ntrees: usize = 0;
        while (height < map.len - 1) {
            xpos = (xpos + slope.right) % width;
            height += slope.down;
            if (map[height][xpos] == '#') {
                ntrees += 1;
            }
        }
        product *= ntrees;
    }
    std.debug.print("{}\n", .{product});
}
