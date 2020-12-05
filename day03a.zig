const std = @import("std");
const lines = @import("./lines.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const map = try lines.getLines(&gpa.allocator);
    const width = map[0].len;
    var ntrees: usize = 0;
    var height: usize = 0;
    var xpos: usize = 0;
    while (height < map.len - 1) {
        xpos = (xpos + 3) % width;
        height += 1;
        if (map[height][xpos] == '#') {
            ntrees += 1;
        }
    }
    std.debug.print("{}\n", .{ntrees});
}
