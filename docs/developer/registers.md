# Registers
| register identifier | description                      |
|---------------------|----------------------------------|
| zero                | register with the constant 0     |
| ra                  | return address                   |
| pp                  | page pointer                     |
| t0-t6               | temporary registers              |
| s0-s11              | saved registers                  |
| a0-a9               | function arguments/return values |

## The `zero` register
Origin of this register is from the Risc-V architecture. Note that all registers are named only for user convenience. There is no guarantee that any register will have a value that it should have. **Not even the `zero` register!** You can assign a value to the `zero` register. But if you run any third-party code note that it can lead to undefined behavior.