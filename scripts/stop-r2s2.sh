#!/bin/bash
# =============================================================================
# Sprint 2 开发环境优雅停止脚本
# R2-S2-004-A: 停止后端 + 前端开发服务器
# =============================================================================

set -euo pipefail

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"

# PID 文件（Sprint 2 统一使用 /tmp）
PID_FILE="/tmp/kayak-r2s2.pids"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 状态跟踪
STOPPED=0

# =============================================================================
# 辅助函数
# =============================================================================

# 从 PID 文件读取指定 key 的值
read_pid_from_file() {
    local key="$1"
    if [ -f "$PID_FILE" ]; then
        grep "^${key}=" "$PID_FILE" 2>/dev/null | cut -d= -f2 || true
    else
        echo ""
    fi
}

# 优雅停止单个进程
stop_process_graceful() {
    local pid="$1"
    local name="$2"
    local max_wait="${3:-10}"

    if [ -z "$pid" ]; then
        return 1
    fi

    # 检查进程是否存在
    if ! kill -0 "$pid" 2>/dev/null; then
        echo -e "${BLUE}  ℹ $name 进程 (PID: $pid) 已不存在${NC}"
        return 1
    fi

    echo -e "${YELLOW}  ▶ 停止 $name (PID: $pid)...${NC}"

    # 发送 TERM 信号
    kill "$pid" 2>/dev/null || true

    # 等待进程退出
    local attempts=0
    while kill -0 "$pid" 2>/dev/null && [ $attempts -lt "$max_wait" ]; do
        sleep 1
        attempts=$((attempts + 1))
    done

    # 如果还在运行，发送 KILL
    if kill -0 "$pid" 2>/dev/null; then
        echo "    $name 未响应，强制终止..."
        kill -9 "$pid" 2>/dev/null || true
        sleep 1
    fi

    # 最终确认
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${RED}  ✗ 无法停止 $name (PID: $pid)${NC}"
        return 1
    else
        echo -e "${GREEN}  ✓ $name 已停止${NC}"
        return 0
    fi
}

# =============================================================================
# 停止函数
# =============================================================================

stop_from_pid_file() {
    echo -e "${YELLOW}▶ 从 PID 文件停止进程...${NC}"

    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}  ⚠ PID 文件不存在: $PID_FILE${NC}"
        echo "    将尝试通过进程名查找并停止。"
        return 1
    fi

    local backend_pid
    local frontend_pid

    backend_pid=$(read_pid_from_file "backend")
    frontend_pid=$(read_pid_from_file "frontend")

    local stopped_any=0

    if [ -n "$backend_pid" ]; then
        if stop_process_graceful "$backend_pid" "后端" 10; then
            stopped_any=1
        fi
    fi

    if [ -n "$frontend_pid" ]; then
        if stop_process_graceful "$frontend_pid" "前端" 10; then
            stopped_any=1
        fi
    fi

    # 清理 PID 文件
    rm -f "$PID_FILE"
    echo -e "${BLUE}  ℹ 已清理 PID 文件${NC}"

    if [ $stopped_any -eq 1 ]; then
        STOPPED=1
    fi

    return 0
}

# 兜底：通过进程名停止
stop_by_process_name() {
    echo -e "${YELLOW}▶ 通过进程名查找并停止...${NC}"

    # 停止 cargo run 进程
    local cargo_pids
    cargo_pids=$(pgrep -f "cargo run" || true)
    if [ -n "$cargo_pids" ]; then
        echo -e "${YELLOW}  ▶ 发现 cargo run 进程:${NC}"
        echo "$cargo_pids" | while IFS= read -r pid; do
            [ -n "$pid" ] && stop_process_graceful "$pid" "cargo" 5
        done
        STOPPED=1
    fi

    # 停止 kayak-backend 进程
    local backend_pids
    backend_pids=$(pgrep -f "kayak-backend" || true)
    if [ -n "$backend_pids" ]; then
        echo -e "${YELLOW}  ▶ 发现 kayak-backend 进程:${NC}"
        echo "$backend_pids" | while IFS= read -r pid; do
            [ -n "$pid" ] && stop_process_graceful "$pid" "kayak-backend" 5
        done
        STOPPED=1
    fi

    # 停止 flutter run 进程
    local flutter_pids
    flutter_pids=$(pgrep -f "flutter run" || true)
    if [ -n "$flutter_pids" ]; then
        echo -e "${YELLOW}  ▶ 发现 flutter run 进程:${NC}"
        echo "$flutter_pids" | while IFS= read -r pid; do
            [ -n "$pid" ] && stop_process_graceful "$pid" "flutter run" 5
        done
        STOPPED=1
    fi

    # 停止 flutter_tools dart 进程
    local dart_pids
    dart_pids=$(pgrep -f "dart.*flutter_tools" || true)
    if [ -n "$dart_pids" ]; then
        echo -e "${YELLOW}  ▶ 发现 flutter_tools 进程:${NC}"
        echo "$dart_pids" | while IFS= read -r pid; do
            [ -n "$pid" ] && stop_process_graceful "$pid" "flutter_tools" 5
        done
        STOPPED=1
    fi
}

# =============================================================================
# 验证函数
# =============================================================================

verify_stopped() {
    echo ""
    echo -e "${YELLOW}▶ 验证所有服务已停止...${NC}"

    local remaining=()

    if pgrep -f "cargo run" > /dev/null 2>&1; then
        remaining+=("cargo run")
    fi

    if pgrep -f "kayak-backend" > /dev/null 2>&1; then
        remaining+=("kayak-backend")
    fi

    if pgrep -f "flutter run" > /dev/null 2>&1; then
        remaining+=("flutter run")
    fi

    if pgrep -f "dart.*flutter_tools" > /dev/null 2>&1; then
        remaining+=("flutter_tools")
    fi

    if [ ${#remaining[@]} -eq 0 ]; then
        echo -e "${GREEN}  ✓ 所有进程已确认停止${NC}"
        return 0
    else
        echo -e "${YELLOW}  ⚠ 以下进程仍在运行:${NC}"
        for proc in "${remaining[@]}"; do
            echo "      - $proc"
        done
        echo ""
        echo -e "${YELLOW}  可以尝试手动停止: pkill -9 -f <进程名>${NC}"
        return 1
    fi
}

# =============================================================================
# 主流程
# =============================================================================

show_help() {
    cat << EOF
Kayak Sprint 2 开发环境停止脚本

用法: $0 [选项]

选项:
    --help, -h      显示此帮助信息

说明:
    本脚本会读取 /tmp/kayak-r2s2.pids 中的 PID 信息，
    优雅地停止后端和前端开发服务器。
    如果 PID 文件不存在，则通过进程名查找并停止相关进程。
EOF
}

main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            ;;
        *)
            echo -e "${RED}错误: 未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac

    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  Kayak Sprint 2 开发环境停止${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""

    # 优先使用 PID 文件精确停止
    stop_from_pid_file

    # 兜底：查找并停止任何残留的相关进程
    stop_by_process_name

    # 验证
    verify_stopped
    local verify_status=$?

    echo ""
    if [ $STOPPED -eq 1 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Sprint 2 开发环境已停止${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}  没有发现运行中的 Sprint 2 服务${NC}"
        echo -e "${BLUE}========================================${NC}"
    fi

    # 清理 PID 文件（即使之前不存在也确保删除）
    rm -f "$PID_FILE"

    exit $verify_status
}

main "$@"
