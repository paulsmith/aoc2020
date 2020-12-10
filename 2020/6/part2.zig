const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const stdin = std.io.getStdIn();
    const input = try stdin.readToEndAlloc(&arena.allocator, 1 * 1024 * 1024);

    const result = customs(input);
    std.debug.print("{}\n", .{result});
}

fn customs(input: []const u8) i32 {
    var it = std.mem.split(input, "\n\n");
    var sum: i32 = 0;
    while (it.next()) |line| {
        var all = [_]bool{false} ** 26;
        var _it = std.mem.split(line, "\n");
        var first = _it.next().?;
        for (first) |ch| {
            all[ch - 'a'] = true;
        }
        while (_it.next()) |person| {
            var answers = [_]bool{false} ** 26;
            for (person) |ch| {
                answers[ch - 'a'] = true;
            }
            for (answers) |_, i| {
                if (all[i] and !answers[i]) all[i] = false;
            }
        }
        for (all) |answer| {
            if (answer) sum += 1;
        }
    }
    return sum;
}

test "" {
    const input =
        \\abc
        \\
        \\a
        \\b
        \\c
        \\
        \\ab
        \\ac
        \\
        \\a
        \\a
        \\a
        \\a
        \\
        \\b
    ;
    std.testing.expect(customs(input) == 6);
}
