const std = @import("std");
const ArrayList = @import("std").ArrayList;
const Instruction = @import("instruction.zig").Instruction;

pub const Flags = packed struct {
  eq: bool = false,
  err: bool = false,
  carry: bool = false,
  signed: bool = false,
  parityt: bool = false,
  remainder: bool = false,
  _: bool = false,
  __: bool = false,

  pub fn as_u8(self: Flags) u8 {
    return @bitCast(u8, self);
  }
};

pub const VM = struct {
  registers: [32]u64 = [_]u64{0} ** 32,
  float_registers: [32]f32 = [_]f32{0} ** 32,
  carry: u8 = 0,
  remainder: u8 = 0,
  flags: u8 = (Flags{}).as_u8(),
  pc: u64 = 0,
  program: []const u8,

  pub fn exec_instruction(self: *VM) ?u8 {
    switch (@intToEnum(Instruction, self.next_byte())) {
      Instruction.IGL => {
        std.log.err("Virtual machine encountered illegal instruction", .{});
        return 0xFF;
      },
      Instruction.HLT => {
        return self.next_byte();
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
        self.registers[result_reg] = self.flags;
      },
      Instruction.WFL => {
        const source_reg = self.next_byte();
        self.flags = @truncate(u8, self.registers[source_reg]);
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
      else => return 0xFF
    }
    return null;
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