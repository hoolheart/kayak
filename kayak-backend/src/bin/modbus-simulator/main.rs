//! Modbus TCP Slave Simulator CLI
//!
//! A standalone binary that starts a Modbus TCP slave (server) listening on a
//! configurable TCP port. Supports Read Coils (FC 0x01) and Read Holding
//! Registers (FC 0x03) with configurable initial values.
//!
//! # Usage
//!
//! ```bash
//! # Start with defaults (port 502, slave ID 1, 64 coils, 64 registers)
//! modbus-simulator
//!
//! # Custom port and slave ID
//! modbus-simulator --port 1502 --slave-id 5
//!
//! # Inline coil and register values
//! modbus-simulator --coils 1,0,1,0,1,0,1,0 --registers 100,200,300,400
//!
//! # From config files
//! modbus-simulator --coils-config coils.json --registers-config regs.json
//!
//! # Verbose logging
//! modbus-simulator --verbose
//!
//! # Full TOML config file
//! modbus-simulator --config simulator.toml
//! ```

mod config;
mod server;

use clap::Parser;
use std::sync::Arc;
use tokio::sync::RwLock;

use config::{CliArgs, SimulatorConfig};
use server::{DataStore, SharedDataStore};

#[tokio::main]
async fn main() {
    // Parse CLI arguments
    let cli = CliArgs::parse();

    // Resolve configuration (merge defaults, config files, CLI overrides)
    let config = match SimulatorConfig::from_cli(&cli) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Configuration error: {}", e);
            std::process::exit(1);
        }
    };

    // Initialize tracing/logging
    init_logging(&config);

    tracing::info!(
        "Starting Modbus TCP Simulator v{}",
        env!("CARGO_PKG_VERSION")
    );

    // Create and initialize the data store
    let mut datastore = DataStore::new(config.num_coils, config.num_registers);

    if !config.initial_coils.is_empty() {
        datastore.init_coils(config.initial_coils.clone());
        if config.verbose {
            tracing::debug!("Initialized {} coil(s)", config.initial_coils.len());
        }
    }

    if !config.initial_registers.is_empty() {
        datastore.init_registers(config.initial_registers.clone());
        if config.verbose {
            tracing::debug!(
                "Initialized {} holding register(s)",
                config.initial_registers.len()
            );
        }
    }

    let shared_ds: SharedDataStore = Arc::new(RwLock::new(datastore));

    // Run the server with graceful shutdown on Ctrl+C
    let server_task = tokio::spawn(server::run_server(config, shared_ds));

    tokio::select! {
        result = server_task => {
            if let Err(e) = result {
                tracing::error!("Server task error: {}", e);
            }
        }
        _ = tokio::signal::ctrl_c() => {
            tracing::info!("Shutting down...");
        }
    }

    tracing::info!("Modbus simulator stopped");
}

/// Initialize the tracing/logging subscriber.
fn init_logging(config: &SimulatorConfig) {
    use tracing_subscriber::fmt;
    use tracing_subscriber::EnvFilter;

    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(config.log_level.clone()));

    fmt()
        .with_target(true)
        .with_thread_ids(false)
        .with_thread_names(false)
        .with_file(false)
        .with_line_number(false)
        .with_env_filter(filter)
        .init();
}
