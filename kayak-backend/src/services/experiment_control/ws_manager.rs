//! WebSocket Manager for Experiment Status Subscriptions
//!
//! Manages WebSocket connections and broadcasts status changes to subscribed clients.

use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};
use uuid::Uuid;

/// Message types sent to WebSocket clients
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "data")]
pub enum WsMessage {
    /// Status change event
    #[serde(rename = "status_change")]
    StatusChange {
        experiment_id: Uuid,
        old_status: String,
        new_status: String,
        operation: String,
        user_id: Uuid,
        timestamp: String,
    },
    /// Error event
    #[serde(rename = "error")]
    Error {
        experiment_id: Uuid,
        error: String,
        code: u16,
    },
}

/// Internal broadcast message format
#[derive(Debug, Clone)]
pub enum BroadcastMessage {
    StatusChange {
        experiment_id: Uuid,
        old_status: String,
        new_status: String,
        operation: String,
        user_id: Uuid,
        timestamp: String,
    },
    Error {
        experiment_id: Uuid,
        error: String,
        code: u16,
    },
}

impl From<BroadcastMessage> for WsMessage {
    fn from(msg: BroadcastMessage) -> Self {
        match msg {
            BroadcastMessage::StatusChange {
                experiment_id,
                old_status,
                new_status,
                operation,
                user_id,
                timestamp,
            } => WsMessage::StatusChange {
                experiment_id,
                old_status,
                new_status,
                operation,
                user_id,
                timestamp,
            },
            BroadcastMessage::Error {
                experiment_id,
                error,
                code,
            } => WsMessage::Error {
                experiment_id,
                error,
                code,
            },
        }
    }
}

/// Sender handle for a subscribed connection
#[derive(Debug, Clone)]
pub struct ConnectionSender {
    experiment_id: Uuid,
    user_id: Uuid,
    sender: broadcast::Sender<WsMessage>,
}

impl ConnectionSender {
    /// Send a message to this connection
    pub async fn send(&self, msg: WsMessage) -> Result<usize, broadcast::error::SendError<WsMessage>> {
        self.sender.send(msg)
    }
}

/// WebSocket manager for experiment subscriptions
#[derive(Debug)]
pub struct ExperimentWsManager {
    /// Map of experiment_id -> list of subscribers
    subscriptions: Arc<RwLock<HashMap<Uuid, Vec<ConnectionSender>>>>,
}

impl ExperimentWsManager {
    /// Create a new WebSocket manager
    pub fn new() -> Self {
        Self {
            subscriptions: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Subscribe a user to an experiment's status updates
    /// Returns a receiver that will receive status change messages
    pub async fn subscribe(
        &self,
        experiment_id: Uuid,
        user_id: Uuid,
    ) -> Result<broadcast::Receiver<WsMessage>, SubscribeError> {
        let (sender, receiver) = broadcast::channel(100);

        let connection = ConnectionSender {
            experiment_id,
            user_id,
            sender: sender.clone(),
        };

        let mut subscriptions = self.subscriptions.write().await;
        subscriptions
            .entry(experiment_id)
            .or_default()
            .push(connection);

        Ok(receiver)
    }

    /// Unsubscribe a user from an experiment
    pub async fn unsubscribe(&self, experiment_id: Uuid, user_id: Uuid) -> Result<(), UnsubscribeError> {
        let mut subscriptions = self.subscriptions.write().await;
        if let Some(connections) = subscriptions.get_mut(&experiment_id) {
            connections.retain(|c| c.user_id != user_id);
            if connections.is_empty() {
                subscriptions.remove(&experiment_id);
            }
        }
        Ok(())
    }

    /// Broadcast a message to all subscribers of an experiment
    pub async fn broadcast(&self, experiment_id: Uuid, msg: BroadcastMessage) -> Result<(), BroadcastError> {
        let subscriptions = self.subscriptions.read().await;
        let Some(connections) = subscriptions.get(&experiment_id) else {
            return Err(BroadcastError::NoSubscribers(experiment_id));
        };

        let ws_msg: WsMessage = msg.into();

        for connection in connections {
            // We don't care if individual sends fail (client might be disconnected)
            let _ = connection.sender.send(ws_msg.clone());
        }

        Ok(())
    }

    /// Get the number of subscribers for an experiment
    pub fn get_subscriber_count(&self, experiment_id: Uuid) -> usize {
        // This is a sync method, so we use try_read
        // For exact count we accept possible race condition in production
        self.subscriptions
            .try_read()
            .map(|subs| subs.get(&experiment_id).map(|c| c.len()).unwrap_or(0))
            .unwrap_or(0)
    }
}

impl Default for ExperimentWsManager {
    fn default() -> Self {
        Self::new()
    }
}

/// Errors for subscribe operation
#[derive(Debug, thiserror::Error)]
pub enum SubscribeError {
    #[error("Failed to create broadcast channel")]
    ChannelError,
}

/// Errors for unsubscribe operation
#[derive(Debug, thiserror::Error)]
pub enum UnsubscribeError {
    #[error("Failed to unsubscribe")]
    UnsubscribeFailed,
}

/// Errors for broadcast operation
#[derive(Debug, thiserror::Error)]
pub enum BroadcastError {
    #[error("No subscribers for experiment {0}")]
    NoSubscribers(Uuid),
    #[error("Broadcast failed")]
    BroadcastFailed,
}

/// Helper to broadcast a status change
pub fn broadcast_status_change(
    manager: Arc<ExperimentWsManager>,
    experiment_id: Uuid,
    old_status: &str,
    new_status: &str,
    operation: &str,
    user_id: Uuid,
) {
    let msg = BroadcastMessage::StatusChange {
        experiment_id,
        old_status: old_status.to_string(),
        new_status: new_status.to_string(),
        operation: operation.to_string(),
        user_id,
        timestamp: Utc::now().to_rfc3339(),
    };

    // Fire and forget - don't block on broadcast errors
    tokio::spawn(async move {
        if let Err(e) = manager.broadcast(experiment_id, msg).await {
            tracing::warn!("Failed to broadcast status change: {}", e);
        }
    });
}

/// Helper to broadcast an error
pub fn broadcast_error(
    manager: Arc<ExperimentWsManager>,
    experiment_id: Uuid,
    error: &str,
    code: u16,
) {
    let msg = BroadcastMessage::Error {
        experiment_id,
        error: error.to_string(),
        code,
    };

    // Fire and forget - don't block on broadcast errors
    tokio::spawn(async move {
        if let Err(e) = manager.broadcast(experiment_id, msg).await {
            tracing::warn!("Failed to broadcast error: {}", e);
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper to create a WebSocket manager for testing
    fn create_test_manager() -> ExperimentWsManager {
        ExperimentWsManager::new()
    }

    #[tokio::test]
    async fn test_ws_manager_subscribe_new_experiment() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();

        // Subscribe to experiment
        let result = manager.subscribe(experiment_id, user_id).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_ws_manager_subscribe_multiple_users_same_experiment() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();
        let user_id_1 = Uuid::new_v4();
        let user_id_2 = Uuid::new_v4();

        // Both users subscribe to same experiment
        let result1 = manager.subscribe(experiment_id, user_id_1).await;
        let result2 = manager.subscribe(experiment_id, user_id_2).await;

        assert!(result1.is_ok());
        assert!(result2.is_ok());

        // Should have 2 subscribers
        let count = manager.get_subscriber_count(experiment_id);
        assert_eq!(count, 2);
    }

    #[tokio::test]
    async fn test_ws_manager_subscribe_same_user_different_experiments() {
        let manager = create_test_manager();
        let experiment_id_1 = Uuid::new_v4();
        let experiment_id_2 = Uuid::new_v4();
        let user_id = Uuid::new_v4();

        // Same user subscribes to different experiments
        let result1 = manager.subscribe(experiment_id_1, user_id).await;
        let result2 = manager.subscribe(experiment_id_2, user_id).await;

        assert!(result1.is_ok());
        assert!(result2.is_ok());

        // Each experiment should have 1 subscriber
        assert_eq!(manager.get_subscriber_count(experiment_id_1), 1);
        assert_eq!(manager.get_subscriber_count(experiment_id_2), 1);
    }

    #[tokio::test]
    async fn test_ws_manager_unsubscribe() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();

        // Subscribe
        manager.subscribe(experiment_id, user_id).await.unwrap();
        assert_eq!(manager.get_subscriber_count(experiment_id), 1);

        // Unsubscribe
        let result = manager.unsubscribe(experiment_id, user_id).await;
        assert!(result.is_ok());
        assert_eq!(manager.get_subscriber_count(experiment_id), 0);
    }

    #[tokio::test]
    async fn test_ws_manager_unsubscribe_nonexistent() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();

        // Unsubscribe non-existent subscription should not error
        let result = manager.unsubscribe(experiment_id, user_id).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_ws_manager_broadcast_status_change() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();

        // Subscribe
        let mut receiver = manager.subscribe(experiment_id, user_id).await.unwrap();

        // Broadcast status change
        let broadcast_msg = BroadcastMessage::StatusChange {
            experiment_id,
            old_status: "RUNNING".to_string(),
            new_status: "PAUSED".to_string(),
            operation: "pause".to_string(),
            user_id,
            timestamp: "2024-01-01T00:00:00Z".to_string(),
        };

        let result = manager.broadcast(experiment_id, broadcast_msg.clone()).await;
        assert!(result.is_ok());

        // Verify message received
        let received = receiver.recv().await.unwrap();
        match received {
            WsMessage::StatusChange { experiment_id: exp_id, .. } => {
                assert_eq!(exp_id, experiment_id);
            }
            _ => panic!("Expected StatusChange message"),
        }
    }

    #[tokio::test]
    async fn test_ws_manager_broadcast_error() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();

        // Subscribe
        let mut receiver = manager.subscribe(experiment_id, user_id).await.unwrap();

        // Broadcast error
        let broadcast_msg = BroadcastMessage::Error {
            experiment_id,
            error: "Invalid transition".to_string(),
            code: 400,
        };

        let result = manager.broadcast(experiment_id, broadcast_msg.clone()).await;
        assert!(result.is_ok());

        // Verify message received
        let received = receiver.recv().await.unwrap();
        match received {
            WsMessage::Error { experiment_id: exp_id, code, .. } => {
                assert_eq!(exp_id, experiment_id);
                assert_eq!(code, 400);
            }
            _ => panic!("Expected Error message"),
        }
    }

    #[tokio::test]
    async fn test_ws_manager_broadcast_nonexistent_experiment() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();

        // Broadcast to non-subscribed experiment should return error
        let broadcast_msg = BroadcastMessage::StatusChange {
            experiment_id,
            old_status: "RUNNING".to_string(),
            new_status: "PAUSED".to_string(),
            operation: "pause".to_string(),
            user_id: Uuid::new_v4(),
            timestamp: "2024-01-01T00:00:00Z".to_string(),
        };

        let result = manager.broadcast(experiment_id, broadcast_msg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_ws_manager_multiple_subscribers_broadcast() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();
        let user_id_1 = Uuid::new_v4();
        let user_id_2 = Uuid::new_v4();

        // Two users subscribe
        let mut receiver1 = manager.subscribe(experiment_id, user_id_1).await.unwrap();
        let mut receiver2 = manager.subscribe(experiment_id, user_id_2).await.unwrap();

        // Broadcast
        let broadcast_msg = BroadcastMessage::StatusChange {
            experiment_id,
            old_status: "LOADED".to_string(),
            new_status: "RUNNING".to_string(),
            operation: "start".to_string(),
            user_id: user_id_1,
            timestamp: "2024-01-01T00:00:00Z".to_string(),
        };

        let result = manager.broadcast(experiment_id, broadcast_msg).await;
        assert!(result.is_ok());

        // Both receivers should get the message
        let received1 = receiver1.recv().await.unwrap();
        let received2 = receiver2.recv().await.unwrap();

        match (&received1, &received2) {
            (WsMessage::StatusChange { .. }, WsMessage::StatusChange { .. }) => {}
            _ => panic!("Expected StatusChange messages"),
        }
    }

    #[tokio::test]
    async fn test_ws_manager_get_subscriber_count_nonexistent() {
        let manager = create_test_manager();
        let experiment_id = Uuid::new_v4();

        // No subscribers for non-existent experiment
        let count = manager.get_subscriber_count(experiment_id);
        assert_eq!(count, 0);
    }

    #[tokio::test]
    async fn test_ws_message_serialization_status_change() {
        let msg = WsMessage::StatusChange {
            experiment_id: Uuid::new_v4(),
            old_status: "RUNNING".to_string(),
            new_status: "PAUSED".to_string(),
            operation: "pause".to_string(),
            user_id: Uuid::new_v4(),
            timestamp: "2024-01-01T00:00:00Z".to_string(),
        };

        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("\"type\":\"status_change\""));
        assert!(json.contains("\"old_status\":\"RUNNING\""));
        assert!(json.contains("\"new_status\":\"PAUSED\""));
    }

    #[tokio::test]
    async fn test_ws_message_serialization_error() {
        let msg = WsMessage::Error {
            experiment_id: Uuid::new_v4(),
            error: "Invalid transition".to_string(),
            code: 400,
        };

        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("\"type\":\"error\""));
        assert!(json.contains("\"code\":400"));
        assert!(json.contains("Invalid transition"));
    }
}
