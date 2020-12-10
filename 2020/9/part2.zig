const std = @import("std");
const heap = std.heap;
const testing = std.testing;
const panic = std.debug.panic;
const print = std.debug.print;
const sort = std.sort;

const lines = @import("../../lines.zig");

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const input = try lines.getLines(&arena.allocator);
    const numbers = try lines.toNumbers(i64, &arena.allocator, input);
    const err = findXmasError(numbers, 25);
    const result = findEncWeakness(numbers, err);
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

const asci64 = sort.asc(i64);

fn findEncWeakness(numbers: []i64, target: i64) i64 {
    var span: usize = 2;
    while (span < numbers.len) : (span += 1) {
        var lo: usize = 0;
        while (lo + span < numbers.len) : (lo += 1) {
            const hi: usize = lo + span;
            var sum: i64 = 0;
            for (numbers[lo..hi]) |n| sum += n;
            if (sum == target) {
                sort.sort(i64, numbers[lo..hi], {}, asci64);
                const result = numbers[lo] + numbers[hi - 1];
                return result;
            }
        }
    }
    panic("could not find encryption weakness for target number {}", .{target});
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
    const result = findEncWeakness(numbers, 127);
    const want: i64 = 62;
    testing.expectEqual(want, result);
}
