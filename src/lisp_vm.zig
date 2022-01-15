const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const Environment = @import("env.zig");

// This provides facility to execute any synchronous code, the VM itself
// doesn't execute, it only calls execution engine, as it has smaller
// overhead
// Also the registers are shared between execution engines
const ExecutionEngine = struct {
    const Self = @This();

    vm: *VM,
    program: []const u64,
    program_counter: u64 = 0,

    pub fn init(vm: *VM, program: []const u64, program_counter: u64) Self {
        return Self{
            .vm = vm,
            .program = program,
            .program_counter = program_counter,
        };
    }

    fn next_instruction(self: *Self) u64 {
        const next = self.program[self.program_counter];
        self.program_counter += 1;
        return next;
    }

    pub fn execute(self: *Self) !bool {
        const instruction = self.next_instruction();
        const opcode = @truncate(u16, instruction);
        const rd = @truncate(u6, instruction >> 17);
        const rs1 = @truncate(u6, instruction >> 23);
        const rs2 = @truncate(u6, instruction >> 29);

        switch (@intToEnum(Instruction, opcode)) {
            .HLT => {
                return false;
            },
            .call_native => {
                const sym = self.next_instruction();
                const val = self.vm.*.env.getHashed(sym);
                switch (val) {
                    .native_function => |native| {
                        self.vm.*.registers[rd] = native.call(self.vm.*.registers[8..32]);
                    },
                    else => {
                        //TODO:
                    },
                }
            },
            .call_native_val => {
                const sym = self.vm.*.registers[rd];
            },
            .call => {
                const sym = self.next_instruction();
                //This creates a new execution engine and executes code
                const val = self.vm.*.symbols.getAdapted(sym, self.vm.*.symbol_hash_adaptor);
                switch (val) {
                    .function => |fun| {
                        (Self{
                            .program = fun.instructions,
                            .vm = self.vm,
                        }).run();
                    },
                    else => {
                        //TODO:
                    },
                }
            },
            .tail => {
                const val = self.vm.*.symbols[sym];
                switch (val) {
                    .function => |fun| {
                        //Reset this execution engine and continue running
                        self.program = fun.instructions;
                        self.program_counter = 0;
                        return;
                    },
                    else => {
                        //TODO:
                    },
                }
            },
            .eval => {},
            .equal => {
                self.vm.*.registers[rd] = self.vm.*.registers[rs1].eql(self.vm.*.registers[rs2]);
            },
        }

        return true;
    }

    pub fn run(self: *Self) void {
        while (self.program_counter < self.program.lenght) {
            self.execute();
        }
    }
};

const VM = struct {
    const Self = @This();

    program: []const u64,
    program_counter: u64 = 0,
    arg_allocator: std.mem.Allocator,
    registers: [64]Value = [_]Value{.{.nil}} ** 64,
    env: *Environment,
    susp: bool = false,
    exec_engine: ?ExecutionEngine = null,

    pub fn run(self: *Self) !void {
        // Start a new execution engine, if one doesn't exist
        self.exec_engine = if (self.exec_engine) |eng| eng else ExecutionEngine.init(self, program, program_counter);

        while (try self.exec_engine.execute() and !susp) {}
    }
};
