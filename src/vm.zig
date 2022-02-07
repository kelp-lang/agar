// Copyright (C) 2022 by Jáchym Tomášek

// Besides, it is not difficult to see that ours is a birth-time
// and a period of transition to a new era. Spirit has broken with
// the world it has hitherto inhabited and imagined, and is of a
// mind to submerge it in the past, and in the labour of its own
// transformation.

const std = @import("std");
const ArrayList = @import("std").ArrayList;
const I_Instruction = @import("instruction.zig").I_Instruction;
const C_Instruction = @import("instruction.zig").C_Instruction;
const R_Instruction = @import("instruction.zig").R_Instruction;
const build_I_Instruction = @import("util.zig").build_I_Instruction;
const build_C_Instruction = @import("util.zig").build_C_Instruction;
const build_R_Instruction = @import("util.zig").build_R_Instruction;
const Register = @import("register.zig").Register;
const PageManager = @import("page_manager.zig");

pub const VMEvent = enum {
    Start,
    Halt,
    OpExec,
    Error,
};

pub const VMError = error{
    Illegal,
    OutOfMemory,
    Todo,
};

pub const VM = struct {
    registers: [32]u64 = [_]u64{0} ** 32,
    //float_registers: [32]f64 = [_]f64{0} ** 32,
    program: []const u32,
    exit_code: u64 = 0,
    advance: bool = true,
    pc: u64 = 0,
    events: std.ArrayList(VMEvent) = undefined,
    event_allocator: std.mem.Allocator = undefined,
    page_manager: PageManager = undefined,

    pub fn init(self: *VM, event_allocator: std.mem.Allocator, page_allocator: std.mem.Allocator) void {
        self.event_allocator = event_allocator;
        self.events = std.ArrayList(VMEvent).init(event_allocator);
        self.page_manager = PageManager.init(page_allocator);
    }

    pub fn deinit(self: *VM) void {
        self.events.deinit();
        self.page_manager.deinit();
    }

    /// Send events to the virtual machine
    pub fn push_event(self: *VM, event: VMEvent) void {
        self.events.append(event) catch |err| {
            std.log.err("Virtual machine encountered an event array error {x}", .{err});
        };
    }

    /// Run the virtual machine and stop only with IGL,HLT or running out of the program
    /// WARNING: VM must be deinitialized aftewards
    pub fn run(self: *VM, event_allocator: std.mem.Allocator, stack_inner_allocator: std.mem.Allocator) !u64 {
        self.init(event_allocator, stack_inner_allocator);
        while (self.advance and try self.exec_instruction() and self.pc < self.program.len) {}
        return self.exit_code;
    }

    /// Load the next instruction and increment the program counter
    fn next_instruction(self: *VM) u32 {
        const next = self.program[self.pc];
        self.pc += 1;
        return std.mem.nativeToLittle(u32, next);
    }

    // Setup some constants for easier masking
    const FIRST_BIT = 0x1;
    const SECOND_BIT = 0x2;
    const R_INS = 0x1FFFC;
    const R_RD = 0x3E0000;
    const R_RS1 = 0x7C00000;
    const R_RS2 = 0xF8000000;
    const C_INS = 0x7C;
    const C_RD = 0xF80;
    const C_i20 = 0xFFFFF000;
    const I_INS = 0x3FE;
    const I_RD = 0x7C00;
    const I_RS1 = 0xF8000;
    const I_i12 = 0xFFF00000;

    /// Execute one instruction
    pub fn exec_instruction(self: *VM) !bool {
        const instruction = self.next_instruction();
        // Switch the instruction type based on the first two bits (as per documentation)
        if (instruction & FIRST_BIT != 0) { //I-Ins
            // Mask of the useful bits, shift them to the right and then truncate bits outside the range
            const opcode = @truncate(u9, (instruction & I_INS) >> 1);
            const rd = @truncate(u5, (instruction & I_RD) >> 10);
            const rs1 = @truncate(u5, (instruction & I_RS1) >> 15);
            // Mask and truncate the bits and then bitcast it to a twos complement signed integer
            const imm12: i12 = @bitCast(i12, @truncate(u12, (instruction & I_i12) >> 20));

            switch (@intToEnum(I_Instruction, opcode)) {
                // Load a memory chunk into rd from page with id rs1 and offset imm12
                I_Instruction.PLB => {
                    self.registers[rd] = self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)];
                },
                I_Instruction.PLH => {
                    // Read int in littleEndian, the architecture is strictly little endian
                    self.registers[rd] = std.mem.readIntLittle(u16, self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)..][0..2]);
                },
                I_Instruction.PLW => {
                    self.registers[rd] = std.mem.readIntLittle(u32, self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)..][0..4]);
                },
                I_Instruction.PLD => {
                    self.registers[rd] = std.mem.readIntLittle(u64, self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)..][0..8]);
                },
                I_Instruction.PSB => {
                    self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)] = @truncate(u8, self.registers[rd]);
                },
                I_Instruction.PSH => {
                    std.mem.writeIntLittle(u16, self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)..][0..2], @truncate(u16, self.registers[rd]));
                },
                I_Instruction.PSW => {
                    std.mem.writeIntLittle(u32, self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)..][0..4], @truncate(u32, self.registers[rd]));
                },
                I_Instruction.PSD => {
                    std.mem.writeIntLittle(u64, self.page_manager.pages.items[self.registers[rs1]][@bitCast(u12, imm12)..][0..8],  self.registers[rd]);

                },
                I_Instruction.BEQ => {
                    if (@bitCast(i64, self.registers[rd]) == @bitCast(i64, self.registers[rs1])) {
                        const dest: i64 = imm12 + @intCast(i64, self.pc);
                        self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                    }
                },
                I_Instruction.BNE => {
                    if (@bitCast(i64, self.registers[rd]) != @bitCast(i64, self.registers[rs1])) {
                        const dest: i64 = imm12 + @intCast(i64, self.pc);
                        self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                    }
                },
                I_Instruction.BLT => {
                    if (@bitCast(i64, self.registers[rd]) < @bitCast(i64, self.registers[rs1])) {
                        const dest: i64 = imm12 + @intCast(i64, self.pc);
                        self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                    }
                },
                I_Instruction.BGE => {
                    if (@bitCast(i64, self.registers[rd]) >= @bitCast(i64, self.registers[rs1])) {
                        const dest: i64 = imm12 + @intCast(i64, self.pc);
                        self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                    }
                },
                I_Instruction.BGEU => {
                    if (self.registers[rd] >= self.registers[rs1]) {
                        const dest: i64 = imm12 + @intCast(i64, self.pc);
                        self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                    }
                },
                I_Instruction.BLTU => {
                    if (self.registers[rd] <= self.registers[rs1]) {
                        const dest: i64 = imm12 + @intCast(i64, self.pc);
                        self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                    }
                },
                I_Instruction.JALR => {
                    const dest: i64 = imm12 + @bitCast(i64, self.registers[rs1]);
                    self.registers[rd] = self.pc + 1;
                    self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                },
                I_Instruction.ADDI => {
                    self.registers[rd] = @bitCast(u64, @bitCast(i64, self.registers[rs1]) + @intCast(i64, imm12));
                },
                I_Instruction.SUBI => {
                    self.registers[rd] = @bitCast(u64, @bitCast(i64, self.registers[rs1]) - @intCast(i64, imm12));
                },
                I_Instruction.MULI => {
                    self.registers[rd] = @bitCast(u64, @bitCast(i64, self.registers[rs1]) * @intCast(i64, imm12));
                },
                I_Instruction.DIVI => {
                    self.registers[rd] = @bitCast(u64, @divTrunc(@bitCast(i64, self.registers[rs1]), @intCast(i64, imm12)));
                },
                I_Instruction.REMI => {
                    self.registers[rd] = @bitCast(u64, @rem(@bitCast(i64, self.registers[rs1]), @intCast(i64, imm12)));
                },
                I_Instruction.ANDI => {
                    self.registers[rd] = self.registers[rs1] & @bitCast(u12, imm12);
                },
                I_Instruction.ORI => {
                    self.registers[rd] = self.registers[rs1] | @bitCast(u12, imm12);
                },
                I_Instruction.XORI => {
                    self.registers[rd] = self.registers[rs1] ^ @bitCast(u12, imm12);
                },
                I_Instruction.SHLI => {
                    self.registers[rd] = self.registers[rs1] <<| @intCast(u64, @bitCast(u12, imm12));
                },
                I_Instruction.SHRI => {
                    self.registers[rd] = self.registers[rs1] >> @truncate(u6, @bitCast(u12, imm12));
                },
                I_Instruction.EQI => {
                    self.registers[rd] = @boolToInt(self.registers[rs1] == imm12);
                },
                I_Instruction.NEQI => {
                    self.registers[rd] = @boolToInt(self.registers[rs1] != imm12);
                },
                else => {
                    std.log.err("Unrecognized opcode: {any} 0b{b:x>}", .{ @intToEnum(I_Instruction, opcode), opcode });
                    return VMError.Todo;
                },
            }
            return true;
        } else if (instruction & SECOND_BIT != 0) { //C-Ins
            const opcode = @truncate(u5, (instruction & C_INS) >> 2);
            const rd = @truncate(u5, (instruction & C_RD) >> 7);
            const imm20 = @bitCast(i20, @truncate(u20, (instruction & C_i20) >> 12));

            switch (@intToEnum(C_Instruction, opcode)) {
                C_Instruction.JR => {
                    //TODO: check this!
                    const dest: i64 = imm20 + @bitCast(i64, self.registers[rd]);
                    self.pc = if (dest > 0) @intCast(u64, dest) else 0;
                },
                C_Instruction.LUI => {
                    self.registers[rd] = @as(u64, (@bitCast(u20, imm20) << 12));
                },
                C_Instruction.AUIPC => {
                    self.registers[rd] = @bitCast(u64, @bitCast(i64, @as(u64, (@bitCast(u20, imm20) << 12))) + @intCast(i64, self.pc));
                },
                C_Instruction.GP => {
                    self.registers[rd] = self.page_manager.new_page();
                },
                C_Instruction.FP => {
                    self.page_manager.release_page(self.registers[rd]);
                },
            }
            return true;
        } else { //R-Ins
            const opcode = @truncate(u15, (instruction & R_INS) >> 2);
            const rd = @truncate(u5, (instruction & R_RD) >> 17);
            const rs1 = @truncate(u5, (instruction & R_RS1) >> 22);
            const rs2 = @truncate(u5, (instruction & R_RS2) >> 27);
            switch (@intToEnum(R_Instruction, opcode)) {
                R_Instruction.IGL => {
                    std.log.err("\nVirtual machine encountered illegal instruction {} at: {x}\n", .{ @intToEnum(R_Instruction, opcode), self.pc }); //         self.push_event(VMEvent.Error);
                    return VMError.Illegal;
                },
                R_Instruction.HLT => {
                    self.exit_code = self.registers[rs2];
                    self.push_event(VMEvent.Halt);
                    return false;
                },
                R_Instruction.ADD => {
                    self.registers[rd] = @bitCast(u64, @bitCast(i64, self.registers[rs1]) + @bitCast(i64, self.registers[rs2]));
                },
                R_Instruction.SUB => {
                    self.registers[rd] = @bitCast(u64, @bitCast(i64, self.registers[rs1]) - @bitCast(i64, self.registers[rs2]));
                },
                R_Instruction.MUL => {
                    self.registers[rd] = @bitCast(u64, @bitCast(i64, self.registers[rs1]) * @bitCast(i64, self.registers[rs2]));
                },
                R_Instruction.DIV => {
                    self.registers[rd] = @bitCast(u64, @divTrunc(@bitCast(i64, self.registers[rs1]), @bitCast(i64, self.registers[rs2])));
                },
                R_Instruction.REM => {
                    self.registers[rd] = @bitCast(u64, @rem(@bitCast(i64, self.registers[rs1]), @bitCast(i64, self.registers[rs2])));
                },
                R_Instruction.AND => {
                    self.registers[rd] = self.registers[rs1] & self.registers[rs2];
                },
                R_Instruction.OR => {
                    self.registers[rd] = self.registers[rs1] | self.registers[rs2];
                },
                R_Instruction.XOR => {
                    self.registers[rd] = self.registers[rs1] ^ self.registers[rs2];
                },
                R_Instruction.SHL => {
                    self.registers[rd] = self.registers[rs1] >> @truncate(u6, self.registers[rs2]);
                },
                R_Instruction.SHR => {
                    self.registers[rd] = self.registers[rs1] << @truncate(u6, self.registers[rs2]);
                },
                R_Instruction.EQ => {
                    self.registers[rd] = @boolToInt(self.registers[rs1] == self.registers[rs2]);
                },
                R_Instruction.NEQ => {
                    self.registers[rd] = @boolToInt(self.registers[rs1] != self.registers[rs2]);
                },
                R_Instruction.GE => {
                    self.registers[rd] = @boolToInt(self.registers[rs1] >= self.registers[rs2]);
                },
                R_Instruction.LT => {
                    self.registers[rd] = @boolToInt(self.registers[rs1] < self.registers[rs2]);
                },
                else => {
                    std.log.err("Unrecognized opcode: {any} 0b{b:x>}", .{ @intToEnum(R_Instruction, opcode), opcode });
                    return VMError.Todo;
                },
            }
            return true;
        }
    }
};

test "VM: HLT with code 0xAF" {
    const program = [_]u32{build_R_Instruction(R_Instruction.HLT, 0, 0, 0)};
    var vm = VM{
        .program = program[0..],
        .registers = ([_]u64{0xAF} ++ ([_]u64{0} ** 31)),
    };
    vm.init(std.testing.allocator, std.testing.allocator);
    defer vm.deinit();

    try std.testing.expect(!try vm.exec_instruction());
    try std.testing.expectEqual(VMEvent.Halt, vm.events.pop());
    try std.testing.expectEqual(@as(u64, 0xAF), vm.exit_code);
}

test "VM: ADD 0x01 0x02" {
    const program = [_]u32{build_R_Instruction(R_Instruction.ADD, 0, 1, 2)};
    const registers = [_]u64{ 0x0, 0x4, 0x8 } ++ ([_]u64{0} ** 29);

    var vm = VM{ .program = program[0..] };
    vm.registers = registers;

    try std.testing.expect(try vm.exec_instruction());
    try std.testing.expectEqual(@as(u64, 0x0C), vm.registers[0]);
}

test "VM: program counter moving with ADD" {
    const program = [_]u32{build_R_Instruction(R_Instruction.ADD, 0, 1, 2)};
    const registers = [_]u64{ 0x0, 0xFF, 0xFF } ++ ([_]u64{0} ** 29);

    var vm = VM{ .program = program[0..] };
    vm.init(std.testing.allocator, std.testing.allocator);
    vm.registers = registers;

    try std.testing.expectEqual(@as(u64, 0), vm.pc);
    try std.testing.expect(try vm.exec_instruction());
    try std.testing.expectEqual(@as(u64, 0x1FE), vm.registers[0]);
    try std.testing.expectEqual(@as(u64, 1), vm.pc);
}

test "VM: execute a short program" {
    const program = [_]u32{
        build_I_Instruction(I_Instruction.ADDI, 0, 1, 0x11),
        build_R_Instruction(R_Instruction.MUL, 2, 0, 1),
        build_R_Instruction(R_Instruction.REM, 1, 0, 2),
        build_R_Instruction(R_Instruction.HLT, 0, 0, 0),
    };

    const registers = [_]u64{ 0x00, 0xFF } ++ ([_]u64{0} ** 30);
    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };

    try std.testing.expectEqual(@as(u64, 0x110), try vm.run(std.testing.allocator, std.testing.allocator));
    defer vm.deinit();

    try std.testing.expectEqual(@as(u64, 0x110), vm.registers[0]);
    try std.testing.expectEqual(@as(u64, 0x110), vm.registers[1]);
    try std.testing.expectEqual(@as(u64, 0x10EF0), vm.registers[2]);
}

test "VM: equality" {
    const program = [_]u32{
        build_R_Instruction(R_Instruction.EQ, 2, 0, 1),
        build_R_Instruction(R_Instruction.NEQ, 3, 0, 1),
        build_R_Instruction(R_Instruction.GE, 5, 0, 1),
        build_R_Instruction(R_Instruction.LT, 6, 0, 1),
    };

    const registers = [_]u64{ 0xF1, 0xF1 } ++ ([_]u64{0} ** 30);

    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };
    _ = try vm.run(std.testing.allocator, std.testing.allocator);
    defer vm.deinit();

    try std.testing.expect(@boolToInt(true) == vm.registers[2]);
    try std.testing.expect(@boolToInt(false) == vm.registers[3]);
    try std.testing.expect(@boolToInt(true) == vm.registers[5]);
    try std.testing.expect(@boolToInt(false) == vm.registers[6]);
}

test "VM: test jumping" {
    const program = [_]u32{
        build_C_Instruction(C_Instruction.JR, 0, 0x02),
        build_R_Instruction(R_Instruction.IGL, 0, 0, 0),
        build_R_Instruction(R_Instruction.HLT, 0, 0, 0x02),
    };

    var vm = VM{
        .program = program[0..],
    };
    try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator, std.testing.allocator));
    defer vm.deinit();
}

test "VM: test conditional jumping" {
    // TODO:
    //std.log.alert("Unimplemented", .{});
    // const program = [_]u8{
    //     @enumToInt(Instruction.EQ),    intReg(0),                   intReg(1),
    //     @enumToInt(Instruction.JMPRE), intReg(2),                   @enumToInt(Instruction.IGL),
    //     @enumToInt(Instruction.NEQ),   intReg(0),                   intReg(1),
    //     @enumToInt(Instruction.JMPRE), intReg(3),                   @enumToInt(Instruction.HLT),
    //     intReg(4),                     @enumToInt(Instruction.IGL),
    // };

    // const registers = [_]u64{ 0x5F, 0x5F, 0x06, 0x0C } ++ ([_]u64{0} ** 28);

    // var vm = VM{
    //     .program = program[0..],
    //     .registers = registers,
    // };
    // try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator, std.testing.allocator));
    // defer vm.deinit();
}
