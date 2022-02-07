# The Virtual Machine (vm.zig)

This file comprises of the actual execution engine. It has 32 64bit registers (this is a limitation due to register ids can only be stored in 5 bits). All instructions are saved in 32 bits. It has a few advantages, as near jump instructions (all pc modifying I-type instructions) can actually address a 4095 other addresses (2047 back and 2046 front).

All arithmetic is done on two's complement signed 64 bit integers if not stated otherwise.

## Initialization

The VM can be initialized in multiple ways. The standard way is to create a VM struct and then call the `.run()` function. It automatically initializes the virtual machine, and starts executing code.

```zig
var vm = VM{
  .program = program[0..],
};

vm.run(event_allocator, page_allocator);

// at the end of this scope, deinitialize all the virtual machine's memory.
defer vm.deinit();
```

The `.run()` function takes two allocators. These are responsible for the memory allocation of particular type (usually you can pass both the same allocator). The `event_allocator` is for the virtual machine events. These are messages that you can use to signal to the VM or the VM itself can use to signal to you.

The `page_allocator` is used to allocate memory inside the virtual machine, the `gp` and `fp` instructions use it to create and free pages. You should use a high performing allocator, it can be beneficial to use the `c_allocator` even though it can produce leaked memory and must be handled with caution.

The couple `.init()` and `.deinit()` are used to initialize and deinitialize structs inside the VM itself. It is a standard zig pattern. All heap allocated memory is freed in `.deinit()`.

## Runtime

`.next_instruction()` this function is a simple one. It returns the next instruction at position of the program counter (`pc`) and advances it by one.

`.exec_instruction()` this function executes one instruction on the VM. It can halt the VM or it should continue.

| returned value | meaning                                                                                   |
| -------------- | ----------------------------------------------------------------------------------------- |
| `VMError.*`    | the VM encountered an error, you should handle it accordingly, the default is to halt     |
| `false`        | the VM halted with the `HLT` instruction, the error code is written in the `VM.exit_code` |
| `true`         | the VM should continue it's execution                                                     |

There are some at first glance weird methods (starting with the `@` symbol) but that's just a type casting that is quite strict in zig and is very well defined contrary to C for example.