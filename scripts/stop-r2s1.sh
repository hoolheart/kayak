#!/bin/bash
# =============================================================================
# Sprint 1 开发环境优雅停止脚本
# R2-S1-003-A: 停止后端 + 前端开发服务器
# =============================================================================

set -e

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# PID 文件
BACKEND_PID_FILE="$LOG_DIR/backend.pid"
FRONTEND_PID_FILE="$LOG_DIR/frontend.pid"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Kayak Sprint 1 开发环境停止${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

STOPPED=0

# 停止通过 PID 文件记录的后端进程
stop_backend_by_pidfile() {
    if [ -f "$BACKEND_PID_FILE" ]; then
        local pid
        pid=$(cat "$BACKEND_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}▶ 停止后端进程 (PID: $pid)...${NC}"
            kill "$pid" 2>/dev/null || true
            local attempts=0
            while kill -0 "$pid" 2>/dev/null && [ $attempts -lt 10 ]; do
                sleep 1
                attempts=$((attempts + 1))
            done
            if kill -0 "$pid" 2>/dev/null; then
                echo "  强制终止后端进程..."
                kill -9 "$pid" 2>/dev/null || true
            fi
            echo -e "${GREEN}✓ 后端已停止${NC}"
            STOPPED=1
        else
            echo -e "${BLUE}ℹ 后端进程 (PID: $pid) 已不存在${NC}"
        fi
        rm -f "$BACKEND_PID_FILE"
    fi
}

# 停止通过 PID 文件记录的前端进程
stop_frontend_by_pidfile() {
    if [ -f "$FRONTEND_PID_FILE" ]; then
        local pid
        pid=$(cat "$FRONTEND_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}▶ 停止前端进程 (PID: $pid)...${NC}"
            kill "$pid" 2>/dev/null || true
            local attempts=0
            while kill -0 "$pid" 2>/dev/null && [ $attempts -lt 10 ]; do
                sleep 1
                attempts=$((attempts + 1))
            done
            if kill -0 "$pid" 2>/dev/null; then
                echo "  强制终止前端进程..."
                kill -9 "$pid" 2>/dev/null || true
            fi
            echo -e "${GREEN}✓ 前端已停止${NC}"
            STOPPED=1
        else
            echo -e "${BLUE}ℹ 前端进程 (PID: $pid) 已不存在${NC}"
        fi
        rm -f "$FRONTEND_PID_FILE"
    fi
}

# 查找并停止 cargo run 进程
stop_cargo_processes() {
    local cargo_pids
    cargo_pids=$(pgrep -f "cargo run" || true)
    
    if [ -n "$cargo_pids" ]; then
        echo -e "${YELLOW}▶ 发现 cargo run 进程:${NC}"
        echo "$cargo_pids" | while read -r pid; do
            echo "  PID: $pid"
            kill "$pid" 2>/dev/null || true
        done
        
        sleep 2
        
        # 检查是否还有残留
        local remaining
        remaining=$(pgrep -f "cargo run" || true)
        if [ -n "$remaining" ]; then
            echo "  强制终止残留的 cargo 进程..."
            echo "$remaining" | while read -r pid; do
                kill -9 "$pid" 2>/dev/null || true
            done
        fi
        
        echo -e "${GREEN}✓ cargo run 进程已清理${NC}"
        STOPPED=1
    fi
}

# 查找并停止 kayak-backend 相关进程
stop_backend_processes() {
    local backend_pids
    backend_pids=$(pgrep -f "kayak-backend" || true)
    
    if [ -n "$backend_pids" ]; then
        echo -e "${YELLOW}▶ 发现 kayak-backend 进程:${NC}"
        echo "$backend_pids" | while read -r pid; do
            echo "  PID: $pid"
            kill "$pid" 2>/dev/null || true
        done
        
        sleep 2
        
        local remaining
        remaining=$(pgrep -f "kayak-backend" || true)
        if [ -n "$remaining" ]; then
            echo "  强制终止残留的后端进程..."
            echo "$remaining" | while read -r pid; do
                kill -9 "$pid" 2>/dev/null || true
            done
        fi
        
        echo -e "${GREEN}✓ kayak-backend 进程已清理${NC}"
        STOPPED=1
    fi
}

# 查找并停止 flutter run 进程
stop_flutter_processes() {
    local flutter_pids
    flutter_pids=$(pgrep -f "flutter run" || true)
    
    if [ -n "$flutter_pids" ]; then
        echo -e "${YELLOW}▶ 发现 flutter run 进程:${NC}"
        echo "$flutter_pids" | while read -r pid; do
            echo "  PID: $pid"
            kill "$pid" 2>/dev/null || true
        done
        
        sleep 2
        
        local remaining
        remaining=$(pgrep -f "flutter run" || true)
        if [ -n "$remaining" ]; then
            echo "  强制终止残留的 flutter 进程..."
            echo "$remaining" | while read -r pid; do
                kill -9 "$pid" 2>/dev/null || true
            done
        fi
        
        echo -e "${GREEN}✓ flutter run 进程已清理${NC}"
        STOPPED=1
    fi
}

# 查找并停止 flutter_tools 子进程（dart 进程）
stop_dart_processes() {
    local dart_pids
    # 查找与 flutter web 开发相关的 dart 进程
    dart_pids=$(pgrep -f "dart.*flutter_tools" || true)
    
    if [ -n "$dart_pids" ]; then
        echo -e "${YELLOW}▶ 发现 flutter_tools 进程:${NC}"
        echo "$dart_pids" | while read -r pid; do
            echo "  PID: $pid"
            kill "$pid" 2>/dev/null || true
        done
        sleep 1
        echo -e "${GREEN}✓ flutter_tools 进程已清理${NC}"
        STOPPED=1
    fi
}

# 确认所有进程已停止
confirm_stopped() {
    echo ""
    echo -e "${YELLOW}▶ 确认所有服务已停止...${NC}"
    
    local cargo_remaining
    cargo_remaining=$(pgrep -f "cargo run" || true)
    
    local backend_remaining
    backend_remaining=$(pgrep -f "kayak-backend" || true)
    
    local flutter_remaining
    flutter_remaining=$(pgrep -f "flutter run" || true)
    
    local dart_remaining
    dart_remaining=$(pgrep -f "dart.*flutter_tools" || true)
    
    if [ -z "$cargo_remaining" ] && [ -z "$backend_remaining" ] && [ -z "$flutter_remaining" ] && [ -z "$dart_remaining" ]; then
        echo -e "${GREEN}✓ 所有进程已确认停止${NC}"
    else
        echo -e "${YELLOW}⚠ 以下进程仍在运行:${NC}"
        [ -n "$cargo_remaining" ] && echo "  cargo run: $cargo_remaining"
        [ -n "$backend_remaining" ] && echo "  kayak-backend: $backend_remaining"
        [ -n "$flutter_remaining" ] && echo "  flutter run: $flutter_remaining"
        [ -n "$dart_remaining" ] && echo "  flutter_tools: $dart_remaining"
    fi
}

# 主流程
main() {
    # 优先使用 PID 文件精确停止
    stop_backend_by_pidfile
    stop_frontend_by_pidfile
    
    # 兜底：查找并停止任何残留的相关进程
    stop_cargo_processes
    stop_backend_processes
    stop_flutter_processes
    stop_dart_processes
    
    # 确认
    confirm_stopped
    
    echo ""
    if [ $STOPPED -eq 1 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Sprint 1 开发环境已停止${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}  没有发现运行中的 Sprint 1 服务${NC}"
        echo -e "${BLUE}========================================${NC}"
    fi
}

main "$@"
