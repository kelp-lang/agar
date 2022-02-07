// Copyright (C) 2022 by Jáchym Tomášek

// The bud disappears when the blossom breaks through, and we might say
// that the former is refuted by the latter; in the same way when the
// fruit comes, the blossom may be explained to be a false form of the
// plant’s existence, for the fruit appears as its true nature in place
// of the blossom. The ceaseless activity of their own inherent nature
// makes these stages moments of an organic unity, where they not merely
// do not contradict one another, but where one is as necessary as the
// other; and constitutes thereby the life of the whole.

const std = @import("std");
const Instruction = @import("instruction.zig").Instruction;
const VM = @import("vm.zig").VM;
const Assembler = @import("asm.zig").Assembler;
const binary = @import("binary.zig");

pub const VERSION = "AgarVM version 0.0.2";
pub const FILE_MAX_SIZE = 4194304; //~ 4MB
pub const AGAR_VM_VERSION: u16 = 0x00; //WARN: Update this every time the instruction set changes

/// Run code in a virtual machine
fn run(program: []const u32, allocator: std.mem.Allocator) !void {
    // Create the VM struct
    var vm = VM{
        .program = program,
    };

    // Run the VM and print it's result code
    std.log.info("VM exited with code: x{x}", .{try vm.run(allocator, allocator)});
    defer vm.deinit();
}

/// Bytecompile the file with assembly in it
fn byteCompile(allocator: std.mem.Allocator, src_path: []const u8) []u32 {
    // Open file
    const src_file = std.fs.cwd().openFile(src_path, .{ .read = true }) catch {
        std.log.err("Cannot open file or directory", .{});
        return allocator.alloc(u32, 0) catch unreachable;
    };
    // Read the file, max size of the file is 4MB, this can be changed, but a max file size must exist
    const src = src_file.readToEndAlloc(allocator, FILE_MAX_SIZE) catch {
        std.log.err("File exceeded the FILE_MAX_SIZE {any} < {any}", .{ FILE_MAX_SIZE, (src_file.stat() catch unreachable).size });
        return allocator.alloc(u32, 0) catch unreachable;
    };
    defer allocator.free(src);

    // Initiate an assembler (a tool to compile from assembly to bytecode)
    var assembler = Assembler.init(allocator, src) catch unreachable;
    defer assembler.deinit();

    // Run the assembly pass, multiple passes are possible but right now unnecessary
    assembler.assembly_pass() catch unreachable;

    // Duplicate the program from the assembler as assembler's memory will be freed
    const result = allocator.dupe(u32, assembler.instruction_buffer) catch unreachable;
    return result;
}

/// Write help to stdout
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

/// Parse arguments from the command line
fn parseArguments() !void {
    // Cretae the argument allocator
    // I use arena, because I can free the memory all at once and the memory required is not that large
    var arg_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arg_arena.deinit();

    // Load the process arguments
    var iter = std.process.args();

    // Check if any arguments were passed or print help
    const subcommand = try iter.next(arg_arena.allocator()) orelse {
        return printHelp();
    };

    // If first argument is assemble
    if (std.mem.eql(u8, "assemble", subcommand)) {
        // Check if user passed source .algae file
        const src_path = try iter.next(arg_arena.allocator()) orelse {
            std.log.info("Expected a source file!", .{});
            return printHelp();
        };

        // Create an allocator for the whole program
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        // Bytecompile the file
        const program = byteCompile(gpa.allocator(), src_path);
        defer gpa.allocator().free(program);

        const next_command = iter.next(arg_arena.allocator());

        // If there's no other arguments passed or user specified --output/-o
        // write the bytecode to the output file
        if (next_command == null or std.mem.eql(u8, "-o", try next_command.?) or std.mem.eql(u8, "--output", try next_command.?)) {
            const dest_path = try iter.next(arg_arena.allocator()) orelse "./output.agar";

            try binary.write(dest_path, std.mem.sliceAsBytes(program));
        }
        // If user passed run
        // run the program in a virtual machine
        else if (std.mem.eql(u8, "run", try next_command.?)) {
            return try run(program, gpa.allocator());
        } else {
            std.log.err("Unrecognized command line option {s}", .{try next_command.?});
            return printHelp();
        }
    }
    // If user's argument was run, open the specified file and run it in a virtual machine
    else if (std.mem.eql(u8, "run", subcommand)) {
        const src_path = try iter.next(arg_arena.allocator()) orelse {
            std.log.info("Expected a file to run!", .{});
            return printHelp();
        };

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        const program: []const u32 = try binary.read(src_path, gpa.allocator());
        defer gpa.allocator().free(program);

        try run(program, gpa.allocator());
    }
    // Print help
    else if (std.mem.eql(u8, "help", subcommand) or std.mem.eql(u8, "--help", subcommand) or std.mem.eql(u8, "-h", subcommand)) {
        return printHelp();
    }
    // Print version
    else if (std.mem.eql(u8, "--version", subcommand) or std.mem.eql(u8, "-V", subcommand)) {
        return std.log.info("{s}", .{VERSION});
    } else {
        std.log.err("Unrecognized command line option {s}", .{subcommand});
        return printHelp();
    }
}

pub fn main() !void {
    try parseArguments();
}
