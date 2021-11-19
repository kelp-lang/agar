const std = @import("std");
const ArrayList = @import("std").ArrayList;
const Instruction = @import("instruction.zig").Instruction;

pub fn last(comptime T: type, slice: []T) ?T {
    if (slice.len == 0) return null;
    return slice[slice.len - 1];
}

pub const Flags = packed struct {
    eq: bool = false,
    err: bool = false,
    carry: bool = false,
    signed: bool = false,
    parityt: bool = false,
    remainder: bool = false,
    _: bool = false,
    __: bool = false,

    pub inline fn as_u8(self: Flags) u8 {
        return @bitCast(u8, self);
    }
};

pub const VMEvent = enum {
    Start,
    Halt,
    OpExec,
    Error,
};

pub const VMError = error {
  Illegal,
};

pub const VM = struct {
    registers: [32]u64 = [_]u64{0} ** 32,
    float_registers: [32]f32 = [_]f32{0} ** 32,
    carry: u8 = 0,
    remainder: u8 = 0,
    flags: Flags = Flags{},
    pc: u64 = 0,
    program: []const u8,
    exit_code: u64 = 0,
    events: std.ArrayList(VMEvent) = undefined,
    allocator: *std.mem.Allocator = undefined,

    pub fn init(self: *VM, allocator: *std.mem.Allocator) void {
      self.allocator = allocator;
      self.events = std.ArrayList(VMEvent).init(allocator);
    }

    pub fn deinit(self: *VM) void {
        self.events.deinit();
    }

    pub fn push_event(self: *VM, event: VMEvent) void {
        self.events.append(event) catch |err| {
            std.log.err("Virtual machine encountered an event array error {x}", .{err});
        };
    }

    /// WARNING: VM must be deinitialized aftewards
    pub fn run(self: *VM, allocator: *std.mem.Allocator) !u64 {
      self.init(allocator);
      while (try self.exec_instruction()){}
      return self.exit_code;
    }

    pub fn exec_instruction(self: *VM) !bool {
        switch (@intToEnum(Instruction, self.next_byte())) {
            Instruction.IGL => {
                std.log.err("Virtual machine encountered illegal instruction at: {x}", .{self.pc});
                self.push_event(VMEvent.Error);
                return VMError.Illegal;
            },
            Instruction.HLT => {
              const register = self.next_byte();
                self.exit_code = self.registers[register];
                self.push_event(VMEvent.Halt);
                return false;
            },
            Instruction.PUSH => {
                return unreachable;
            },
            Instruction.POP => {
                return unreachable;
            },
            Instruction.JMP => {
                const dest_reg = self.next_byte();
                self.pc = self.registers[dest_reg];
            },
            Instruction.JMPE => {
                const dest_reg = self.next_byte();
                if (self.flags.eq) {
                    self.pc = self.registers[dest_reg];
                }
            },
            Instruction.EQ => {
                const reg_a = self.next_byte();
                const reg_b = self.next_byte();
                self.flags.eq = self.registers[reg_a] == self.registers[reg_b];
            },
            Instruction.NEQ => {
                const reg_a = self.next_byte();
                const reg_b = self.next_byte();
                self.flags.eq = self.registers[reg_a] != self.registers[reg_b];
            },
            Instruction.GT => {
                const reg_a = self.next_byte();
                const reg_b = self.next_byte();
                self.flags.eq = self.registers[reg_a] > self.registers[reg_b];
            },
            Instruction.GE => {
                const reg_a = self.next_byte();
                const reg_b = self.next_byte();
                self.flags.eq = self.registers[reg_a] >= self.registers[reg_b];
            },
            Instruction.LT => {
                const reg_a = self.next_byte();
                const reg_b = self.next_byte();
                self.flags.eq = self.registers[reg_a] < self.registers[reg_b];
            },
            Instruction.LE => {
                const reg_a = self.next_byte();
                const reg_b = self.next_byte();
                self.flags.eq = self.registers[reg_a] <= self.registers[reg_b];
            },
            Instruction.ADD => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = @bitCast(u64, @bitCast(i64, self.registers[a_reg]) + @bitCast(i64, self.registers[b_reg]));
            },
            Instruction.SUB => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = @bitCast(u64, @bitCast(i64, self.registers[a_reg]) - @bitCast(i64, self.registers[b_reg]));
            },
            Instruction.MUL => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = @bitCast(u64, @bitCast(i64, self.registers[a_reg]) * @bitCast(i64, self.registers[b_reg]));
            },
            Instruction.DIV => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = @bitCast(u64, @divTrunc(@bitCast(i64, self.registers[a_reg]), @bitCast(i64, self.registers[b_reg])));
            },
            Instruction.REM => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = @bitCast(u64, @rem(@bitCast(i64, self.registers[a_reg]), @bitCast(i64, self.registers[b_reg])));
            },
            Instruction.INC => {
                //TODO: Once +|= is stable, use that instead
                const register = self.next_byte();
                self.registers[register] +%= 1;
            },
            Instruction.DEC => {
                //TODO: Once -|= is stable, use that instead
                const register = self.next_byte();
                self.registers[register] -%= 1;
            },
            Instruction.AND => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = self.registers[a_reg] & self.registers[b_reg];
            },
            Instruction.OR => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = self.registers[a_reg] | self.registers[b_reg];
            },
            Instruction.XOR => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = self.registers[a_reg] ^ self.registers[b_reg];
            },
            Instruction.NOT => {
                const result_reg = self.next_byte();
                const source_reg = self.next_byte();
                self.registers[result_reg] = ~self.registers[source_reg];
            },
            Instruction.SHL => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = self.registers[a_reg] << @truncate(u6, self.registers[b_reg]);
            },
            Instruction.SHR => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.registers[result_reg] = self.registers[a_reg] >> @truncate(u6, self.registers[b_reg]);
            },
            Instruction.RFL => {
                const result_reg = self.next_byte();
                self.registers[result_reg] = @as(u64, self.flags.as_u8());
            },
            Instruction.WFL => {
                const source_reg = self.next_byte();
                self.flags = @bitCast(Flags, @truncate(u8, self.registers[source_reg]));
            },
            Instruction.FADD => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.float_registers[result_reg] = self.float_registers[a_reg] + self.float_registers[b_reg];
            },
            Instruction.FSUB => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.float_registers[result_reg] = self.float_registers[a_reg] - self.float_registers[b_reg];
            },
            Instruction.FMUL => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.float_registers[result_reg] = self.float_registers[a_reg] * self.float_registers[b_reg];
            },
            Instruction.FDIV => {
                const result_reg = self.next_byte();
                const a_reg = self.next_byte();
                const b_reg = self.next_byte();
                self.float_registers[result_reg] = self.float_registers[a_reg] / self.float_registers[b_reg];
            },
            Instruction.FINT => {
                const result_reg = self.next_byte();
                const source_reg = self.next_byte();
                self.registers[result_reg] = @bitCast(u64, @floatToInt(i64, self.float_registers[source_reg]));
            },
            Instruction.INTF => {
                const result_reg = self.next_byte();
                const source_reg = self.next_byte();
                self.float_registers[result_reg] = @intToFloat(f32, self.registers[source_reg]);
            },
            // TODO: Proper EQ on floats (maybe allow for rounding errorr?)
            Instruction.FEQ => {
              return undefined;
            },
            Instruction.FGT => {
              return undefined;
            },
            Instruction.FGE => {
              return undefined;
            },
            Instruction.FLT => {
              return undefined;
            },
            Instruction.FLE => {
              return undefined;
            },
            _ => {
                self.push_event(VMEvent.Error);
                self.exit_code = 0xFF;
                return VMError.Illegal;
            },
        }
        return true;
    }

    fn next_byte(self: *VM) u8 {
        const result = self.program[self.pc];
        self.pc += 1;
        return result;
    }

    fn next_halfword(self: *VM) u16 {
        return (@as(u16, self.next_byte()) << 8) + @as(u16, self.next_byte());
    }

    fn next_word(self: *WM) u32 {
        return (@as(u32, self.next_halfword()) << 16) + @as(u32, self.next_halfword());
    }

    fn next_doubleword(self: *WM) u64 {
        return (@as(u64, self.next_word()) << 32) + @as(u64, self.next_word());
    }

    pub fn register_value(self: *VM, address: u8) u64 {
        return self.registers[address];
    }
};

test "VM: HLT with code 0xFF" {
    const program = [_]u8{ @enumToInt(Instruction.HLT), 0x00 };
    var vm = VM{
        .program = program[0..],
        .registers = ([_]u64{0xAF} ++ ([_]u64{0} ** 31)),
    };
    vm.init(std.testing.allocator);
    defer vm.deinit();

    try std.testing.expect(!(try vm.exec_instruction()));
    try std.testing.expect(vm.events.pop() == VMEvent.Halt);
    try std.testing.expectEqual(@as(u64, 0xAF), vm.exit_code);
}

test "VM: ADD 0x01 0x02" {
    const program = [_]u8{ @enumToInt(Instruction.ADD), 0x00, 0x01, 0x02 };
    const registers = [_]u64{ 0x0, 0x4, 0x8 } ++ ([_]u64{0} ** 29);

    var vm = VM{ .program = program[0..] };
    vm.registers = registers;

    try std.testing.expect(try vm.exec_instruction());
    try std.testing.expectEqual(@as(u64, 0x0C), vm.register_value(0x00));
}

test "VM: program counter moving with ADD" {
    const program = [_]u8{ @enumToInt(Instruction.ADD), 0x00, 0x01, 0x02 };
    const registers = [_]u64{ 0x0, 0xFF, 0xFF } ++ ([_]u64{0} ** 29);

    var vm = VM{ .program = program[0..] };
    vm.init(std.testing.allocator);
    vm.registers = registers;

    try std.testing.expectEqual(@as(u64, 0), vm.pc);
    try std.testing.expect(try vm.exec_instruction());
    try std.testing.expectEqual(@as(u64, 0x1FE), vm.register_value(0x00));
    try std.testing.expectEqual(@as(u64, 4), vm.pc);
}

test "VM: execute a short program" {
    const program = [_]u8{
        @enumToInt(Instruction.ADD), 0x00, 0x01, 0x02, //0x110 0xFF 0x11
        @enumToInt(Instruction.MUL), 0x02, 0x00, 0x01, //0x110 0xFF 0x10EF0
        @enumToInt(Instruction.REM), 0x01, 0x00, 0x02, //0x110 0x110 0x10EF0
        @enumToInt(Instruction.HLT), 0x04,
    };

    const registers = [_]u64{ 0x00, 0xFF, 0x11 } ++ ([_]u64{0} ** 29);
    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };

    try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator));
    defer vm.deinit();

    try std.testing.expectEqual(@as(u64, 0x110), vm.registers[0]);
    try std.testing.expectEqual(@as(u64, 0x110), vm.registers[1]);
    try std.testing.expectEqual(@as(u64, 0x10EF0), vm.registers[2]);
}

test "VM: equality" {
    const program = [_]u8{
        @enumToInt(Instruction.EQ),  0x00, 0x01,
        @enumToInt(Instruction.NEQ), 0x00, 0x01,
        @enumToInt(Instruction.GT),  0x00, 0x01,
        @enumToInt(Instruction.GE),  0x00, 0x01,
        @enumToInt(Instruction.LT),  0x00, 0x01,
        @enumToInt(Instruction.LE),  0x00, 0x01,
    };

    const registers = [_]u64{ 0xF1, 0xF1 } ++ ([_]u64{0} ** 30);

    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };
    vm.init(std.testing.allocator);
    defer vm.deinit();

    _ = try vm.exec_instruction();
    try std.testing.expectEqual(true, vm.flags.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(false, vm.flags.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(false, vm.flags.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(true, vm.flags.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(false, vm.flags.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(true, vm.flags.eq);
}

test "VM: test jumping" {
    const program = [_]u8{
        @enumToInt(Instruction.JMP), 0x00,
        @enumToInt(Instruction.IGL),
        @enumToInt(Instruction.HLT), 0x02,
    };

    const registers = [_]u64{ 0x03, 0xFF, 0x00 } ++ ([_]u64{0} ** 29);

    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };
    try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator));
    defer vm.deinit();
}

test "VM: test conditional jumping" {
  const program = [_]u8{
    @enumToInt(Instruction.EQ), 0x00, 0x01,
    @enumToInt(Instruction.JMPE), 0x02,
    @enumToInt(Instruction.IGL),
    @enumToInt(Instruction.NEQ), 0x00, 0x01,
    @enumToInt(Instruction.JMPE), 0x03,
    @enumToInt(Instruction.HLT), 0x05,
    @enumToInt(Instruction.IGL),
  };

  const registers = [_]u64{0x5F, 0x5F, 0x06, 0x0C} ++ ([_]u64{0} ** 28);

  var vm = VM {
    .program = program[0..],
    .registers = registers,
  };
  try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator));
  defer vm.deinit();
}