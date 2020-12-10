const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;
const heap = std.heap;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const assert = std.debug.assert;
const print = std.debug.print;

const lines = @import("../../lines.zig");

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    const input = try lines.getLines(&arena.allocator);
    const instructions = try parseInstructions(&arena.allocator, input);
    defer arena.allocator.free(instructions);
    var cpu = try CPU.new(testing.allocator, instructions);
    defer cpu.free();
    while (cpu.loopNotHit()) {
        cpu.step();
    }
    const result = cpu.accumulator;
    print("{}\n", .{result});
}

const CPU = struct {
    accumulator: i32,
    pc: i32,
    counter: AutoHashMap(i32, i32),
    mem: []Inst,
    allocator: *mem.Allocator,

    const Self = @This();

    fn new(allocator: *mem.Allocator, ram: []Inst) !*Self {
        var cpu = try allocator.create(Self);
        cpu.accumulator = 0;
        cpu.pc = 0;
        cpu.counter = AutoHashMap(i32, i32).init(allocator);
        cpu.mem = ram;
        cpu.allocator = allocator;
        return cpu;
    }

    fn free(self: *Self) void {
        self.counter.deinit();
        self.allocator.destroy(self);
    }

    fn loopNotHit(self: *Self) bool {
        const nhit = self.counter.get(self.pc) orelse 0;
        if (nhit == 1) return false;
        return true;
    }

    fn step(self: *Self) void {
        assert(self.pc < self.mem.len);
        const inst = self.mem[@intCast(usize, self.pc)];
        var advance_pc: i32 = 1;
        switch (inst.op) {
            .acc => self.accumulator += inst.arg,
            .jmp => advance_pc = inst.arg,
            .nop => {},
        }
        self.counter.put(self.pc, (self.counter.get(self.pc) orelse 0) + 1) catch unreachable;
        self.pc += advance_pc;
    }
};

const Op = enum {
    acc,
    jmp,
    nop,
};

const Inst = struct {
    op: Op,
    arg: i32,
};

fn parseInstructions(allocator: *mem.Allocator, input: [][]const u8) ![]Inst {
    var insts = try allocator.alloc(Inst, input.len);
    for (input) |line, i| {
        var op = if (mem.eql(u8, line[0..3], "acc"))
            Op.acc
        else if (mem.eql(u8, line[0..3], "jmp"))
            Op.jmp
        else if (mem.eql(u8, line[0..3], "nop"))
            Op.nop
        else
            unreachable;
        const arg = try fmt.parseInt(i32, line[4..], 10);
        const inst = .{ .op = op, .arg = arg };
        insts[i] = inst;
    }
    return insts;
}

test "" {
    const test_input =
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\jmp -4
        \\acc +6
    ;
    const input = try lines.strToLines(testing.allocator, test_input);
    defer input.deinit();
    const instructions = try parseInstructions(testing.allocator, input.items);
    defer testing.allocator.free(instructions);
    var cpu = try CPU.new(testing.allocator, instructions);
    defer cpu.free();
    while (cpu.loopNotHit()) {
        cpu.step();
    }
    testing.expectEqual(cpu.accumulator, 5);
}
