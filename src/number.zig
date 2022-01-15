const std = @import("std");

pub const IntType = enum {
    word,
    doubleword,
    arbitrary,
};

pub const Int = union(IntType) {
    const Self = @This();

    word: i64,
    doubleword: i128,
    //each field is a base 16 digit
    //TODO: find which base is the fastest to compute
    arbitrary: []u4,

    pub fn eql(self: *Self, other: Self) bool {
        fn eql_w(arbitrary: Self, w: Self) bool{};
        fn eql_dw(arbitrary: Self, dw: Self) bool{};

        switch (self) {
            .word => |lhs| {
                return switch (other) {
                    .word => |rhs| lhs == rhs,
                    .doubleword => |rhs| lhs == rhs,
                    .arbitrary => |rhs| eql_w(rhs, lhs),
                };
            },
            .doubleword => |lhs| {
                return switch (other) {
                    .word => |rhs| lhs == rhs,
                    .doubleword => |rhs| lhs == rhs,
                    .arbitrary => |rhs| eql_dw(rhs, lhs),
                };
            },
            .arbitrary => |lhs| {
                return switch (other) {
                    .word => |rhs| eql_w(lhs, rhs),
                    .doubleword => |rhs| eql_dw(lhs, rhs),
                    .arbitrary => |rhs| std.mem.eql(u4, lhs, rhs),
                };
            },
        }
    }
};

pub const Rational = struct {
    const Self = @This();

    numerator: Int,
    denominator: Int,

    pub fn eql(self: *Self, other: Self) bool {
        return self.numerator.eql(other.numerator) and self.denominator.eql(other.denominator);
    }
};

pub const RealType = enum {
    float_half,
    float_word,
    float_double,
    fixed,
};

pub const Real = union(RealType) {
    const Self = @This();

    float_half: f32,
    float_word: f64,
    float_double: f128,
    fixed: struct {
        upper: Int,
        lower: Int,
    },

    pub fn eql(self: *Self, other: Self) bool {
        //TODO:
        return unreachable;
    }
};

pub const Complex = struct {
    const Self = @This();

    real: Real,
    imaginary: Real,

    pub fn eql(self: *Self, other: Self) bool {
        return self.real.eql(other.real) and self.imaginary.eql(other.imaginary);
    }
};
