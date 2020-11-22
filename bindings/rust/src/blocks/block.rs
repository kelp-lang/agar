use crate::variables::Variable;
use crate::instructions::Instruction;

pub struct Block {
    body: Vec<Instruction>,
    value: Variable,
}