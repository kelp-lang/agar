// Copyright (C) 2022 by Jáchym Tomášek

// Our duty is to hold ourselves responsible to the people. Every word,
// every act and every policy must conform to the people's interests,
// and if mistakes occur, they must be corrected - that is what being
// responsible to the people means.

const std = @import("std");
const root = @import("root");

const MagicNumber: u48 = 0x61676172564D; // agarVM in ASCII

const err = error{
    IncompatibleVersion,
    NotAgarBinary,
};


pub fn write(file_path: []const u8, data: []const u8) !void {
    var file = try std.fs.cwd().createFile(file_path, .{ .truncate = true });
    try file.writeAll(std.mem.toBytes(std.mem.nativeToLittle(u48, MagicNumber))[0..]);
    try file.writeAll(std.mem.toBytes(std.mem.nativeToLittle(u16, root.AGAR_VM_VERSION))[0..]);
    try file.writeAll(data);
    file.close();
}

pub fn read(file_path: []const u8, allocator: std.mem.Allocator) ![]const u32 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    const data = try file.readToEndAlloc(allocator, root.FILE_MAX_SIZE);

    const magicIdent = std.mem.readIntLittle(u48, data[0..6]);
    if (magicIdent != MagicNumber) {
        return err.NotAgarBinary;
    }

    const version = std.mem.readIntLittle(u16, data[6..8]);
    if (version != root.AGAR_VM_VERSION) {
        return err.IncompatibleVersion;
    }

    return @alignCast(32, std.mem.bytesAsSlice(u32, data[8..]));
}
