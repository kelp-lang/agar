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
    equal, //dest_register value value
    create_list_item, //dest_register value list_tail
    append_to_list, //dest_register list_value list_value
    //list_item_to_object, //dest_register list_pointer
    //object_to_list_item, //dest_register list_pointer next_pointer
    //clone_object, //dest_register object_pointer
    get_type, //dest_register value
    object_field, //dest_register object_pointer field_offset
    travel_list_by, //dest_register list_item_pointer number_pointer/offset
    clone_list_from, //dest_register list_pointer length_pointer/offset
    list_len, //dest_register list_pointer
    //from_object_64_offset, //dest_register pointer offset
    reserve_call_header, //dest_reg _____ size_immediate TODO: assembler should do this when expanding call macro
    quote, //save from current instruction offset instructions into memory //dest_register offset
    eval_offset, //from some register load that memory and execute it until offset*4 //AKA load memory as 32bits
    eval, //TODO:
    load_symbol, // dest_register name_object context //context can be either a local context or a global one
    def_symbol, //dest_name value context
    release_symbol,
    set_symbol, //dest_name value context
    call_form, //
    //NOTE: Converting a list item to an object, should be trivial, as objects begin exactly 8 bytes after the list head
    _,
};

pub const I_Instruction = enum(u9) {
    // Load/Store with offset
    SB,
    SD,
    SQ,
    SO,
    LB,
    LD,
    LQ,
    LO,
    LRB,
    LRD,
    LRQ,
    LRO,
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

pub const Instruction = enum(u16) {
    call_native, // //form_ident
    call, //symbol_ident
    tail, //symbol_ident
    reserve_stack, //pointer_to_stack stack_size
    call_partial, //result_pointer_to symbol_ident
    eval, //object_pointer call eval until depleted, if quote, unwrap, aka spawn subvm with a program
    quote, //package object into a quote object
    add_list_item, //dest_reg object_ptr_reg next_ptr_reg
    duplicate_list, //dest_reg list_ptr
    stack_store_register, //register stack_offset
    stack_load_register, //dest_register offset
    jump, //offset
    jump_eq, //rs1 rs2 offset
    jump_neq,
};
