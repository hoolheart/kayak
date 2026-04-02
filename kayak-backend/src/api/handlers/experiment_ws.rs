//! Experiment WebSocket Handler
//!
//! Handles WebSocket connections for real-time experiment status updates.

use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        Path, State,
    },
    response::Response,
};
use futures_util::{SinkExt, StreamExt};
use std::sync::Arc;
use tokio::time::{interval, Duration};
use uuid::Uuid;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::services::experiment_control::ws_manager::{ExperimentWsManager, WsMessage};

/// Application state for WebSocket handlers
#[derive(Clone)]
pub struct AppState {
    pub ws_manager: Arc<ExperimentWsManager>,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            ws_manager: Arc::new(ExperimentWsManager::new()),
        }
    }

    pub fn with_ws_manager(ws_manager: Arc<ExperimentWsManager>) -> Self {
        Self { ws_manager }
    }
}

impl Default for AppState {
    fn default() -> Self {
        Self::new()
    }
}

/// WebSocket handler for experiment status subscriptions
/// 
/// Path: /ws/experiments/{id}
/// 
/// Authentication: JWT token via Authorization header
/// 
/// Heartbeat: 
/// - Server sends ping every 30 seconds
/// - 60 seconds without activity = disconnected
pub async fn ws_handler(
    State(state): State<AppState>,
    Path(experiment_id): Path<Uuid>,
    RequireAuth(user_ctx): RequireAuth,
    ws: WebSocketUpgrade,
) -> Response {
    tracing::info!(
        "WebSocket connection request: experiment_id={}, user_id={}",
        experiment_id,
        user_ctx.user_id
    );

    ws.on_upgrade(move |socket| handle_socket(socket, state, experiment_id, user_ctx.user_id))
}

/// Handle the WebSocket connection
async fn handle_socket(
    socket: WebSocket,
    state: AppState,
    experiment_id: Uuid,
    user_id: Uuid,
) {
    let (mut sender, mut receiver) = socket.split();

    // Subscribe to experiment status updates
    let mut rx = match state.ws_manager.subscribe(experiment_id, user_id).await {
        Ok(recv) => recv,
        Err(e) => {
            tracing::error!("Failed to subscribe to experiment {}: {}", experiment_id, e);
            return;
        }
    };

    tracing::info!(
        "User {} subscribed to experiment {} via WebSocket",
        user_id,
        experiment_id
    );

    // Create a heartbeat interval
    let mut heartbeat_interval = interval(Duration::from_secs(30));
    let mut last_activity = std::time::Instant::now();

    // Send welcome message
    let welcome = WsMessage::StatusChange {
        experiment_id,
        old_status: "".to_string(),
        new_status: "CONNECTED".to_string(),
        operation: "connect".to_string(),
        user_id,
        timestamp: chrono::Utc::now().to_rfc3339(),
    };
    if sender
        .send(Message::Text(serde_json::to_string(&welcome).unwrap()))
        .await
        .is_err()
    {
        tracing::warn!("Failed to send welcome message");
        return;
    }

    loop {
        tokio::select! {
            // Handle messages from the experiment broadcast channel
            msg = rx.recv() => {
                match msg {
                    Ok(ws_msg) => {
                        last_activity = std::time::Instant::now();
                        let json = match serde_json::to_string(&ws_msg) {
                            Ok(j) => j,
                            Err(e) => {
                                tracing::error!("Failed to serialize message: {}", e);
                                continue;
                            }
                        };
                        if sender.send(Message::Text(json)).await.is_err() {
                            tracing::warn!("Failed to send message to client");
                            break;
                        }
                    }
                    Err(_) => {
                        tracing::info!("WebSocket receiver dropped for experiment {}", experiment_id);
                        break;
                    }
                }
            }

            // Handle heartbeat
            _ = heartbeat_interval.tick() => {
                // Check if we've exceeded the timeout (60 seconds without activity)
                if last_activity.elapsed() > Duration::from_secs(60) {
                    tracing::info!(
                        "WebSocket connection timed out for experiment {}, user {}",
                        experiment_id,
                        user_id
                    );
                    break;
                }

                // Send a ping frame at the WebSocket protocol level
                if sender.send(Message::Ping(vec![])).await.is_err() {
                    break;
                }
            }

            // Handle incoming messages from client (pong responses, etc.)
            incoming = receiver.next() => {
                match incoming {
                    Some(Ok(Message::Pong(_))) => {
                        last_activity = std::time::Instant::now();
                    }
                    Some(Ok(Message::Close(_))) => {
                        tracing::info!("Client closed WebSocket for experiment {}", experiment_id);
                        break;
                    }
                    Some(Err(_)) => {
                        tracing::info!("WebSocket error for experiment {}", experiment_id);
                        break;
                    }
                    None => {
                        tracing::info!("WebSocket stream ended for experiment {}", experiment_id);
                        break;
                    }
                    _ => {
                        // Ignore other message types
                    }
                }
            }
        }
    }

    // Cleanup: unsubscribe
    if let Err(e) = state.ws_manager.unsubscribe(experiment_id, user_id).await {
        tracing::error!("Failed to unsubscribe: {}", e);
    }

    tracing::info!(
        "WebSocket connection closed for experiment {}, user {}",
        experiment_id,
        user_id
    );
}
