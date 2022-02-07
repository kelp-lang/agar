# Legend
| symbol | meaning                                                                                                                                           |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `off`  | offset, the value is added to the program counter, can be a label too! (if label, the value is automatically subtracted from the program counter) |
| `rd`   | destination register, can be any register                                                                                                         |
| `rs`   | source register, if there are two `rs1` and `rs2`                                                                                                 |
| `imm`  | immediate, the value is used as is, can be a label too!                                                                                           |
| `zero` | ignore these operands, use the `zero` register                                                                                                    |
| `XXX`  | value of this immediate is ignored                                                                                                                |
 
# Pseudoinstructions
  | name   | usage        | description                                                                           |
  | ------ | ------------ | ------------------------------------------------------------------------------------- |
  | `NOP`  | no operands  | perform no operation for one instruction cycle                                        |
  | `J`    | `off`        | jump to an absolute address                                                           |
  | `JAL`  | `rd off`     | jump to an absolute address and save the return address to the destination register   |
  | `CALL` | `off`        | jump to a relative address/label and save the return address into `ra` register       |
  | `TAIL` | `off`        | jump to a relative address/label and DON'T save the return address                    |
  | `MV`   | `rd rs`      | copy value from the source register to the destination register                       |
  | `LI`   | `rd imm`     | load up to a 32 bit signed int into a register                                        |
  | `RET`  | no operands  | jump to the `ra` register value (usually used with `CALL`)                            |
  | `NOT`  | `rd rs`      | bit invert the value from the source register and save it in the destination register |
  | `NEG`  | `rd rs`      | convert from positive to negative and back                                            |
  | `GT`   | `rd rs1 rs2` | set destination to one if `rs1` is greater than `rs2`                                 |
  | `LE`   | `rd rs1 rs2` | set destination to one if `rs1` is less or equal to `rs2`                             |
# R Instructions
  | name  | usage           | description                                                                    |
  | ----- | --------------- | ------------------------------------------------------------------------------ |
  | `IGL` | no operands     | illegal instruction, this stops the virtual machine and produces illegal event |
  | `HLT` | `zero zero rs2` | halt the virtual machine with the exit code in `rs2`                           |
  | `ADD` | `rd rs1 rs2`    | add the two source registers in two's complement signed arithmetic             |
  | `SUB` | `rd rs1 rs2`    | subtract                                                                       |
  | `MUL` | `rd rs1 rs2`    | multiply                                                                       |
  | `DIV` | `rd rs1 rs2`    | result of `rs1` divided by `rs2`                                               |
  | `REM` | `rd rs1 rs2`    | remainder from division `rs1` divided by `rs2`                                  |
  | `AND` | `rd rs1 rs2`    | bitwise AND                                                                    |
  | `OR`  | `rd rs1 rs2`    | bitwise OR                                                                     |
  | `XOR` | `rd rs1 rs2`    | bitwise XOR                                                                    |
  | `SHL` | `rd rs1 rs2`    | shift left `rs1` by amount in `rs2`                                            |
  | `SHR` | `rd rs1 rs2`    | shift right `rs1` by amount in `rs2`                                           |
  | `EQ`  | `rd rs1 rs2`    | set `rd` to one if `rs1` is equal to `rs2`                                     |
  | `NEQ` | `rd rs1 rs2`    | set `rd` to one if `rs1` is not equal to `rs2`                                 |
  | `GE`  | `rd rs1 rs2`    | set destination to one if `rs1` is greater or equal to `rs2`                   |
  | `LT`  | `rd rs1 rs2`    | set destination to one if `rs1` is less than `rs2`                             |
# I Instructions
  | name   | usage         | description                                                                                            |
  | ------ | ------------- | ------------------------------------------------------------------------------------------------------ |
  | `PLB`  | `rd rs imm`   | load byte to `rd` from memory page with id in `rs` at offset `imm`                                     |
  | `PLH`  | `rd rs imm`   | load two bytes to `rd` in little-endian from memory page with id in `rs` first byte at offset `imm`    |
  | `PLW`  | `rd rs imm`   | load four bytes to `rd` in little-endian from memory page with id in `rs` first byte at offset `imm`   |
  | `PLD`  | `rd rs imm`   | load eight bytes to `rd` in little-endian from memory page with id in `rs` first byte at offset `imm`  |
  | `PSB`  | `rs1 rs2 imm` | store byte from `rs1` to page with id in `rs2` at offset `imm`                                         |
  | `PSH`  | `rs1 rs2 imm` | store two bytes from `rs1` in little-endian to page with with id in `rs2` first byte at offset `imm`   |
  | `PSW`  | `rs1 rs2 imm` | store four bytes from `rs1` in little-endian to page with with id in `rs2` first byte at offset `imm`  |
  | `PSD`  | `rs1 rs2 imm` | store eight bytes from `rs1` in little-endian to page with with id in `rs2` first byte at offset `imm` |
  | `BEQ`  | `rs1 rs2 off` | jump to offset `off` if `rs1` is equal to `rs2`                                                        |
  | `BNE`  | `rs1 rs2 off` | jump to offset `off` if `rs1` is not equal to `rs2`                                                    |
  | `BLT`  | `rs1 rs2 off` | jump to offset `off` if `rs1` is less than `rs2` (both signed)                                         |
  | `BGE`  | `rs1 rs2 off` | jump to offset `off` if `rs1` is greater or equal to `rs2` (both signed)                               |
  | `BGEU` | `rs1 rs2 off` | jump to offset `off` if unsigned `rs1` is greater than unsigned `rs2`                                    |
  | `BLTU` | `rs1 rs2 off` | jump to offset `off` if unsigned `rs1` is less or equal to unsigned `rs2`                                |
  | `JALR` | `rd rs imm`   | jump to address in `rs + imm` and save current program counter value into `rd`                         |
  | `ADDI` | `rd rs imm`   | add `imm` to `rs` and save it to `rd`                                                                  |
  | `SUBI` | `rd rs imm`   | subtract                                                                                               |
  | `MULI` | `rd rs imm`   | multiply                                                                                               |
  | `DIVI` | `rd rs imm`   | divide                                                                                                 |
  | `REMI` | `rd rs imm`   | remainder                                                                                              |
  | `ANDI` | `rd rs imm`   | bitwise AND with `imm`                                                                                 |
  | `ORI`  | `rd rs imm`   | bitwise OR with `imm`                                                                                  |
  | `XORI` | `rd rs imm`   | bitwise XOR with `imm`                                                                                 |
  | `SHLI` | `rd rs imm`   | shift left `rs` by `imm` and save it to `rd`                                                           |
  | `SHRI` | `rd rs imm`   | shift right `rs` by `imm` and save it to `rd`                                                          |
  | `EQI`  | `rd rs imm`   | set `rd` to one if `rs` is equal to `imm`                                                              |
  | `NEQI` | `rd rs imm`   | set `rd` to one if `rs` is not equal to `imm`                                                          |
# C instructions
  | name    | usage    | description                                                                                   |
  | ------- | -------- | --------------------------------------------------------------------------------------------- |
  | `JR`    | `rs imm` | jump to `rs + imm`                                                                            |
  | `LUI`   | `rd imm` | load a 20 bit number into `rd` into the upper 20 bits                                         |
  | `AUIPC` | `rd imm` | load a 20 bit number into `rd` into the upper 20 bits and add the program counter value to it |
  | `GP`    | `rd XXX` | request a new page from memory and save its id into `rd`                                      |
  | `FP`    | `rs XXX` | free the page with id from `rs`                                                               |
