// Copyright (C) 2021 by Jáchym Tomášek
const std = @import("std");
const R_Instruction = @import("instruction.zig").R_Instruction;
const I_Instruction = @import("instruction.zig").I_Instruction;
const C_Instruction = @import("instruction.zig").C_Instruction;
const PseudoInstruction = @import("instruction.zig").PseudoInstruction;
const Register = @import("register.zig").Register;
const vm = @import("vm.zig");
const string_to_enum = @import("util.zig").string_to_enum;
const build_instruction = @import("util.zig").build_instruction;
const register_to_address = @import("util.zig").register_to_address;
const build_I_Instruction = @import("util.zig").build_I_Instruction;
const build_C_Instruction = @import("util.zig").build_C_Instruction;
const build_R_Instruction = @import("util.zig").build_R_Instruction;

pub const Assembler = struct {
    const TagLocation = struct { location: u64, tag_name: []const u8 };
    tokens: std.ArrayList([][]const u8),
    allocator: *std.mem.Allocator,
    unresolved_tags_table: std.ArrayList(TagLocation),
    tag_locations_table: std.StringHashMap(u64),
    instruction_buffer: []u32,
    assembler_progress: std.Progress = std.Progress{},

    fn tokenize_line(allocator: *std.mem.Allocator, line: []const u8) !std.ArrayList([]const u8) {
        var tokens = std.ArrayList([]const u8).init(allocator);
        var token_iterator = std.mem.tokenize(line, " ");
        while (token_iterator.next()) |token| {
            try tokens.append(token);
        }
        return tokens;
    }

    fn tokenize_file(allocator: *std.mem.Allocator, input: []const u8) !std.ArrayList([][]const u8) {
        var lines = std.ArrayList([][]const u8).init(allocator);
        var line_iterator = std.mem.tokenize(input, "\n");
        while (line_iterator.next()) |line| {
            try lines.append((try tokenize_line(allocator, line)).toOwnedSlice());
        }
        // This leaves the slice allocated in memory and must be freed with deinit()
        return lines;
    }

    pub fn init(allocator: *std.mem.Allocator, input: []const u8) !Assembler {
        var unresolved_tags_table = std.ArrayList(TagLocation).init(allocator);
        var tag_locations_table = std.StringHashMap(u64).init(allocator);

        const lines = try tokenize_file(allocator, input);

        return Assembler{
            // This also leaves the slice allocated in memory and must be freed
            .tokens = lines,
            .allocator = allocator,
            .unresolved_tags_table = unresolved_tags_table,
            .tag_locations_table = tag_locations_table,
            .instruction_buffer = &[_]u32{},
        };
    }

    fn parse_line(self: *Assembler, line: [][]const u8, location: u64) !?[]const u32 {
        var buffer = std.ArrayList(u32).init(self.allocator);
        const ins = line[0];
        if (ins[0] == ";"[0]) {
            return null;
        } else if (ins[ins.len - 1] == ":"[0]) {
            try self.tag_locations_table.put(ins[0 .. ins.len - 1], location);
            return null;
        } else {
            var upper_ins: []const u8 = std.ascii.allocUpperString(self.allocator, ins) catch |e| blk: {
                std.log.err("Cannot upperate the string {s}", .{e});
                break :blk "IGL";
            };
            defer self.allocator.free(upper_ins);

            if (string_to_enum(R_Instruction, upper_ins)) |r_ins| {
                if (line.len < 4) {
                    std.log.err("Line: {s}\nR-Instruction must have at least 3 operands", .{line});
                }
                const rd = register_to_address(line[1]).?;
                const rs1 = register_to_address(line[2]).?;
                const rs2 = register_to_address(line[3]).?;

                try buffer.append(build_R_Instruction(r_ins, rd, rs1, rs2));
            } else if (string_to_enum(I_Instruction, upper_ins)) |i_ins| {
                if (line.len < 4) {
                    std.log.err("Line: {s}\nR-Instruction must have at least 2 operands and a offset", .{line});
                }
                const rd = register_to_address(line[1]).?;
                const rs1 = register_to_address(line[2]).?;
                const imm12 = @bitCast(u12, @intCast(i12, try self.label_to_offset(line[3], location)));

                try buffer.append(build_I_Instruction(i_ins, rd, rs1, imm12));
            } else if (string_to_enum(C_Instruction, upper_ins)) |c_ins| {
                if (line.len < 3) {
                    std.log.err("Line: {s}\nR-Instruction must have at least 1 operand and a offset", .{line});
                }

                const rd = register_to_address(line[1]).?;
                const imm20 = @bitCast(u20, @intCast(i20, try self.label_to_offset(line[2], location)));

                try buffer.append(build_C_Instruction(c_ins, rd, imm20));
            } else {
                if (string_to_enum(PseudoInstruction, upper_ins)) |pseudo_ins| {
                    switch (pseudo_ins) {
                        PseudoInstruction.NOP => {
                            try buffer.append(build_instruction(I_Instruction.ADDI, "zero", "zero", null, 0));
                        },
                        PseudoInstruction.J => {
                            if (line.len < 2) {
                                std.log.err("Line: {s}\n J-pseudoinstruction must have atleast an offset", .{line});
                            }
                            const offset = try self.label_to_offset(line[1], location);
                            try buffer.append(build_instruction(C_Instruction.JR, "zero", null, null, @bitCast(u32, offset)));
                        },
                        PseudoInstruction.JAL => {
                            if (line.len < 3) {
                                std.log.err("Line: {s}\n JAL-pseudoinstruction must have atleast rd and offset", .{line});
                            }
                            const offset = try self.label_to_offset(line[2], location);
                            try buffer.append(build_instruction(I_Instruction.JALR, line[1], "zero", null, @bitCast(u32, offset)));
                        },
                        PseudoInstruction.CALL => {
                            if (line.len < 2) {
                                std.log.err("Line: {s}\n CALL-pseudoinstruction must have atleast an offset", .{line});
                            }
                            const offset = try self.label_to_offset(line[2], location);
                            const imm20 = @truncate(u20, @bitCast(u32, offset) >> 12);
                            const imm12 = @truncate(u12, @bitCast(u32, offset));

                            try buffer.append(build_instruction(C_Instruction.AUIPC, "ra", null, null, imm20));
                            try buffer.append(build_instruction(I_Instruction.JALR, "ra", "ra", null, imm12));
                        },
                        PseudoInstruction.TAIL => {
                            if (line.len < 2) {
                                std.log.err("Line: {s}\n TAIL-pseudoinstruction must have atleast an offset", .{line});
                            }
                            const offset = try self.label_to_offset(line[2], location);
                            const imm20 = @truncate(u20, @bitCast(u32, offset) >> 12);
                            const imm12 = @truncate(u12, @bitCast(u32, offset));

                            try buffer.append(build_instruction(C_Instruction.AUIPC, "t0", null, null, imm20));
                            try buffer.append(build_instruction(C_Instruction.JR, "t0", null, null, @as(u20, imm12)));
                        },
                        PseudoInstruction.MV => {
                            if (line.len < 3) {
                                std.log.err("Line: {s}\n MV-pseudoinstruction must have atleast rd and rs", .{line});
                            }

                            try buffer.append(build_instruction(I_Instruction.ADDI, line[1], line[2], null, 0));
                        },
                        PseudoInstruction.RET => {
                            try buffer.append(build_instruction(C_Instruction.JR, "ra", null, null, 0));
                        },
                        PseudoInstruction.NOT => {
                            try buffer.append(build_instruction(I_Instruction.XORI, line[1], line[2], null, @bitCast(u32, @as(i32, -1))));
                        },
                        PseudoInstruction.NEG => {
                            try buffer.append(build_instruction(R_Instruction.SUB, line[1], "zero", line[2], null));
                        },
                        PseudoInstruction.GT => {
                            try buffer.append(build_instruction(R_Instruction.LT, line[1], line[3], line[2], null));
                        },
                        PseudoInstruction.LE => {
                            try buffer.append(build_instruction(R_Instruction.GE, line[1], line[3], line[2], null));
                        },
                        else => return undefined,
                    }
                }
            }
            return buffer.toOwnedSlice();
        }
    }

    fn label_to_offset(self: *Assembler, token: []const u8, call_location: u64) !i32 {
        if (token[0] == ':') {
            if (self.tag_locations_table.get(token[1..])) |location| {
                return @intCast(i32, @intCast(i65, location) - @intCast(i65, (call_location + 1)));
            } else {
                std.log.err("Label {s} not found! {s} item", .{ token, self.tag_locations_table.keyIterator().next().?.* });
                return 0;
            }
        } else {
            return try std.fmt.parseInt(i32, token, 0);
        }
    }

    /// Convert instructions into bytecode and scan for labels
    pub fn assembly_pass(self: *Assembler) !void {
        const first_pass_node = try self.assembler_progress.start("Assembler first pass", self.tokens.items.len);
        var buffer = std.ArrayList(u32).init(self.allocator);

        for (self.tokens.items) |line| {
            if (try self.parse_line(line, buffer.items.len)) |parsed| {
                try buffer.appendSlice(parsed);
                self.allocator.free(parsed);
            }
            first_pass_node.completeOne();
        }

        self.instruction_buffer = buffer.toOwnedSlice();
        first_pass_node.end();
    }

    pub fn deinit(self: *Assembler) void {
        // deinit arrays
        self.tag_locations_table.deinit();
        self.unresolved_tags_table.deinit();

        // free slices
        // Free all the inner slices
        for (self.tokens.items) |token| {
            self.allocator.free(token);
        }
        // Free the outer slice
        self.tokens.deinit();
        self.allocator.free(self.instruction_buffer);
    }
};

test "ASM: Test tokenization" {
    const assembly = "add a0 a1 a2";

    var assm = try Assembler.init(std.testing.allocator, assembly);
    defer assm.deinit();

    const test_data: []const []const []const u8 = ([_][]const []const u8{([_]([]const u8){ "add", "a0", "a1", "a2" })[0..]})[0..];
    for (assm.tokens.items) |line, line_index| {
        for (line) |_, index| {
            try std.testing.expectEqualStrings(test_data[line_index][index], line[index]);
        }
    }
}

test "ASM: simple program translation" {
    const assembly = "add a0 a1 a2\nhlt zero zero zero";
    var assembler = try Assembler.init(std.testing.allocator, assembly);
    defer assembler.deinit();

    const test_data: []const u32 = &[_]u32{
        build_R_Instruction(R_Instruction.ADD, @enumToInt(Register.a0), @enumToInt(Register.a1), @enumToInt(Register.a2)),
        build_R_Instruction(R_Instruction.HLT, @enumToInt(Register.zero), @enumToInt(Register.zero), @enumToInt(Register.zero)),
    };

    try assembler.assembly_pass();

    try std.testing.expectEqualSlices(u32, test_data, assembler.instruction_buffer);
}

test "ASM: tag resolution" {
    const assembly = "add a0 a1 zero\ntag:\nj :tag";
    const test_data: []const u32 = &[_]u32{
        build_instruction(R_Instruction.ADD, "a0", "a1", "zero", 0),
        build_instruction(C_Instruction.JR, "zero", null, null, @bitCast(u32, @as(i32, -1))),
    };
    var assembler = try Assembler.init(std.testing.allocator, assembly);
    defer assembler.deinit();
    try assembler.assembly_pass();
    try std.testing.expectEqualSlices(u32, test_data, assembler.instruction_buffer);
}

// TODO: test stack pointer
