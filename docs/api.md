# Kayak API Documentation

**Version**: 0.2.0  
**Base URL**: `http://localhost:8080/api/v1`  
**Authentication**: Bearer Token (JWT)

---

## Table of Contents

1. [Authentication](#authentication)
2. [Users](#users)
3. [Workbenches](#workbenches)
4. [Devices](#devices)
5. [Device Connection](#device-connection)
6. [Points](#points)
7. [Experiments](#experiments)
8. [Modbus Simulator](#modbus-simulator)
9. [WebSocket](#websocket)

---

## Authentication

### Login

Authenticate user and obtain access token.

**Endpoint**: `POST /auth/login`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "Password123"
}
```

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "Bearer",
    "expires_in": 900,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "username"
    }
  }
}
```

### Register

Register a new user.

**Endpoint**: `POST /auth/register`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "Password123",
  "username": "username"
}
```

**Response** (201 Created):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "created_at": "2026-05-03T00:00:00Z"
  }
}
```

### Refresh Token

Refresh access token.

**Endpoint**: `POST /auth/refresh`

**Request**:
```json
{
  "refresh_token": "eyJ..."
}
```

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "Bearer",
    "expires_in": 900,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "username"
    }
  }
}
```

### Get Current User

Get authenticated user's information.

**Endpoint**: `GET /auth/me`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

---

## Users

### Get User Profile

**Endpoint**: `GET /users/me`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "avatar_url": null,
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

### Update User Profile

**Endpoint**: `PUT /users/me`

**Headers**: `Authorization: Bearer <access_token>`

**Request**:
```json
{
  "username": "newname",
  "avatar_url": "https://example.com/avatar.png"
}
```

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "newname",
    "avatar_url": "https://example.com/avatar.png",
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

### Change Password

**Endpoint**: `POST /users/me/password`

**Headers**: `Authorization: Bearer <access_token>`

**Request**:
```json
{
  "current_password": "OldPassword123",
  "new_password": "NewPassword456"
}
```

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "password updated",
  "data": null
}
```

---

## Workbenches

### List Workbenches

**Endpoint**: `GET /workbenches`

**Headers**: `Authorization: Bearer <access_token>`

**Query Parameters**:
- `page` (int, optional): Page number, default 1
- `size` (int, optional): Page size, default 20

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "uuid",
        "name": "Workbench 1",
        "description": "Description",
        "owner_id": "uuid",
        "owner_type": "user",
        "status": "active",
        "created_at": "2026-05-03T00:00:00Z",
        "updated_at": "2026-05-03T00:00:00Z"
      }
    ],
    "total": 10,
    "page": 1,
    "size": 20
  }
}
```

### Create Workbench

**Endpoint**: `POST /workbenches`

**Headers**: `Authorization: Bearer <access_token>`

**Request**:
```json
{
  "name": "New Workbench",
  "description": "Description"
}
```

**Response** (201 Created):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "name": "New Workbench",
    "description": "Description",
    "owner_id": "uuid",
    "owner_type": "user",
    "status": "active",
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

### Get Workbench

**Endpoint**: `GET /workbenches/{id}`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "name": "Workbench 1",
    "description": "Description",
    "owner_id": "uuid",
    "owner_type": "user",
    "status": "active",
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

### Update Workbench

**Endpoint**: `PUT /workbenches/{id}`

**Headers**: `Authorization: Bearer <access_token>`

**Request**:
```json
{
  "name": "Updated Name",
  "description": "Updated description"
}
```

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "name": "Updated Name",
    "description": "Updated description",
    "owner_id": "uuid",
    "owner_type": "user",
    "status": "active",
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

### Delete Workbench

**Endpoint**: `DELETE /workbenches/{id}`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (204 No Content)

---

## Devices

### List Devices

**Endpoint**: `GET /workbenches/{workbench_id}/devices`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "uuid",
      "workbench_id": "uuid",
      "parent_id": null,
      "name": "Device 1",
      "protocol_type": "modbus-tcp",
      "protocol_params": {
        "host": "192.168.1.100",
        "port": 502
      },
      "status": "online",
      "created_at": "2026-05-03T00:00:00Z",
      "updated_at": "2026-05-03T00:00:00Z"
    }
  ]
}
```

### Create Device

**Endpoint**: `POST /workbenches/{workbench_id}/devices`

**Headers**: `Authorization: Bearer <access_token>`

**Request** (Virtual device):
```json
{
  "name": "New Virtual Device",
  "protocol_type": "virtual",
  "protocol_params": {
    "type": "random",
    "min": 0,
    "max": 100
  }
}
```

**Request** (Modbus TCP device):
```json
{
  "name": "PLC Controller",
  "protocol_type": "modbus-tcp",
  "protocol_params": {
    "host": "192.168.1.100",
    "port": 502,
    "unit_id": 1
  }
}
```

**Request** (Modbus RTU device):
```json
{
  "name": "RTU Sensor",
  "protocol_type": "modbus-rtu",
  "protocol_params": {
    "port": "/dev/ttyUSB0",
    "baud_rate": 9600,
    "data_bits": 8,
    "stop_bits": 1,
    "parity": "none",
    "unit_id": 1
  }
}
```

**Response** (201 Created):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "workbench_id": "uuid",
    "parent_id": null,
    "name": "PLC Controller",
    "protocol_type": "modbus-tcp",
    "protocol_params": {
      "host": "192.168.1.100",
      "port": 502,
      "unit_id": 1
    },
    "status": "online",
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

**Supported `protocol_type` values:**
- `virtual` — Virtual/simulated device for testing
- `modbus-tcp` — Modbus TCP device
- `modbus-rtu` — Modbus RTU device (serial)

### Get Device

**Endpoint**: `GET /workbenches/{workbench_id}/devices/{device_id}`

**Headers**: `Authorization: Bearer <access_token>`

### Update Device

**Endpoint**: `PUT /workbenches/{workbench_id}/devices/{device_id}`

**Headers**: `Authorization: Bearer <access_token>`

### Delete Device

**Endpoint**: `DELETE /workbenches/{workbench_id}/devices/{device_id}`

**Headers**: `Authorization: Bearer <access_token>`

---

## Device Connection

### Connect

Establish a connection to the device.

**Endpoint**: `POST /devices/{device_id}/connect`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "Device connected successfully",
  "data": {
    "device_id": "uuid",
    "status": "connected",
    "connection_id": "conn-uuid"
  }
}
```

### Disconnect

Disconnect from the device and release connection resources.

**Endpoint**: `POST /devices/{device_id}/disconnect`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "Device disconnected",
  "data": null
}
```

### Connection Test

Test connectivity to a device without affecting its current state.

**Endpoint**: `POST /devices/{device_id}/test`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "device_id": "uuid",
    "reachable": true,
    "latency_ms": 12,
    "error": null
  }
}
```

**Response** (test failed, 200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "device_id": "uuid",
    "reachable": false,
    "latency_ms": null,
    "error": "Connection refused (os error 61)"
  }
}
```

---

## Points

### List Points

**Endpoint**: `GET /devices/{device_id}/points`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "uuid",
      "device_id": "uuid",
      "name": "Temperature",
      "channel": "temp_1",
      "register_type": "holding",
      "register_address": 100,
      "data_type": "number",
      "access_type": "ro",
      "initial_value": 0,
      "created_at": "2026-05-03T00:00:00Z"
    }
  ]
}
```

### Create Point

**Endpoint**: `POST /devices/{device_id}/points`

**Headers**: `Authorization: Bearer <access_token>`

**Request** (Virtual device point):
```json
{
  "name": "Temperature",
  "channel": "temp_1",
  "data_type": "number",
  "access_type": "ro"
}
```

**Request** (Modbus device point):
```json
{
  "name": "Temperature",
  "channel": "temp_1",
  "register_type": "holding",
  "register_address": 100,
  "data_type": "number",
  "access_type": "ro"
}
```

**Supported `register_type` values (Modbus only):**
- `coil` — Coil register (1-bit, read-write)
- `discrete` — Discrete input (1-bit, read-only)
- `holding` — Holding register (16-bit, read-write)
- `input` — Input register (16-bit, read-only)

**Response** (201 Created):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "device_id": "uuid",
    "name": "Temperature",
    "channel": "temp_1",
    "register_type": "holding",
    "register_address": 100,
    "data_type": "number",
    "access_type": "ro",
    "initial_value": 0,
    "created_at": "2026-05-03T00:00:00Z"
  }
}
```

### Read Point Value

Read the current real-time value of a point.

**Endpoint**: `GET /points/{id}/value`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "channel": "temp_1",
    "value": 25.5,
    "timestamp": "2026-05-03T00:00:00Z"
  }
}
```

---

## Experiments

### List Experiments

**Endpoint**: `GET /experiments`

**Headers**: `Authorization: Bearer <access_token>`

**Query Parameters**:
- `page` (int, optional): Page number, default 1
- `size` (int, optional): Page size, default 10
- `status` (string, optional): Filter by status (IDLE, RUNNING, PAUSED, COMPLETED, ABORTED)
- `started_after` (datetime, optional): Filter experiments started after this time
- `started_before` (datetime, optional): Filter experiments started before this time

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "uuid",
        "user_id": "uuid",
        "method_id": null,
        "name": "Experiment 1",
        "description": "Description",
        "status": "RUNNING",
        "started_at": "2026-05-03T00:00:00Z",
        "ended_at": null,
        "created_at": "2026-05-03T00:00:00Z",
        "updated_at": "2026-05-03T00:00:00Z"
      }
    ],
    "page": 1,
    "size": 10,
    "total": 5,
    "has_next": false,
    "has_prev": false
  }
}
```

### Get Experiment

**Endpoint**: `GET /experiments/{id}`

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "method_id": null,
    "name": "Experiment 1",
    "description": "Description",
    "status": "RUNNING",
    "started_at": "2026-05-03T00:00:00Z",
    "ended_at": null,
    "created_at": "2026-05-03T00:00:00Z",
    "updated_at": "2026-05-03T00:00:00Z"
  }
}
```

### Get Point History

**Endpoint**: `GET /experiments/{experiment_id}/points/{channel}/history`

**Headers**: `Authorization: Bearer <access_token>`

**Query Parameters**:
- `start_time` (datetime, optional): Start of time range
- `end_time` (datetime, optional): End of time range
- `limit` (int, optional): Maximum number of points to return, default 10000

**Response** (200 OK):
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "experiment_id": "uuid",
    "channel": "temp_1",
    "data": [
      {
        "timestamp": 1709251200000000000,
        "value": 25.5
      },
      {
        "timestamp": 1709251201000000000,
        "value": 25.6
      }
    ],
    "start_time": "2026-05-03T00:00:00Z",
    "end_time": "2026-05-03T00:01:00Z",
    "total_points": 2
  }
}
```

---

## Modbus Simulator

The Modbus TCP simulator provides a virtual Modbus device for development and testing.

### Running the Simulator

```bash
cd kayak-backend

# Default port 5020
cargo run --bin modbus-simulator

# Custom port
cargo run --bin modbus-simulator -- --port 5021
```

### Connecting to the Simulator

When creating a Modbus TCP device, use the simulator's host/port:

```json
{
  "protocol_type": "modbus-tcp",
  "protocol_params": {
    "host": "127.0.0.1",
    "port": 5020,
    "unit_id": 1
  }
}
```

---

## WebSocket

WebSocket endpoint for real-time data streaming.

**Endpoint**: `ws://localhost:8080/ws`

**Protocol**: The WebSocket connection uses JSON-formatted messages. Authentication is required.

### Message Format

**Server → Client** (data push):
```json
{
  "type": "point_value",
  "data": {
    "point_id": "uuid",
    "channel": "temp_1",
    "value": 25.5,
    "timestamp": "2026-05-03T00:00:00Z"
  }
}
```

**Server → Client** (experiment status):
```json
{
  "type": "experiment_status",
  "data": {
    "experiment_id": "uuid",
    "status": "RUNNING",
    "progress": 45
  }
}
```

---

## Error Responses

### Standard Error Format

```json
{
  "code": 400,
  "message": "validation error",
  "data": null
}
```

### Error Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 400 | Bad Request — Invalid request format |
| 401 | Unauthorized — Invalid or missing token |
| 403 | Forbidden — Access denied |
| 404 | Not Found — Resource not found |
| 409 | Conflict — Resource already exists |
| 422 | Unprocessable — Device connection error |
| 500 | Internal Server Error |

### Device-Specific Error Responses

**Connection Failed** (422):
```json
{
  "code": 422,
  "message": "Failed to connect to device: Connection refused (os error 61)",
  "data": {
    "device_id": "uuid",
    "protocol_type": "modbus-tcp",
    "host": "192.168.1.100:502"
  }
}
```
