const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;
const heap = std.heap;
const io = std.io;

const max_stdin_size = 1 * 1024 * 1024;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const stdin = io.getStdIn();
    const input = try stdin.readToEndAlloc(&gpa.allocator, max_stdin_size);
    const result = countValid(input);
    std.debug.print("{}\n", .{result});
}

fn isValid(line: []const u8) !bool {
    var bits = mem.tokenize(line, " :-");
    const lo = try fmt.parseUnsigned(usize, bits.next().?, 10);
    const hi = try fmt.parseUnsigned(usize, bits.next().?, 10);
    const ch = bits.next().?[0];
    const pw = bits.next().?;
    var count: usize = 0;
    for (pw) |_, i| {
        if (pw[i] == ch) {
            count += 1;
        }
    }
    const valid = count >= lo and count <= hi;
    return valid;
}

fn countValid(input: []const u8) !usize {
    var it = mem.split(input, "\n");
    var n: usize = 0;
    while (it.next()) |line| {
        if (line.len > 0) {
            if (try isValid(line)) {
                n += 1;
            }
        }
    }
    return n;
}

test "day 2 test input" {
    const input =
        \\1-3 a: abcde
        \\1-3 b: cdefg
        \\2-9 c: ccccccccc
    ;
    const n = try countValid(input);
    testing.expect(n == 2);
}
