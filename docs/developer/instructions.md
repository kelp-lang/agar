# Instructions

## Instruction format
Instructions are modeled after the Risc-V architecture but with modifications. They are strictly 32 bits wide always saved in little endian.
> Note that the format listed below is backwards from the real memory representation. The bit 0 is on the right and bit 31 is on the left. Same as we write numbers - MSB first.
### the R-format for 3 operand instructions
```
|0|1|2            16|17 21|22 26|27 31|
|0|0|xxxxxxxxxxxxxxx|xxxxx|xxxxx|xxxxx|
|-|R|opcode         |rd   |rs1  |rs2  |
```
### the I-format for instructions with immediates
```
|0|1       9|10 14|15 19|20        31|
|1|xxxxxxxxx|xxxxx|xxxxx|xxxxxxxxxxxx|
|I|opcode   |rd   |rs1  |imm12       |
```
### the C-format for instructions with bigger immediates
```
|0|1|2   6|7  11|12                31|
|0|1|xxxxx|xxxxx|xxxxxxxxxxxxxxxxxxxx|
|-|C|opcod|rd   |imm20               |
```
## Binary compatibility
Opcode numbers *can* be changed between versions. To prevent malfunctioning code each `.agar` file has version of the instruction set written and should produce an error instead of running other versions (as described in the `AGAR_VM_VERSION` variable) of code.