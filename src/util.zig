// Copyright (C) 2022 by Jáchym Tomášek

// Two types of social contradictions - those between ourselves and the enemy
// and those among the people themselves confront us. The two are totally 
// different in their nature. 

const std = @import("std");
const I_Instruction = @import("instruction.zig").I_Instruction;
const C_Instruction = @import("instruction.zig").C_Instruction;
const R_Instruction = @import("instruction.zig").R_Instruction;
const Register = @import("register.zig").Register;
const vm = @import("vm.zig");

/// Convert string to an enum variant.
pub fn string_to_enum(comptime T: type, str: []const u8) ?T {
    // This is some advanced zig magic that I don't truly understand.
    // Thanks to people on the zig discord
    // inline for unrolls the loop
    inline for (@typeInfo(T).Enum.fields) |enumField| {
        // for each enum field it equates its name to the string
        // if they are equal, return the enum field
        if (std.mem.eql(u8, str, enumField.name)) {
            return @field(T, enumField.name);
        }
    }
    return null;
}

/// Covert from string with the register name to a u5 id of the register
pub fn register_to_address(ident: []const u8) ?u5 {
    // for string methods they need a preallocated buffer to save to
    var buffer: [100]u8 = undefined;

    const lower_reg = std.ascii.lowerString(buffer[0..], ident);

    if (string_to_enum(Register, lower_reg)) |enum_variant| {
        return @enumToInt(enum_variant);
    } else {
        std.log.err("Unrecognized register {s}", .{ident});
        return null;
    }
}

pub fn build_R_Instruction(opcode: R_Instruction, rd: u5, rs1: u5, rs2: u5) u32 {
    const r_ins = (@intCast(u32, @enumToInt(opcode)) << 2) | (@intCast(u32, rd) << 17) | (@intCast(u32, rs1) << 22) | (@intCast(u32, rs2) << 27);
    return r_ins;
}

pub fn build_I_Instruction(opcode: I_Instruction, rd: u5, rs1: u5, imm12: u12) u32 {
    const i_ins = 1 | (@intCast(u32, @enumToInt(opcode)) << 1) | (@intCast(u32, rd) << 10) | (@intCast(u32, rs1) << 15) | (@intCast(u32, imm12) << 20);
    return i_ins;
}

pub fn build_C_Instruction(opcode: C_Instruction, rd: u5, imm20: u20) u32 {
    const c_ins = 2 | (@intCast(u32, @enumToInt(opcode)) << 2) | (@intCast(u32, rd) << 7) | (@intCast(u32, imm20) << 12);
    return c_ins;
}

/// Build instruction of any type. Depending on the type fill unused operands with `null`
pub fn build_instruction(comptime instruction: anytype, op1: ?[]const u8, op2: ?[]const u8, op3: ?[]const u8, imm: ?u32) u32 {
    switch (@TypeOf(instruction)) {
        C_Instruction => {
            const imm64 = imm.?;
            const ins = build_C_Instruction(instruction, register_to_address(op1.?).?, @truncate(u20, imm64));
            return ins;
        },
        I_Instruction => {
            const imm64 = imm.?;
            return build_I_Instruction(instruction, register_to_address(op1.?).?, register_to_address(op2.?).?, @truncate(u12, imm64));
        },
        R_Instruction => {
            return build_R_Instruction(instruction, register_to_address(op1.?).?, register_to_address(op2.?).?, register_to_address(op3.?).?);
        },
        else => {
            @compileError("Cannot call build_instruction with non-instruction enum!");
        },
    }
}
