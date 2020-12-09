const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fmt = std.fmt;
const heap = std.heap;
const assert = std.debug.assert;
const panic = std.debug.panic;
const print = std.debug.print;

const lines = @import("./lines.zig");

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    const input = try lines.getLines(&arena.allocator);
    const instructions = try parseInstructions(&arena.allocator, input);
    defer arena.allocator.free(instructions);
    var cpu = try CPU.new(testing.allocator, instructions);
    defer cpu.free();
    cpu.fixProgram();
    const result = cpu.accumulator;
    print("{}\n", .{result});
}

const CPU = struct {
    accumulator: i32,
    pc: usize,
    counter: []i8,
    mem: []Inst,
    allocator: *mem.Allocator,
    inst_ptr: usize,

    const Self = @This();

    fn new(allocator: *mem.Allocator, ram: []Inst) !*Self {
        var cpu = try allocator.create(Self);
        cpu.accumulator = 0;
        cpu.pc = 0;
        cpu.mem = ram;
        cpu.counter = try allocator.alloc(i8, ram.len);
        cpu.allocator = allocator;
        return cpu;
    }

    fn free(self: *Self) void {
        self.allocator.free(self.counter);
        self.allocator.destroy(self);
    }

    fn isLooping(self: *Self) bool {
        assert(self.pc < self.mem.len);
        if (self.counter[@intCast(usize, self.pc)] > 0) return true;
        return false;
    }

    fn running(self: *Self) bool {
        const stopped = (self.pc >= self.mem.len) or self.isLooping();
        return !stopped;
    }

    fn step(self: *Self) void {
        assert(self.pc < self.mem.len);
        const inst = self.mem[self.pc];
        var advance_pc: i32 = 1;
        switch (inst.op) {
            .acc => self.accumulator += inst.arg,
            .jmp => advance_pc = inst.arg,
            .nop => {},
        }
        const count = self.counter[self.pc];
        self.counter[self.pc] = count + 1;
        self.pc = @intCast(usize, (@intCast(i32, self.pc) + advance_pc));
    }

    fn run(self: *Self, instrument: bool) void {
        while (self.running()) {
            self.step();
        }
    }

    fn reset(self: *Self) void {
        self.pc = 0;
        self.accumulator = 0;
        for (self.counter) |*ptr| ptr.* = 0;
    }

    fn terminatedNormally(self: *Self) bool {
        return self.pc == self.mem.len;
    }

    fn fixProgram(self: *Self) void {
        var idx: usize = 0;
        while (idx < self.mem.len - 1) {
            while (self.mem[idx].op != .jmp and self.mem[idx].op != .nop) : (idx += 1) {}
            if (idx == self.mem.len) break;
            const old_op = self.mem[idx].op;
            self.mem[idx].op = switch (old_op) {
                .jmp => .nop,
                .nop => .jmp,
                else => unreachable,
            };
            self.reset();
            self.run(false);
            if (self.terminatedNormally()) break;
            self.mem[idx].op = old_op;
            idx += 1;
        }
        if (!self.terminatedNormally()) panic("no fixable instruction found", .{});
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
    cpu.fixProgram();
    testing.expectEqual(cpu.accumulator, 8);
}
