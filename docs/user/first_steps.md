# First steps
>If you want to run precompiled code, refer to the [running bytecode](#running-bytecode) section. If you know what assembly and virtual machines are, refer to the [writing your first assembly section](#writing-your-first-assembly) section.

## What is AgarVM anyway?
As you probably know, most computers use machine code to operate. It is a set of instructions the machine should perform. This code is usually a binary file as they tend to be smaller and the computer also works in binary. Agar isn't dissimilar to other computers (it's actually very similar to the Risc-V architecture). And it also uses binary files to operate.

Since writing binary files is really time consuming and not fun, we created programming languages to make it easier to write instructions to our computers. The first programming languages that were made were called Assemblers.

They are really simple. Each line of assembly usually corresponds to one instruction for the machine. You would be surprised how small the number of instructions you really need for any program in that could ever exist. (Actually it's only [one instruction](https://en.wikipedia.org/wiki/One-instruction_set_computer)!)

AgarVM is a virtual machine. That means that Agar is practically a computer same as the computers previously mentioned. The big difference is that Agar is not made from transistors but is simulated on you computer. Since the computer is turing complete, you can simulate any other computer.

## Why would anyone want to simulate another computer?
If you noticed when downloaded Agar from the releases page, there were a few files. Even though Agar doesn't depend on any external libraries. That is because each operating system has different interface by which it communicates with programs.

That's why you cannot run a macOS program on Windows, you need to have a Windows version of that program. And since that is really laborious task, to maintain many versions of each program for every platform, some programming languages decided that they will solve this issue.

For example Java uses the Java Virtual Machine. Agar isn't like JVM, it isn't widely used, and it is more of a proof of concept than a production ready virtual machine. But you can try it if you want!

## Writing your first assembly

> If you want to see all the instructions see [their documentation page](./instructions.md)

As we previously discussed virtual machines have instructions. Agar has them too. They are separated into 3 groups.

1. the R-format instructions which take 3 registers
2. the I-format instructions which take 2 registers and a 12 bit signed immediate
3. the C-format instructions which takes 1 register and a 20 bit signed immediate

What is a register you may ask? It is simply a compartment from which you can take values and save values. For example, if you want to add two numbers together with the `ADD` instruction, you first have to load them into two registers.

Agar doesn't have a specific instruction for loading a constant into a register. Instead it uses a trick, where adding register `zero` and a "immediate" sets the destination register to the immediate value.

Note that lines beginning with `;` are ignored

```assembly
; set register a0 to 1
ADDI a0 zero 1

; set register a1 to 3
ADDI a1 zero 3

; add register a0 and a1 together and save the result in register a3
ADD a3 a0 a1
```

## Registers

Before continuing we should probably look at what registers Agar has available. Note that this is just a convention. There is no difference between registers. You are highly encouraged to follow it though.

| register identifier | description                      |
|---------------------|----------------------------------|
| zero                | register with the constant 0     |
| ra                  | return address                   |
| pp                  | page pointer                     |
| t0-t6               | temporary registers              |
| s0-s11              | saved registers                  |
| a0-a9               | function arguments/return values |

1. the `zero` register is like any other register, but usually it is used as a constant zero, because some instructions (like setting a register to an immediate) will not work, if there is no constant zero.
2. the `ra` register is used for function calling. The return address is used by the `RET` pseudo-instruction to return to the callsite, set by either the programmer or the `JALR` (jump and link register) instruction.
3. the `pp` register is used to save active page id. Pages are the only memory that can be used by the virtual machine. You can have multiple pages and you need to free them manually. More information on [their page](./pages.md).
4. the `t0, t1, t2,...,t6` registers are temporary registers that can be used anyway you want. The only limitation is that they can be overwritten by the called function.
5. the `s0, s1, s2,...,s11` are similar to the `tX` registers, but they will not be overwritten by the called function. If you want to modify them in the function, you must set their original value back, when returning.
6. the `a0, a1, a2,...,a9` registers are for function arguments and their return values.

## Immediates

What are immediates? You can mostly think about them as if you directly input numbers when writing the code. For example if you want to add one to a register, you can call `ADDI t0 t0 1` the `1` is the immediate.

If instruction takes immediate depends on which type of instruction is it. Only I and C instruction types take one. And each has a different length.

The I type takes a 12-bit signed (in two's complement) integer. That means you can represent numbers between `-2048` and `2047` (inclusive).

The C type takes a 20-bit signed (in two's complement) integer. That means you can represent numbers between `-524288` and `524287` (inclusive).

Because all the registers are 64 bit and quite often you need to load bigger immediates (for example when jumping). There exists the `LI` pseudoinstruction, which loads a 32 bit signed integer. In reality it gets translated into two instructions. The `LUI` load upper immediate instruction, which takes the upper 20 bits of the number and bit-shifts them and the `ADDI` instruction we used previously.

```assembly
; the pseudoinstruction LI
LI t0 2147483646

; gets translated into two instructions
LUI t0 2147479552
ADDI t0 t0 4095
```
## Running bytecode
For compiling assembly into bytecode
```bash
agar assemble [input-file] -o [output-file]
```
For running bytecode
```bash
agar run [input-binary-file]
```
For running assembly directly
```bash
agar assemble [input-file] run
```