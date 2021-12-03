// Copyright (C) 2021 by Jáchym Tomášek
pub const PseudoInstruction = enum {
    NOP, //addi zero zero zero
    J, //j offset -> jr zero offset
    JAL, //jal rd offset -> jalr rd zero offset
    CALL, //call offset -> auipc ra offset20, jalr ra ra offset12
    TAIL, //tail offset -> auipc t0 offset20, jr t0 offset12
    MV, //mv rd rs -> addi rd rs 0
    LI, //lui rd offset20, addi rd offset12
    RET, //jr ra 0
    NOT, //not rd rs -> xori rd rs -1
    NEG, //neg rd rs -> sub rd zero rs
    GT, //gt rd rs1 rs2 -> lt rd rs2 rs1
    LE, //le rd rs1 rs2 -> ge rd rs2 rs1
};

pub const R_Instruction = enum(u17) {
    IGL,
    HLT,
    ADD,
    SUB,
    MUL,
    DIV,
    REM,
    AND,
    OR,
    XOR,
    SHL,
    SHR,
    EQ,
    NEQ,
    GE,
    LT,
    FADD,
    FSUB,
    FMUL,
    FDIV,
    FINT,
    INTF,
    FEQ,
    FGE,
    FLT,
    _,
};

pub const I_Instruction = enum(u9) {
    // Stack Load/Store with offset
    SLB,
    SLH,
    SLW,
    SLD,
    SSB,
    SSH,
    SSW,
    SSD,
    // Branching
    BEQ,
    BNE,
    BLT,
    BGE,
    BGEU,
    BLTU,
    JALR, //jalr rd rs1 offset -> rd = pc+1, pc = pc+(rs1+offset)
    // Immediate arithmetic
    ADDI,
    SUBI,
    MULI,
    DIVI,
    REMI,
    ANDI,
    ORI,
    XORI,
    SHLI,
    SHRI,
    EQI,
    NEQI,
    _,
};

pub const C_Instruction = enum(u5) {
    JR, //jr rs1 offset -> pc = pc+(rs1+offset)
    LUI,
    AUIPC,
};
