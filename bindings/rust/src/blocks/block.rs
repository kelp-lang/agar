use crate::variables::Variable;
use crate::expressions::Expression;

pub struct Block {
    body: Vec<Expression>,
    value: Variable,
}