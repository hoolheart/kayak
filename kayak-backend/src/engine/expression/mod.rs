//! 表达式引擎模块
//!
//! 提供表达式求值能力，支持算术、比较、逻辑运算和变量引用。

mod engine;
mod result;

// 公开导出 - #[allow(unused)] 因为表达式引擎功能在S2-010已完成但未在Release 0中使用
#[allow(unused)]
pub use engine::{EvalexprEngine, ExpressionEngine};
#[allow(unused)]
pub use result::{EvalResult, ExpressionError};
