const std = @import("std");
const ArrayList = @import("std").ArrayList;
const Instruction = @import("instruction.zig").Instruction;

pub fn last(comptime T: type, slice: []T) ?T {
    if (slice.len == 0) return null;
    return slice[slice.len - 1];
}

pub const RegisterSelector = enum(u3) {
    zero,
    int,
    //float,
    sp, // return stack pointer at address with the other 5 bits addressing the int register of the offset
    sp_offset, // return stack pointer with static offset (signed 5 bits)
    _,
};

pub const VMEvent = enum {
    Start,
    Halt,
    OpExec,
    Error,
};

pub const VMError = error{
    Illegal,
    OutOfMemory,
};

pub const VM = struct {
    registers: [32]u64 = [_]u64{0} ** 32,
    //float_registers: [32]f64 = [_]f64{0} ** 32,
    eq: bool = false,
    pc: u64 = 0,
    sp: u64 = 0,
    program: []const u8,
    exit_code: u64 = 0,
    events: std.ArrayList(VMEvent) = undefined,
    event_allocator: *std.mem.Allocator = undefined,
    stack_arena: std.heap.ArenaAllocator = undefined,
    stack: []u8 = undefined,

    pub fn init(self: *VM, event_allocator: *std.mem.Allocator, stack_inner_allocator: *std.mem.Allocator) void {
        self.event_allocator = event_allocator;
        self.stack_arena = std.heap.ArenaAllocator.init(stack_inner_allocator);
        self.events = std.ArrayList(VMEvent).init(event_allocator);
    }

    pub fn deinit(self: *VM) void {
        self.stack_arena.deinit();
        self.events.deinit();
    }

    pub fn push_event(self: *VM, event: VMEvent) void {
        self.events.append(event) catch |err| {
            std.log.err("Virtual machine encountered an event array error {x}", .{err});
        };
    }

    /// WARNING: VM must be deinitialized aftewards
    pub fn run(self: *VM, event_allocator: *std.mem.Allocator, stack_inner_allocator: *std.mem.Allocator) !u64 {
        self.init(event_allocator, stack_inner_allocator);
        while (try self.exec_instruction()) {}
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
                const address = self.next_byte();
                self.exit_code = self.get_register(address);
                self.push_event(VMEvent.Halt);
                return false;
            },
            Instruction.CNW => {
                const dest_address = self.next_byte();
                const num = self.next_word();
                self.set_register(dest_address, @as(u64, num));
            },
            Instruction.CND => {
                const dest_address = self.next_byte();
                const num = self.next_doubleword();
                self.set_register(dest_address, num);
            },
            Instruction.JMP => {
                const dest = self.next_doubleword();
                self.pc = dest;
            },
            Instruction.JMPR => {
                const dest_address = self.next_byte();
                self.pc = self.get_register(dest_address);
            },

            Instruction.JMPE => {
                const dest = self.next_doubleword();
                if (self.eq) {
                    self.pc = dest;
                }
            },
            Instruction.JMPRE => {
                const dest_address = self.next_byte();
                if (self.eq) {
                    self.pc = self.get_register(dest_address);
                }
            },
            Instruction.EQ => {
                const add_a = self.next_byte();
                const add_b = self.next_byte();
                self.eq = self.get_register(add_a) == self.get_register(add_b);
            },
            Instruction.NEQ => {
                 const add_a = self.next_byte();
                const add_b = self.next_byte();
                self.eq = self.get_register(add_a) != self.get_register(add_b);
            },
            Instruction.GT => {
                const add_a = self.next_byte();
                const add_b = self.next_byte();
                self.eq = self.get_register(add_a) > self.get_register(add_b);
            },
            Instruction.GE => {
                const add_a = self.next_byte();
                const add_b = self.next_byte();
                self.eq = self.get_register(add_a) >= self.get_register(add_b);
            },
            Instruction.LT => {
                const add_a = self.next_byte();
                const add_b = self.next_byte();
                self.eq = self.get_register(add_a) < self.get_register(add_b);
            },
            Instruction.LE => {
               const add_a = self.next_byte();
                const add_b = self.next_byte();
                self.eq = self.get_register(add_a) <= self.get_register(add_b);
            },
            Instruction.ADD => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @bitCast(i64, self.get_register(a_add)) + @bitCast(i64, self.get_register(b_add))));
            },
            Instruction.SUB => {
               const result_add = self.next_byte();
               const a_add = self.next_byte();
               const b_add = self.next_byte();
               self.set_register(result_add, @bitCast(u64, @bitCast(i64, self.get_register(a_add)) - @bitCast(i64, self.get_register(b_add))));
            },
            Instruction.MUL => {
               const result_add = self.next_byte();
               const a_add = self.next_byte();
               const b_add = self.next_byte();
               self.set_register(result_add, @bitCast(u64, @bitCast(i64, self.get_register(a_add)) * @bitCast(i64, self.get_register(b_add))));
            },
            Instruction.DIV => {
               const result_add = self.next_byte();
               const a_add = self.next_byte();
               const b_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @divTrunc(@bitCast(i64, self.get_register(a_add)), @bitCast(i64, self.get_register(b_add)))));
            },
            Instruction.REM => {
               const result_add = self.next_byte();
               const a_add = self.next_byte();
               const b_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @rem(@bitCast(i64, self.get_register(a_add)), @bitCast(i64, self.get_register(b_add)))));
            },
            Instruction.INC => {
                const address = self.next_byte();
                self.set_register(address, self.get_register(address) +| 1);
            },
            Instruction.DEC => {
                const address = self.next_byte();
                self.set_register(address, self.get_register(address) -| 1);
            },
            Instruction.AND => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, self.get_register(a_add) & self.get_register(b_add));
            },
            Instruction.OR => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, self.get_register(a_add) | self.get_register(b_add));
            },
            Instruction.XOR => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, self.get_register(a_add) ^ self.get_register(b_add));
            },
            Instruction.NOT => {
                const result_add = self.next_byte();
                const source_add = self.next_byte();
                self.set_register(result_add, ~self.get_register(source_add));
            },
            Instruction.SHL => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add,self.get_register(a_add) << @truncate(u6, self.get_register(b_add)));
            },
            Instruction.SHR => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add,self.get_register(a_add) >> @truncate(u6, self.get_register(b_add)));
            },
            Instruction.FADD => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @bitCast(f64, self.get_register(a_add)) + @bitCast(f64, self.get_register(b_add))));
            },
            Instruction.FSUB => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @bitCast(f64, self.get_register(a_add)) - @bitCast(f64, self.get_register(b_add))));
            },
            Instruction.FMUL => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @bitCast(f64, self.get_register(a_add)) * @bitCast(f64, self.get_register(b_add))));
            },
            Instruction.FDIV => {
                const result_add = self.next_byte();
                const a_add = self.next_byte();
                const b_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @bitCast(f64, self.get_register(a_add)) / @bitCast(f64, self.get_register(b_add))));
            },
            Instruction.FINT => {
                const result_add = self.next_byte();
                const source_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @floatToInt(i64, @bitCast(f64, self.get_register(source_add)))));
            },
            Instruction.INTF => {
                const result_add = self.next_byte();
                const source_add = self.next_byte();
                self.set_register(result_add, @bitCast(u64, @intToFloat(f64, @bitCast(i64, self.get_register(source_add)))));
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
        // This is some advanced pointer magic, courtesy of Spex_guy#0444 (on discord)
        const result = std.mem.bytesAsValue(u16, self.program[self.pc..][0..2]).*;
        self.pc += 2;
        return result;
    }

    fn next_word(self: *VM) u32 {
        const result = std.mem.bytesAsValue(u32, self.program[self.pc..][0..4]).*;
        self.pc += 4;
        return result;
    }

    fn next_doubleword(self: *VM) u64 {
        const result = std.mem.bytesAsValue(u64, self.program[self.pc..][0..8]).*;
        self.pc += 8;
        return result;
    }

    fn resize_stack(self: *VM, new_size: u64) void {
        self.stack = self.stack_arena.allocator.resize(self.stack, new_size) catch {
            std.log.err("Out of memory! When allocating space for stack!", .{});
            return unreachable;
        };
    }

    fn get_register(self: *VM, address: u8) u64 {
        const register_selector = 0b11100000;
        const selected_register = (address & register_selector) >> 5;

        switch (@intToEnum(RegisterSelector, selected_register)) {
            RegisterSelector.zero => return 0x00,
            RegisterSelector.int => {
                return self.registers[@truncate(u5, address)];
            },
            //RegisterSelector.float => {
            //    return self.float_registers[@truncate(u5, address)];
            //},
            RegisterSelector.sp => {
                return self.sp -| self.registers[@truncate(u5, address)];
            },
            RegisterSelector.sp_offset => {
                return self.sp -| @truncate(u5, address);
            },
            _ => return 0x00,
        }
    }

    fn set_register(self: *VM, address: u8, value: u64) void {
        const register_selector: u8 = 0b11100000;
        const selected_register: u8 = (address & register_selector) >> 5;

        switch (@intToEnum(RegisterSelector, selected_register)) {
            RegisterSelector.zero => {},
            RegisterSelector.int => {
                self.registers[address & ~register_selector] = value;
            },
            // RegisterSelector.float => {
            //     self.float_registers[address & ~register_selector] = @bitCast(f64, value);
            // },
            RegisterSelector.sp, RegisterSelector.sp_offset => {
                self.sp = value;
                // Resize the stack buffer if the stack pointer would leave the stack
                // or the stack is 3 times bigger than the stack pointer
                // TODO: Tweak those values
                if (self.sp >= self.stack.len or self.stack.len > self.sp * 3) {
                    self.resize_stack(value * 2);
                }
            },
            _ => return,
        }
    }
};

pub fn intReg(index: u5) u8 {
    const selector: u8 = @as(u8, @enumToInt(RegisterSelector.int)) << 5;
    return selector | index;
}

test "VM: HLT with code 0xFF" {
    const program = [_]u8{ @enumToInt(Instruction.HLT), intReg(0) };
    var vm = VM{
        .program = program[0..],
        .registers = ([_]u64{0xAF} ++ ([_]u64{0} ** 31)),
    };
    vm.init(std.testing.allocator, std.testing.allocator);
    defer vm.deinit();

    try std.testing.expect(!(try vm.exec_instruction()));
    try std.testing.expect(vm.events.pop() == VMEvent.Halt);
    try std.testing.expectEqual(@as(u64, 0xAF), vm.exit_code);
}

test "VM: ADD 0x01 0x02" {
    const program = [_]u8{ @enumToInt(Instruction.ADD), intReg(0), intReg(1), intReg(2) };
    const registers = [_]u64{ 0x0, 0x4, 0x8 } ++ ([_]u64{0} ** 29);

    var vm = VM{ .program = program[0..] };
    vm.registers = registers;

    try std.testing.expect(try vm.exec_instruction());
    try std.testing.expectEqual(@as(u64, 0x0C), vm.get_register(intReg(0)));
}

test "VM: program counter moving with ADD" {
    const program = [_]u8{ @enumToInt(Instruction.ADD), intReg(0), intReg(1), intReg(2) };
    const registers = [_]u64{ 0x0, 0xFF, 0xFF } ++ ([_]u64{0} ** 29);

    var vm = VM{ .program = program[0..] };
    vm.init(std.testing.allocator, std.testing.allocator);
    vm.registers = registers;

    try std.testing.expectEqual(@as(u64, 0), vm.pc);
    try std.testing.expect(try vm.exec_instruction());
    try std.testing.expectEqual(@as(u64, 0x1FE), vm.get_register(intReg(0)));
    try std.testing.expectEqual(@as(u64, 4), vm.pc);
}

test "VM: execute a short program" {
    const program = [_]u8{
        @enumToInt(Instruction.ADD), intReg(0), intReg(1), intReg(2), //0x110 0xFF 0x11
        @enumToInt(Instruction.MUL), intReg(2), intReg(0), intReg(1), //0x110 0xFF 0x10EF0
        @enumToInt(Instruction.REM), intReg(1), intReg(0), intReg(2), //0x110 0x110 0x10EF0
        @enumToInt(Instruction.HLT), 0x00,
    };

    const registers = [_]u64{ 0x00, 0xFF, 0x11 } ++ ([_]u64{0} ** 29);
    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };

    try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator, std.testing.allocator));
    defer vm.deinit();

    try std.testing.expectEqual(@as(u64, 0x110), vm.get_register(intReg(0)));
    try std.testing.expectEqual(@as(u64, 0x110), vm.get_register(intReg(1)));
    try std.testing.expectEqual(@as(u64, 0x10EF0), vm.get_register(intReg(2)));
}

test "VM: equality" {
    const program = [_]u8{
        @enumToInt(Instruction.EQ),  intReg(0), intReg(1),
        @enumToInt(Instruction.NEQ), intReg(0), intReg(1),
        @enumToInt(Instruction.GT),  intReg(0), intReg(1),
        @enumToInt(Instruction.GE),  intReg(0), intReg(1),
        @enumToInt(Instruction.LT),  intReg(0), intReg(1),
        @enumToInt(Instruction.LE),  intReg(0), intReg(1),
    };

    const registers = [_]u64{ 0xF1, 0xF1 } ++ ([_]u64{0} ** 30);

    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };
    vm.init(std.testing.allocator, std.testing.allocator);
    defer vm.deinit();

    _ = try vm.exec_instruction();
    try std.testing.expectEqual(true, vm.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(false, vm.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(false, vm.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(true, vm.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(false, vm.eq);
    _ = try vm.exec_instruction();
    try std.testing.expectEqual(true, vm.eq);
}

test "VM: test jumping" {
    const program = [_]u8{
        @enumToInt(Instruction.JMPR), intReg(0),
        @enumToInt(Instruction.IGL),
        @enumToInt(Instruction.HLT), intReg(2),
    };

    const registers = [_]u64{ 0x03, 0xFF, 0x00 } ++ ([_]u64{0} ** 29);

    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };
    try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator, std.testing.allocator));
    defer vm.deinit();
}

test "VM: test conditional jumping" {
    const program = [_]u8{
        @enumToInt(Instruction.EQ),    intReg(0),                        intReg(1),
        @enumToInt(Instruction.JMPRE), intReg(2),
        @enumToInt(Instruction.IGL),
        @enumToInt(Instruction.NEQ),   intReg(0),                        intReg(1),
        @enumToInt(Instruction.JMPRE), intReg(3),
        @enumToInt(Instruction.HLT), intReg(4),
        @enumToInt(Instruction.IGL),
    };

    const registers = [_]u64{ 0x5F, 0x5F, 0x06, 0x0C } ++ ([_]u64{0} ** 28);

    var vm = VM{
        .program = program[0..],
        .registers = registers,
    };
    try std.testing.expectEqual(@as(u64, 0x00), try vm.run(std.testing.allocator, std.testing.allocator));
    defer vm.deinit();
}
