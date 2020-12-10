const std = @import("std");
const mem = @import("std").mem;
const io = @import("std").io;
const fmt = @import("std").fmt;
const heap = @import("std").heap;
const Allocator = mem.Allocator;
const expect = @import("std").testing.expect;

const max_stdin_size = 1 * 1024 * 1024;

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const stdin = io.getStdIn().reader();
    const input = try stdin.readAllAlloc(allocator, max_stdin_size);
    const result = try find(allocator, input);
    std.debug.print("{}\n", .{result});
}

fn find(allocator: *Allocator, input: []const u8) !usize {
    const VecUsize = std.ArrayList(usize);
    var nums = VecUsize.init(allocator);
    defer nums.deinit();
    var iter = mem.split(input, "\n");
    while (iter.next()) |num| {
        if (num.len > 0) {
            const n = try fmt.parseUnsigned(usize, num, 10);
            try nums.append(n);
        }
    }
    for (nums.items) |n| {
        for (nums.items[1..]) |m| {
            for (nums.items[2..]) |x| {
                if (n + m + x == 2020) {
                    return n * m * x;
                }
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
    expect(got == 241861950);
}
