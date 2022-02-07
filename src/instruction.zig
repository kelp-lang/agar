// Copyright (C) 2022 by Jáchym Tomášek

// It is well known that when you do anything, unless you understand 
// its actual circumstances, its nature and its relations to other things,
// you will not know the laws governing it, or know how to do it, or be able
// to do it well. 

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
    // FADD,
    // FSUB,
    // FMUL,
    // FDIV,
    // FINT,
    // INTF,
    // FEQ,
    // FGE,
    // FLT,
    _,
};

pub const I_Instruction = enum(u9) {
    // Page Load/Store with offset
    PLB,
    PLH,
    PLW,
    PLD,
    PSB,
    PSH,
    PSW,
    PSD,
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
    GP, //get os page //gp rd
    FP, //free os page //fp rs1
    //FPI, //free os page immediate //fpi id
    //SP, //set os page register
};
