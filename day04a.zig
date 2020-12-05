const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const stdin = std.io.getStdIn();
    const input = try stdin.readToEndAlloc(&gpa.allocator, std.math.maxInt(u32));
    var it = std.mem.split(input, "\n\n");
    const fields = [_][]const u8{
        "byr",
        "iyr",
        "eyr",
        "hgt",
        "hcl",
        "ecl",
        "pid",
        //"cid", // optional
    };
    var map = std.StringHashMap(bool).init(&gpa.allocator);
    var nvalid: usize = 0;
    while (it.next()) |passport| {
        for (fields) |field| {
            try map.put(field, false);
        }
        var fit = std.mem.tokenize(passport, " \n");
        while (fit.next()) |field| {
            const key = std.mem.split(field, ":").next().?;
            try map.put(key, true);
        }
        const valid = blk: {
            for (fields) |field| {
                if (!map.get(field).?) {
                    break :blk false;
                }
            }
            break :blk true;
        };
        if (valid) {
            nvalid += 1;
        }
    }
    std.debug.print("{}\n", .{nvalid});
}
