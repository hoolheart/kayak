//! 表达式引擎模块
//!
//! 提供表达式求值能力，支持算术、比较、逻辑运算和变量引用。

mod engine;
mod result;

// 公开导出
pub use engine::{EvalexprEngine, ExpressionEngine};
pub use result::{EvalResult, ExpressionError};
