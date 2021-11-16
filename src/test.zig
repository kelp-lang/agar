const std = @import("std");
const testing = @import("std").testing;
const VM = @import("vm.zig").VM;
const Instruction = @import("instruction.zig").Instruction;

test "VM: HLT with code 0xFF" {
    const program = [_]u8{@enumToInt(Instruction.HLT), 0xFF};
    var vm = VM {
        .program = program[0..]
    };
    try testing.expectEqual(vm.exec_instruction(), @as(u8, 0xFF));
}

test "VM: ADD 0x01 0x02" {
    const program = [_]u8{@enumToInt(Instruction.ADD), 0x00, 0x01, 0x02};
    const registers = [_]u64{0x0, 0x4, 0x8} ++ ([_]u64{0} ** 29);

    var vm = VM {
        .program = program[0..],
        .registers = registers,
    };
    try testing.expectEqual(vm.exec_instruction(), null);
    try testing.expectEqual(vm.register_value(0x00), 0x0C);
}

test "VM: pointer moving with ADD" {
    const program = [_]u8{@enumToInt(Instruction.ADD), 0x00, 0x01, 0x02};
    const registers = [_]u64{0x0, 0xFF, 0xFF} ++ ([_]u64{0} ** 29);

    var vm = VM {
      .program = program[0..],
      .registers = registers,
    };
    try testing.expectEqual(vm.pc, 0);
    try testing.expectEqual(vm.exec_instruction(), null);
    try testing.expectEqual(vm.register_value(0x00), 0x1FE);
    try testing.expectEqual(vm.pc, 4);
}