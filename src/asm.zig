const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const RegisterSelector = @import("vm.zig").RegisterSelector;

pub const Assembler = struct {
    const TagLocation = struct { location: u64, tag_name: []const u8 };
    tokens: [][][]const u8,
    allocator: *std.mem.Allocator,
    unresolved_tags_table: std.ArrayList(TagLocation),
    tag_locations_table: std.StringHashMap(u64),
    byte_buffer: []u8,

    pub fn init(allocator: *std.mem.Allocator, input: []const u8) !Assembler {
        var unresolved_tags_table = std.ArrayList(TagLocation).init(allocator);
        var tag_locations_table = std.StringHashMap(u64).init(allocator);

        var lines = std.ArrayList([][]const u8).init(allocator);
        var line_iterator = std.mem.tokenize(u8, input, "\n");
        while (line_iterator.next()) |line| {
            var tokens = std.ArrayList([]const u8).init(allocator);
            var token_iterator = std.mem.tokenize(u8, line, " ");
            while (token_iterator.next()) |token| {
                try tokens.append(token);
            }
            // This leaves the slice allocated in memory and must be freed with deinit()
            try lines.append(tokens.toOwnedSlice());
        }

        return Assembler{
            // This also leaves the slice allocated in memory and must be freed
            .tokens = lines.toOwnedSlice(),
            .allocator = allocator,
            .unresolved_tags_table = unresolved_tags_table,
            .tag_locations_table = tag_locations_table,
            .byte_buffer = &[_]u8{},
        };
    }

    fn string_to_enum(comptime T: type, str: []const u8) ?T {
        inline for (@typeInfo(T).Enum.fields) |enumField| {
            if (std.mem.eql(u8, str, enumField.name)) {
                return @field(T, enumField.name);
            }
        }
        return null;
    }

    fn register_to_address(self: *Assembler, ident: []const u8, location: u64) !?u8 {
        const reg: u8 = if (std.mem.eql(u8, ident, "zero")) 0x00 else if (std.mem.eql(u8, ident[0..2], "sp")) sp: {
            if (ident[3] == "@"[0]) {
                const address = @truncate(u5, try std.fmt.parseInt(u6, ident[4..], 0));
                break :sp @as(u8, @enumToInt(RegisterSelector.sp)) << 5 | address;
            } else {
                break :sp @as(u8, @enumToInt(RegisterSelector.sp_offset)) << 5 | try std.fmt.parseInt(u5, ident[1..], 0);
            }
            break :sp 0x00;
        } else blk: {
            break :blk switch (ident[0]) {
                "a"[0] | "A"[0] => @as(u8, @enumToInt(RegisterSelector.int)) << 5 | try std.fmt.parseInt(u8, ident[1..], 0),
                ":"[0] => {
                    try self.unresolved_tags_table.append(.{
                        .location = location,
                        .tag_name = ident[1..],
                    });
                    return null;
                },
                else => els: {
                    std.log.alert("Invalid register identifier! {s}", .{ident});
                    break :els 0xFF;
                },
            };
        };
        return reg;
    }

    pub fn first_pass(self: *Assembler) !void {
        var buffer = std.ArrayList(u8).init(self.allocator);

        for (self.tokens) |line| {
            const ins = line[0];
            if (ins[ins.len - 1] == ":"[0]) {
                try self.tag_locations_table.put(ins[0 .. ins.len - 1], buffer.items.len);
                continue;
            } else {
                var upper_ins: []const u8 = std.ascii.allocUpperString(self.allocator, ins) catch |e| blk: {
                    std.log.err("Cannot upperate the string {s}", .{e});
                    break :blk "IGL";
                };
                defer self.allocator.free(upper_ins);

                if (string_to_enum(Instruction, upper_ins)) |enum_variant| {
                    try buffer.append(@enumToInt(enum_variant));
                    for (line[1..]) |token| {
                        if (try self.register_to_address(token, buffer.items.len)) |byte| {
                            try buffer.append(byte);
                        } else {
                            // Append 8 bytes of free space, as the instruction needs them reserved
                            try buffer.appendNTimes(0x00, 8);
                        }
                    }
                }
            }
        }

        self.byte_buffer = buffer.toOwnedSlice();
    }

    pub fn second_pass(self: *Assembler) !void {
        for (self.unresolved_tags_table.items) |unresolved_tag| {
            self.byte_buffer[unresolved_tag.location..][0..8].* = std.mem.asBytes(&self.tag_locations_table.get(unresolved_tag.tag_name).?).*;
        }
    }

    pub fn deinit(self: *Assembler) void {
        // deinit arrays
        self.tag_locations_table.deinit();
        self.unresolved_tags_table.deinit();

        // free slices
        // Free all the inner slices
        for (self.tokens) |token| {
            self.allocator.free(token);
        }
        // Free the outer slice
        self.allocator.free(self.tokens);
        self.allocator.free(self.byte_buffer);
    }
};

test "ASM: Test tokenization" {
    const assembly = "add a0 a1 a2";

    var assm = try Assembler.init(std.testing.allocator, assembly);
    defer assm.deinit();

    const test_data: []const []const []const u8 = ([_][]const []const u8{([_]([]const u8){ "add", "a0", "a1", "a2" })[0..]})[0..];
    for (assm.tokens) |line, line_index| {
        for (line) |_, index| {
            try std.testing.expectEqualStrings(test_data[line_index][index], line[index]);
        }
    }
}

test "ASM: String to enum translation" {
    const assembly = "add\nhlt";

    var assembler = try Assembler.init(std.testing.allocator, assembly);
    defer assembler.deinit();

    const test_data: []const u8 = &[_]u8{ @enumToInt(Instruction.ADD), @enumToInt(Instruction.HLT) };

    try assembler.first_pass();

    try std.testing.expectEqualSlices(u8, test_data, assembler.byte_buffer);
}

test "ASM: simple program translation" {
    const intReg = @import("vm.zig").intReg;
    const assembly = "add a0 a1 a2\nhlt zero";
    var assembler = try Assembler.init(std.testing.allocator, assembly);
    defer assembler.deinit();

    const test_data: []const u8 = &[_]u8{ @enumToInt(Instruction.ADD), intReg(0), intReg(1), intReg(2), @enumToInt(Instruction.HLT), 0 };

    try assembler.first_pass();

    try std.testing.expectEqualSlices(u8, test_data, assembler.byte_buffer);
}

test "ASM: tag generation" {
    const assembly = "tag:\njmp :tag";
    var assembler = try Assembler.init(std.testing.allocator, assembly);
    defer assembler.deinit();

    try assembler.first_pass();

    try std.testing.expectEqual(@as(u64, 0x00), assembler.tag_locations_table.get("tag").?);
    try std.testing.expectEqual(@as(u64, 0x01), assembler.unresolved_tags_table.items[0].location);
    try std.testing.expectEqualStrings("tag", assembler.unresolved_tags_table.items[0].tag_name);
}

test "ASM: tag resolution" {
    const intReg = @import("vm.zig").intReg;
    const assembly = "add a0 a1 zero\ntag:\njmp :tag";
    var assembler = try Assembler.init(std.testing.allocator, assembly);
    defer assembler.deinit();

    try assembler.first_pass();
    try std.testing.expectEqualSlices(u8, ([_]u8{ @enumToInt(Instruction.ADD), intReg(0), intReg(1), 0, @enumToInt(Instruction.JMP), 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 })[0..], assembler.byte_buffer);
    try assembler.second_pass();
    try std.testing.expectEqualSlices(u8, ([_]u8{ @enumToInt(Instruction.ADD), intReg(0), intReg(1), 0, @enumToInt(Instruction.JMP), 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 })[0..], assembler.byte_buffer);
}

// TODO: test stack pointer
