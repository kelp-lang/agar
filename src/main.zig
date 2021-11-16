const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const VM = @import("vm.zig").VM;

fn load_program() VM {
    const program = [_]u8{@enumToInt(Instruction.ADD), 0x00, 0x01, 0x02, @enumToInt(Instruction.DB)};

    return VM.init(program[0..]);
}

pub fn main() !void {
    var vm = load_program();
    const result = vm.exec_instruction();
    if (result != null) {
        std.log.info("Did halt with code {x}", .{result});
    } else {
        std.log.info("Didn't halt", .{});
    }
    std.log.info("All your codebase are belong to us. {x}", .{vm});
}