const std = @import("std");
const getLines = @import("./lines.zig").getLines;
const print = std.debug.print;
const assert = std.debug.assert;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const lines = try getLines(&arena.allocator);

    var max_seat_id: u32 = 0;
    for (lines) |line| {
        const seat_id = findSeat(line);
        max_seat_id = std.math.max(seat_id, max_seat_id);
    }

    print("{}\n", .{max_seat_id});
}

fn parseBinary(str: []const u8, lo_ch: u8, hi_ch: u8, max_n: u32) u32 {
    var result: u32 = 0;
    var n = max_n;
    for (str) |ch| {
        result += if (ch == hi_ch) (n / 2) else 0;
        n /= 2;
    }
    return result;
}

fn findSeat(boarding_pass: []const u8) u32 {
    const row = parseBinary(boarding_pass[0..7], 'F', 'B', 128);
    const col = parseBinary(boarding_pass[7..], 'L', 'R', 8);
    const seat_id = row * 8 + col;
    return seat_id;
}

test "" {
    const TestCase = struct {
        input: []const u8,
        seat_id: u32,
    };
    const test_cases = [_]TestCase{
        .{ .input = "FBFBBFFRLR", .seat_id = 357 },
        .{ .input = "BFFFBBFRRR", .seat_id = 567 },
        .{ .input = "FFFBBBFRRR", .seat_id = 119 },
        .{ .input = "BBFFBBFRLL", .seat_id = 820 },
    };
    for (test_cases) |test_case| {
        const got = findSeat(test_case.input);
        std.testing.expect(test_case.seat_id == got);
    }
}
