# Assembler (asm.zig)

This file contains a struct that allows parsing strings into Agar bytecode. Label resolution is currently limited and only works with labels that are defined before the label usage. This will be fixed in the future.

Assembler uses a fairly standard patter with one exception. There is an additional step, you initialize it, then run the `.assembly_pass()` which creates the `instruction_buffer` which you can then copy elsewhere and finally deinitialize it.

The reason for the assembly pass step is that it is possible in the future to add more steps to the compilation.

The `.tokenize_*()` functions convert the strings into tokens, based on lines and spaces. There are no commas or anything like that, syntactic meaning is handled using just spaces and line breaks inside the assembly.

The `.parse_line()` function scraps lines beginning with `;`, if the first token ends with `:` then registers a label and otherwise tries to parse the line as a instruction. If the instruction is a pseudoinstruction then it is first expanded into a slice of instructions.

The `.label_to_offset()` function takes a label or a integer and converts it into a integer, if the label exists or is an integer. Any instruction can take an immediate in form of a label, they are mutually interchangeable.