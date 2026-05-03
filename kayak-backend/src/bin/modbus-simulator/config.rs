//! Configuration for the Modbus TCP simulator.
//!
//! Handles CLI argument parsing via clap, TOML/JSON config file loading,
//! and merging of configuration sources with CLI override priority.

use clap::Parser;
use serde::Deserialize;
use std::collections::HashMap;
use std::path::PathBuf;

// ============================================================================
// Default Constants
// ============================================================================

/// Default TCP listening port (Modbus standard)
pub const DEFAULT_PORT: u16 = 502;
/// Default Modbus slave/unit ID
pub const DEFAULT_SLAVE_ID: u8 = 1;
/// Default number of coils in the data store
pub const DEFAULT_NUM_COILS: u16 = 64;
/// Default number of holding registers in the data store
pub const DEFAULT_NUM_HOLDING_REGISTERS: u16 = 64;
/// Default log level
pub const DEFAULT_LOG_LEVEL: &str = "info";

// ============================================================================
// CLI Arguments
// ============================================================================

/// Modbus TCP Slave Simulator
///
/// Starts a Modbus TCP slave (server) that listens on a TCP port and responds
/// to Modbus TCP master (client) requests.
///
/// Supported function codes:
///   - FC 0x01: Read Coils
///   - FC 0x03: Read Holding Registers
#[derive(Parser, Debug)]
#[command(name = "modbus-simulator")]
#[command(version = "0.1.0")]
#[command(about = "Modbus TCP Slave Simulator", long_about = None)]
pub struct CliArgs {
    /// Path to a full TOML configuration file
    #[arg(short = 'c', long = "config", value_name = "FILE")]
    pub config: Option<PathBuf>,

    /// TCP listening port [default: 502]
    #[arg(short = 'p', long = "port", value_name = "PORT")]
    pub port: Option<u16>,

    /// Modbus slave/unit ID (1-247) [default: 1]
    #[arg(short = 's', long = "slave-id", value_name = "ID")]
    pub slave_id: Option<u8>,

    /// Path to a JSON file containing coils initial values.
    /// Format: {"0": true, "1": false, "3": true}
    #[arg(long = "coils-config", value_name = "FILE")]
    pub coils_config: Option<PathBuf>,

    /// Path to a JSON file containing holding registers initial values.
    /// Format: {"0": 100, "1": 200, "2": 300}
    #[arg(long = "registers-config", value_name = "FILE")]
    pub registers_config: Option<PathBuf>,

    /// Comma-separated coils initial values (e.g., "1,0,1,0").
    /// Overrides --coils-config for specified indices.
    #[arg(long = "coils", value_name = "VALUES", value_delimiter = ',')]
    pub coils: Option<Vec<u8>>,

    /// Comma-separated holding registers initial values (e.g., "100,200,300,400").
    /// Overrides --registers-config for specified indices.
    #[arg(long = "registers", value_name = "VALUES", value_delimiter = ',')]
    pub registers: Option<Vec<u16>>,

    /// Number of coils in the data store [default: 64].
    /// Only used when no config file is specified.
    #[arg(long = "num-coils", value_name = "COUNT")]
    pub num_coils: Option<u16>,

    /// Number of holding registers in the data store [default: 64].
    /// Only used when no config file is specified.
    #[arg(long = "num-registers", value_name = "COUNT")]
    pub num_registers: Option<u16>,

    /// Verbose logging output (equivalent to --log-level debug)
    #[arg(short = 'v', long = "verbose")]
    pub verbose: bool,

    /// Log level [possible values: trace, debug, info, warn, error] [default: info]
    #[arg(long = "log-level", value_name = "LEVEL", default_value = DEFAULT_LOG_LEVEL)]
    pub log_level: String,
}

// ============================================================================
// TOML Config File Structures
// ============================================================================

/// Full TOML configuration file structure.
///
/// All fields are optional; unspecified fields use defaults or CLI overrides.
#[derive(Debug, Deserialize)]
pub struct TomlConfig {
    /// TCP listening port
    pub port: Option<u16>,
    /// Modbus slave/unit ID
    pub slave_id: Option<u8>,
    /// Number of coils
    pub num_coils: Option<u16>,
    /// Number of holding registers
    pub num_holding_registers: Option<u16>,
    /// Coil initial values as index-value pairs
    pub initial_coils: Option<Vec<IndexedBool>>,
    /// Holding register initial values as index-value pairs
    pub initial_holding_registers: Option<Vec<IndexedU16>>,
    /// Log level
    pub log_level: Option<String>,
    /// Verbose mode
    pub verbose: Option<bool>,
}

/// Indexed boolean value for TOML coil configuration.
#[derive(Debug, Deserialize)]
pub struct IndexedBool {
    /// Coil address index (0-based)
    pub index: u16,
    /// Coil value (true = ON, false = OFF)
    pub value: bool,
}

/// Indexed u16 value for TOML register configuration.
#[derive(Debug, Deserialize)]
pub struct IndexedU16 {
    /// Register address index (0-based)
    pub index: u16,
    /// Register value (0-65535)
    pub value: u16,
}

// ============================================================================
// Runtime Configuration
// ============================================================================

/// Resolved runtime configuration for the simulator.
///
/// This is the final merged configuration used at runtime,
/// after combining defaults, config file, and CLI overrides.
#[derive(Debug, Clone)]
pub struct SimulatorConfig {
    /// TCP listening port
    pub port: u16,
    /// Modbus slave/unit ID
    pub slave_id: u8,
    /// Number of coils in the data store
    pub num_coils: u16,
    /// Number of holding registers in the data store
    pub num_registers: u16,
    /// Coil initial values as (index, value) pairs
    pub initial_coils: Vec<(u16, bool)>,
    /// Holding register initial values as (index, value) pairs
    pub initial_registers: Vec<(u16, u16)>,
    /// Whether verbose logging is enabled
    pub verbose: bool,
    /// Log level string
    pub log_level: String,
}

impl Default for SimulatorConfig {
    fn default() -> Self {
        Self {
            port: DEFAULT_PORT,
            slave_id: DEFAULT_SLAVE_ID,
            num_coils: DEFAULT_NUM_COILS,
            num_registers: DEFAULT_NUM_HOLDING_REGISTERS,
            initial_coils: Vec::new(),
            initial_registers: Vec::new(),
            verbose: false,
            log_level: DEFAULT_LOG_LEVEL.to_string(),
        }
    }
}

impl SimulatorConfig {
    /// Build the resolved configuration from CLI args.
    ///
    /// Merge order (lowest to highest priority):
    /// 1. Hard-coded defaults
    /// 2. TOML config file (--config)
    /// 3. JSON coils config file (--coils-config)
    /// 4. JSON registers config file (--registers-config)
    /// 5. CLI inline values (--coils, --registers)
    /// 6. CLI scalar overrides (--port, --slave-id, --verbose, --log-level, --num-coils, --num-registers)
    pub fn from_cli(cli: &CliArgs) -> Result<Self, String> {
        let mut config = Self::default();

        // Layer 2: TOML config file
        if let Some(ref config_path) = cli.config {
            let toml_config = Self::load_toml(config_path)?;
            config.merge_toml(&toml_config);
        }

        // Layer 3: JSON coils config file
        if let Some(ref coils_path) = cli.coils_config {
            let coils = Self::load_json_coils(coils_path)?;
            config.initial_coils = coils;
        }

        // Layer 4: JSON registers config file
        if let Some(ref regs_path) = cli.registers_config {
            let regs = Self::load_json_registers(regs_path)?;
            config.initial_registers = regs;
        }

        // Layer 5: CLI inline values (append/override specific indices)
        if let Some(ref csv) = cli.coils {
            let coils = Self::parse_coils_csv(csv)?;
            // Merge: CLI values override config values for the same indices
            Self::merge_coils(&mut config.initial_coils, &coils);
        }

        if let Some(ref csv) = cli.registers {
            let regs = Self::parse_registers_csv(csv)?;
            Self::merge_registers(&mut config.initial_registers, &regs);
        }

        // Layer 6: CLI scalar overrides
        if let Some(port) = cli.port {
            config.port = port;
        }
        if let Some(slave_id) = cli.slave_id {
            if slave_id < 1 || slave_id > 247 {
                return Err(format!(
                    "Invalid slave-id: {}. Must be between 1 and 247.",
                    slave_id
                ));
            }
            config.slave_id = slave_id;
        }
        if let Some(num_coils) = cli.num_coils {
            config.num_coils = num_coils;
        }
        if let Some(num_registers) = cli.num_registers {
            config.num_registers = num_registers;
        }
        if cli.verbose {
            config.verbose = true;
            config.log_level = "debug".to_string();
        } else {
            config.log_level = cli.log_level.clone();
        }

        Ok(config)
    }

    // ========================================================================
    // TOML Config File
    // ========================================================================

    /// Load and parse a TOML configuration file.
    fn load_toml(path: &PathBuf) -> Result<TomlConfig, String> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| format!("Failed to read config file '{}': {}", path.display(), e))?;

        toml::from_str(&content).map_err(|e| {
            format!(
                "Failed to parse TOML config file '{}': {}",
                path.display(),
                e
            )
        })
    }

    /// Merge TOML config values into this configuration.
    fn merge_toml(&mut self, toml: &TomlConfig) {
        if let Some(port) = toml.port {
            self.port = port;
        }
        if let Some(slave_id) = toml.slave_id {
            self.slave_id = slave_id;
        }
        if let Some(num_coils) = toml.num_coils {
            self.num_coils = num_coils;
        }
        if let Some(num_registers) = toml.num_holding_registers {
            self.num_registers = num_registers;
        }
        if let Some(ref coils) = toml.initial_coils {
            self.initial_coils = coils.iter().map(|c| (c.index, c.value)).collect();
        }
        if let Some(ref regs) = toml.initial_holding_registers {
            self.initial_registers = regs.iter().map(|r| (r.index, r.value)).collect();
        }
        if let Some(ref log_level) = toml.log_level {
            self.log_level = log_level.clone();
        }
        if let Some(verbose) = toml.verbose {
            self.verbose = verbose;
        }
    }

    // ========================================================================
    // JSON Config Files (--coils-config / --registers-config)
    // ========================================================================

    /// Load coils initial values from a JSON file.
    /// Expected format: {"0": true, "1": false, "3": true}
    fn load_json_coils(path: &PathBuf) -> Result<Vec<(u16, bool)>, String> {
        let content = std::fs::read_to_string(path).map_err(|e| {
            format!(
                "Failed to read coils config file '{}': {}",
                path.display(),
                e
            )
        })?;

        let map: HashMap<String, bool> = serde_json::from_str(&content).map_err(|e| {
            format!(
                "Failed to parse coils config JSON '{}': {}",
                path.display(),
                e
            )
        })?;

        let mut coils = Vec::new();
        for (key, value) in map {
            let index: u16 = key.parse().map_err(|_| {
                format!(
                    "Invalid coil index '{}' in '{}': must be an integer",
                    key,
                    path.display()
                )
            })?;
            coils.push((index, value));
        }
        // Sort by index for deterministic behavior
        coils.sort_by_key(|(i, _)| *i);
        Ok(coils)
    }

    /// Load holding registers initial values from a JSON file.
    /// Expected format: {"0": 100, "1": 200, "2": 300}
    fn load_json_registers(path: &PathBuf) -> Result<Vec<(u16, u16)>, String> {
        let content = std::fs::read_to_string(path).map_err(|e| {
            format!(
                "Failed to read registers config file '{}': {}",
                path.display(),
                e
            )
        })?;

        let map: HashMap<String, serde_json::Value> =
            serde_json::from_str(&content).map_err(|e| {
                format!(
                    "Failed to parse registers config JSON '{}': {}",
                    path.display(),
                    e
                )
            })?;

        let mut registers = Vec::new();
        for (key, value) in map {
            let index: u16 = key.parse().map_err(|_| {
                format!(
                    "Invalid register index '{}' in '{}': must be an integer",
                    key,
                    path.display()
                )
            })?;

            let reg_value: u16 = value
                .as_u64()
                .and_then(|v| u16::try_from(v).ok())
                .ok_or_else(|| {
                    format!(
                        "Invalid register value at index {} in '{}': must be 0-65535",
                        index,
                        path.display()
                    )
                })?;

            registers.push((index, reg_value));
        }
        registers.sort_by_key(|(i, _)| *i);
        Ok(registers)
    }

    // ========================================================================
    // CSV Parsing (--coils / --registers inline values)
    // ========================================================================

    /// Parse coils values from a CSV string.
    ///
    /// Each element is a 0/1 (or true/false) value representing a coil state.
    /// The first element is coil index 0, second is index 1, etc.
    fn parse_coils_csv(csv: &[u8]) -> Result<Vec<(u16, bool)>, String> {
        csv.iter()
            .enumerate()
            .map(|(i, &v)| match v {
                0 => Ok((i as u16, false)),
                1 => Ok((i as u16, true)),
                _ => Err(format!(
                    "Invalid coil value at position {}: {}. Expected 0 or 1.",
                    i, v
                )),
            })
            .collect()
    }

    /// Parse registers values from a CSV string.
    ///
    /// Each element is a decimal u16 value.
    /// The first element is register index 0, second is index 1, etc.
    fn parse_registers_csv(csv: &[u16]) -> Result<Vec<(u16, u16)>, String> {
        Ok(csv
            .iter()
            .enumerate()
            .map(|(i, &v)| (i as u16, v))
            .collect())
    }

    /// Merge CLI inline coils into the initial coils list.
    /// CLI values override config values for matching indices.
    fn merge_coils(existing: &mut Vec<(u16, bool)>, new: &[(u16, bool)]) {
        for &(index, value) in new {
            // Remove any existing entry for this index
            existing.retain(|(i, _)| *i != index);
            existing.push((index, value));
        }
        existing.sort_by_key(|(i, _)| *i);
    }

    /// Merge CLI inline registers into the initial registers list.
    fn merge_registers(existing: &mut Vec<(u16, u16)>, new: &[(u16, u16)]) {
        for &(index, value) in new {
            existing.retain(|(i, _)| *i != index);
            existing.push((index, value));
        }
        existing.sort_by_key(|(i, _)| *i);
    }
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = SimulatorConfig::default();
        assert_eq!(config.port, 502);
        assert_eq!(config.slave_id, 1);
        assert_eq!(config.num_coils, 64);
        assert_eq!(config.num_registers, 64);
        assert_eq!(config.initial_coils.len(), 0);
        assert_eq!(config.initial_registers.len(), 0);
        assert!(!config.verbose);
        assert_eq!(config.log_level, "info");
    }

    #[test]
    fn test_parse_coils_csv() {
        let coils = SimulatorConfig::parse_coils_csv(&[1, 0, 1, 0]).unwrap();
        assert_eq!(coils, vec![(0, true), (1, false), (2, true), (3, false)]);
    }

    #[test]
    fn test_parse_registers_csv() {
        let regs = SimulatorConfig::parse_registers_csv(&[100, 200, 300]).unwrap();
        assert_eq!(regs, vec![(0, 100), (1, 200), (2, 300)]);
    }

    #[test]
    fn test_parse_coils_csv_invalid_value() {
        let result = SimulatorConfig::parse_coils_csv(&[1, 2, 0]);
        assert!(result.is_err());
    }

    #[test]
    fn test_merge_coils() {
        let mut existing = vec![(0, false), (1, false), (2, false)];
        let new = [(1, true), (3, true)];
        SimulatorConfig::merge_coils(&mut existing, &new);
        // Index 0: false (unchanged), 1: true (overridden), 2: false (unchanged), 3: true (new)
        assert_eq!(existing, vec![(0, false), (1, true), (2, false), (3, true)]);
    }

    #[test]
    fn test_merge_registers() {
        let mut existing = vec![(0, 0), (1, 0), (2, 0)];
        let new = [(1, 999), (3, 777)];
        SimulatorConfig::merge_registers(&mut existing, &new);
        assert_eq!(existing, vec![(0, 0), (1, 999), (2, 0), (3, 777)]);
    }

    #[test]
    fn test_cli_default_args() {
        let args = CliArgs::parse_from(["modbus-simulator"]);
        assert!(args.config.is_none());
        assert!(args.port.is_none());
        assert!(args.slave_id.is_none());
        assert!(!args.verbose);
        assert_eq!(args.log_level, "info");
    }

    #[test]
    fn test_cli_port_override() {
        let args = CliArgs::parse_from(["modbus-simulator", "--port", "1502"]);
        assert_eq!(args.port, Some(1502));
    }

    #[test]
    fn test_cli_slave_id_override() {
        let args = CliArgs::parse_from(["modbus-simulator", "--slave-id", "5"]);
        assert_eq!(args.slave_id, Some(5));
    }

    #[test]
    fn test_cli_coils_override() {
        let args = CliArgs::parse_from(["modbus-simulator", "--coils", "1,0,1"]);
        assert_eq!(args.coils, Some(vec![1, 0, 1]));
    }

    #[test]
    fn test_cli_registers_override() {
        let args = CliArgs::parse_from(["modbus-simulator", "--registers", "100,200"]);
        assert_eq!(args.registers, Some(vec![100, 200]));
    }

    #[test]
    fn test_from_cli_default() {
        let args = CliArgs::parse_from(["modbus-simulator"]);
        let config = SimulatorConfig::from_cli(&args).unwrap();
        assert_eq!(config.port, 502);
        assert_eq!(config.slave_id, 1);
        assert_eq!(config.num_coils, 64);
        assert_eq!(config.num_registers, 64);
    }

    #[test]
    fn test_from_cli_with_overrides() {
        let args = CliArgs::parse_from([
            "modbus-simulator",
            "--port",
            "1502",
            "--slave-id",
            "5",
            "--coils",
            "1,0,1,0",
            "--registers",
            "100,200,300",
            "--num-coils",
            "128",
            "--num-registers",
            "256",
            "--verbose",
        ]);
        let config = SimulatorConfig::from_cli(&args).unwrap();
        assert_eq!(config.port, 1502);
        assert_eq!(config.slave_id, 5);
        assert_eq!(config.num_coils, 128);
        assert_eq!(config.num_registers, 256);
        assert_eq!(
            config.initial_coils,
            vec![(0, true), (1, false), (2, true), (3, false)]
        );
        assert_eq!(config.initial_registers, vec![(0, 100), (1, 200), (2, 300)]);
        assert!(config.verbose);
    }

    #[test]
    fn test_from_cli_invalid_slave_id() {
        let args = CliArgs::parse_from(["modbus-simulator", "--slave-id", "0"]);
        let result = SimulatorConfig::from_cli(&args);
        assert!(result.is_err());

        let args = CliArgs::parse_from(["modbus-simulator", "--slave-id", "248"]);
        let result = SimulatorConfig::from_cli(&args);
        assert!(result.is_err());
    }
}
