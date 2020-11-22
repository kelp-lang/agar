use crate::types::Type;
use crate::variables::Variable;

pub struct Function {
    arguments: Vec<(Variable, Type)>,
    variables: Vec<(Variable, Type)>,
    return_type: Type,
}