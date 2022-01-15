const std = @import("std");

const ErrEnum = error{
    OneError,
    TwoError,
};

fn bug(a: []const u8, b: ?(ErrEnum![]u8)) bool {
    if (b) |b_not_null| {
        _ = a;
        _ = b_not_null catch return false;
        std.log.info("Everything a-ok!", .{});
        return true;
    }
    return false;
}

test "b" {
    const x: ?i32 = null;
    const y: i32 = x;
    _ = y;
}

test "bug" {
    var b: ?(ErrEnum![:0]u8) = try std.testing.allocator.dupeZ(u8, "bbb");
    defer if (b) |b_nn| std.testing.allocator.free(b_nn catch unreachable);
    //std.mem.copy(u8, b, "bbb");

    try std.testing.expect(bug("bbb", b));
}
