const std = @import("std");
const VM = @import("vm.zig").VM;

const ListHeadPointer = u64;

const MemoryManager = struct {
    const Self = @This();

    // // New memory requests
    // pub fn new_list_head(self: *MemoryManager) ListHeadPointer {}
    // pub fn new_list_part(self: *MemoryManager) u64 {}
    // pub fn new_object(self: *MemoryManager) u64 {}

    // // Garbage collection
    // fn swap_memory(self: *MemoryManager) void {}
    // fn mark(self: *MemoryManager) void {}
    // fn sweep(self: *MemoryManager) void {}
    // pub fn collect_garbage(self: *MemoryManager) !void {}

    // pub fn object_from_ptr(self: *MemoryManager, ptr: u60) Object {}

    fn reserveMemory(self: *Self, size: u60) []u8 {
        return unreachable;
    }

    // Lists:
    pub fn getList(self: *Self, handle: ListHandle) List {
        //TODO:
        return unreachable;
    }

    // Objects:
    pub fn getObject(self: *Self, handle: ObjectHandle) !Object {
        return;
    }

    pub fn registerObject(self: *Self, object: Object) ObjectHandle {
        const size = object.size;
        object.to_bytes(self.reserveMemory(size));
        //TODO: add it to registry
    }
};
