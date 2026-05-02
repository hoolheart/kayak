use serde::{Deserialize, Serialize};

/// Modbus TCP MBAP (Modbus Application Protocol) 头部
///
/// MBAP 头部共 7 字节，包含：
/// - Transaction ID (2 bytes): 事务标识符，用于匹配请求和响应
/// - Protocol ID (2 bytes): 协议标识符，Modbus TCP 固定为 0
/// - Length (2 bytes): 后续字节长度，包括 Unit ID 和 PDU
/// - Unit ID (1 byte): 从站标识符
///
/// ```text
/// +-------+-------+-------+-------+-------+-------+-------+
/// | TID   | TID   |  PID  |  PID  | Length | Length| UID   |
/// |  High |  Low  |  High |  Low  |  High |  Low  |       |
/// +-------+-------+-------+-------+-------+-------+-------+
///   0     1       2       3       4       5       6
/// ```
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct MbapHeader {
    /// 事务标识符 (Transaction Identifier)
    pub transaction_id: u16,
    /// 协议标识符 (Protocol Identifier)，固定为 0
    pub protocol_id: u16,
    /// 后续字节长度 (Length)，包括 Unit ID 和 PDU
    pub length: u16,
    /// 从站标识符 (Unit Identifier)
    pub unit_id: u8,
}

impl MbapHeader {
    /// MBAP 头部的固定长度
    pub const LENGTH: usize = 7;

    /// 协议标识符的固定值
    pub const MODBUS_PROTOCOL_ID: u16 = 0x0000;

    /// 创建新的 MBAP 头部
    ///
    /// # Arguments
    /// * `transaction_id` - 事务标识符
    /// * `unit_id` - 从站标识符
    /// * `pdu_length` - PDU 长度
    pub fn new(transaction_id: u16, unit_id: u8, pdu_length: u16) -> Self {
        Self {
            transaction_id,
            protocol_id: Self::MODBUS_PROTOCOL_ID,
            // Length = Unit ID (1) + PDU (pdu_length)
            length: 1 + pdu_length,
            unit_id,
        }
    }

    /// 从字节数组解析 MBAP 头部
    ///
    /// # Arguments
    /// * `data` - 至少 7 字节的数据
    ///
    /// # Returns
    /// * `Ok(MbapHeader)` - 解析成功
    /// * `Err(ModbusError::IncompleteFrame)` - 数据不足
    pub fn parse(data: &[u8]) -> Result<Self, super::error::ModbusError> {
        if data.len() < Self::LENGTH {
            return Err(super::error::ModbusError::IncompleteFrame);
        }

        let transaction_id = u16::from_be_bytes([data[0], data[1]]);
        let protocol_id = u16::from_be_bytes([data[2], data[3]]);
        let length = u16::from_be_bytes([data[4], data[5]]);
        let unit_id = data[6];

        // 验证协议标识符
        if protocol_id != Self::MODBUS_PROTOCOL_ID {
            return Err(super::error::ModbusError::MbapError(format!(
                "Invalid protocol ID: 0x{:04X}, expected 0x{:04X}",
                protocol_id,
                Self::MODBUS_PROTOCOL_ID
            )));
        }

        // 验证长度字段
        if length < 1 {
            return Err(super::error::ModbusError::MbapError(
                "Invalid length field: must be at least 1".into(),
            ));
        }

        Ok(Self {
            transaction_id,
            protocol_id,
            length,
            unit_id,
        })
    }

    /// 将 MBAP 头部序列化为字节数组
    ///
    /// # Returns
    /// * `[u8; 7]` - 7 字节的 MBAP 头部
    pub fn to_bytes(&self) -> [u8; Self::LENGTH] {
        let mut bytes = [0u8; Self::LENGTH];
        bytes[0..2].copy_from_slice(&self.transaction_id.to_be_bytes());
        bytes[2..4].copy_from_slice(&self.protocol_id.to_be_bytes());
        bytes[4..6].copy_from_slice(&self.length.to_be_bytes());
        bytes[6] = self.unit_id;
        bytes
    }

    /// 获取 PDU 长度（从 length 字段计算）
    ///
    /// length 字段包含 Unit ID (1) + PDU，所以 PDU 长度 = length - 1
    pub fn pdu_length(&self) -> u16 {
        self.length.saturating_sub(1)
    }

    /// 检查数据是否足够长以包含完整的 MBAP + PDU
    pub fn is_complete(&self, total_data_len: usize) -> bool {
        total_data_len >= Self::LENGTH + (self.length as usize)
    }
}

impl Default for MbapHeader {
    fn default() -> Self {
        Self {
            transaction_id: 0,
            protocol_id: Self::MODBUS_PROTOCOL_ID,
            length: 1, // 最小长度，仅 Unit ID
            unit_id: 0,
        }
    }
}

impl std::fmt::Display for MbapHeader {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "MBAP {{ tid: {}, proto: 0x{:04X}, len: {}, uid: {} }}",
            self.transaction_id, self.protocol_id, self.length, self.unit_id
        )
    }
}
