//! 表达式引擎实现

use std::collections::HashMap;

use crate::drivers::core::PointValue;
use evalexpr::ContextWithMutableVariables;

use super::result::{EvalResult, ExpressionError};

/// 表达式引擎 trait
///
/// 定义表达式求值的基本接口。
pub trait ExpressionEngine: Send + Sync {
    fn eval(
        &self,
        expression: &str,
        context: &HashMap<String, PointValue>,
    ) -> Result<EvalResult, ExpressionError>;
}

/// 基于 evalexpr crate 的表达式引擎实现
pub struct EvalexprEngine;

impl EvalexprEngine {
    pub fn new() -> Self {
        Self
    }

    fn to_evalexpr_value(pv: &PointValue) -> evalexpr::Value {
        match pv {
            PointValue::Number(n) => evalexpr::Value::Float(*n),
            PointValue::Integer(n) => evalexpr::Value::Int(*n),
            PointValue::Boolean(b) => evalexpr::Value::Boolean(*b),
            PointValue::String(s) => evalexpr::Value::String(s.clone()),
        }
    }

    fn from_evalexpr_value(val: evalexpr::Value) -> Result<EvalResult, ExpressionError> {
        match val {
            evalexpr::Value::Float(n) => Ok(EvalResult::Number(n)),
            evalexpr::Value::Int(n) => Ok(EvalResult::Number(n as f64)),
            evalexpr::Value::Boolean(b) => Ok(EvalResult::Boolean(b)),
            evalexpr::Value::String(s) => Ok(EvalResult::String(s)),
            evalexpr::Value::Tuple(_) => Err(ExpressionError::Internal(
                "Tuple value not expected".to_string(),
            )),
            evalexpr::Value::Empty => Err(ExpressionError::Internal(
                "Empty value not expected".to_string(),
            )),
        }
    }

    fn map_error(err: evalexpr::EvalexprError) -> ExpressionError {
        let err_str = err.to_string();
        // Division by zero: "Error dividing 10 / 0"
        if err_str.contains("dividing") {
            return ExpressionError::DivisionByZero;
        }
        // Undefined variable: "Variable identifier is not bound to anything by context: "varname"."
        if err_str.contains("not bound to anything by context") {
            if let Some(var_part) = err_str.split("context: \"").nth(1) {
                // Variable name is between quotes, may end with " or ".\n or similar
                let var_name = var_part.split('"').next().unwrap_or(var_part.trim()).trim();
                return ExpressionError::UndefinedVariable(var_name.to_string());
            }
        }
        ExpressionError::Syntax(err_str)
    }
}

impl Default for EvalexprEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl ExpressionEngine for EvalexprEngine {
    fn eval(
        &self,
        expression: &str,
        context: &HashMap<String, PointValue>,
    ) -> Result<EvalResult, ExpressionError> {
        let trimmed = expression.trim();
        if trimmed.is_empty() {
            return Err(ExpressionError::EmptyExpression);
        }

        // Build context with variables
        let mut ctx = evalexpr::HashMapContext::new();
        for (name, value) in context.iter() {
            ctx.set_value(name.clone(), Self::to_evalexpr_value(value))
                .map_err(|e| {
                    ExpressionError::Internal(format!("Failed to set variable '{}': {}", name, e))
                })?;
        }

        // Parse expression
        let node = evalexpr::build_operator_tree(trimmed)
            .map_err(|e| ExpressionError::Syntax(e.to_string()))?;

        // Evaluate
        let result = node.eval_with_context(&ctx).map_err(Self::map_error)?;

        // Convert result
        Self::from_evalexpr_value(result)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    fn ctx(vars: &[(&str, PointValue)]) -> HashMap<String, PointValue> {
        vars.iter()
            .map(|(k, v)| (k.to_string(), v.clone()))
            .collect()
    }

    fn assert_eval(expr: &str, context: &HashMap<String, PointValue>, expected: EvalResult) {
        let engine = EvalexprEngine::new();
        let result = engine.eval(expr, context).unwrap();
        assert_eq!(result, expected, "Expression: {}", expr);
    }

    fn assert_eval_error(
        expr: &str,
        context: &HashMap<String, PointValue>,
        expected_error: ExpressionError,
    ) {
        let engine = EvalexprEngine::new();
        let result = engine.eval(expr, context);
        assert!(result.is_err(), "Expected error for expression: {}", expr);
        assert_eq!(result.unwrap_err(), expected_error);
    }

    #[test]
    fn test_basic_addition() {
        assert_eval("2 + 3", &ctx(&[]), EvalResult::Number(5.0));
    }

    #[test]
    fn test_basic_subtraction() {
        assert_eval("10 - 4", &ctx(&[]), EvalResult::Number(6.0));
    }

    #[test]
    fn test_basic_multiplication() {
        assert_eval("3 * 5", &ctx(&[]), EvalResult::Number(15.0));
    }

    #[test]
    fn test_basic_division() {
        assert_eval("10 / 2", &ctx(&[]), EvalResult::Number(5.0));
    }

    #[test]
    fn test_modulo() {
        assert_eval("10 % 3", &ctx(&[]), EvalResult::Number(1.0));
    }

    #[test]
    fn test_division_by_zero() {
        assert_eval_error("10 / 0", &ctx(&[]), ExpressionError::DivisionByZero);
    }

    #[test]
    fn test_operator_precedence() {
        assert_eval("2 + 3 * 4", &ctx(&[]), EvalResult::Number(14.0));
        assert_eval("(2 + 3) * 4", &ctx(&[]), EvalResult::Number(20.0));
    }

    #[test]
    fn test_simple_variable() {
        let context = ctx(&[("x", PointValue::Integer(42))]);
        assert_eval("x", &context, EvalResult::Number(42.0));
    }

    #[test]
    fn test_variable_arithmetic() {
        let context = ctx(&[
            ("a", PointValue::Integer(10)),
            ("b", PointValue::Integer(20)),
        ]);
        assert_eval("a + b", &context, EvalResult::Number(30.0));
    }

    #[test]
    fn test_undefined_variable() {
        let result = EvalexprEngine::new().eval("undefined_var + 1", &ctx(&[]));
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err(),
            ExpressionError::UndefinedVariable("undefined_var".to_string())
        );
    }

    #[test]
    fn test_integer_to_number() {
        let context = ctx(&[("x", PointValue::Integer(3))]);
        assert_eval("x + 2.5", &context, EvalResult::Number(5.5));
    }

    #[test]
    fn test_boolean_to_number() {
        // NOTE: evalexpr doesn't support boolean arithmetic (true + 1)
        // This test verifies that boolean values CAN be used in comparisons
        let context = ctx(&[("flag", PointValue::Boolean(true))]);
        assert_eval("flag == true", &context, EvalResult::Boolean(true));
    }

    #[test]
    fn test_number_to_boolean_requires_comparison() {
        let context = ctx(&[("x", PointValue::Number(5.0))]);
        let result = EvalexprEngine::new().eval("!x", &context);
        assert!(result.is_err());
    }

    #[test]
    fn test_comparison() {
        assert_eval("10 > 5", &ctx(&[]), EvalResult::Boolean(true));
        assert_eval("5 > 10", &ctx(&[]), EvalResult::Boolean(false));
    }

    #[test]
    fn test_logical_and() {
        assert_eval("true && true", &ctx(&[]), EvalResult::Boolean(true));
        assert_eval("true && false", &ctx(&[]), EvalResult::Boolean(false));
    }

    #[test]
    fn test_logical_or() {
        assert_eval("false || false", &ctx(&[]), EvalResult::Boolean(false));
        assert_eval("false || true", &ctx(&[]), EvalResult::Boolean(true));
    }

    #[test]
    fn test_logical_not() {
        assert_eval("!true", &ctx(&[]), EvalResult::Boolean(false));
        assert_eval("!false", &ctx(&[]), EvalResult::Boolean(true));
    }

    #[test]
    fn test_overflow() {
        let result = EvalexprEngine::new().eval("1e308 * 10", &ctx(&[])).unwrap();
        assert_eq!(result, EvalResult::Number(f64::INFINITY));
    }

    #[test]
    fn test_nan() {
        let result = EvalexprEngine::new().eval("0.0 / 0.0", &ctx(&[])).unwrap();
        assert!(matches!(result, EvalResult::Number(n) if n.is_nan()));
    }

    #[test]
    fn test_empty_expression() {
        let result = EvalexprEngine::new().eval("", &ctx(&[]));
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), ExpressionError::EmptyExpression);
    }

    #[test]
    fn test_whitespace_only_expression() {
        let result = EvalexprEngine::new().eval("   ", &ctx(&[]));
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), ExpressionError::EmptyExpression);
    }

    #[test]
    fn test_syntax_error() {
        let result = EvalexprEngine::new().eval("2 +", &ctx(&[]));
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ExpressionError::Syntax(_)));
    }
}
