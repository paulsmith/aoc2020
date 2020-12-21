const std = @import("std");
const io = std.io;
const ascii = std.ascii;
const fmt = std.fmt;
const ArrayList = std.ArrayList;
const mem = std.mem;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const stdin = std.io.getStdIn().reader();
    const input = try stdin.readAllAlloc(allocator, 256 * std.mem.page_size);
    var line_it = std.mem.tokenize(input, "\n");
    var sum: isize = 0;
    while (line_it.next()) |line| {
        const tokens = try scan(allocator, line);
        const parser = Parser.new(allocator, tokens);
        const result = parser.parse();
        sum += result;
    }
    std.debug.print("{}\n", .{sum});
}

const TokenKind = enum {
    num,
    add,
    mul,
    lparen,
    rparen,
    eof,
};

const Token = struct {
    kind: TokenKind,
    val: []const u8,

    const Self = @This();

    fn eof() Self {
        return Self{
            .kind = .eof,
            .val = "",
        };
    }

    fn new(kind: TokenKind, val: []const u8) Self {
        return Self{
            .kind = kind,
            .val = val,
        };
    }
};

fn eatWhitespace(input: []const u8) []const u8 {
    var s = input;
    while (s.len > 0 and ascii.isSpace(s[0])) s = s[1..];
    return s;
}

fn scan(allocator: *mem.Allocator, input: []const u8) ![]Token {
    var s = input;
    var tokens = ArrayList(Token).init(allocator);
    while (s.len > 0) {
        s = eatWhitespace(s);
        if (s.len == 0) break;
        if (ascii.isDigit(s[0])) {
            var i: usize = 0;
            while (s.len > i and ascii.isDigit(s[i])) i += 1;
            try tokens.append(Token.new(.num, s[0..i]));
            s = s[i..];
        } else {
            switch (s[0]) {
                '+' => {
                    try tokens.append(Token.new(.add, s[0..1]));
                    s = s[1..];
                },
                '*' => {
                    try tokens.append(Token.new(.mul, s[0..1]));
                    s = s[1..];
                },
                '(' => {
                    try tokens.append(Token.new(.lparen, s[0..1]));
                    s = s[1..];
                },
                ')' => {
                    try tokens.append(Token.new(.rparen, s[0..1]));
                    s = s[1..];
                },
                else => unreachable,
            }
        }
    }
    try tokens.append(Token.eof());
    return tokens.toOwnedSlice();
}

// without precedence:
// expr := factor ( '+' | '*' | ) expr
// factor := num | '(' expr ')'

const Parser = struct {
    tokens: []Token,
    allocator: *mem.Allocator,

    const Self = @This();

    fn new(allocator: *mem.Allocator, tokens: []Token) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .tokens = tokens,
            .allocator = allocator,
        };
        return self;
    }

    fn advance(self: *Self) Token {
        const token = self.tokens[0];
        self.tokens = self.tokens[1..];
        return token;
    }

    fn match(self: *Self, kind: TokenKind) bool {
        if (self.tokens.len > 0 and self.tokens[0].kind == kind)
            return true
        else
            return false;
    }

    fn expect(self: *Self, kind: TokenKind) void {
        if (!self.match(kind))
            self.parseError()
        else
            _ = self.advance();
    }

    fn parseError(self: *Self) void {
        std.debug.print("parse error\n", .{});
        std.process.exit(1);
    }

    fn parseFactor(self: *Self) isize {
        if (self.match(.num)) {
            const val = self.advance().val;
            return fmt.parseInt(isize, val, 10) catch @panic("parse int");
        } else if (self.match(.lparen)) {
            _ = self.advance();
            const val = self.parseExpr();
            self.expect(.rparen);
            return val;
        } else {
            self.parseError();
            unreachable;
        }
    }

    fn isBinOp(self: *Self) bool {
        return self.match(.add) or self.match(.mul);
    }

    fn parseExpr(self: *Self) isize {
        var lhs = self.parseFactor();
        while (self.isBinOp()) {
            const op = self.advance();
            const rhs = self.parseFactor();
            switch (op.kind) {
                .add => lhs += rhs,
                .mul => lhs *= rhs,
                else => unreachable,
            }
        }
        return lhs;
    }

    fn parse(self: *Self) isize {
        return self.parseExpr();
    }
};

test "" {
    const input = "1 + 2 * 3 + 4 * 5 + 6";
    const tokens = try scan(std.testing.allocator, input);
    defer std.testing.allocator.free(tokens);
    for (tokens) |token|
        std.debug.print("kind:{}\tval:{}\n", .{ token.kind, token.val });
    const parser = Parser.new(std.testing.allocator, tokens);
    defer std.testing.allocator.destroy(parser);
    const result = parser.parse();
    std.debug.print("{} => {}\n", .{ input, result });
}
