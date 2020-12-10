const std = @import("std");
const heap = std.heap;
const testing = std.testing;
const panic = std.debug.panic;
const print = std.debug.print;

const lines = @import("../../lines.zig");

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const input = try lines.getLines(&arena.allocator);
    const numbers = try lines.toNumbers(i64, &arena.allocator, input);
    const result = findXmasError(numbers, 25);
    print("{}\n", .{result});
}

fn findXmasError(numbers: []i64, preambleLen: usize) i64 {
    var idx: usize = 0;
    while (idx + preambleLen < numbers.len - 1) : (idx += 1) {
        const preamble = numbers[idx .. idx + preambleLen];
        const next = numbers[idx + preambleLen];

        var found = false;
        for (preamble) |n| loop: {
            for (preamble[1..]) |m| {
                if (n != m and n + m == next) {
                    found = true;
                    break :loop;
                }
            }
        }
        if (!found) return next;
    }
    panic("could not find error number", .{});
}

test "" {
    const test_input =
        \\35
        \\20
        \\15
        \\25
        \\47
        \\40
        \\62
        \\55
        \\65
        \\95
        \\102
        \\117
        \\150
        \\182
        \\127
        \\219
        \\299
        \\277
        \\309
        \\576
    ;
    const input = try lines.strToLines(testing.allocator, test_input);
    defer input.deinit();
    const numbers = try lines.toNumbers(i64, testing.allocator, input.items);
    defer testing.allocator.free(numbers);
    const result = findXmasError(numbers, 5);
    const want: i64 = 127;
    testing.expectEqual(want, result);
}
