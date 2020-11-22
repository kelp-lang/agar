use crate::blocks::Block;
use crate::variables::Variable;

pub enum Expression {
    // Math
    add_i32(Variable, Variable, Variable),
    sub_i32(Variable, Variable, Variable),
    mul_i32(Variable, Variable, Variable),
    div_i32(Variable, Variable, Variable),
    // Equality
    eq_i32(Variable, Variable, Variable),
    neq_i32(Variable, Variable, Variable),
    // Block manipulatiton
    val(Variable),
    val_cpy(Variable),
    // Set
    set_var(Variable, Variable),
    set_prm(Variable),
    // Jumping
    jmp(Block, Option<Variable>),
    jmp_eq(Variable, Block, Option<Variable>),
    jmp_neq(Variable, Block, Option<Variable>),
}