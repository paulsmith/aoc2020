const std = @import("std");
const math = std.math;
const mem = std.mem;
const io = std.io;
const fs = std.fs;
const process = std.process;
const ArrayList = std.ArrayList;
const Allocator = mem.Allocator;

pub fn getLines(allocator: *Allocator) ![][]const u8 {
    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    const input = if (args.len == 1 or (args.len == 2 and mem.eql(u8, args[1], "-"))) blk: {
        // consume stdin
        break :blk try io.getStdIn().readToEndAlloc(allocator, math.maxInt(u32));
    } else blk: {
        // open file and read it
        break :blk try fs.cwd().readFileAlloc(allocator, args[1], math.maxInt(u32));
    };
    const lines = try strToLines(allocator, input);
    return lines.items;
}

pub fn strToLines(allocator: *Allocator, str: []const u8) !ArrayList([]const u8) {
    var lines = ArrayList([]const u8).init(allocator);
    var iter = mem.split(str, "\n");
    while (iter.next()) |line| {
        if (line.len > 0) {
            try lines.append(line);
        }
    }
    return lines;
}
