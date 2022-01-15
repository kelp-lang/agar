const std = @import("std");
const bitutils = @import("bitutils.zig");
const IS_VERSION = @import("constants.zig").IS_VERSION;

pub const AgarBinary = packed struct {
    magic: u32 = 0x41474152,
    format_version: u32 = 0x01,
    agar_version: u32 = IS_VERSION,
    //readonly_data: u64 =
    entry_point: u64 = 0x14,

    pub fn read(parse_source: anytype) !AgarBinary {
        var hdr_buf: [20]u8 = undefined;
        try parse_source.seekableStream().seekTo(0);
        try parse_source.reader().readNoEof(&hdr_buf);
        return try AgarBinary.parse(&hdr_buf);
    }

    pub fn parse(hdr_buf: [20]u8) AgarBinary {}
};
