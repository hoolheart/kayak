//! 表达式求值结果类型定义

use std::fmt;

/// 表达式求值结果
///
/// 表达式求值可能返回数值结果、布尔结果或错误。
/// 注意：字符串结果在 Release 0 中仅用于字符串相等比较，
/// 不支持字符串连接等复杂操作。
#[derive(Debug, Clone, PartialEq)]
pub enum EvalResult {
    /// 数值结果
    Number(f64),
    /// 布尔结果
    Boolean(bool),
    /// 字符串结果（Release 0 仅用于比较）
    String(String),
}

impl fmt::Display for EvalResult {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            EvalResult::Number(n) => write!(f, "{}", n),
            EvalResult::Boolean(b) => write!(f, "{}", b),
            EvalResult::String(s) => write!(f, "\"{}\"", s),
        }
    }
}

/// 表达式求值错误
///
/// 所有表达式相关的错误都通过此枚举表示。
#[derive(Debug, Clone, PartialEq)]
pub enum ExpressionError {
    /// 语法错误：表达式格式不正确
    Syntax(String),
    /// 变量未定义：引用的变量在上下文中不存在
    UndefinedVariable(String),
    /// 类型不匹配：操作数类型不支持该运算
    TypeMismatch {
        /// 期望的类型描述
        expected: String,
        /// 实际得到的类型描述
        got: String,
        /// 额外的上下文信息（可选）
        context: Option<String>,
    },
    /// 除零错误
    DivisionByZero,
    /// 空表达式
    EmptyExpression,
    /// 不支持的运算符
    UnsupportedOperator(String),
    /// 内部错误
    Internal(String),
}

impl fmt::Display for ExpressionError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ExpressionError::Syntax(msg) => write!(f, "Syntax error: {}", msg),
            ExpressionError::UndefinedVariable(name) => {
                write!(f, "Undefined variable: '{}'", name)
            }
            ExpressionError::TypeMismatch {
                expected,
                got,
                context,
            } => {
                if let Some(ctx) = context {
                    write!(
                        f,
                        "Type mismatch: expected {}, got {} ({})",
                        expected, got, ctx
                    )
                } else {
                    write!(f, "Type mismatch: expected {}, got {}", expected, got)
                }
            }
            ExpressionError::DivisionByZero => write!(f, "Division by zero"),
            ExpressionError::EmptyExpression => write!(f, "Empty expression"),
            ExpressionError::UnsupportedOperator(op) => {
                write!(f, "Unsupported operator: {}", op)
            }
            ExpressionError::Internal(msg) => write!(f, "Internal error: {}", msg),
        }
    }
}

impl std::error::Error for ExpressionError {}
