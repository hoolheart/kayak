//! Team management service module

pub mod error;
pub mod service;

pub use error::TeamServiceError;
pub use service::{TeamService, TeamServiceImpl};
