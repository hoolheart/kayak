//! Modbus TCP server implementation for the simulator.
//!
//! Handles TCP listening, per-connection frame reading, PDU processing,
//! and response construction. Uses the existing kayak_backend modbus types
//! for MBAP/PDU parsing and construction.

use kayak_backend::drivers::modbus::{FunctionCode, MbapHeader, ModbusError, Pdu};
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::RwLock;

use super::config::SimulatorConfig;

// ============================================================================
// DataStore
// ============================================================================

/// Thread-safe Modbus data store.
///
/// Stores coil and holding register values for the simulated Modbus slave device.
/// Uses `Arc<RwLock<DataStore>>` for concurrent access across connection tasks.
#[derive(Debug, Clone)]
pub struct DataStore {
    /// Coil values (bit array), indexed by address
    coils: Vec<bool>,
    /// Holding register values (16-bit array), indexed by address
    holding_registers: Vec<u16>,
}

/// Thread-safe shared reference to the data store.
pub type SharedDataStore = Arc<RwLock<DataStore>>;

impl DataStore {
    /// Create a new data store with the given sizes.
    ///
    /// All values are initialized to default (false for coils, 0 for registers).
    pub fn new(num_coils: u16, num_registers: u16) -> Self {
        Self {
            coils: vec![false; num_coils as usize],
            holding_registers: vec![0u16; num_registers as usize],
        }
    }

    /// Initialize coil values from a list of (index, value) pairs.
    ///
    /// Only indices within the allocated range are applied; out-of-range
    /// indices are silently ignored.
    pub fn init_coils<I: IntoIterator<Item = (u16, bool)>>(&mut self, initial: I) {
        for (index, value) in initial {
            if (index as usize) < self.coils.len() {
                self.coils[index as usize] = value;
            }
        }
    }

    /// Initialize holding register values from a list of (index, value) pairs.
    pub fn init_registers<I: IntoIterator<Item = (u16, u16)>>(&mut self, initial: I) {
        for (index, value) in initial {
            if (index as usize) < self.holding_registers.len() {
                self.holding_registers[index as usize] = value;
            }
        }
    }

    /// Read coil values from the data store.
    ///
    /// # Returns
    /// * `Ok(Vec<bool>)` - the coil values at the requested addresses
    /// * `Err(ModbusError::IllegalDataAddress)` - if the address range is out of bounds
    pub fn read_coils(&self, start_address: u16, quantity: u16) -> Result<Vec<bool>, ModbusError> {
        let start = start_address as usize;
        let end = start + quantity as usize;
        if end > self.coils.len() {
            return Err(ModbusError::IllegalDataAddress);
        }
        Ok(self.coils[start..end].to_vec())
    }

    /// Read holding register values from the data store.
    ///
    /// # Returns
    /// * `Ok(Vec<u16>)` - the register values at the requested addresses
    /// * `Err(ModbusError::IllegalDataAddress)` - if the address range is out of bounds
    pub fn read_holding_registers(
        &self,
        start_address: u16,
        quantity: u16,
    ) -> Result<Vec<u16>, ModbusError> {
        let start = start_address as usize;
        let end = start + quantity as usize;
        if end > self.holding_registers.len() {
            return Err(ModbusError::IllegalDataAddress);
        }
        Ok(self.holding_registers[start..end].to_vec())
    }

    /// Get the number of coils.
    pub fn coil_count(&self) -> u16 {
        self.coils.len() as u16
    }

    /// Get the number of holding registers.
    pub fn register_count(&self) -> u16 {
        self.holding_registers.len() as u16
    }
}

// ============================================================================
// Server
// ============================================================================

/// Start the Modbus TCP slave server.
///
/// Binds to `0.0.0.0:<port>` and accepts connections indefinitely.
/// Each connection is handled in a separate tokio task.
pub async fn run_server(config: SimulatorConfig, datastore: SharedDataStore) {
    let bind_addr = format!("0.0.0.0:{}", config.port);
    let listener = match TcpListener::bind(&bind_addr).await {
        Ok(l) => l,
        Err(e) => {
            tracing::error!("Failed to bind to {}: {}", bind_addr, e);
            std::process::exit(1);
        }
    };

    tracing::info!("Modbus TCP Simulator listening on {}", bind_addr);
    tracing::info!("  Slave ID: {}", config.slave_id);
    {
        let ds = datastore.read().await;
        tracing::info!("  Coils available: {}", ds.coil_count());
        tracing::info!("  Registers available: {}", ds.register_count());
    }
    if config.verbose {
        tracing::debug!("  Configuration: {:?}", config);
    }

    let slave_id = config.slave_id;

    loop {
        match listener.accept().await {
            Ok((stream, peer_addr)) => {
                tracing::info!("New connection from {}", peer_addr);

                let ds_clone = Arc::clone(&datastore);

                tokio::spawn(async move {
                    handle_connection(stream, ds_clone, peer_addr, slave_id).await;
                    tracing::info!("Connection closed: {}", peer_addr);
                });
            }
            Err(e) => {
                tracing::error!("Accept error: {}", e);
                // Brief delay before retrying accept
                tokio::time::sleep(std::time::Duration::from_millis(100)).await;
            }
        }
    }
}

// ============================================================================
// Connection Handler
// ============================================================================

/// Handle a single Modbus TCP client connection.
///
/// Reads frames in a loop: MBAP header → PDU → process → write response.
/// Disconnects on fatal errors or client EOF.
async fn handle_connection(
    mut stream: TcpStream,
    datastore: SharedDataStore,
    peer_addr: SocketAddr,
    slave_id: u8,
) {
    let mut mbap_buf = [0u8; MbapHeader::LENGTH];

    loop {
        // ===== Phase 1: Read MBAP header (7 bytes) =====
        match stream.read_exact(&mut mbap_buf).await {
            Ok(_) => {
                // Continue processing (read_exact returns usize)
            }
            Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof => {
                tracing::info!("Client {} disconnected", peer_addr);
                break;
            }
            Err(e) => {
                tracing::error!("Read error from {}: {}", peer_addr, e);
                break;
            }
        }

        // Parse MBAP header
        let request_mbap = match MbapHeader::parse(&mbap_buf) {
            Ok(header) => header,
            Err(e) => {
                tracing::warn!("Invalid MBAP from {}: {}", peer_addr, e);
                break;
            }
        };

        // Check slave/unit ID
        if request_mbap.unit_id != slave_id {
            tracing::debug!(
                "Ignoring request from {} with unit_id={} (expected {})",
                peer_addr,
                request_mbap.unit_id,
                slave_id
            );
            // Silently ignore: read next frame
            continue;
        }

        // ===== Phase 2: Read PDU data =====
        let pdu_len = request_mbap.pdu_length() as usize;
        if pdu_len == 0 {
            tracing::warn!("Zero-length PDU from {}", peer_addr);
            // Send exception: Server Device Failure
            let exception_frame = build_mbap_exception_response(&request_mbap, 0x00, 0x04);
            let _ = stream.write_all(&exception_frame).await;
            continue;
        }

        let mut pdu_buf = vec![0u8; pdu_len];
        if let Err(e) = stream.read_exact(&mut pdu_buf).await {
            tracing::error!("Failed to read PDU from {}: {}", peer_addr, e);
            break;
        }

        // Trace raw request in verbose mode
        tracing::debug!(
            "[{}] REQ tid={} uid={} pdu={:02X?}",
            peer_addr,
            request_mbap.transaction_id,
            request_mbap.unit_id,
            &pdu_buf
        );

        // Parse PDU
        let request_pdu = match Pdu::parse(&pdu_buf) {
            Ok(pdu) => pdu,
            Err(e) => {
                tracing::warn!(
                    "[{}] Invalid PDU: {:?}, raw function code byte: 0x{:02X}",
                    peer_addr,
                    e,
                    pdu_buf.first().unwrap_or(&0)
                );
                // Build exception response with the original function code byte
                let original_fc = pdu_buf.first().copied().unwrap_or(0);
                let exception_frame = build_mbap_exception_response(
                    &request_mbap,
                    original_fc,
                    exception_code_for_error(&e),
                );
                let _ = stream.write_all(&exception_frame).await;
                continue;
            }
        };

        // Log request in verbose mode
        if request_pdu.function_code.is_read() {
            let addr = request_pdu.start_address().map(|a| a.value()).unwrap_or(0);
            let qty = request_pdu.quantity().unwrap_or(0);
            tracing::info!(
                "[{}] REQ tid={} FC={} addr={} qty={}",
                peer_addr,
                request_mbap.transaction_id,
                request_pdu.function_code,
                addr,
                qty
            );
        } else {
            tracing::info!(
                "[{}] REQ tid={} FC={}",
                peer_addr,
                request_mbap.transaction_id,
                request_pdu.function_code
            );
        }

        // Process the request - returns raw PDU bytes
        let resp_bytes = process_request(&request_pdu, &datastore).await;

        // Log response in verbose mode
        tracing::debug!(
            "[{}] RES tid={} pdu={:02X?}",
            peer_addr,
            request_mbap.transaction_id,
            &resp_bytes
        );

        // Build response frame: MBAP header + PDU bytes
        let response_mbap = MbapHeader::new(
            request_mbap.transaction_id, // Echo transaction ID
            request_mbap.unit_id,        // Echo slave ID
            resp_bytes.len() as u16,
        );

        let mut response_frame = Vec::with_capacity(MbapHeader::LENGTH + resp_bytes.len());
        response_frame.extend_from_slice(&response_mbap.to_bytes());
        response_frame.extend_from_slice(&resp_bytes);

        // Send response
        if let Err(e) = stream.write_all(&response_frame).await {
            tracing::error!("Failed to send response to {}: {}", peer_addr, e);
            break;
        }
    }
}

// ============================================================================
// PDU Processing
// ============================================================================

/// Process a Modbus PDU request and return raw PDU response bytes.
///
/// Routes to the appropriate handler based on the function code.
/// Unsupported function codes receive an Illegal Function exception.
async fn process_request(pdu: &Pdu, datastore: &SharedDataStore) -> Vec<u8> {
    let ds = datastore.read().await;

    match pdu.function_code {
        FunctionCode::ReadCoils => handle_read_coils(pdu, &ds),
        FunctionCode::ReadHoldingRegisters => handle_read_holding_registers(pdu, &ds),
        // Unsupported function codes → Illegal Function exception
        _ => {
            tracing::debug!(
                "Unsupported function code: {} (0x{:02X})",
                pdu.function_code,
                pdu.function_code.code()
            );
            build_exception_bytes(pdu.function_code.code(), 0x01)
        }
    }
}

// ============================================================================
// FC 0x01: Read Coils
// ============================================================================

/// Handle Read Coils (FC 0x01) request.
///
/// Request PDU:  [0x01, addr_hi, addr_lo, qty_hi, qty_lo]
/// Response PDU: [0x01, byte_count, coil_data...]
fn handle_read_coils(pdu: &Pdu, ds: &DataStore) -> Vec<u8> {
    let start_addr = pdu.start_address().map(|a| a.value()).unwrap_or(0);
    let quantity = pdu.quantity().unwrap_or(0);

    tracing::debug!(
        "ReadCoils: start_addr={}, quantity={}",
        start_addr,
        quantity
    );

    // Validate quantity (Modbus protocol limit)
    if quantity == 0 || quantity > 2000 {
        return build_exception_bytes(0x01, 0x03); // Illegal Data Value
    }

    // Read from data store
    match ds.read_coils(start_addr, quantity) {
        Ok(coils) => {
            // Pack coils into bytes (8 coils per byte, LSB first)
            let byte_count = (quantity as usize).div_ceil(8);
            let mut coil_bytes = vec![0u8; byte_count];
            for (i, &coil) in coils.iter().enumerate() {
                if coil {
                    coil_bytes[i / 8] |= 1 << (i % 8);
                }
            }

            // Build response PDU bytes
            let mut data = Vec::with_capacity(1 + byte_count);
            data.push(0x01); // Function code: ReadCoils
            data.push(byte_count as u8);
            data.extend_from_slice(&coil_bytes);
            data
        }
        Err(_) => {
            build_exception_bytes(0x01, 0x02) // Illegal Data Address
        }
    }
}

// ============================================================================
// FC 0x03: Read Holding Registers
// ============================================================================

/// Handle Read Holding Registers (FC 0x03) request.
///
/// Request PDU:  [0x03, addr_hi, addr_lo, qty_hi, qty_lo]
/// Response PDU: [0x03, byte_count, register_data...]
fn handle_read_holding_registers(pdu: &Pdu, ds: &DataStore) -> Vec<u8> {
    let start_addr = pdu.start_address().map(|a| a.value()).unwrap_or(0);
    let quantity = pdu.quantity().unwrap_or(0);

    tracing::debug!(
        "ReadHoldingRegisters: start_addr={}, quantity={}",
        start_addr,
        quantity
    );

    // Validate quantity (Modbus protocol limit)
    if quantity == 0 || quantity > 125 {
        return build_exception_bytes(0x03, 0x03); // Illegal Data Value
    }

    // Read from data store
    match ds.read_holding_registers(start_addr, quantity) {
        Ok(registers) => {
            let byte_count = (quantity * 2) as usize;
            let mut data = Vec::with_capacity(1 + byte_count);
            data.push(0x03); // Function code: ReadHoldingRegisters
            data.push(byte_count as u8);

            // Each register is encoded as 2 bytes, big-endian
            for &reg in &registers {
                data.extend_from_slice(&reg.to_be_bytes());
            }
            data
        }
        Err(_) => {
            build_exception_bytes(0x03, 0x02) // Illegal Data Address
        }
    }
}

// ============================================================================
// Exception Response Helpers
// ============================================================================

/// Build raw Modbus exception response PDU bytes.
///
/// # Arguments
/// * `function_code` - The original function code byte (e.g., 0x01, 0x03)
/// * `exception_code` - Modbus exception code (1-8)
///
/// # Returns
/// * `Vec<u8>`: [function_code | 0x80, exception_code]
fn build_exception_bytes(function_code: u8, exception_code: u8) -> Vec<u8> {
    vec![function_code | 0x80, exception_code]
}

/// Map a ModbusError to an appropriate Modbus exception code.
fn exception_code_for_error(error: &ModbusError) -> u8 {
    match error {
        ModbusError::InvalidFunctionCode(_) => 0x01, // Illegal Function
        ModbusError::IllegalDataAddress => 0x02,     // Illegal Data Address
        ModbusError::IllegalDataValue => 0x03,       // Illegal Data Value
        ModbusError::IncompleteFrame => 0x04,        // Server Device Failure
        _ => 0x04,                                   // Server Device Failure
    }
}

/// Build a complete Modbus exception response frame (MBAP + error PDU).
///
/// # Arguments
/// * `mbap` - The MBAP header from the original request
/// * `original_fc` - The original function code byte
/// * `exception_code` - Modbus exception code
fn build_mbap_exception_response(
    mbap: &MbapHeader,
    original_fc: u8,
    exception_code: u8,
) -> Vec<u8> {
    let error_fc = original_fc | 0x80;
    let error_pdu = vec![error_fc, exception_code];

    let response_mbap = MbapHeader::new(mbap.transaction_id, mbap.unit_id, error_pdu.len() as u16);
    let mut frame = Vec::with_capacity(MbapHeader::LENGTH + error_pdu.len());
    frame.extend_from_slice(&response_mbap.to_bytes());
    frame.extend_from_slice(&error_pdu);
    frame
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    use kayak_backend::drivers::modbus::ModbusAddress;

    // ========== DataStore Tests ==========

    #[test]
    fn test_datastore_new() {
        let ds = DataStore::new(64, 64);
        assert_eq!(ds.coil_count(), 64);
        assert_eq!(ds.register_count(), 64);
        assert_eq!(ds.coils.len(), 64);
        assert_eq!(ds.holding_registers.len(), 64);
    }

    #[test]
    fn test_datastore_default_values() {
        let ds = DataStore::new(10, 10);
        // All coils should be false by default
        assert_eq!(ds.read_coils(0, 10).unwrap(), vec![false; 10]);
        // All registers should be 0 by default
        assert_eq!(ds.read_holding_registers(0, 10).unwrap(), vec![0u16; 10]);
    }

    #[test]
    fn test_datastore_init_coils() {
        let mut ds = DataStore::new(10, 10);
        ds.init_coils([(0, true), (3, true), (5, true)]);
        let coils = ds.read_coils(0, 10).unwrap();
        assert!(coils[0]);
        assert!(!coils[1]);
        assert!(!coils[2]);
        assert!(coils[3]);
        assert!(!coils[4]);
        assert!(coils[5]);
        assert!(!coils[6]);
        assert!(!coils[7]);
        assert!(!coils[8]);
        assert!(!coils[9]);
    }

    #[test]
    fn test_datastore_init_registers() {
        let mut ds = DataStore::new(10, 10);
        ds.init_registers([(0, 100), (5, 5678)]);
        let regs = ds.read_holding_registers(0, 10).unwrap();
        assert_eq!(regs[0], 100);
        assert_eq!(regs[1], 0);
        assert_eq!(regs[5], 5678);
    }

    #[test]
    fn test_datastore_read_coils_out_of_bounds() {
        let ds = DataStore::new(10, 10);
        // Start address out of bounds
        assert!(ds.read_coils(10, 1).is_err());
        // Start + quantity out of bounds
        assert!(ds.read_coils(5, 6).is_err());
        // Valid range
        assert!(ds.read_coils(0, 10).is_ok());
        assert!(ds.read_coils(9, 1).is_ok());
    }

    #[test]
    fn test_datastore_read_registers_out_of_bounds() {
        let ds = DataStore::new(10, 10);
        assert!(ds.read_holding_registers(10, 1).is_err());
        assert!(ds.read_holding_registers(5, 6).is_err());
        assert!(ds.read_holding_registers(0, 10).is_ok());
        assert!(ds.read_holding_registers(9, 1).is_ok());
    }

    #[test]
    fn test_datastore_init_out_of_range_ignored() {
        let mut ds = DataStore::new(5, 5);
        // Init values outside the allocated range should be silently ignored
        ds.init_coils([(10, true), (100, true)]);
        ds.init_registers([(10, 999), (100, 999)]);
        // All values should still be defaults
        assert_eq!(ds.read_coils(0, 5).unwrap(), vec![false; 5]);
        assert_eq!(ds.read_holding_registers(0, 5).unwrap(), vec![0u16; 5]);
    }

    // ========== Read Coils Handler Tests (RFC response format) ==========

    #[test]
    fn test_handle_read_coils_all_false() {
        let ds = DataStore::new(8, 8);
        let pdu = Pdu::read_coils(ModbusAddress::new(0), 8).unwrap();
        let response = handle_read_coils(&pdu, &ds);
        // Normal response: [0x01, byte_count=1, data=0x00]
        assert!(response[0] & 0x80 == 0); // not an error response
        assert_eq!(response[0], 0x01); // function code
        assert_eq!(response[1], 1); // byte_count = ceil(8/8) = 1
        assert_eq!(response[2], 0x00); // all coils false
    }

    #[test]
    fn test_handle_read_coils_some_true() {
        let mut ds = DataStore::new(8, 8);
        ds.init_coils([(0, true), (2, true), (5, true)]);

        let pdu = Pdu::read_coils(ModbusAddress::new(0), 8).unwrap();
        let response = handle_read_coils(&pdu, &ds);
        assert!(response[0] & 0x80 == 0); // not an error response
                                          // Bit pattern: coil0=true (LSB), coil1=false, coil2=true, coil3=false,
                                          //              coil4=false, coil5=true, coil6=false, coil7=false
                                          // => 0b00100101 = 0x25
        assert_eq!(response[1], 1); // byte_count
        assert_eq!(response[2], 0x25);
    }

    #[test]
    fn test_handle_read_coils_start_address() {
        let mut ds = DataStore::new(16, 8);
        ds.init_coils([(8, true), (10, true)]);

        let pdu = Pdu::read_coils(ModbusAddress::new(8), 4).unwrap();
        let response = handle_read_coils(&pdu, &ds);
        assert!(response[0] & 0x80 == 0); // not an error response
                                          // coil8=true, coil9=false, coil10=true, coil11=false => 0b0101 = 0x05
        assert_eq!(response[1], 1); // byte_count
        assert_eq!(response[2], 0x05);
    }

    #[test]
    fn test_handle_read_coils_exception_illegal_data_address() {
        let ds = DataStore::new(8, 8);
        // Request beyond data store bounds
        let pdu = Pdu::read_coils(ModbusAddress::new(8), 1).unwrap();
        let response = handle_read_coils(&pdu, &ds);
        // Error response: [0x81, 0x02]
        assert!(response[0] & 0x80 != 0); // error response
        assert_eq!(response[0], 0x81); // FC01 + 0x80
        assert_eq!(response[1], 0x02); // Illegal Data Address
    }

    #[test]
    fn test_handle_read_coils_exception_illegal_data_value() {
        let ds = DataStore::new(8, 8);
        // Quantity exceeds Modbus protocol limit (> 2000)
        let pdu = Pdu::new(FunctionCode::ReadCoils, vec![0x00, 0x00, 0x07, 0xD1]).unwrap(); // qty=2001
        let response = handle_read_coils(&pdu, &ds);
        // Error response: [0x81, 0x03]
        assert!(response[0] & 0x80 != 0); // error response
        assert_eq!(response[0], 0x81); // FC01 + 0x80
        assert_eq!(response[1], 0x03); // Illegal Data Value
    }

    // ========== Read Holding Registers Handler Tests ==========

    #[test]
    fn test_handle_read_holding_registers_all_zero() {
        let ds = DataStore::new(8, 8);
        let pdu = Pdu::read_holding_registers(ModbusAddress::new(0), 1).unwrap();
        let response = handle_read_holding_registers(&pdu, &ds);
        // Normal response: [0x03, byte_count=2, data=0x00, 0x00]
        assert!(response[0] & 0x80 == 0); // not an error response
        assert_eq!(response[0], 0x03); // function code
        assert_eq!(response[1], 2); // byte_count = 2
        assert_eq!(&response[2..4], [0x00, 0x00]); // register value = 0
    }

    #[test]
    fn test_handle_read_holding_registers_values() {
        let mut ds = DataStore::new(10, 10);
        ds.init_registers([(0, 0x1234), (1, 0x5678)]);

        let pdu = Pdu::read_holding_registers(ModbusAddress::new(0), 2).unwrap();
        let response = handle_read_holding_registers(&pdu, &ds);
        assert!(response[0] & 0x80 == 0); // not an error response
        assert_eq!(response[0], 0x03); // function code = ReadHoldingRegisters
        assert_eq!(response[1], 4); // byte_count = 4
        assert_eq!(&response[2..4], [0x12, 0x34]); // register 0 = 0x1234
        assert_eq!(&response[4..6], [0x56, 0x78]); // register 1 = 0x5678
    }

    #[test]
    fn test_handle_read_holding_registers_multiple() {
        let mut ds = DataStore::new(10, 10);
        ds.init_registers([(0, 100), (1, 200), (2, 300), (3, 400), (4, 500)]);

        let pdu = Pdu::read_holding_registers(ModbusAddress::new(0), 5).unwrap();
        let response = handle_read_holding_registers(&pdu, &ds);
        assert!(response[0] & 0x80 == 0); // not an error response
        assert_eq!(response[1], 10); // byte_count = 10
                                     // Parse back the register values (big-endian)
        for i in 0..5 {
            let offset = 2 + i * 2;
            let val = u16::from_be_bytes([response[offset], response[offset + 1]]);
            assert_eq!(val, ((i + 1) * 100) as u16);
        }
    }

    #[test]
    fn test_handle_read_holding_registers_exception_illegal_data_address() {
        let ds = DataStore::new(10, 10);
        let pdu = Pdu::read_holding_registers(ModbusAddress::new(10), 1).unwrap();
        let response = handle_read_holding_registers(&pdu, &ds);
        // Error response: [0x83, 0x02]
        assert!(response[0] & 0x80 != 0); // error response
        assert_eq!(response[0], 0x83); // FC03 + 0x80
        assert_eq!(response[1], 0x02); // Illegal Data Address
    }

    #[test]
    fn test_handle_read_holding_registers_exception_illegal_data_value() {
        let ds = DataStore::new(10, 10);
        // Quantity exceeds Modbus protocol limit (> 125)
        let pdu = Pdu::new(
            FunctionCode::ReadHoldingRegisters,
            vec![0x00, 0x00, 0x00, 126u8],
        )
        .unwrap();
        let response = handle_read_holding_registers(&pdu, &ds);
        // Error response: [0x83, 0x03]
        assert!(response[0] & 0x80 != 0); // error response
        assert_eq!(response[0], 0x83); // FC03 + 0x80
        assert_eq!(response[1], 0x03); // Illegal Data Value
    }

    // ========== PDU Processing (process_request) Tests ==========

    #[test]
    fn test_process_request_read_coils() {
        let mut ds = DataStore::new(8, 8);
        ds.init_coils([(0, true)]);
        let shared = Arc::new(RwLock::new(ds));

        let pdu = Pdu::read_coils(ModbusAddress::new(0), 1).unwrap();
        let rt = tokio::runtime::Runtime::new().unwrap();
        let response = rt.block_on(process_request(&pdu, &shared));

        assert!(response[0] & 0x80 == 0); // not an error response
        assert_eq!(response[0], 0x01); // ReadCoils
    }

    #[test]
    fn test_process_request_read_holding_registers() {
        let mut ds = DataStore::new(8, 8);
        ds.init_registers([(0, 100)]);
        let shared = Arc::new(RwLock::new(ds));

        let pdu = Pdu::read_holding_registers(ModbusAddress::new(0), 1).unwrap();
        let rt = tokio::runtime::Runtime::new().unwrap();
        let response = rt.block_on(process_request(&pdu, &shared));

        assert!(response[0] & 0x80 == 0); // not an error response
        assert_eq!(response[0], 0x03); // ReadHoldingRegisters
    }

    #[test]
    fn test_process_request_unsupported_fc() {
        let ds = DataStore::new(8, 8);
        let shared = Arc::new(RwLock::new(ds));

        // WriteSingleRegister (FC 0x06) is not supported
        let pdu = Pdu::write_single_register(ModbusAddress::new(0), 100).unwrap();
        let rt = tokio::runtime::Runtime::new().unwrap();
        let response = rt.block_on(process_request(&pdu, &shared));

        // Error response: [0x86, 0x01]
        assert!(response[0] & 0x80 != 0); // error response
        assert_eq!(response[0], 0x86); // FC06 + 0x80
        assert_eq!(response[1], 0x01); // Illegal Function
    }

    // ========== Exception Bytes Builder Tests ==========

    #[test]
    fn test_build_exception_bytes_illegal_function() {
        let bytes = build_exception_bytes(0x01, 0x01);
        assert_eq!(bytes[0], 0x81); // FC01 + 0x80
        assert_eq!(bytes[1], 0x01); // Illegal Function
    }

    #[test]
    fn test_build_exception_bytes_illegal_data_address() {
        let bytes = build_exception_bytes(0x03, 0x02);
        assert_eq!(bytes[0], 0x83); // FC03 + 0x80
        assert_eq!(bytes[1], 0x02); // Illegal Data Address
    }

    #[test]
    fn test_build_exception_bytes_illegal_data_value() {
        let bytes = build_exception_bytes(0x01, 0x03);
        assert_eq!(bytes[0], 0x81); // FC01 + 0x80
        assert_eq!(bytes[1], 0x03); // Illegal Data Value
    }

    #[test]
    fn test_build_exception_bytes_server_device_failure() {
        let bytes = build_exception_bytes(0x03, 0x04);
        assert_eq!(bytes[0], 0x83); // FC03 + 0x80
        assert_eq!(bytes[1], 0x04); // Server Device Failure
    }

    // ========== MBAP Exception Response Builder Tests ==========

    #[test]
    fn test_build_mbap_exception_response() {
        let mbap = MbapHeader::new(1, 1, 5);
        let frame = build_mbap_exception_response(&mbap, 0x03, 0x02);

        // Frame = MBAP(7) + error PDU(2)
        assert_eq!(frame.len(), 9);

        // Parse MBAP header from frame
        let parsed_mbap = MbapHeader::parse(&frame[..7]).unwrap();
        assert_eq!(parsed_mbap.transaction_id, 1);
        assert_eq!(parsed_mbap.unit_id, 1);
        assert_eq!(parsed_mbap.pdu_length(), 2); // 2-byte error PDU

        // Error PDU: 0x83, 0x02
        assert_eq!(frame[7], 0x83); // FC 0x03 + 0x80
        assert_eq!(frame[8], 0x02); // Illegal Data Address
    }

    // ========== Exception Code Mapping Tests ==========

    #[test]
    fn test_exception_code_for_error_illegal_function() {
        assert_eq!(
            exception_code_for_error(&ModbusError::InvalidFunctionCode(0xFF)),
            0x01
        );
    }

    #[test]
    fn test_exception_code_for_error_illegal_data_address() {
        assert_eq!(
            exception_code_for_error(&ModbusError::IllegalDataAddress),
            0x02
        );
    }

    #[test]
    fn test_exception_code_for_error_illegal_data_value() {
        assert_eq!(
            exception_code_for_error(&ModbusError::IllegalDataValue),
            0x03
        );
    }

    #[test]
    fn test_exception_code_for_error_incomplete_frame() {
        assert_eq!(
            exception_code_for_error(&ModbusError::IncompleteFrame),
            0x04
        );
    }

    #[test]
    fn test_exception_code_for_error_unknown() {
        assert_eq!(
            exception_code_for_error(&ModbusError::Unknown("test".into())),
            0x04
        );
    }
}
