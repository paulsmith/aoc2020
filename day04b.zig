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
            var kv = std.mem.split(field, ":");
            const key = kv.next().?;
            const val = kv.next().?;
            const valid = blk: {
                if (std.mem.eql(u8, key, "byr")) {
                    break :blk validYear(val, 1920, 2002);
                } else if (std.mem.eql(u8, key, "iyr")) {
                    break :blk validYear(val, 2010, 2020);
                } else if (std.mem.eql(u8, key, "eyr")) {
                    break :blk validYear(val, 2020, 2030);
                } else if (std.mem.eql(u8, key, "hgt")) {
                    break :blk validHeight(val);
                } else if (std.mem.eql(u8, key, "hcl")) {
                    break :blk validHex(val);
                } else if (std.mem.eql(u8, key, "ecl")) {
                    break :blk validEyeColor(val);
                } else if (std.mem.eql(u8, key, "pid")) {
                    break :blk validPid(val);
                } else if (std.mem.eql(u8, key, "cid")) {
                    break :blk true;
                } else {
                    std.debug.print("unknown key: {}: {}\n", .{ key, val });
                    break :blk true;
                }
            };
            //if (!valid) std.debug.print("got invalid {}: {}\n", .{ key, val });
            try map.put(key, valid);
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

fn validYear(val: []const u8, lo: u32, hi: u32) bool {
    if (val.len != 4) return false;
    const n = std.fmt.parseUnsigned(u32, val, 10) catch |_| return false;
    if (n < lo or n > hi) return false;
    return true;
}

fn validHeight(val: []const u8) bool {
    var idx: usize = 0;
    while (idx < val.len and std.ascii.isDigit(val[idx])) : (idx += 1) {}
    const n = std.fmt.parseUnsigned(u32, val[0..idx], 10) catch |_| return false;
    if (std.mem.eql(u8, val[idx..], "cm")) {
        if (n < 150 or n > 193) return false;
    } else {
        if (n < 59 or n > 76) return false;
    }
    return true;
}

fn validHex(val: []const u8) bool {
    if (val[0] != '#') return false;
    if (val[1..].len != 6) return false;
    var idx: usize = 1;
    while (idx <= 6) : (idx += 1) {
        if (!isHexChar(val[idx])) return false;
    }
    return true;
}

fn isHexChar(ch: u8) bool {
    const result = std.ascii.isDigit(ch) or ('a' <= ch and ch <= 'f');
    return result;
}

fn validEyeColor(val: []const u8) bool {
    const colors = [_][]const u8{
        "amb", "blu", "brn", "gry", "grn", "hzl", "oth",
    };
    for (colors) |color| {
        if (std.mem.eql(u8, color, val)) return true;
    }
    return false;
}

fn validPid(val: []const u8) bool {
    if (val.len != 9) return false;
    for (val) |ch| {
        if (!std.ascii.isDigit(ch)) return false;
    }
    return true;
}
