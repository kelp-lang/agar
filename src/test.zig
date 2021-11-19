
const std = @import("std");
const vm = @import("vm.zig");
const assm = @import("asm.zig");

test "Test All" {
  std.testing.refAllDecls(@This());
}