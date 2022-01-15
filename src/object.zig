pub const std = @import("std");
pub const Value = @import("value.zig").Value;
pub const number = @import("number.zig");
pub const String = @import("string.zig").String;
const MemoryManager = @import("memmanager.zig").MemoryManager;

pub const ObjectHandle = packed struct {
    const Self = @This();

    ptr: u64,

    pub fn object(self: *Self, memmanager: *MemoryManager) !Object {
        return try memmanager.getObject(self.ptr);
    }

    pub fn eql(self: *Self, other: Self) bool {
        return self.ptr == other.ptr or val: {};
    }
};

pub const ListHandle = packed struct {
    const Self = @This();

    ptr: u64,
};

pub const List = struct {
    const Self = @This();

    next: ListHandle,
    value: Value,

    pub fn serialize(bytes: []const u8) List {}

    pub fn deserialize(self: *Self, location: []u8) void {
        location[0..8] = std.mem.toBytes(self.next);
        location[8..80] = std.mem.toBytes(self.value.as_u72());
    }
};

pub const ObjectType = enum(u4) {
    String,
    Int,
    Rational,
    Real,
    Complex,
    Structure,
};

pub const Object = struct {
    const Self = @This();

    size: u60,
    type: ObjectType,
    data: union {
        Structure: Structure,
        Int: number.Int,
        Rational: number.Rational,
        Real: number.Real,
        Complex: number.Complex,
        String: String,
    },

    pub fn serialize(bytes: []const u8) Object {
        const first_word = std.mem.bytesAsValue(u64, bytes[0..8]);

        var self: Object = .{
            .size = @truncate(u60, first_word.* >> 4),
            .type = @intToEnum(ObjectType, @truncate(u4, first_word.*)),
            .data = undefined,
        };

        switch (self.type) {
            ObjectType.String => {
                self.data.String = String.serialize(bytes[8 .. self.size + 8]);
            },
            ObjectType.Int => {
                self.data.Int = number.Int.serialize(bytes[8 .. self.size + 8]);
            },
            ObjectType.Rational => {
                self.data.Rational = number.Rational.serialize(bytes[8 .. self.size + 8]);
            },
            ObjectType.Real => {
                self.data.Real = number.Real.serialize(bytes[8 .. self.size + 8]);
            },
            ObjectType.Complex => {
                self.data.Complex = number.Complex.serialize(bytes[8 .. self.size + 8]);
            },
            ObjectType.Structure => {
                self.data.Structure = Structure.serialize(bytes[8 .. self.size + 8]);
            },
        }
        std.debug.print("{}", .{self});
        return self;
    }

    pub fn deserialize(self: *Self, location: []u8) void {
        const first_word: u64 = (self.size << 4) | self.type;
        location[0..8] = std.mem.toBytes(first_word);
        location[8 .. self.size + 8] = switch (self.type) {
            ObjectType.String => self.data.String.deserialize(),
            ObjectType.Int => self.data.Int.deserialize(),
            ObjectType.Rational => self.data.Rational.deserialize(),
            ObjectType.Real => self.data.Real.deserialize(),
            ObjectType.Complex => self.data.Complex.deserialize(),
            ObjectType.Structure => self.data.Structure.deserialize(),
        };
    }

    pub fn eql(self: *Self, other: Object) bool {
        const Tag = std.meta.Tag(Self);
        if (@as(Tag, self) != @as(Tag, other)) return false;
        switch (self) {
            .String => |lhs| lhs.eql(other.String),
            .Int => |lhs| lhs.eql(other.Int),
            .Rational => |lhs| lhs.eql(other.Rational),
            .Real => |lhs| lhs.eql(other.Real),
            .Complex => |lhs| lhs.eql(other.Complex),
            .Structure => |lhs| lhs.eql(other.Structure),
        }
    }
};

pub const Structure = struct {
    env: *Environment,
};

test "llo" {
    //_ = Object.serialize(&[_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });
    //std.debug.print("size {}\n", .{@bitSizeOf(ListHandle)});
}
