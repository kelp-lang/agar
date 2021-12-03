// Copyright (C) 2021 by Jáchym Tomášek
const std = @import("std");
const vm = @import("vm.zig");
const assm = @import("asm.zig");

test "Test All" {
    std.testing.refAllDecls(@This());
}

test "Load and execute addition_test.algae" {
    const file = try std.fs.cwd().openFile("tests/addition_test.algae", .{});
    defer file.close();

    const algae = try file.readToEndAlloc(std.testing.allocator, 400000);
    defer std.testing.allocator.free(algae);

    var assembly = try assm.Assembler.init(std.testing.allocator, algae);
    defer assembly.deinit();

    try assembly.assembly_pass();

    var virt_machine = vm.VM{
        .program = assembly.instruction_buffer,
    };
    defer virt_machine.deinit();
    try std.testing.expectEqual(@as(u64, 0x0A), try virt_machine.run(std.testing.allocator, std.testing.allocator));
}
