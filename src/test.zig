// Copyright (C) 2022 by Jáchym Tomášek

// We must learn to look at problems all-sidedly, seeing the reverse as
// well as the obverse side of things. In given conditions, a bad thing
// can lead to good results and a good thing to bad results. 

const std = @import("std");
const vm = @import("vm.zig");
const assm = @import("asm.zig");
const page_manager = @import("page_manager.zig");
const binary = @import("binary.zig");

test "Test All" {
    // Test all tests in files
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
