const std = @import("std");
const ListHandle = @import("object.zig").ListHandle;
const ObjectHandle = @import("object.zig").ObjectHandle;
const Function = @import("function.zig").Function;

comptime {
    _ = NativeFunction;
}

pub const TypeId = enum(u8) {
    literal_int,
    nil,
    boolean,
    list,
    //array,
    //symbol,
    object,
    function,
    native_function,
    //environment,
    //quote,
    //string,
};

pub const NativeFunction = struct {
    const Self = @This();

    fun: fn () void,

    pub fn init(fun: fn ([]const Value) Value) Self {
        return .{
            .fun = @ptrCast(fn () void, fun),
        };
    }

    pub fn invoke(self: *NativeFunction, args: []const Value) Value {
        // Don't ask
        // Since you asked, this is a weird workaround
        // I cannot save fun: fn(args: []const Value) Value
        // as that would mean, that Value depends on itself
        // instead I do some weird pointer magic, to cast it
        // first when wraping, the function gets casted
        // and then when invoking it gets casted back, before
        // it gets invoked
        return @ptrCast(fn ([]const Value) Value, self.fun)(args);
    }

    /// Wrap a zig function into a Agar Native Function
    /// This allows it to be called by the call_native
    /// instruction. Maximal number of arguments is 24.
    /// Handling on the Agar side must be done manually
    pub fn wrap(comptime function: anytype) NativeFunction {
        const F = @TypeOf(function);
        const info = @typeInfo(F);
        if (info != .Fn)
            @compileError("Cannot wrap a non-function");
        const function_info = info.Fn;
        if (function_info.is_generic)
            @compileError("Cannot wrap generic functions");
        if (function_info.is_var_args)
            @compileError("Cannot wrap function with variadic args");

        const ArgsTuple = std.meta.ArgsTuple(F);

        const Impl = struct {
            fn invoke(args: []const Value) Value {
                var zig_args: ArgsTuple = undefined;
                comptime var index = 0;
                inline while (index < function_info.args.len) : (index += 1) {
                    const T = function_info.args[index].arg_type.?;
                    const value = args[index];
                    if (T == Value) {
                        zig_args[index] = value;
                    } else {
                        zig_args[index] = try Value.convertToZig(T, value);
                    }
                }

                const ReturnType = function_info.return_type.?;

                const ActualReturnType = switch (@typeInfo(ReturnType)) {
                    .ErrorUnion => |eu| eu.payload,
                    else => ReturnType,
                };

                var result: ActualReturnType = if (ReturnType != ActualReturnType)
                    try @call(.{}, function, zig_args)
                else
                    @call(.{}, function, zig_args);

                return try Value.convertToValue(result);
            }
        };

        //return Self{ .fun = @ptrCast(fn (args: []*c_void) *c_void, Impl.invoke) };
        return Self.init(Impl.invoke);
    }
};

pub const Value = union(TypeId) {
    const Self = @This();

    // Value Types
    literal_int: i64,
    nil: void,
    boolean: u1,

    // Reference types
    list: ListHandle,
    //array: ArrayHandle,
    object: ObjectHandle,
    function: Function,
    native_function: NativeFunction,
    //TODO: strings?
    //quote: Value,

    pub fn initInt(val: i64) Self {
        return Self{ .literal_int = val };
    }

    pub fn toInt(self: *const Self, comptime Target: type) !Target {
        return @intCast(Target, self.literal_int);
    }

    pub fn nil() Self {
        return Self{.nil};
    }

    pub fn initBoolean(val: bool) Self {
        return Self{ .boolean = @boolToInt(val) };
    }

    pub fn toBoolean(self: *const Self) !bool {
        return self.boolean != 0;
    }

    pub fn initObject(val: ObjectHandle) Self {
        return Self{ .object = val };
    }

    pub fn initList(val: ListHandle) Self {
        return Self{ .list = val };
    }

    pub fn convertToZig(comptime Target: type, value: Value) !Target {
        if (Target == Value) {
            return value;
        } else {
            const info = @typeInfo(Target);
            switch (info) {
                .Int => return try value.toInt(Target),
                .Bool => return try value.toBoolean(),
                else => {
                    @compileError("Usupported type to wrap");
                },
            }
        }
    }

    pub fn convertToValue(value: anytype) !Value {
        const T = @TypeOf(value);
        const info = @typeInfo(T);

        if (info == .Int)
            return Value.initInt(value);
        if (info == .Bool)
            return Value.initBoolean(value);
    }

    pub fn quote(self: *Self) Self {
        return .{ .quote = self.* };
    }

    pub fn eql(self: *Self, other: Self) bool {
        const Tag = std.meta.Tag(Self);
        if (@as(Tag, self) != @as(Tag, other)) return false;

        return switch (self) {
            .nil => true,
            .literal_int => |lhs| lhs == other.literal_int,
            .boolean => |lhs| lhs == other.boolean,
            .object => |lhs| lhs.ptr == other.object.ptr or lhs.eql(other.object),
            .list => |lhs| lhs.ptr == other.list.ptr or lhs.eql(other.list),
            else => undefined,
        };
    }

    pub fn deserialize(self: *Self) u72 {
        return switch (self) {
            Self.literal_int => |value| @enumToInt(TypeId.literal_int) << 64 | @bitCast(u64, value),
            Self.nil => @enumToInt(TypeId.nil) << 64,
            Self.boolean => |value| @enumToInt(TypeId.boolean) << 64 | value,
            Self.list => |value| @enumToInt(TypeId.list) << 64 | value.ptr,
            Self.object => |value| @enumToInt(TypeId.object) << 64 | value.ptr,
        };
    }

    pub fn serialize(uint: u72) Self {
        const val = @truncate(u64, uint);
        return switch (@intToEnum(TypeId, @truncate(u8, uint >> 64))) {
            TypeId.literal_int => .{ .literal_int = val },
            TypeId.nil => .{.nil},
            TypeId.boolean => .{ .boolean = @boolToInt(val > 0) },
            TypeId.list => .{ .list = .{ .ptr = val } },
            TypeId.object => .{ .object = .{ .ptr = val } },
        };
    }
};

test "Value: Test native function wraping" {
    const Str = struct {
        fn fun(a: i64, b: i64) i64 {
            return a + b;
        }

        fn dun(a: bool, b: bool) bool {
            return a and b;
        }
    };

    var wrap = NativeFunction.wrap(Str.fun);
    var brap = NativeFunction.wrap(Str.dun);
    const args = [_]Value{ Value.initInt(3), Value.initInt(4) };
    const bargs = [_]Value{ Value.initBoolean(true), Value.initBoolean(false) };

    try std.testing.expectEqual(@as(i64, 7), (wrap.invoke(args[0..])).literal_int);
    try std.testing.expect((brap.invoke(bargs[0..])).boolean == 0);
}
