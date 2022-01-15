const std = @import("std");
const Value = @import("value.zig").Value;

const Self = @This();

parent: ?*Self,
children: std.ArrayList(*Self),
symbols: std.StringHashMap(Value),

pub fn init(allocator: std.mem.Allocator, parent: ?*Self) Self {
    const self: Self = .{
        .parent = parent,
        .children = std.ArrayList(*Self).init(allocator),
        .symbols = std.StringHashMap(Value).init(allocator),
    };
    return self;
}

pub fn deinit(self: *Self) void {
    for (self.children.items) |child| child.*.deinit();
    self.children.deinit();
    self.symbols.deinit();
}

pub fn get(self: *Self, symbol: []const u8) ?Value {
    return if (self.symbols.get(symbol)) |val| val else if (self.parent) |parent| parent.*.get(symbol) else null;
}

pub fn getHashed(self: *Self, hash: u64) ?Value {
    return if (self.symbols.getAdapted(hash, SymbolHashAdaptor{})) |val| val else if (self.parent) |parent| parent.*.getAdapted(hash) else null;
}

pub fn registerSymbol(self: *Self, symbol: []const u8, val: Value) !u64 {
    const hash = std.hash.Wyhash.hash(0, symbol);

    try self.symbols.putNoClobber(symbol, val);

    return hash;
}

const SymbolHashAdaptor = struct {
    const SHA = @This();
    pub fn eql(self: SHA, a: u64, b_string: []const u8) bool {
        _ = self;
        // Use the std.StringHashMap hasher
        return a == std.hash.Wyhash.hash(0, b_string);
    }

    pub fn hash(self: SHA, adapted_key: u64) u64 {
        _ = self;
        return adapted_key;
    }
};

test "Environment: Test adapter" {
    var env = Self{
        .parent = null,
        .symbols = std.StringHashMap(Value).init(std.testing.allocator),
    };
    defer env.symbols.deinit();

    const hash = std.hash.Wyhash.hash(0, "key");
    const val = Value.initInt(5);
    const sha: SymbolHashAdaptor = .{};
    try env.symbols.put("key", val);
    try std.testing.expectEqual(val, env.symbols.getAdapted(hash, sha).?);
}

test "Environment: Test parent" {
    var parent_env = Self{
        .parent = null,
        .symbols = std.StringHashMap(Value).init(std.testing.allocator),
    };
    defer parent_env.symbols.deinit();
    var child_env = Self{
        .parent = *parent_env,
        .symbols = std.StringHashMap(Value).init(std.testing.allocator),
    };
    defer child_env.symbols.deinit();
}
