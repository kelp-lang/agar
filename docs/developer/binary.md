# Binary (binary.zig)

The original (and future) plan is to use the ELF binary format. But this turned out to be quite a complex task, so in the meantime Agar uses a very simple binary format. It has no checksum, but at least can check if the code has the correct version.

| start | number of bytes | meaning                                                                 |
| ----- | --------------- | ----------------------------------------------------------------------- |
| 0     | 6               | the Agar magic number, it is the string "agarVM" in ASCII               |
| 6     | 2               | Agar version, it is changed each time the binary format is incompatible |
| 8     | X               | the Agar bytecode                                                       |