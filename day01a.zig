const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = @import("std").testing.expect;

const max_stdin_size = 1 * 1024 * 1024;

pub fn main() !void {
    //var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    //defer arena.deinit();
    //const allocator = &arena.allocator;
    var allocator_instance = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &allocator_instance.allocator;
    const stdin = std.io.getStdIn();
    const input = try stdin.readToEndAlloc(allocator, max_stdin_size);
    const result = try find(allocator, input);
    std.debug.print("{}\n", .{result});
}

fn find(allocator: *Allocator, input: []const u8) !usize {
    const VecUsize = std.ArrayList(usize);
    var nums = VecUsize.init(allocator);
    defer nums.deinit();
    var iter = std.mem.split(input, "\n");
    while (iter.next()) |num| {
        if (num.len > 0) {
            const n = try std.fmt.parseUnsigned(usize, num, 10);
            try nums.append(n);
        }
    }
    for (nums.items) |n, i| {
        for (nums.items[1..]) |m, j| {
            if (n + m == 2020) {
                return n * m;
            }
        }
    }
    return error.NotFound;
}

test "day 1 test input" {
    const test_input =
        \\1721
        \\979
        \\366
        \\299
        \\675
        \\1456
    ;
    const got = try find(std.testing.allocator, test_input);
    expect(got == 514579);
}
