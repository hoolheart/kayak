# TASK-019: Device + Point Integration Test Cases

## Test Information
- **Task ID**: TASK-019
- **Tester**: sw-mike
- **Date**: 2026-06-01
- **Scope**: Cross-component integration testing for Device Tree, Device Config Dialog, and Point List Widget
- **Sprint**: Sprint 4

## Related Tasks
- TASK-015: Device Service/Provider
- TASK-016: Device Tree Component UI
- TASK-017: Device Config Form UI
- TASK-018: Point Service/Provider

---

## Overview

This document contains integration test cases covering end-to-end user journeys across device management and point management components. These tests verify that:
1. DeviceTree, DeviceConfigDialog, WorkbenchDetailPage, and PointListWidget work together correctly
2. State changes in one component reflect in others
3. Three-state handling (Loading/Data/Error+Empty) works across component boundaries

---

## Journey A: Add Virtual Device and Configure Points

### INT-A-01: Complete device + point creation flow
**Priority**: P0
**Preconditions**:
- User is authenticated
- Workbench "wb-test" exists with no devices

**Test Steps**:
1. Navigate to WorkbenchDetailPage for "wb-test"
2. Verify device tree shows empty state with "No devices yet" message
3. Click "+" add device button in device tree header
4. In DeviceConfigDialog:
   a. Enter device name "Test Virtual Device"
   b. Select Protocol Type "Virtual"
   c. Select Virtual Mode "random"
   d. Select Data Type "float32"
   e. Enter Min Value "0", Max Value "100"
   f. Enter Update Interval "1000"
   g. Click "Save"
5. Verify device appears in device tree
6. Verify device is auto-selected
7. Verify device detail panel shows device info
8. Verify point list shows empty state "No points yet"
9. Click "Add Point" button
10. In PointFormDialog:
    a. Enter point name "Temperature"
    b. Select Data Type "Number"
    c. Select Access Type "RO"
    d. Enter Unit "°C"
    e. Click "Save"
11. Verify point appears in point list
12. Verify point count shows "1 point"

**Expected Results**:
- Device created successfully with correct protocol params
- Device tree refreshes and shows new device
- Device detail panel updates
- Point list refreshes and shows new point
- All state transitions work without errors

### INT-A-02: Edit point and verify list updates
**Priority**: P0
**Preconditions**:
- Journey A-01 completed
- Device "Test Virtual Device" with point "Temperature" exists

**Test Steps**:
1. With device selected, verify point "Temperature" visible in list
2. Click edit icon on "Temperature" point
3. In PointFormDialog:
   a. Change name to "Temperature Sensor"
   b. Change unit to "°F"
   c. Click "Save"
4. Verify point list updates with new name and unit

**Expected Results**:
- Point updated successfully
- List refreshes without full page reload
- Updated values display correctly

### INT-A-03: Delete point and verify tree remains
**Priority**: P0
**Preconditions**:
- Journey A-02 completed

**Test Steps**:
1. Click delete icon on "Temperature Sensor" point
2. Verify ConfirmDialog appears with point name
3. Click "Delete" to confirm
4. Verify point list shows empty state
5. Verify device tree still shows "Test Virtual Device"
6. Verify device is still selected

**Expected Results**:
- Point deleted successfully
- Point list shows empty state
- Device tree unaffected
- Device selection preserved

---

## Journey B: Modbus TCP Device + Point Configuration

### INT-B-01: Create Modbus TCP device with points
**Priority**: P0
**Preconditions**:
- User is authenticated
- Workbench "wb-test" exists

**Test Steps**:
1. Navigate to WorkbenchDetailPage for "wb-test"
2. Click "+" add device button
3. In DeviceConfigDialog:
   a. Enter device name "PLC Controller"
   b. Select Protocol Type "Modbus TCP"
   c. Enter Host "192.168.1.100"
   d. Enter Port "502"
   e. Enter Slave ID "1"
   f. Enter Timeout "5000"
   g. Click "Save"
4. Verify device appears in tree with LAN icon
5. Verify device detail panel shows protocol params (host, port)
6. Click "Add Point"
7. In PointFormDialog:
   a. Enter point name "Coil Status"
   b. Select Data Type "Boolean"
   c. Select Access Type "RW"
   d. Verify Modbus config section appears (register type, address, data format)
   e. Select Register Type "Coil"
   f. Enter Address "1000"
   g. Select Data Format "uint16"
   h. Click "Save"
8. Verify point appears in list with Modbus info

**Expected Results**:
- Modbus TCP device created with correct params
- Device detail shows protocol configuration
- Modbus-specific fields visible in point form
- Point created with Modbus configuration

### INT-B-02: Create Modbus RTU device
**Priority**: P1
**Preconditions**:
- Workbench "wb-test" exists

**Test Steps**:
1. Click "+" add device button
2. In DeviceConfigDialog:
   a. Enter device name "Serial Sensor"
   b. Select Protocol Type "Modbus RTU"
   c. Enter Serial Port "/dev/ttyUSB0"
   d. Select Baud Rate "9600"
   e. Select Data Bits "8"
   f. Select Stop Bits "1"
   g. Select Parity "None"
   h. Enter Slave ID "2"
   i. Enter Timeout "3000"
   j. Click "Save"
3. Verify device appears in tree with Cable icon
4. Select device and verify protocol params displayed

**Expected Results**:
- Modbus RTU device created with all serial params
- Protocol params displayed in detail panel

---

## Journey C: Device Tree and Point List Interaction

### INT-C-01: Switch between devices updates point list
**Priority**: P0
**Preconditions**:
- Workbench with 2+ devices, each with different points

**Test Steps**:
1. Navigate to WorkbenchDetailPage
2. Verify Device A visible in tree
3. Click Device A
4. Verify Point List shows Device A's points
5. Click Device B in tree
6. Verify Point List updates to show Device B's points
7. Verify Device A's points no longer visible

**Expected Results**:
- Point list correctly switches between devices
- No stale data from previous device
- State transitions smooth

### INT-C-02: Delete device refreshes tree and clears detail
**Priority**: P0
**Preconditions**:
- Workbench with 2 devices (Device A and Device B)
- Device A selected with points visible

**Test Steps**:
1. Select Device A
2. Open context menu (more_vert icon)
3. Click "Delete Device"
4. Confirm deletion in dialog
5. Verify Device A removed from tree
6. Verify detail panel shows placeholder (no device selected)
7. Verify Device B still in tree

**Expected Results**:
- Device deleted successfully
- Tree refreshes without deleted device
- Detail panel returns to placeholder state
- Other devices unaffected

### INT-C-03: Device tree empty state to data transition
**Priority**: P1
**Preconditions**:
- Workbench with no devices

**Test Steps**:
1. Navigate to empty workbench
2. Verify empty state shown
3. Add first device
4. Verify empty state replaced with device tree
5. Delete all devices
6. Verify empty state returns

**Expected Results**:
- Empty state shown when no devices
- Tree shown when devices exist
- Transitions smooth without errors

---

## Error Handling Tests

### INT-E-01: Device creation failure handling
**Priority**: P1
**Preconditions**:
- Backend returns error on device create

**Test Steps**:
1. Open add device dialog
2. Fill in required fields
3. Submit form with backend error
4. Verify error message displayed
5. Verify dialog remains open
6. Verify device tree unchanged

**Expected Results**:
- Error handled gracefully
- User can retry
- No state corruption

### INT-E-02: Point list error recovery
**Priority**: P1
**Preconditions**:
- Device exists but point list fails to load

**Test Steps**:
1. Select device
2. Point list shows error state
3. Click "Retry" button
4. Verify list reloads

**Expected Results**:
- Error state shown with retry option
- Retry successfully reloads data

---

## Responsive Layout Tests

### INT-R-01: Desktop layout (>1024px)
**Priority**: P1
**Preconditions**:
- Desktop screen size

**Test Steps**:
1. Verify left panel (device tree) and right panel (detail) side by side
2. Verify tree width approximately 280px
3. Verify detail panel flexes to fill remaining space

**Expected Results**:
- Two-column layout
- Proper panel proportions

### INT-R-02: Mobile layout (<600px)
**Priority**: P1
**Preconditions**:
- Mobile screen size

**Test Steps**:
1. Verify panels stack vertically
2. Verify device tree collapsible
3. Verify point list shows cards instead of table

**Expected Results**:
- Single column layout
- Collapsible tree panel
- Card-based point list

---

## Test Data Requirements

### Workbenches
| ID | Name | Status | Devices |
|----|------|--------|---------|
| wb-empty | Empty Workbench | active | 0 |
| wb-test | Test Workbench | active | 2 |

### Devices (for wb-test)
| ID | Name | Protocol | Parent | Status |
|----|------|----------|--------|--------|
| dev-1 | Virtual Sensor | Virtual | null | online |
| dev-2 | PLC Controller | Modbus TCP | null | offline |
| dev-3 | Serial Device | Modbus RTU | null | online |

### Points (for dev-1)
| ID | Name | Data Type | Access | Unit |
|----|------|-----------|--------|------|
| pt-1 | Temperature | Number | RO | °C |
| pt-2 | Pressure | Integer | RO | MPa |

### Points (for dev-2)
| ID | Name | Data Type | Access | Unit |
|----|------|-----------|--------|------|
| pt-3 | Coil Status | Boolean | RW | — |

---

## Traceability Matrix

| Test Case | PRD Requirement | Tasks Covered |
|-----------|----------------|---------------|
| INT-A-01 | US-DEV-001, US-PT-001 | TASK-015, TASK-016, TASK-017, TASK-018 |
| INT-A-02 | US-PT-004 | TASK-018, TASK-019 |
| INT-A-03 | US-PT-004, US-DEV-004 | TASK-016, TASK-018 |
| INT-B-01 | US-DEV-005, US-PT-005 | TASK-017, TASK-019 |
| INT-B-02 | US-DEV-005 | TASK-017 |
| INT-C-01 | US-DEV-002, US-PT-003 | TASK-016, TASK-019 |
| INT-C-02 | US-DEV-004 | TASK-016 |
| INT-C-03 | US-DEV-002 | TASK-016 |
| INT-E-01 | M5 error handling | TASK-015, TASK-017 |
| INT-E-02 | M6 error handling | TASK-018 |
| INT-R-01 | Mobile adaptation | TASK-014, TASK-016 |
| INT-R-02 | Mobile adaptation | TASK-014, TASK-019 |

---

## Test Execution Checklist

- [ ] All Journey A tests executed
- [ ] All Journey B tests executed
- [ ] All Journey C tests executed
- [ ] Error handling tests executed
- [ ] Responsive layout tests executed
- [ ] All tests pass
- [ ] Bugs documented (if any)
