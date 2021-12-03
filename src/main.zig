// Copyright (C) 2021 by Jáchym Tomášek
const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const VM = @import("vm.zig").VM;
const Assembler = @import("asm.zig").Assembler;
const VERSION = "AgarVM version 0.0.1";
const FILE_MAX_SIZE = 4194304; //~ 4MB
pub const AGAR_VM_VERSION = 0x00; //TODO: Update this every time the instruction set changes

fn run(program: []const u32) !void {
    var vm = VM{
        .program = program,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    defer _ = gpa.deinit();

    std.log.info("VM exited with code: x{x}", .{try vm.run(allocator, allocator)});
    defer vm.deinit();
}

fn byteCompile(allocator: *std.mem.Allocator, src_path: []const u8) []u32 {
    const src_file = std.fs.cwd().openFile(src_path, .{ .read = true }) catch {
        std.log.alert("Cannot open file or directory", .{});
        return allocator.alloc(u32, 0) catch unreachable;
    };
    const src = src_file.readToEndAlloc(allocator, FILE_MAX_SIZE) catch {
        std.log.alert("File exceeded the FILE_MAX_SIZE {any} < {any}", .{ FILE_MAX_SIZE, (src_file.stat() catch unreachable).size });
        return allocator.alloc(u32, 0) catch unreachable;
    };
    defer allocator.free(src);
    var assembler = Assembler.init(allocator, src) catch unreachable;
    defer assembler.deinit();
    assembler.assembly_pass() catch unreachable;
    const result = allocator.dupe(u32, assembler.instruction_buffer) catch unreachable;
    return result;
}

fn loadElf(allocator: *std.mem.Allocator, src_path: []const u8) ![]const u8 {
    _ = allocator;
    _ = src_path;
    return unreachable;
}

fn printHelp() void {
    const help =
        \\ Usage: agar assemble [input-file] -o [output-file]
        \\        agar run [input-binary-file]
        \\        agar assemble [input-file] run
        \\
        \\Supported file types:
        \\                     .agar            Agar binary file (ELF)
        \\                     .algae           Agar assembly file
        \\                     .elf/.o/.a/.out  Generic ELF file (compiled with Agar)
        \\General Options:
        \\  -h, --help      Prints this help
        \\  -V, --version   Prints version info
    ;

    std.log.info("{s}", .{help});
}

fn parseArguments() !void {
    var arg_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arg_arena.deinit();
    var iter = std.process.args();
    const pwd = try iter.next(&arg_arena.allocator) orelse unreachable;
    _ = pwd;
    const subcommand = try iter.next(&arg_arena.allocator) orelse {
        return printHelp();
    };
    if (std.mem.eql(u8, "assemble", subcommand)) {
        const src_path = try iter.next(&arg_arena.allocator) orelse {
            std.log.info("Expected a source file!", .{});
            return printHelp();
        };

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const program = byteCompile(&gpa.allocator, src_path);
        defer gpa.allocator.free(program);

        const next_command = iter.next(&arg_arena.allocator);

        if (next_command == null or std.mem.eql(u8, "-o", try next_command.?) or std.mem.eql(u8, "--output", try next_command.?)) {
            std.log.err("--output currently unsupported", .{});
            //const dest_path = try iter.next(&arg_arena.allocator) orelse "./output.agar";

            //TODO: Write to elf file instead

            //const dest_file = try std.fs.cwd().createFile(dest_path, .{ .truncate = true });
            //defer dest_file.close();

            //try dest_file.writeAll(program);
        } else if (std.mem.eql(u8, "run", try next_command.?)) {
            return try run(program);
        } else {
            std.log.alert("Unrecognized command line option {s}", .{try next_command.?});
            return printHelp();
        }
    } else if (std.mem.eql(u8, "help", subcommand) or std.mem.eql(u8, "--help", subcommand) or std.mem.eql(u8, "-h", subcommand)) {
        return printHelp();
    } else if (std.mem.eql(u8, "--version", subcommand) or std.mem.eql(u8, "-V", subcommand)) {
        return std.log.info("{s}", .{VERSION});
    } else {
        std.log.alert("Unrecognized command line option {s}", .{subcommand});
        return printHelp();
    }
}

pub fn main() !void {
    try parseArguments();
}
